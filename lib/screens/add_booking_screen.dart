import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/app_repository.dart';
import '../models/booking_model.dart';
import '../theme/app_theme.dart';

final _money = NumberFormat('#,##0', 'ar');

/// شاشة إنشاء حجز جديد - Add Booking Screen
class AddBookingScreen extends StatefulWidget {
  const AddBookingScreen({super.key});

  @override
  State<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends State<AddBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // بيانات الحجز
  final _nameCtrl = TextEditingController();
  final _pnrCtrl = TextEditingController();
  final _ticketCtrl = TextEditingController();
  String? _fromCity;
  String? _toCity;
  DateTime? _flightDate;
  BookingStatus _status = BookingStatus.confirmed;

  /// قائمة المدن المتاحة (يمكن لاحقاً جلبها من قاعدة البيانات)
  static const _cities = [
    'القاهرة', 'الإسكندرية', 'الرياض', 'جدة', 'الدمام',
    'دبي', 'أبوظبي', 'الكويت', 'الدوحة', 'إسطنبول',
    'عمّان', 'بيروت', 'لندن', 'باريس', 'نيويورك',
  ];

  // البيانات المالية
  final _purchaseCtrl = TextEditingController();
  final _sellingCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _pnrCtrl, _ticketCtrl,
      _purchaseCtrl, _sellingCtrl, _paidCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _purchase => double.tryParse(_purchaseCtrl.text) ?? 0;
  double get _selling => double.tryParse(_sellingCtrl.text) ?? 0;
  double get _paid => double.tryParse(_paidCtrl.text) ?? 0;

  /// هامش الربح المتوقع (محسوب لحظياً أثناء الكتابة)
  double get _profit => _selling - _purchase;

  /// المتبقي على العميل
  double get _due => (_selling - _paid).clamp(0, double.infinity);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _flightDate = picked);
  }

  final _repo = AppRepository();
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromCity == null || _toCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر مدينتي المغادرة والوصول')),
      );
      return;
    }
    if (_fromCity == _toCity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('مدينة المغادرة لا يمكن أن تساوي مدينة الوصول')),
      );
      return;
    }
    if (_flightDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر تاريخ الرحلة')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // الحفظ في قاعدة البيانات (PostgreSQL عبر Supabase)
      await _repo.addBooking(
        passengerName: _nameCtrl.text.trim(),
        pnr: _pnrCtrl.text.trim().toUpperCase(),
        ticketNumber: _ticketCtrl.text.trim(),
        departureCity: _fromCity!,
        arrivalCity: _toCity!,
        flightDate: _flightDate!,
        status: _status,
        purchasePrice: _purchase,
        sellingPrice: _selling,
        paidAmount: _paid,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحفظ: تحقق من الاتصال')),
        );
      }
      return;
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حجز جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== كارت بيانات الرحلة =====
            _SectionCard(
              title: 'بيانات الرحلة',
              icon: Icons.flight_takeoff_rounded,
              children: [
                _field(_nameCtrl, 'اسم المسافر',
                    icon: Icons.person_outline, required_: true),
                Row(
                  children: [
                    Expanded(
                      child: _field(_pnrCtrl, 'PNR',
                          icon: Icons.confirmation_number_outlined,
                          required_: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(_ticketCtrl, 'رقم التذكرة',
                          icon: Icons.airplane_ticket_outlined,
                          required_: true),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _cityDropdown(
                        label: 'مدينة المغادرة',
                        icon: Icons.flight_takeoff,
                        value: _fromCity,
                        onChanged: (v) => setState(() => _fromCity = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _cityDropdown(
                        label: 'مدينة الوصول',
                        icon: Icons.flight_land,
                        value: _toCity,
                        onChanged: (v) => setState(() => _toCity = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // تاريخ الرحلة
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _decoration('تاريخ الرحلة',
                        icon: Icons.calendar_today_outlined),
                    child: Text(
                      _flightDate == null
                          ? 'اضغط للاختيار'
                          : DateFormat('d MMM yyyy', 'ar')
                              .format(_flightDate!),
                      style: TextStyle(
                        fontSize: 14,
                        color: _flightDate == null
                            ? AppColors.textMuted
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // حالة الحجز
                DropdownButtonFormField<BookingStatus>(
                  value: _status,
                  decoration:
                      _decoration('حالة الحجز', icon: Icons.flag_outlined),
                  items: BookingStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.labelAr,
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v ?? _status),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ===== كارت البيانات المالية =====
            _SectionCard(
              title: 'البيانات المالية',
              icon: Icons.payments_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _field(_purchaseCtrl, 'سعر الشراء',
                          icon: Icons.shopping_cart_outlined,
                          numeric: true,
                          required_: true,
                          onChanged: (_) => setState(() {})),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(_sellingCtrl, 'سعر البيع',
                          icon: Icons.sell_outlined,
                          numeric: true,
                          required_: true,
                          onChanged: (_) => setState(() {})),
                    ),
                  ],
                ),
                _field(_paidCtrl, 'المدفوع من العميل',
                    icon: Icons.account_balance_wallet_outlined,
                    numeric: true,
                    onChanged: (_) => setState(() {})),

                // ===== ملخص لحظي: الربح والمتبقي =====
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LiveStat(
                        label: 'هامش الربح',
                        value: _profit,
                        color: _profit >= 0
                            ? AppColors.green
                            : AppColors.softRed,
                      ),
                      Container(
                          width: 1, height: 30, color: Colors.grey.shade300),
                      _LiveStat(
                        label: 'المتبقي على العميل',
                        value: _due,
                        color: _due > 0
                            ? AppColors.softRed
                            : AppColors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // زر الحفظ
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ الحجز',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    required IconData icon,
    bool numeric = false,
    bool required_ = false,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        inputFormatters: numeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
            : null,
        decoration: _decoration(label, icon: icon),
        validator: required_
            ? (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null
            : null,
        onChanged: onChanged,
      ),
    );
  }

  /// قائمة منسدلة لاختيار المدينة
  Widget _cityDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _decoration(label, icon: icon),
      items: _cities
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _decoration(String label, {required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
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

/// كارت قسم في الفورم
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.navy),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// إحصائية لحظية (الربح/المتبقي)
class _LiveStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _LiveStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        Text('${_money.format(value)} ج.م',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
