/// نموذج الحركة المالية - TransactionModel
/// يمثل أي حركة في المحفظة: دفع لمورد، استلام من عميل، أو تسوية

/// أنواع المعاملات
enum TransactionType {
  payToSupplier, // دفع لمورد
  receiveFromCustomer, // استلام من عميل
  settlement; // تسوية

  String get labelAr {
    switch (this) {
      case TransactionType.payToSupplier:
        return 'دفع لمورد';
      case TransactionType.receiveFromCustomer:
        return 'استلام من عميل';
      case TransactionType.settlement:
        return 'تسوية';
    }
  }

  /// هل الحركة داخلة (فلوس ليك)؟
  bool get isInflow => this == TransactionType.receiveFromCustomer;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.settlement,
    );
  }
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String? note;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
