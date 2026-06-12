import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/data/repositories/app_repository.dart';
import '../../../../core/theme/app_theme.dart';

/// شاشة إنشاء طلب مرتجع جديد
class AddRefundScreen extends StatefulWidget {
  final BookingModel booking;
  const AddRefundScreen({super.key, required this.booking});

  @override
  State<AddRefundScreen> createState() => _AddRefundScreenState();
}

class _AddRefundScreenState extends State<AddRefundScreen> {
  final _repo = AppRepository();
  final _originalCtrl = TextEditingController();
  final _feesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  RefundPriority _priority = RefundPriority.normal;
  DateTime? _deadline;
  bool _saving = false;

  double get _original => double.tryParse(_originalCtrl.text) ?? 0;
  double get _fees => double.tryParse(_feesCtrl.text) ?? 0;
  double get _net => (_original - _fees).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    // ملء تلقائي من الحجز
    _originalCtrl.text = widget.booking.salePrice.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _originalCtrl.dispose();
    _feesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_original <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل قيمة التذكرة الأصلية')));
      return;
    }
    setState(() => _saving = true);
    try {
      final refund = RefundModel(
        id: '',
        bookingId: widget.booking.id,
        customerId: widget.booking.customerId,
        passengerName: widget.booking.passengerName,
        pnr: widget.booking.pnr,
        ticketNumber: widget.booking.ticketNumber,
        airline: widget.booking.airline,
        originalTicketValue: _original,
        cancellationFees: _fees,
        refundAmount: _net,
        priority: _priority,
        deadlineAt: _deadline,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        requestedAt: DateTime.now(),
      );
      await _repo.createRefund(refund);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الحفظ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب استرداد جديد')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بيانات الحجز (للعرض فقط)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.booking.passengerName,
                  style: const TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 15, color: AppColors.textDark)),
              Text('PNR: ${widget.booking.pnr}  •  ${widget.booking.ticketNumber ?? "—"}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ),
          const SizedBox(height: 16),

          // الأرقام المالية
          _field(_originalCtrl, 'قيمة التذكرة الأصلية *',
              icon: Icons.receipt_long_outlined),
          _field(_feesCtrl, 'رسوم الإلغاء',
              icon: Icons.remove_circle_outline_rounded,
              onChanged: (_) => setState(() {})),

          // صافي الاسترداد
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.successContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.payments_outlined,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Text('صافي الاسترداد: ${NumberFormat('#,##0', 'ar').format(_net)} ج.م',
                  style: const TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 15, color: AppColors.success)),
            ]),
          ),
          const SizedBox(height: 16),

          // الأولوية
          DropdownButtonFormField<RefundPriority>(
            value: _priority,
            decoration: const InputDecoration(
                labelText: 'الأولوية',
                prefixIcon: Icon(Icons.flag_outlined, size: 20,
                    color: AppColors.textMuted)),
            items: RefundPriority.values.map((p) =>
                DropdownMenuItem(value: p,
                    child: Text(p.labelAr))).toList(),
            onChanged: (v) => setState(() => _priority = v ?? _priority),
          ),
          const SizedBox(height: 12),

          // الموعد النهائي
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 14)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (d != null) setState(() => _deadline = d);
            },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'الموعد النهائي (SLA)',
                  prefixIcon: Icon(Icons.timer_outlined, size: 20,
                      color: AppColors.textMuted)),
              child: Text(
                _deadline == null ? 'اختر الموعد النهائي'
                    : DateFormat('d MMM yyyy', 'ar').format(_deadline!),
                style: TextStyle(fontSize: 14,
                    color: _deadline == null
                        ? AppColors.textMuted : AppColors.textDark),
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: Icon(Icons.notes_rounded, size: 20,
                    color: AppColors.textMuted)),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded),
            label: Text(_saving ? 'جارٍ الحفظ...' : 'إرسال طلب الاسترداد',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {required IconData icon, ValueChanged<String>? onChanged}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted)),
        onChanged: onChanged,
      ),
    );
}
