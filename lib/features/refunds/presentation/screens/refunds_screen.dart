import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/data/repositories/app_repository.dart';
import '../../../../core/theme/app_theme.dart';

final _money = NumberFormat('#,##0', 'ar');
final _repo = AppRepository();

/// شاشة المرتجعات - 6 مراحل مع SLA والأولوية
class RefundsScreen extends StatefulWidget {
  const RefundsScreen({super.key});
  @override
  State<RefundsScreen> createState() => _RefundsScreenState();
}

class _RefundsScreenState extends State<RefundsScreen> {
  late Future<List<RefundModel>> _future;
  String _priorityFilter = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() {
    _future = _repo.fetchRefunds(
        priorityFilter: _priorityFilter.isEmpty ? null : _priorityFilter);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المرتجعات'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              for (final (val, label, color) in [
                ('', 'الكل', AppColors.primary),
                ('normal', 'عادي', AppColors.success),
                ('urgent', 'عاجل', AppColors.warning),
                ('overdue', 'متأخر', AppColors.error),
              ]) ...[
                ChoiceChip(
                  label: Text(label),
                  selected: _priorityFilter == val,
                  selectedColor: color,
                  onSelected: (_) {
                    setState(() => _priorityFilter = val);
                    _reload();
                  },
                  labelStyle: TextStyle(
                    color: _priorityFilter == val
                        ? Colors.white : AppColors.textDark,
                    fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ]),
          ),
        ),
      ),
      body: FutureBuilder<List<RefundModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('تعذر التحميل',
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reload,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: const Text('إعادة المحاولة')),
              ]),
            );
          }
          final refunds = snap.data ?? [];
          if (refunds.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.replay_rounded, size: 56, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text('لا توجد مرتجعات',
                    style: TextStyle(color: AppColors.textMuted)),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: refunds.length,
              itemBuilder: (context, i) => _RefundCard(
                refund: refunds[i],
                onStatusChanged: () => _reload(),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// كارت المرتجع مع 6 مراحل وSLA والأولوية
class _RefundCard extends StatelessWidget {
  final RefundModel refund;
  final VoidCallback onStatusChanged;

  const _RefundCard({required this.refund, required this.onStatusChanged});

  Color get _priorityColor {
    switch (refund.priority) {
      case RefundPriority.urgent: return AppColors.warning;
      case RefundPriority.overdue: return AppColors.error;
      case RefundPriority.normal: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = refund.daysRemaining;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── رأس الكارت ─────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(refund.passengerName,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold,
                  color: AppColors.textDark))),
          // الأولوية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _priorityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(refund.priority.labelAr,
                style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.bold, color: _priorityColor)),
          ),
        ]),
        const SizedBox(height: 4),
        Wrap(spacing: 12, children: [
          if (refund.pnr != null)
            Text('PNR: ${refund.pnr}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          if (refund.ticketNumber != null)
            Text('تذكرة: ${refund.ticketNumber}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          if (refund.airline != null)
            Text(refund.airline!,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 10),

        // ── الأرقام المالية ────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _FinRow('قيمة التذكرة', refund.originalTicketValue, AppColors.textDark),
          _FinRow('رسوم الإلغاء', refund.cancellationFees, AppColors.error),
          _FinRow('صافي الاسترداد', refund.refundAmount, AppColors.success, bold: true),
        ]),
        const SizedBox(height: 14),

        // ── شريط التقدم 6 مراحل ────────────────────────────
        _SixStepProgress(currentStep: refund.refundStatus.stepIndex),
        const SizedBox(height: 10),

        // ── الحالة + SLA ────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(refund.refundStatus.labelAr,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                  color: refund.refundStatus == RefundStatus.closed
                      ? AppColors.success : AppColors.warning)),
          if (days != null)
            Row(children: [
              Icon(Icons.timer_outlined,
                  size: 13, color: days < 0 ? AppColors.error : AppColors.textMuted),
              const SizedBox(width: 3),
              Text(
                days >= 0 ? 'متبقي $days يوم' : 'متأخر ${days.abs()} يوم',
                style: TextStyle(fontSize: 11,
                    color: days < 0 ? AppColors.error : AppColors.textMuted),
              ),
            ]),
        ]),
        const SizedBox(height: 10),

        // ── تحديث الحالة ───────────────────────────────────
        if (refund.refundStatus != RefundStatus.closed)
          _NextStepButton(refund: refund, onDone: onStatusChanged),
      ]),
    );
  }
}

class _FinRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;
  const _FinRow(this.label, this.value, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    const SizedBox(height: 3),
    Text('${_money.format(value)} ج.م',
        style: TextStyle(fontSize: 12,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color)),
  ]);
}

/// شريط تقدم أفقي 6 خطوات
class _SixStepProgress extends StatelessWidget {
  final int currentStep; // 0..5
  const _SixStepProgress({required this.currentStep});

  static const _steps = ['طلب','مراجعة','موافقة','استلام','رد','إغلاق'];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isEven) {
            final step = i ~/ 2;
            final done = step <= currentStep;
            final isCurr = step == currentStep;
            return Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.success : Colors.white,
                border: Border.all(
                  color: done ? AppColors.success : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: done
                  ? Icon(isCurr && currentStep < 5
                      ? Icons.more_horiz : Icons.check,
                      size: 11, color: Colors.white)
                  : null,
            );
          } else {
            final filled = (i ~/ 2) < currentStep;
            return Expanded(child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: filled ? AppColors.success : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ));
          }
        }),
      ),
      const SizedBox(height: 4),
      Row(children: List.generate(_steps.length, (i) => Expanded(
        child: Text(_steps[i],
          textAlign: i == 0 ? TextAlign.start
              : i == _steps.length - 1 ? TextAlign.end : TextAlign.center,
          style: TextStyle(fontSize: 9,
              fontWeight: i <= currentStep ? FontWeight.bold : FontWeight.normal,
              color: i <= currentStep ? AppColors.textDark : AppColors.textMuted)),
      ))),
    ]);
  }
}

/// زر الانتقال للمرحلة التالية
class _NextStepButton extends StatelessWidget {
  final RefundModel refund;
  final VoidCallback onDone;
  const _NextStepButton({required this.refund, required this.onDone});

  RefundStatus get _nextStatus {
    final all = RefundStatus.values;
    final idx = refund.refundStatus.stepIndex;
    return idx < all.length - 1 ? all[idx + 1] : RefundStatus.closed;
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () async {
          await _repo.updateRefundStatus(refund.id, next);
          onDone();
        },
        style: FilledButton.styleFrom(
          backgroundColor: next == RefundStatus.closed
              ? AppColors.success : AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('→ ${next.labelAr}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}
