import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/mock_repository.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

final _money = NumberFormat('#,##0', 'ar');

/// شاشة المحفظة والمدفوعات - Wallet & Transactions
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _selectedType = TransactionType.receiveFromCustomer;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// تسجيل حركة مالية جديدة
  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل مبلغاً صحيحاً')),
      );
      return;
    }

    setState(() {
      MockRepository.transactions.insert(
        0,
        TransactionModel(
          id: 't${DateTime.now().millisecondsSinceEpoch}',
          type: _selectedType,
          amount: amount,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
      _amountController.clear();
      _noteController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل الحركة بنجاح ✓')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحفظة والمدفوعات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== النصف العلوي: نموذج تسجيل حركة =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: kSoftShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تسجيل حركة مالية',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 14),

                // حقل المبلغ
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: _inputDecoration('المبلغ (ج.م)',
                      icon: Icons.payments_outlined),
                ),
                const SizedBox(height: 12),

                // نوع المعاملة
                DropdownButtonFormField<TransactionType>(
                  value: _selectedType,
                  decoration: _inputDecoration('نوع المعاملة',
                      icon: Icons.swap_horiz_rounded),
                  items: TransactionType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.labelAr,
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(
                      () => _selectedType = v ?? _selectedType),
                ),
                const SizedBox(height: 12),

                // الملاحظات
                TextField(
                  controller: _noteController,
                  decoration: _inputDecoration('ملاحظات (اختياري)',
                      icon: Icons.notes_rounded),
                ),
                const SizedBox(height: 16),

                // زر التسجيل
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('تسجيل الحركة',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ===== النصف السفلي: أحدث الحركات =====
          const Text(
            'أحدث الحركات',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          if (MockRepository.transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: Text('لا توجد حركات مسجلة',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ...MockRepository.transactions
                .map((t) => _TransactionTile(tx: t)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(fontSize: 13, color: AppColors.textMuted),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.scaffoldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
      ),
    );
  }
}

/// عنصر الحركة المالية في القائمة
class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final inflow = tx.type.isInflow;
    final color = inflow ? AppColors.green : AppColors.softRed;
    final sign = inflow ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kSoftShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              inflow ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.type.labelAr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontSize: 14,
                  ),
                ),
                if (tx.note != null)
                  Text(
                    tx.note!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                Text(
                  DateFormat('d MMM yyyy – hh:mm a', 'ar')
                      .format(tx.createdAt),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '$sign${_money.format(tx.amount)} ج.م',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
