import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/data/repositories/app_repository.dart';
import '../../../../core/theme/app_theme.dart';

final _money = NumberFormat('#,##0', 'ar');
final _repo = AppRepository();

/// شاشة المحفظة ودفتر الأستاذ
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<LedgerEntryModel> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.fetchLedger(limit: 100);
      if (mounted) setState(() { _entries = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // حساب الرصيد الإجمالي
  double get _balance {
    double total = 0;
    for (final e in _entries) {
      total += e.isCredit ? e.amount : -e.amount;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر الأستاذ'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'السجلات', icon: Icon(Icons.list_alt_rounded, size: 18)),
            Tab(text: 'قيد جديد', icon: Icon(Icons.add_rounded, size: 18)),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── تبويب السجلات ──────────────────────────────────
          _LedgerTab(entries: _entries, balance: _balance, loading: _loading,
              onRefresh: _load),
          // ── تبويب قيد جديد ─────────────────────────────────
          _NewEntryTab(onSaved: () { _load(); _tabs.animateTo(0); }),
        ],
      ),
    );
  }
}

/// تبويب عرض السجلات
class _LedgerTab extends StatelessWidget {
  final List<LedgerEntryModel> entries;
  final double balance;
  final bool loading;
  final VoidCallback onRefresh;

  const _LedgerTab({required this.entries, required this.balance,
      required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقة الرصيد
          _BalanceCard(balance: balance),
          const SizedBox(height: 16),
          const Text('أحدث القيود',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const Center(child: Text('لا توجد قيود',
                style: TextStyle(color: AppColors.textMuted)))
          else
            ...entries.map((e) => _LedgerTile(entry: e)),
        ],
      ),
    );
  }
}

/// بطاقة الرصيد الإجمالي
class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final isPos = balance >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPos
              ? [AppColors.success, const Color(0xFF1A7A4A)]
              : [AppColors.error, const Color(0xFFA33C34)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPos ? AppColors.success : AppColors.error).withOpacity(0.3),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('إجمالي الرصيد',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Text('${_money.format(balance.abs())} ج.م',
            style: const TextStyle(color: Colors.white,
                fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(isPos ? '✓ رصيد دائن' : '⚠ رصيد مدين',
            style: TextStyle(
                color: isPos ? Colors.greenAccent.shade100
                    : Colors.redAccent.shade100,
                fontSize: 12)),
      ]),
    );
  }
}

/// صف القيد في القائمة
class _LedgerTile extends StatelessWidget {
  final LedgerEntryModel entry;
  const _LedgerTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.isCredit ? AppColors.success : AppColors.error;
    final sign = entry.isCredit ? '+' : '-';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: kCardShadow,
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            entry.isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: color, size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.type.labelAr,
              style: const TextStyle(fontWeight: FontWeight.w600,
                  color: AppColors.textDark, fontSize: 13)),
          Text(entry.description,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          Text(DateFormat('d MMM yyyy – h:mm a', 'ar').format(entry.createdAt),
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ])),
        Text('$sign${_money.format(entry.amount)} ج.م',
            style: TextStyle(fontWeight: FontWeight.bold,
                color: color, fontSize: 14)),
      ]),
    );
  }
}

/// تبويب إضافة قيد جديد
class _NewEntryTab extends StatefulWidget {
  final VoidCallback onSaved;
  const _NewEntryTab({required this.onSaved});
  @override
  State<_NewEntryTab> createState() => _NewEntryTabState();
}

class _NewEntryTabState extends State<_NewEntryTab> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  LedgerType _type = LedgerType.customerPayment;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل مبلغاً صحيحاً')));
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل الوصف')));
      return;
    }

    setState(() => _saving = true);
    try {
      await _repo.addManualLedgerEntry(
        type: _type, amount: amount,
        description: _descCtrl.text.trim(),
        reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      );
      _amountCtrl.clear();
      _descCtrl.clear();
      _refCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تسجيل القيد ✓')));
        widget.onSaved();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل التسجيل')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('تسجيل قيد محاسبي',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        const SizedBox(height: 16),

        DropdownButtonFormField<LedgerType>(
          value: _type,
          decoration: const InputDecoration(
              labelText: 'نوع القيد',
              prefixIcon: Icon(Icons.category_outlined, size: 20,
                  color: AppColors.textMuted)),
          items: LedgerType.values.map((t) => DropdownMenuItem(
              value: t, child: Text(t.labelAr,
                  style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _type = v ?? _type),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          decoration: const InputDecoration(
              labelText: 'المبلغ (ج.م) *',
              prefixIcon: Icon(Icons.payments_outlined, size: 20,
                  color: AppColors.textMuted)),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _descCtrl,
          decoration: const InputDecoration(
              labelText: 'الوصف *',
              prefixIcon: Icon(Icons.description_outlined, size: 20,
                  color: AppColors.textMuted)),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _refCtrl,
          decoration: const InputDecoration(
              labelText: 'رقم مرجعي (اختياري)',
              prefixIcon: Icon(Icons.numbers_rounded, size: 20,
                  color: AppColors.textMuted)),
        ),
        const SizedBox(height: 24),

        // مؤشر نوع القيد (دائن/مدين)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (_type.isInflow ? AppColors.success : AppColors.error)
                .withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(
              _type.isInflow
                  ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: _type.isInflow ? AppColors.success : AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _type.isInflow ? 'قيد دائن (أموال داخلة)' : 'قيد مدين (أموال خارجة)',
              style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13,
                color: _type.isInflow ? AppColors.success : AppColors.error,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_rounded),
          label: Text(_saving ? 'جارٍ التسجيل...' : 'تسجيل القيد',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
