/// نموذج المرتجعات - RefundModel (محدّث: 4 مراحل)
/// يتتبع عملية الاسترداد من الطلب حتى رد المبلغ للعميل

/// مراحل الاسترداد الأربعة
enum RefundStatus {
  requested, // تم الطلب
  underReview, // قيد المراجعة مع شركة الطيران
  amountReceived, // تم استلام المبلغ
  deliveredToCustomer; // تم رد المبلغ للعميل

  String get labelAr {
    switch (this) {
      case RefundStatus.requested:
        return 'تم الطلب';
      case RefundStatus.underReview:
        return 'قيد المراجعة مع شركة الطيران';
      case RefundStatus.amountReceived:
        return 'تم استلام المبلغ';
      case RefundStatus.deliveredToCustomer:
        return 'تم رد المبلغ للعميل';
    }
  }

  /// رقم المرحلة (0..3) لاستخدامه في الـ Stepper
  int get stepIndex => RefundStatus.values.indexOf(this);

  static RefundStatus fromString(String value) {
    return RefundStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RefundStatus.requested,
    );
  }
}

class RefundModel {
  final String refundId;

  /// معرف الحجز المرتبط بهذا المرتجع
  final String bookingId;

  /// اسم العميل (للعرض المباشر في كارت المرتجع)
  final String customerName;

  /// رقم التذكرة
  final String ticketNumber;

  /// المبلغ المسترد
  final double refundAmount;

  /// حالة الاسترداد الحالية
  final RefundStatus refundStatus;

  /// تاريخ إنشاء طلب الاسترداد
  final DateTime createdAt;

  const RefundModel({
    required this.refundId,
    required this.bookingId,
    required this.customerName,
    required this.ticketNumber,
    required this.refundAmount,
    required this.refundStatus,
    required this.createdAt,
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    return RefundModel(
      refundId: json['refund_id'] as String,
      bookingId: json['booking_id'] as String,
      customerName: json['customer_name'] as String,
      ticketNumber: json['ticket_number'] as String,
      refundAmount: (json['refund_amount'] as num).toDouble(),
      refundStatus: RefundStatus.fromString(json['refund_status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refund_id': refundId,
      'booking_id': bookingId,
      'customer_name': customerName,
      'ticket_number': ticketNumber,
      'refund_amount': refundAmount,
      'refund_status': refundStatus.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  RefundModel copyWith({
    String? refundId,
    String? bookingId,
    String? customerName,
    String? ticketNumber,
    double? refundAmount,
    RefundStatus? refundStatus,
    DateTime? createdAt,
  }) {
    return RefundModel(
      refundId: refundId ?? this.refundId,
      bookingId: bookingId ?? this.bookingId,
      customerName: customerName ?? this.customerName,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      refundAmount: refundAmount ?? this.refundAmount,
      refundStatus: refundStatus ?? this.refundStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
