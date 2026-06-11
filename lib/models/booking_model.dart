/// نموذج الحجز - BookingModel
/// يمثل حجز طيران واحد في النظام

/// حالات الحجز المتاحة
enum BookingStatus {
  confirmed, // مؤكد
  cancelled, // ملغي
  pending, // معلق
  refunded; // مرتجع

  /// التسمية بالعربي للعرض في الواجهات
  String get labelAr {
    switch (this) {
      case BookingStatus.confirmed:
        return 'مؤكد';
      case BookingStatus.cancelled:
        return 'ملغي';
      case BookingStatus.pending:
        return 'معلق';
      case BookingStatus.refunded:
        return 'مرتجع';
    }
  }

  /// تحويل النص القادم من قاعدة البيانات إلى enum
  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

class BookingModel {
  final String id;
  final String passengerName;
  final String pnr;
  final String ticketNumber;
  final String departureCity;
  final String arrivalCity;
  final DateTime flightDate;
  final BookingStatus status;

  const BookingModel({
    required this.id,
    required this.passengerName,
    required this.pnr,
    required this.ticketNumber,
    required this.departureCity,
    required this.arrivalCity,
    required this.flightDate,
    required this.status,
  });

  /// إنشاء نموذج من JSON (صف قادم من PostgreSQL)
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      passengerName: json['passenger_name'] as String,
      pnr: json['pnr'] as String,
      ticketNumber: json['ticket_number'] as String,
      departureCity: json['departure_city'] as String,
      arrivalCity: json['arrival_city'] as String,
      flightDate: DateTime.parse(json['flight_date'] as String),
      status: BookingStatus.fromString(json['status'] as String),
    );
  }

  /// تحويل النموذج إلى JSON (للإرسال إلى قاعدة البيانات)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passenger_name': passengerName,
      'pnr': pnr,
      'ticket_number': ticketNumber,
      'departure_city': departureCity,
      'arrival_city': arrivalCity,
      'flight_date': flightDate.toIso8601String(),
      'status': status.name,
    };
  }

  /// نسخة معدّلة من النموذج (مفيد عند تحديث الحالة مثلاً)
  BookingModel copyWith({
    String? id,
    String? passengerName,
    String? pnr,
    String? ticketNumber,
    String? departureCity,
    String? arrivalCity,
    DateTime? flightDate,
    BookingStatus? status,
  }) {
    return BookingModel(
      id: id ?? this.id,
      passengerName: passengerName ?? this.passengerName,
      pnr: pnr ?? this.pnr,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      departureCity: departureCity ?? this.departureCity,
      arrivalCity: arrivalCity ?? this.arrivalCity,
      flightDate: flightDate ?? this.flightDate,
      status: status ?? this.status,
    );
  }
}
