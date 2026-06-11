import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_repository.dart';
import '../models/refund_model.dart';
import '../theme/app_theme.dart';

final _money = NumberFormat('#,##0', 'ar');

/// شاشة المرتجعات - Refunds Screen (متصلة بـ Supabase)
class RefundsScreen extends StatefulWidget {
  const RefundsScreen({super.key});

  @override
  State<RefundsScreen> createState() => _RefundsScreenState();
}

class _RefundsScreenState extends State<RefundsScreen> {
  final _repo = AppRepository();
  late Future<List<RefundModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchRefunds();
  }

  Future<void> _reload() async {
    setState(() => _future = _repo.fetchRefunds());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المرتجعات')),
      body: FutureBuilder<List<RefundModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('تعذر تحميل المرتجعات',
                      style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _reload,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }
          final refunds = snap.data ?? [];
          if (refunds.isEmpty) {
            return const Center(
              child: Text('لا توجد مرتجعات حالياً',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: refunds.length,
              itemBuilder: (context, i) =>
                  _RefundCard(refund: refunds[i]),
            ),
          );
        },
      ),
    );
  }
}

/// كارت المرتجع الواحد مع شريط التقدم
class _RefundCard extends StatelessWidget {
  final RefundModel refund;
  const _RefundCard({required this.refund});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم العميل + المبلغ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  refund.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${_money.format(refund.refundAmount)} ج.م',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'تذكرة: ${refund.ticketNumber}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),

          // ===== شريط التقدم الأفقي (Progress Stepper) =====
          _RefundStepper(currentStep: refund.refundStatus.stepIndex),
          const SizedBox(height: 10),

          // الحالة الحالية + التاريخ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  refund.refundStatus.labelAr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: refund.refundStatus ==
                            RefundStatus.deliveredToCustomer
                        ? AppColors.green
                        : AppColors.orange,
                  ),
                ),
              ),
              Text(
                DateFormat('d MMM yyyy', 'ar').format(refund.createdAt),
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شريط تقدم أفقي من 4 خطوات
class _RefundStepper extends StatelessWidget {
  /// المرحلة الحالية (0..3)
  final int currentStep;
  const _RefundStepper({required this.currentStep});

  static const _steps = ['الطلب', 'المراجعة', 'الاستلام', 'رد للعميل'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // الدوائر والخطوط
        Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            // عناصر زوجية = دوائر، فردية = خطوط واصلة
            if (i.isEven) {
              final step = i ~/ 2;
              final done = step <= currentStep;
              final isCurrent = step == currentStep;
              return Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.green : Colors.white,
                  border: Border.all(
                    color: done ? AppColors.green : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: done
                    ? Icon(
                        isCurrent && currentStep < 3
                            ? Icons.more_horiz
                            : Icons.check,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              );
            } else {
              final lineAfterStep = i ~/ 2;
              final filled = lineAfterStep < currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: filled ? AppColors.green : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 6),
        // تسميات المراحل
        Row(
          children: List.generate(_steps.length, (i) {
            final done = i <= currentStep;
            return Expanded(
              child: Text(
                _steps[i],
                textAlign: i == 0
                    ? TextAlign.start
                    : i == _steps.length - 1
                        ? TextAlign.end
                        : TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                  color: done ? AppColors.textDark : AppColors.textMuted,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
