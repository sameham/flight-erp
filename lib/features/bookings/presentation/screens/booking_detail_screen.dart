import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/app_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../refunds/presentation/screens/add_refund_screen.dart';

final _money = NumberFormat('#,##0', 'ar');
final _dateTime = DateFormat('d MMM yyyy', 'ar');

/// شاشة تفاصيل الحجز مع كل الإجراءات
class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _repo = AppRepository();
  BookingModel? _booking;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final b = await _repo.fetchBookingById(widget.bookingId);
      if (mounted) setState(() { _booking = b; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── تسجيل دفعة ──────────────────────────────────────────
  Future<void> _registerPayment() async {
    final amountCtrl = TextEditingController();
    String method = 'cash';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 24),
        child: StatefulBuilder(builder: (ctx, ss) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تسجيل دفعة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'المبلغ (ج.م)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(labelText: 'طريقة الدفع'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('نقداً')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('تحويل بنكي')),
                DropdownMenuItem(value: 'card', child: Text('بطاقة')),
              ],
              onChanged: (v) => ss(() => method = v ?? method),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              )),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('تسجيل'),
              )),
            ]),
          ],
        )),
      ),
    );

    if (confirmed != true || _booking == null) return;
    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    try {
      await _repo.registerPayment(
        bookingId: _booking!.id,
        customerId: _booking!.customerId,
        amount: amount, method: method,
      );
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الدفعة ✓')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل التسجيل')));
      }
    }
  }

  // ── طلب استرداد ─────────────────────────────────────────
  Future<void> _requestRefund() async {
    if (_booking == null) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRefundScreen(booking: _booking!),
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('لم يتم العثور على الحجز')),
      );
    }

    final b = _booking!;
    final canRefund = b.bookingStatus != BookingStatus.refundRequested &&
        b.bookingStatus != BookingStatus.refundCompleted &&
        b.bookingStatus != BookingStatus.cancelled;

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل: ${b.passengerName}'),
        actions: [
          PopupMenuButton(itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit',
                child: ListTile(dense: true,
                    leading: Icon(Icons.edit_rounded),
                    title: Text('تعديل'))),
            const PopupMenuItem(value: 'print',
                child: ListTile(dense: true,
                    leading: Icon(Icons.print_rounded),
                    title: Text('طباعة'))),
          ]),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── بطاقة الحالة ───────────────────────────────────
          _StatusBanner(booking: b),
          const SizedBox(height: 14),

          // ── بيانات التذكرة ─────────────────────────────────
          _InfoCard(title: 'بيانات التذكرة', icon: Icons.airplane_ticket_outlined, rows: [
            ('PNR', b.pnr),
            if (b.ticketNumber != null) ('رقم التذكرة', b.ticketNumber!),
            if (b.airline != null) ('شركة الطيران', b.airline!),
            if (b.flightNumber != null) ('رقم الرحلة', b.flightNumber!),
          ]),
          const SizedBox(height: 12),

          // ── مسار الرحلة ────────────────────────────────────
          _InfoCard(title: 'مسار الرحلة', icon: Icons.map_outlined, rows: [
            ('من', '${b.departureAirport ?? "—"}  →  ${b.arrivalAirport ?? "—"}'),
            ('تاريخ المغادرة', _dateTime.format(b.departureDate)),
            if (b.returnDate != null)
              ('تاريخ العودة', _dateTime.format(b.returnDate!)),
          ]),
          const SizedBox(height: 12),

          // ── المسافر والعميل ────────────────────────────────
          _InfoCard(title: 'المسافر', icon: Icons.person_outline_rounded, rows: [
            ('الاسم', b.passengerName),
            if (b.passengerPhone != null) ('الهاتف', b.passengerPhone!),
            if (b.customerName != null) ('الحساب', b.customerName!),
          ]),
          const SizedBox(height: 12),

          // ── الملخص المالي ──────────────────────────────────
          _FinanceCard(booking: b),
          const SizedBox(height: 24),

          // ── الإجراءات ──────────────────────────────────────
          const Text('الإجراءات', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold,
              color: AppColors.textDark)),
          const SizedBox(height: 12),

          if (b.paymentStatus != PaymentStatus.paid)
            _ActionButton(
              label: 'تسجيل دفعة',
              icon: Icons.payments_outlined,
              color: AppColors.success,
              onTap: _registerPayment,
            ),
          const SizedBox(height: 10),

          if (canRefund)
            _ActionButton(
              label: 'طلب استرداد',
              icon: Icons.replay_rounded,
              color: AppColors.warning,
              onTap: _requestRefund,
            ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final BookingModel booking;
  const _StatusBanner({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = booking.bookingStatus == BookingStatus.issued
        ? AppColors.success
        : booking.bookingStatus == BookingStatus.cancelled
            ? AppColors.error
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.airplane_ticket_rounded, color: statusColor, size: 24),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(booking.bookingStatus.labelAr,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: statusColor)),
          Text(booking.paymentStatus.labelAr,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ]),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String, String)> rows;

  const _InfoCard({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      boxShadow: kCardShadow,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(
            fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
      ]),
      const Divider(height: 16),
      ...rows.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SizedBox(width: 110, child: Text(r.$1,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
          Expanded(child: Text(r.$2,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textDark))),
        ]),
      )),
    ]),
  );
}

class _FinanceCard extends StatelessWidget {
  final BookingModel booking;
  const _FinanceCard({required this.booking});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      boxShadow: kCardShadow,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.payments_outlined, size: 16, color: AppColors.primary),
        SizedBox(width: 6),
        Text('الملخص المالي', style: TextStyle(
            fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
      ]),
      const Divider(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _FinStat('التكلفة', booking.costPrice, AppColors.textDark),
        _FinStat('البيع', booking.salePrice, AppColors.info),
        _FinStat('الربح', booking.profitMargin,
            booking.profitMargin >= 0 ? AppColors.success : AppColors.error,
            bold: true),
      ]),
    ]),
  );
}

class _FinStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;
  const _FinStat(this.label, this.value, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
    const SizedBox(height: 4),
    Text('${_money.format(value)} ج.م',
        style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color)),
  ]);
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 18),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
