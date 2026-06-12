import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../bookings/data/repositories/app_repository.dart';
import '../../../../core/theme/app_theme.dart';

final _money = NumberFormat('#,##0', 'ar');
final _repo = AppRepository();

/// لوحة التحكم التنفيذية - Enterprise Dashboard
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardKPIs> _kpiFuture;

  @override
  void initState() {
    super.initState();
    _kpiFuture = _repo.fetchDashboardKPIs();
  }

  Future<void> _refresh() async {
    setState(() => _kpiFuture = _repo.fetchDashboardKPIs());
    await _kpiFuture;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<DashboardKPIs>(
        future: _kpiFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _buildError();
          }
          final kpis = snap.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // تاريخ اليوم
                Text(
                  DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),

                // ── صف KPIs الرئيسية ──
                Row(children: [
                  Expanded(child: _KpiCard(
                    title: 'حجوزات اليوم',
                    value: kpis.todayBookings.toString(),
                    icon: Icons.airplane_ticket_outlined,
                    color: AppColors.info,
                    isCount: true,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _KpiCard(
                    title: 'إيرادات الشهر',
                    value: _money.format(kpis.monthlyRevenue),
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                  )),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _KpiCard(
                    title: 'صافي الربح',
                    value: _money.format(kpis.monthlyProfit),
                    icon: Icons.attach_money_rounded,
                    color: AppColors.success,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _KpiCard(
                    title: 'مرتجعات معلقة',
                    value: _money.format(kpis.pendingRefundsTotal),
                    icon: Icons.replay_rounded,
                    color: AppColors.warning,
                  )),
                ]),
                const SizedBox(height: 10),

                // ── الرصيد النقدي (بطاقة كاملة العرض) ──
                _CashCard(cashPosition: kpis.cashPosition),
                const SizedBox(height: 24),

                // ── الإجراءات السريعة ──
                const _SectionTitle('إجراءات سريعة'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _QuickAction(
                    label: 'حجز جديد',
                    icon: Icons.add_circle_outline_rounded,
                    color: AppColors.primary,
                    onTap: () => context.go('/bookings/add'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(
                    label: 'كل الحجوزات',
                    icon: Icons.list_alt_rounded,
                    color: AppColors.info,
                    onTap: () => context.go('/bookings'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(
                    label: 'المرتجعات',
                    icon: Icons.replay_rounded,
                    color: AppColors.warning,
                    onTap: () => context.go('/refunds'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(
                    label: 'دفتر الأستاذ',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.success,
                    onTap: () => context.go('/wallet'),
                  )),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textMuted),
        const SizedBox(height: 16),
        const Text('تعذر الاتصال بقاعدة البيانات',
            style: TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة المحاولة'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
        ),
      ]),
    );
  }
}

// ── Widgets ─────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark));
}

class _KpiCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final bool isCount;

  const _KpiCard({
    required this.title, required this.value,
    required this.icon, required this.color, this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ]),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            isCount ? value : '$value ج.م',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ]),
    );
  }
}

class _CashCard extends StatelessWidget {
  final double cashPosition;
  const _CashCard({required this.cashPosition});

  @override
  Widget build(BuildContext context) {
    final isPositive = cashPosition >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('الرصيد النقدي',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: isPositive ? AppColors.success : AppColors.error,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            '${_money.format(cashPosition.abs())} ج.م',
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          isPositive ? 'رصيد دائن' : 'رصيد مدين',
          style: TextStyle(
              color: isPositive
                  ? Colors.greenAccent.shade100
                  : Colors.redAccent.shade100,
              fontSize: 12),
        ),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label, required this.icon,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}
