import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

/// المستودع الرئيسي - يتعامل مع جميع جداول PostgreSQL
class AppRepository {
  SupabaseClient get _db => Supabase.instance.client;

  // ═══════════════════════════════════════════════════════
  // BOOKINGS
  // ═══════════════════════════════════════════════════════

  Future<List<BookingModel>> fetchBookings({
    String? statusFilter,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _db.from('bookings').select('''
      *, 
      customers(name, phone),
      suppliers(name)
    ''');

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('booking_status', statusFilter);
    }
    if (fromDate != null) {
      query = query.gte('departure_date', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('departure_date', toDate.toIso8601String());
    }

    final rows = await query.order('created_at', ascending: false);

    var result = rows.map<BookingModel>((r) => BookingModel.fromJson(r)).toList();

    // البحث النصي محلياً (PNR / الاسم / رقم التذكرة)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((b) =>
        b.passengerName.toLowerCase().contains(q) ||
        b.pnr.toLowerCase().contains(q) ||
        (b.ticketNumber?.toLowerCase().contains(q) ?? false) ||
        (b.passengerPhone?.contains(q) ?? false)
      ).toList();
    }
    return result;
  }

  Future<BookingModel?> fetchBookingById(String id) async {
    final row = await _db.from('bookings').select('''
      *, customers(name, phone), suppliers(name)
    ''').eq('id', id).maybeSingle();
    return row != null ? BookingModel.fromJson(row) : null;
  }

  Future<BookingModel> createBooking(BookingModel b) async {
    final row = await _db.from('bookings').insert(b.toJson()).select().single();
    final created = BookingModel.fromJson(row);

    // قيد دفتر الأستاذ تلقائياً
    await _addLedgerEntry(LedgerEntryModel(
      id: '', type: LedgerType.customerPayment,
      amount: created.salePrice, direction: 'debit',
      bookingId: created.id, customerId: created.customerId,
      description: 'حجز جديد - ${created.passengerName} (${created.pnr})',
      createdAt: DateTime.now(),
    ));
    return created;
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    await _db.from('bookings')
        .update({'booking_status': status.name}).eq('id', id);
  }

  Future<void> registerPayment({
    required String bookingId,
    required String? customerId,
    required double amount,
    required String method,
    String? notes,
  }) async {
    // تسجيل الدفعة
    await _db.from('payments').insert({
      'booking_id': bookingId, 'customer_id': customerId,
      'amount': amount, 'method': method, 'notes': notes,
    });

    // تحديث حالة الدفع بناءً على إجمالي المدفوعات
    final payments = await _db.from('payments')
        .select('amount').eq('booking_id', bookingId);
    final totalPaid = (payments as List)
        .fold<double>(0, (s, r) => s + (r['amount'] as num).toDouble());

    final booking = await fetchBookingById(bookingId);
    if (booking == null) return;

    final newStatus = totalPaid >= booking.salePrice
        ? PaymentStatus.paid
        : totalPaid > 0
            ? PaymentStatus.partial
            : PaymentStatus.unpaid;

    await _db.from('bookings')
        .update({'payment_status': newStatus.name}).eq('id', bookingId);

    // قيد دفتر الأستاذ
    await _addLedgerEntry(LedgerEntryModel(
      id: '', type: LedgerType.customerPayment,
      amount: amount, direction: 'credit',
      bookingId: bookingId, customerId: customerId,
      description: 'دفعة من العميل - ${method == "cash" ? "نقداً" : "تحويل"}',
      createdAt: DateTime.now(),
    ));
  }

  // ═══════════════════════════════════════════════════════
  // CUSTOMERS
  // ═══════════════════════════════════════════════════════

  Future<List<CustomerModel>> fetchCustomers({String? search}) async {
    final rows = await _db.from('customers')
        .select().order('name', ascending: true);
    var list = rows.map<CustomerModel>((r) => CustomerModel.fromJson(r)).toList();
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.phone?.contains(q) ?? false)
      ).toList();
    }
    return list;
  }

  Future<CustomerModel> createCustomer(CustomerModel c) async {
    final row = await _db.from('customers').insert(c.toJson()).select().single();
    return CustomerModel.fromJson(row);
  }

  // ═══════════════════════════════════════════════════════
  // SUPPLIERS
  // ═══════════════════════════════════════════════════════

  Future<List<SupplierModel>> fetchSuppliers() async {
    final rows = await _db.from('suppliers').select().order('name');
    return rows.map<SupplierModel>((r) => SupplierModel.fromJson(r)).toList();
  }

  Future<SupplierModel> createSupplier(SupplierModel s) async {
    final row = await _db.from('suppliers').insert(s.toJson()).select().single();
    return SupplierModel.fromJson(row);
  }

  // ═══════════════════════════════════════════════════════
  // REFUNDS (6 مراحل)
  // ═══════════════════════════════════════════════════════

  Future<List<RefundModel>> fetchRefunds({String? priorityFilter}) async {
    var query = _db.from('refunds').select();
    if (priorityFilter != null) query = query.eq('priority', priorityFilter);
    final rows = await query.order('requested_at', ascending: false);
    return rows.map<RefundModel>((r) => RefundModel.fromJson(r)).toList();
  }

  Future<RefundModel> createRefund(RefundModel r) async {
    final data = r.toJson();
    final row = await _db.from('refunds').insert(data).select().single();
    final created = RefundModel.fromJson(row);

    // تحديث حالة الحجز
    await updateBookingStatus(r.bookingId, BookingStatus.refundRequested);

    // قيد دفتر الأستاذ
    await _addLedgerEntry(LedgerEntryModel(
      id: '', type: LedgerType.refundToCustomer,
      amount: r.refundAmount, direction: 'debit',
      bookingId: r.bookingId, refundId: created.id,
      customerId: r.customerId,
      description: 'طلب استرداد - ${r.passengerName}',
      createdAt: DateTime.now(),
    ));
    return created;
  }

  Future<void> updateRefundStatus(String refundId, RefundStatus status) async {
    final update = <String, dynamic>{'refund_status': status.dbValue};
    if (status == RefundStatus.closed) {
      update['closed_at'] = DateTime.now().toIso8601String();
    }
    await _db.from('refunds').update(update).eq('id', refundId);
  }

  Future<void> updateRefundPriority(String refundId, RefundPriority p) async {
    await _db.from('refunds').update({'priority': p.name}).eq('id', refundId);
  }

  // ═══════════════════════════════════════════════════════
  // LEDGER
  // ═══════════════════════════════════════════════════════

  Future<List<LedgerEntryModel>> fetchLedger({
    String? customerId, String? supplierId,
    DateTime? from, DateTime? to, int limit = 50,
  }) async {
    var query = _db.from('ledger_entries').select();
    if (customerId != null) query = query.eq('customer_id', customerId);
    if (supplierId != null) query = query.eq('supplier_id', supplierId);
    if (from != null) query = query.gte('created_at', from.toIso8601String());
    if (to != null) query = query.lte('created_at', to.toIso8601String());

    final rows = await query
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map<LedgerEntryModel>((r) => LedgerEntryModel.fromJson(r)).toList();
  }

  Future<void> addManualLedgerEntry({
    required LedgerType type,
    required double amount,
    required String description,
    String? customerId, String? supplierId, String? reference,
  }) async {
    await _addLedgerEntry(LedgerEntryModel(
      id: '', type: type, amount: amount,
      direction: type.isInflow ? 'credit' : 'debit',
      customerId: customerId, supplierId: supplierId,
      description: description, reference: reference,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> _addLedgerEntry(LedgerEntryModel entry) async {
    await _db.from('ledger_entries').insert(entry.toJson());
  }

  // ═══════════════════════════════════════════════════════
  // DASHBOARD KPIs
  // ═══════════════════════════════════════════════════════

  Future<DashboardKPIs> fetchDashboardKPIs() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    final results = await Future.wait([
      // حجوزات اليوم
      _db.from('bookings').select('id').gte('created_at', todayStart.toIso8601String()),
      // حجوزات الشهر
      _db.from('bookings').select('sale_price,cost_price,booking_status')
          .gte('created_at', monthStart.toIso8601String()),
      // مرتجعات معلقة
      _db.from('refunds').select('refund_amount,refund_status')
          .neq('refund_status', 'closed'),
      // أحدث قيود دفتر الأستاذ للرصيد النقدي
      _db.from('ledger_entries').select('amount,direction').limit(200),
    ]);

    final todayBookings = (results[0] as List).length;
    final monthBookings = results[1] as List;
    final pendingRefunds = results[2] as List;
    final ledgerEntries = results[3] as List;

    double monthlyRevenue = 0, monthlyProfit = 0;
    for (final b in monthBookings) {
      if (b['booking_status'] != 'cancelled') {
        monthlyRevenue += (b['sale_price'] as num?)?.toDouble() ?? 0;
        monthlyProfit += ((b['sale_price'] as num?)?.toDouble() ?? 0) -
            ((b['cost_price'] as num?)?.toDouble() ?? 0);
      }
    }

    double pendingRefundTotal = 0;
    for (final r in pendingRefunds) {
      if (r['refund_status'] != 'paid_to_customer') {
        pendingRefundTotal += (r['refund_amount'] as num?)?.toDouble() ?? 0;
      }
    }

    double cashPosition = 0;
    for (final e in ledgerEntries) {
      final amount = (e['amount'] as num).toDouble();
      cashPosition += e['direction'] == 'credit' ? amount : -amount;
    }

    return DashboardKPIs(
      todayBookings: todayBookings,
      monthlyRevenue: monthlyRevenue,
      monthlyProfit: monthlyProfit,
      pendingRefundsTotal: pendingRefundTotal,
      cashPosition: cashPosition,
    );
  }
}

/// KPIs للداشبورد
class DashboardKPIs {
  final int todayBookings;
  final double monthlyRevenue;
  final double monthlyProfit;
  final double pendingRefundsTotal;
  final double cashPosition;

  const DashboardKPIs({
    this.todayBookings = 0, this.monthlyRevenue = 0,
    this.monthlyProfit = 0, this.pendingRefundsTotal = 0,
    this.cashPosition = 0,
  });
}
