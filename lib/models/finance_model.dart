/// نموذج المعاملات المالية - FinanceModel
/// مرتبط بحجز معين عبر bookingId ويحتوي كل التفاصيل المالية

class FinanceModel {
  final String id;

  /// معرف الحجز المرتبط بهذه المعاملة
  final String bookingId;

  /// سعر الشراء من المورد (التكلفة)
  final double purchasePrice;

  /// سعر البيع للعميل
  final double sellingPrice;

  /// المبلغ المدفوع فعلياً من العميل
  final double paidAmount;

  const FinanceModel({
    required this.id,
    required this.bookingId,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.paidAmount,
  });

  /// المديونية: المتبقي على العميل (يُحسب تلقائياً)
  /// لا يقل عن صفر حتى لو دفع العميل زيادة
  double get dueAmount =>
      (sellingPrice - paidAmount).clamp(0, double.infinity);

  /// هامش الربح (يُحسب تلقائياً): البيع - الشراء
  double get profitMargin => sellingPrice - purchasePrice;

  /// هل العميل سدّد بالكامل؟
  bool get isFullyPaid => paidAmount >= sellingPrice;

  /// إنشاء نموذج من JSON (صف قادم من PostgreSQL)
  /// ملاحظة: dueAmount و profitMargin لا يُخزّنان لأنهما محسوبان
  factory FinanceModel.fromJson(Map<String, dynamic> json) {
    return FinanceModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
    );
  }

  /// تحويل النموذج إلى JSON (للإرسال إلى قاعدة البيانات)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'paid_amount': paidAmount,
    };
  }

  FinanceModel copyWith({
    String? id,
    String? bookingId,
    double? purchasePrice,
    double? sellingPrice,
    double? paidAmount,
  }) {
    return FinanceModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      paidAmount: paidAmount ?? this.paidAmount,
    );
  }
}
