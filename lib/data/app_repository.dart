import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import '../models/finance_model.dart';
import '../models/refund_model.dart';
import '../models/transaction_model.dart';

/// طبقة البيانات الحقيقية - تتعامل مع PostgreSQL عبر Supabase
class AppRepository {
  SupabaseClient get _db => Supabase.instance.client;

  // ==================== الحجوزات ====================

  /// جلب كل الحجوزات (الأحدث أولاً)
  Future<List<BookingModel>> fetchBookings() async {
    final rows = await _db
        .from('bookings')
        .select()
        .order('created_at', ascending: false);
    return rows.map<BookingModel>((r) => BookingModel.fromJson(r)).toList();
  }

  /// إضافة حجز جديد مع سجله المالي (عمليتان مرتبطتان)
  /// ملاحظة: الـ id يولّده PostgreSQL تلقائياً (UUID)
  Future<void> addBooking({
    required String passengerName,
    required String pnr,
    required String ticketNumber,
    required String departureCity,
    required String arrivalCity,
    required DateTime flightDate,
    required BookingStatus status,
    required double purchasePrice,
    required double sellingPrice,
    required double paidAmount,
  }) async {
    // 1) إدراج الحجز واستلام الـ id المولّد
    final inserted = await _db
        .from('bookings')
        .insert({
          'passenger_name': passengerName,
          'pnr': pnr,
          'ticket_number': ticketNumber,
          'departure_city': departureCity,
          'arrival_city': arrivalCity,
          'flight_date': flightDate.toIso8601String(),
          'status': status.name,
        })
        .select()
        .single();

    // 2) إدراج السجل المالي المرتبط
    await _db.from('finances').insert({
      'booking_id': inserted['id'],
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'paid_amount': paidAmount,
    });
  }

  // ==================== الماليات ====================

  /// جلب كل السجلات المالية كخريطة bookingId → FinanceModel
  Future<Map<String, FinanceModel>> fetchFinances() async {
    final rows = await _db.from('finances').select();
    final map = <String, FinanceModel>{};
    for (final r in rows) {
      final f = FinanceModel.fromJson(r);
      map[f.bookingId] = f;
    }
    return map;
  }

  // ==================== المرتجعات ====================

  Future<List<RefundModel>> fetchRefunds() async {
    final rows = await _db
        .from('refunds')
        .select()
        .order('created_at', ascending: false);
    return rows.map<RefundModel>((r) => RefundModel.fromJson(r)).toList();
  }

  /// إنشاء طلب استرداد جديد
  Future<void> addRefund({
    required String bookingId,
    required String customerName,
    required String ticketNumber,
    required double refundAmount,
  }) async {
    await _db.from('refunds').insert({
      'booking_id': bookingId,
      'customer_name': customerName,
      'ticket_number': ticketNumber,
      'refund_amount': refundAmount,
      'refund_status': RefundStatus.requested.name,
    });
    // تحديث حالة الحجز إلى "مرتجع"
    await _db
        .from('bookings')
        .update({'status': BookingStatus.refunded.name})
        .eq('id', bookingId);
  }

  /// تحديث مرحلة الاسترداد
  Future<void> updateRefundStatus(String refundId, RefundStatus s) async {
    await _db
        .from('refunds')
        .update({'refund_status': s.name})
        .eq('refund_id', refundId);
  }

  // ==================== الحركات المالية ====================

  Future<List<TransactionModel>> fetchTransactions() async {
    final rows = await _db
        .from('transactions')
        .select()
        .order('created_at', ascending: false);
    return rows
        .map<TransactionModel>((r) => TransactionModel.fromJson(r))
        .toList();
  }

  Future<void> addTransaction({
    required TransactionType type,
    required double amount,
    String? note,
  }) async {
    await _db.from('transactions').insert({
      'type': type.name,
      'amount': amount,
      'note': note,
    });
  }
}
