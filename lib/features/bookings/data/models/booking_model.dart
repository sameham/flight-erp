// ═══════════════════════════════════════════════════════════
// Enterprise Models v2.0
// ═══════════════════════════════════════════════════════════

import 'package:equatable/equatable.dart';

// ───────────────────────────────────────────────────────────
// Enums
// ───────────────────────────────────────────────────────────

enum BookingStatus {
  pending, issued, cancelled, refundRequested, refundCompleted;

  String get labelAr {
    const labels = {
      'pending': 'معلق', 'issued': 'مصدرة', 'cancelled': 'ملغي',
      'refundRequested': 'طلب استرداد', 'refundCompleted': 'اكتمل الاسترداد',
    };
    return labels[name] ?? name;
  }

  static BookingStatus fromString(String v) =>
      BookingStatus.values.firstWhere((e) => e.name == v,
          orElse: () => BookingStatus.pending);
}

enum PaymentStatus {
  paid, partial, unpaid;

  String get labelAr => const {'paid':'مدفوع','partial':'جزئي','unpaid':'غير مدفوع'}[name] ?? name;

  static PaymentStatus fromString(String v) =>
      PaymentStatus.values.firstWhere((e) => e.name == v,
          orElse: () => PaymentStatus.unpaid);
}

enum RefundStatus {
  requested, underReview, airlineApproved, refundReceived, paidToCustomer, closed;

  String get labelAr {
    const labels = {
      'requested': 'تم الطلب', 'underReview': 'قيد المراجعة',
      'airlineApproved': 'موافقة شركة الطيران',
      'refundReceived': 'تم استلام المبلغ',
      'paidToCustomer': 'تم رد المبلغ للعميل', 'closed': 'مغلق',
    };
    return labels[name] ?? name;
  }

  int get stepIndex => RefundStatus.values.indexOf(this);

  static RefundStatus fromString(String v) {
    final map = {
      'requested': RefundStatus.requested,
      'under_review': RefundStatus.underReview,
      'airline_approved': RefundStatus.airlineApproved,
      'refund_received': RefundStatus.refundReceived,
      'paid_to_customer': RefundStatus.paidToCustomer,
      'closed': RefundStatus.closed,
    };
    return map[v] ?? RefundStatus.requested;
  }

  String get dbValue {
    const map = {
      'requested': 'requested', 'underReview': 'under_review',
      'airlineApproved': 'airline_approved', 'refundReceived': 'refund_received',
      'paidToCustomer': 'paid_to_customer', 'closed': 'closed',
    };
    return map[name] ?? name;
  }
}

enum RefundPriority {
  normal, urgent, overdue;

  String get labelAr => const {'normal':'عادي','urgent':'عاجل','overdue':'متأخر'}[name] ?? name;

  static RefundPriority fromString(String v) =>
      RefundPriority.values.firstWhere((e) => e.name == v,
          orElse: () => RefundPriority.normal);
}

enum LedgerType {
  customerPayment, supplierPayment, refundToCustomer, refundFromAirline,
  commission, expense, cashDeposit, cashWithdrawal, adjustment;

  String get labelAr {
    const labels = {
      'customerPayment': 'استلام من عميل', 'supplierPayment': 'دفع لمورد',
      'refundToCustomer': 'رد لعميل', 'refundFromAirline': 'استرداد من شركة الطيران',
      'commission': 'عمولة', 'expense': 'مصروف',
      'cashDeposit': 'إيداع نقدي', 'cashWithdrawal': 'سحب نقدي',
      'adjustment': 'تسوية',
    };
    return labels[name] ?? name;
  }

  bool get isInflow => [
    LedgerType.customerPayment, LedgerType.refundFromAirline,
    LedgerType.cashDeposit, LedgerType.commission,
  ].contains(this);

  static LedgerType fromString(String v) {
    final map = {
      'customer_payment': LedgerType.customerPayment,
      'supplier_payment': LedgerType.supplierPayment,
      'refund_to_customer': LedgerType.refundToCustomer,
      'refund_from_airline': LedgerType.refundFromAirline,
      'commission': LedgerType.commission,
      'expense': LedgerType.expense,
      'cash_deposit': LedgerType.cashDeposit,
      'cash_withdrawal': LedgerType.cashWithdrawal,
      'adjustment': LedgerType.adjustment,
    };
    return map[v] ?? LedgerType.adjustment;
  }

  String get dbValue {
    const map = {
      'customerPayment': 'customer_payment', 'supplierPayment': 'supplier_payment',
      'refundToCustomer': 'refund_to_customer', 'refundFromAirline': 'refund_from_airline',
      'commission': 'commission', 'expense': 'expense',
      'cashDeposit': 'cash_deposit', 'cashWithdrawal': 'cash_withdrawal',
      'adjustment': 'adjustment',
    };
    return map[name] ?? name;
  }
}

// ───────────────────────────────────────────────────────────
// Customer Model
// ───────────────────────────────────────────────────────────
class CustomerModel extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final double balance; // موجب = له علينا، سالب = عليه لنا
  final String? notes;

  const CustomerModel({
    required this.id, required this.name,
    this.phone, this.email, this.balance = 0, this.notes,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> j) => CustomerModel(
    id: j['id'], name: j['name'],
    phone: j['phone'], email: j['email'],
    balance: (j['balance'] as num?)?.toDouble() ?? 0,
    notes: j['notes'],
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'phone': phone,
    'email': email, 'balance': balance, 'notes': notes,
  };

  @override
  List<Object?> get props => [id];
}

// ───────────────────────────────────────────────────────────
// Supplier Model
// ───────────────────────────────────────────────────────────
class SupplierModel extends Equatable {
  final String id;
  final String name;
  final String type;
  final String? phone;
  final double balance;

  const SupplierModel({
    required this.id, required this.name,
    this.type = 'airline', this.phone, this.balance = 0,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> j) => SupplierModel(
    id: j['id'], name: j['name'],
    type: j['type'] ?? 'airline', phone: j['phone'],
    balance: (j['balance'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'type': type, 'phone': phone, 'balance': balance,
  };

  @override
  List<Object?> get props => [id];
}

// ───────────────────────────────────────────────────────────
// Booking Model (Enterprise)
// ───────────────────────────────────────────────────────────
class BookingModel extends Equatable {
  final String id;
  final String pnr;
  final String? ticketNumber;
  final String? airline;
  final String? flightNumber;
  final String? departureAirport;
  final String? arrivalAirport;
  final DateTime departureDate;
  final DateTime? returnDate;
  final String passengerName;
  final String? passengerPhone;
  final String? customerId;
  final String? customerName;
  final String? supplierId;
  final String? supplierName;
  final double costPrice;
  final double salePrice;
  final PaymentStatus paymentStatus;
  final BookingStatus bookingStatus;
  final String? notes;
  final DateTime? createdAt;

  const BookingModel({
    required this.id, required this.pnr,
    this.ticketNumber, this.airline, this.flightNumber,
    this.departureAirport, this.arrivalAirport,
    required this.departureDate, this.returnDate,
    required this.passengerName, this.passengerPhone,
    this.customerId, this.customerName,
    this.supplierId, this.supplierName,
    this.costPrice = 0, this.salePrice = 0,
    this.paymentStatus = PaymentStatus.unpaid,
    this.bookingStatus = BookingStatus.pending,
    this.notes, this.createdAt,
  });

  double get profitMargin => salePrice - costPrice;
  bool get isRoundTrip => returnDate != null;

  factory BookingModel.fromJson(Map<String, dynamic> j) => BookingModel(
    id: j['id'],
    pnr: j['pnr'] ?? '',
    ticketNumber: j['ticket_number'],
    airline: j['airline'],
    flightNumber: j['flight_number'],
    departureAirport: j['departure_airport'],
    arrivalAirport: j['arrival_airport'],
    departureDate: DateTime.parse(j['departure_date']),
    returnDate: j['return_date'] != null ? DateTime.parse(j['return_date']) : null,
    passengerName: j['passenger_name'] ?? '',
    passengerPhone: j['passenger_phone'],
    customerId: j['customer_id'],
    customerName: j['customers'] != null ? j['customers']['name'] : null,
    supplierId: j['supplier_id'],
    supplierName: j['suppliers'] != null ? j['suppliers']['name'] : null,
    costPrice: (j['cost_price'] as num?)?.toDouble() ?? 0,
    salePrice: (j['sale_price'] as num?)?.toDouble() ?? 0,
    paymentStatus: PaymentStatus.fromString(j['payment_status'] ?? 'unpaid'),
    bookingStatus: BookingStatus.fromString(j['booking_status'] ?? 'pending'),
    notes: j['notes'],
    createdAt: j['created_at'] != null ? DateTime.parse(j['created_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'pnr': pnr, 'ticket_number': ticketNumber,
    'airline': airline, 'flight_number': flightNumber,
    'departure_airport': departureAirport, 'arrival_airport': arrivalAirport,
    'departure_date': departureDate.toIso8601String(),
    'return_date': returnDate?.toIso8601String(),
    'passenger_name': passengerName, 'passenger_phone': passengerPhone,
    'customer_id': customerId, 'supplier_id': supplierId,
    'cost_price': costPrice, 'sale_price': salePrice,
    'payment_status': paymentStatus.name,
    'booking_status': bookingStatus.name,
    'notes': notes,
  };

  BookingModel copyWith({
    BookingStatus? bookingStatus, PaymentStatus? paymentStatus,
    String? ticketNumber, String? notes,
  }) => BookingModel(
    id: id, pnr: pnr,
    ticketNumber: ticketNumber ?? this.ticketNumber,
    airline: airline, flightNumber: flightNumber,
    departureAirport: departureAirport, arrivalAirport: arrivalAirport,
    departureDate: departureDate, returnDate: returnDate,
    passengerName: passengerName, passengerPhone: passengerPhone,
    customerId: customerId, customerName: customerName,
    supplierId: supplierId, supplierName: supplierName,
    costPrice: costPrice, salePrice: salePrice,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    bookingStatus: bookingStatus ?? this.bookingStatus,
    notes: notes ?? this.notes, createdAt: createdAt,
  );

  @override
  List<Object?> get props => [id];
}

// ───────────────────────────────────────────────────────────
// Refund Model (6 Steps + Priority + SLA)
// ───────────────────────────────────────────────────────────
class RefundModel extends Equatable {
  final String id;
  final String bookingId;
  final String? customerId;
  final String passengerName;
  final String? pnr;
  final String? ticketNumber;
  final String? airline;
  final double originalTicketValue;
  final double cancellationFees;
  final double refundAmount;
  final RefundStatus refundStatus;
  final RefundPriority priority;
  final DateTime requestedAt;
  final DateTime? deadlineAt;
  final DateTime? closedAt;
  final String? notes;

  const RefundModel({
    required this.id, required this.bookingId,
    this.customerId, required this.passengerName,
    this.pnr, this.ticketNumber, this.airline,
    this.originalTicketValue = 0, this.cancellationFees = 0,
    required this.refundAmount,
    this.refundStatus = RefundStatus.requested,
    this.priority = RefundPriority.normal,
    required this.requestedAt,
    this.deadlineAt, this.closedAt, this.notes,
  });

  /// أيام متبقية لحد الـ deadline
  int? get daysRemaining {
    if (deadlineAt == null) return null;
    return deadlineAt!.difference(DateTime.now()).inDays;
  }

  factory RefundModel.fromJson(Map<String, dynamic> j) => RefundModel(
    id: j['id'], bookingId: j['booking_id'],
    customerId: j['customer_id'],
    passengerName: j['passenger_name'] ?? '',
    pnr: j['pnr'], ticketNumber: j['ticket_number'], airline: j['airline'],
    originalTicketValue: (j['original_ticket_value'] as num?)?.toDouble() ?? 0,
    cancellationFees: (j['cancellation_fees'] as num?)?.toDouble() ?? 0,
    refundAmount: (j['refund_amount'] as num?)?.toDouble() ?? 0,
    refundStatus: RefundStatus.fromString(j['refund_status'] ?? 'requested'),
    priority: RefundPriority.fromString(j['priority'] ?? 'normal'),
    requestedAt: DateTime.parse(j['requested_at']),
    deadlineAt: j['deadline_at'] != null ? DateTime.parse(j['deadline_at']) : null,
    closedAt: j['closed_at'] != null ? DateTime.parse(j['closed_at']) : null,
    notes: j['notes'],
  );

  Map<String, dynamic> toJson() => {
    'booking_id': bookingId, 'customer_id': customerId,
    'passenger_name': passengerName, 'pnr': pnr,
    'ticket_number': ticketNumber, 'airline': airline,
    'original_ticket_value': originalTicketValue,
    'cancellation_fees': cancellationFees, 'refund_amount': refundAmount,
    'refund_status': refundStatus.dbValue,
    'priority': priority.name,
    'requested_at': requestedAt.toIso8601String(),
    'deadline_at': deadlineAt?.toIso8601String(),
    'notes': notes,
  };

  @override
  List<Object?> get props => [id];
}

// ───────────────────────────────────────────────────────────
// Ledger Entry Model
// ───────────────────────────────────────────────────────────
class LedgerEntryModel extends Equatable {
  final String id;
  final LedgerType type;
  final double amount;
  final String direction; // debit / credit
  final String? bookingId;
  final String? refundId;
  final String? customerId;
  final String? supplierId;
  final String description;
  final String? reference;
  final DateTime createdAt;

  const LedgerEntryModel({
    required this.id, required this.type,
    required this.amount, required this.direction,
    this.bookingId, this.refundId,
    this.customerId, this.supplierId,
    required this.description,
    this.reference, required this.createdAt,
  });

  bool get isCredit => direction == 'credit';

  factory LedgerEntryModel.fromJson(Map<String, dynamic> j) => LedgerEntryModel(
    id: j['id'],
    type: LedgerType.fromString(j['type'] ?? ''),
    amount: (j['amount'] as num).toDouble(),
    direction: j['direction'] ?? 'debit',
    bookingId: j['booking_id'], refundId: j['refund_id'],
    customerId: j['customer_id'], supplierId: j['supplier_id'],
    description: j['description'] ?? '',
    reference: j['reference'],
    createdAt: DateTime.parse(j['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'type': type.dbValue, 'amount': amount, 'direction': direction,
    'booking_id': bookingId, 'refund_id': refundId,
    'customer_id': customerId, 'supplier_id': supplierId,
    'description': description, 'reference': reference,
  };

  @override
  List<Object?> get props => [id];
}
