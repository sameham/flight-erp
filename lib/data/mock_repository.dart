import '../models/booking_model.dart';
import '../models/finance_model.dart';
import '../models/refund_model.dart';
import '../models/transaction_model.dart';

/// مستودع بيانات مؤقت (Mock) مبني على نفس الموديلات الحقيقية.
/// لاحقاً سيتم استبداله بطبقة اتصال بـ PostgreSQL بنفس الواجهة.
class MockRepository {
  static final bookings = <BookingModel>[
    BookingModel(
      id: 'b1',
      passengerName: 'أحمد محمود السيد',
      pnr: 'XK9P2L',
      ticketNumber: '077-2456789012',
      departureCity: 'القاهرة',
      arrivalCity: 'دبي',
      flightDate: DateTime.now().add(const Duration(days: 5)),
      status: BookingStatus.confirmed,
    ),
    BookingModel(
      id: 'b2',
      passengerName: 'سارة عبد الرحمن',
      pnr: 'MQ4T7N',
      ticketNumber: '157-9988776655',
      departureCity: 'القاهرة',
      arrivalCity: 'الرياض',
      flightDate: DateTime.now().add(const Duration(days: 12)),
      status: BookingStatus.pending,
    ),
    BookingModel(
      id: 'b3',
      passengerName: 'محمد علي حسن',
      pnr: 'ZR1W8B',
      ticketNumber: '235-1122334455',
      departureCity: 'الإسكندرية',
      arrivalCity: 'جدة',
      flightDate: DateTime.now().subtract(const Duration(days: 20)),
      status: BookingStatus.confirmed,
    ),
    BookingModel(
      id: 'b4',
      passengerName: 'منى إبراهيم',
      pnr: 'TL6C3V',
      ticketNumber: '607-5566778899',
      departureCity: 'القاهرة',
      arrivalCity: 'إسطنبول',
      flightDate: DateTime.now().subtract(const Duration(days: 8)),
      status: BookingStatus.refunded,
    ),
  ];

  static final finances = <FinanceModel>[
    const FinanceModel(
        id: 'f1', bookingId: 'b1',
        purchasePrice: 8500, sellingPrice: 9800, paidAmount: 9800),
    const FinanceModel(
        id: 'f2', bookingId: 'b2',
        purchasePrice: 6200, sellingPrice: 7100, paidAmount: 3000),
    const FinanceModel(
        id: 'f3', bookingId: 'b3',
        purchasePrice: 5400, sellingPrice: 6300, paidAmount: 6300),
    const FinanceModel(
        id: 'f4', bookingId: 'b4',
        purchasePrice: 7800, sellingPrice: 7800, paidAmount: 7800),
  ];

  static final refunds = <RefundModel>[
    RefundModel(
      refundId: 'r1',
      bookingId: 'b4',
      customerName: 'منى إبراهيم',
      ticketNumber: '607-5566778899',
      refundAmount: 7800,
      refundStatus: RefundStatus.underReview,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    RefundModel(
      refundId: 'r2',
      bookingId: 'b3',
      customerName: 'خالد فتحي',
      ticketNumber: '176-3344556677',
      refundAmount: 4500,
      refundStatus: RefundStatus.deliveredToCustomer,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    RefundModel(
      refundId: 'r3',
      bookingId: 'b2',
      customerName: 'هدى سمير',
      ticketNumber: '077-8899001122',
      refundAmount: 6100,
      refundStatus: RefundStatus.requested,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  /// قائمة الحركات المالية (قابلة للإضافة من شاشة المحفظة)
  static final transactions = <TransactionModel>[
    TransactionModel(
      id: 't1',
      type: TransactionType.receiveFromCustomer,
      amount: 9800,
      note: 'تحويل بنكي - تذكرة دبي',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: 't2',
      type: TransactionType.payToSupplier,
      amount: 8500,
      note: 'مكتب النور للسياحة',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: 't3',
      type: TransactionType.settlement,
      amount: 1200,
      note: 'تسوية فرق سعر',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static FinanceModel? financeOf(String bookingId) {
    for (final f in finances) {
      if (f.bookingId == bookingId) return f;
    }
    return null;
  }

  /// إجمالي الأرباح (من الحجوزات غير المرتجعة/الملغية)
  static double get totalProfit {
    double sum = 0;
    for (final b in bookings) {
      if (b.status == BookingStatus.refunded ||
          b.status == BookingStatus.cancelled) continue;
      sum += financeOf(b.id)?.profitMargin ?? 0;
    }
    return sum;
  }

  /// إجمالي المديونيات (المتبقي على العملاء)
  static double get totalDue {
    double sum = 0;
    for (final f in finances) {
      sum += f.dueAmount;
    }
    return sum;
  }

  /// إجمالي المرتجعات المعلقة (لم تُسلَّم للعميل بعد)
  static double get totalPendingRefunds {
    double sum = 0;
    for (final r in refunds) {
      if (r.refundStatus != RefundStatus.deliveredToCustomer) {
        sum += r.refundAmount;
      }
    }
    return sum;
  }
}
