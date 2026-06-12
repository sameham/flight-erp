import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/app_repository.dart';
import '../../../../core/theme/app_theme.dart';
import 'add_booking_screen.dart';
import 'booking_detail_screen.dart';

final _money = NumberFormat('#,##0', 'ar');

/// شاشة قائمة الحجوزات مع البحث والفلترة
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _repo = AppRepository();
  final _searchCtrl = TextEditingController();

  List<BookingModel> _bookings = [];
  bool _loading = true;
  String _statusFilter = '';
  String _searchQuery = '';

  static const _statusFilters = [
    ('', 'الكل'), ('pending', 'معلق'), ('issued', 'مصدرة'),
    ('cancelled', 'ملغي'), ('refund_requested', 'مرتجع'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.fetchBookings(
        statusFilter: _statusFilter.isEmpty ? null : _statusFilter,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) setState(() { _bookings = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحجوزات'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(children: [
              // حقل البحث العالمي
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ابحث: الاسم، PNR، رقم التذكرة، الهاتف...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                            _load();
                          })
                      : null,
                ),
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                  Future.delayed(
                    const Duration(milliseconds: 400), _load);
                },
              ),
              const SizedBox(height: 8),
              // فلاتر الحالة
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statusFilters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final (val, label) = _statusFilters[i];
                    final selected = val == _statusFilter;
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _statusFilter = val);
                        _load();
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('حجز جديد',
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final saved = await context.push<bool>('/bookings/add');
          if (saved == true) _load();
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _bookings.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _bookings.length,
                      itemBuilder: (context, i) =>
                          _BookingListTile(
                            booking: _bookings[i],
                            onTap: () async {
                              await context.push('/bookings/\${_bookings[i].id}');
                              _load();
                            },
                          ),
                    ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.airplane_ticket_outlined,
            size: 64, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isNotEmpty
              ? 'لا نتائج لـ "$_searchQuery"'
              : 'لا توجد حجوزات بعد',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
      ]),
    );
  }
}

/// صف الحجز في القائمة
class _BookingListTile extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _BookingListTile({required this.booking, required this.onTap});

  Color get _statusColor {
    switch (booking.bookingStatus) {
      case BookingStatus.issued: return AppColors.success;
      case BookingStatus.cancelled: return AppColors.error;
      case BookingStatus.refundRequested: return AppColors.warning;
      case BookingStatus.refundCompleted: return AppColors.info;
      case BookingStatus.pending: return AppColors.textMuted;
    }
  }

  Color get _paymentColor {
    switch (booking.paymentStatus) {
      case PaymentStatus.paid: return AppColors.success;
      case PaymentStatus.partial: return AppColors.warning;
      case PaymentStatus.unpaid: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy', 'ar').format(booking.departureDate);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // الصف الأول: الحالة + التاريخ
              Row(children: [
                _StatusBadge(label: booking.bookingStatus.labelAr, color: _statusColor),
                const SizedBox(width: 8),
                _StatusBadge(label: booking.paymentStatus.labelAr, color: _paymentColor),
                const Spacer(),
                Text(dateStr,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ]),
              const SizedBox(height: 10),

              // اسم المسافر + PNR
              Text(booking.passengerName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.tag_rounded, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('PNR: ${booking.pnr}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (booking.ticketNumber != null) ...[
                  const Text('  •  ',
                      style: TextStyle(color: AppColors.textMuted)),
                  Text(booking.ticketNumber!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ]),
              const SizedBox(height: 10),

              // مسار الرحلة
              Row(children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Text(
                        booking.departureAirport ?? booking.passengerName.substring(0, 1),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppColors.primary,
                            fontSize: 14),
                      ),
                      const Expanded(child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.flight_rounded,
                            size: 16, color: AppColors.primary),
                      )),
                      Text(
                        booking.arrivalAirport ?? '---',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppColors.primary,
                            fontSize: 14),
                      ),
                      if (booking.airline != null) ...[
                        const Text('  ', style: TextStyle(fontSize: 12)),
                        Text(booking.airline!,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 10),

              // الأسعار والربح
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _PriceItem(label: 'التكلفة',
                    value: _money.format(booking.costPrice)),
                _PriceItem(label: 'البيع',
                    value: _money.format(booking.salePrice)),
                _PriceItem(
                    label: 'الربح',
                    value: _money.format(booking.profitMargin),
                    valueColor: booking.profitMargin >= 0
                        ? AppColors.success : AppColors.error,
                    bold: true),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}

class _PriceItem extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool bold;

  const _PriceItem({
    required this.label, required this.value,
    this.valueColor, this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      const SizedBox(height: 2),
      Text('$value ج.م',
          style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.textDark)),
    ],
  );
}
