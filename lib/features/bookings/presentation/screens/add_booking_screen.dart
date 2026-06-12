import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/app_repository.dart';
import '../../../../core/theme/app_theme.dart';

final _money = NumberFormat('#,##0', 'ar');

/// شاشة إضافة حجز جديد - Enterprise
class AddBookingScreen extends StatefulWidget {
  const AddBookingScreen({super.key});
  @override
  State<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends State<AddBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = AppRepository();
  bool _saving = false;

  // Controllers
  final _pnrCtrl = TextEditingController();
  final _ticketCtrl = TextEditingController();
  final _airlineCtrl = TextEditingController();
  final _flightNumCtrl = TextEditingController();
  final _depAirportCtrl = TextEditingController();
  final _arrAirportCtrl = TextEditingController();
  final _passengerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _saleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _depDate;
  DateTime? _retDate;
  BookingStatus _status = BookingStatus.pending;
  List<CustomerModel> _customers = [];
  List<SupplierModel> _suppliers = [];
  CustomerModel? _selectedCustomer;
  SupplierModel? _selectedSupplier;

  // حسابات لحظية
  double get _cost => double.tryParse(_costCtrl.text) ?? 0;
  double get _sale => double.tryParse(_saleCtrl.text) ?? 0;
  double get _profit => _sale - _cost;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    for (final c in [_pnrCtrl, _ticketCtrl, _airlineCtrl, _flightNumCtrl,
      _depAirportCtrl, _arrAirportCtrl, _passengerCtrl, _phoneCtrl,
      _costCtrl, _saleCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    try {
      final results = await Future.wait([
        _repo.fetchCustomers(), _repo.fetchSuppliers(),
      ]);
      if (mounted) setState(() {
        _customers = results[0] as List<CustomerModel>;
        _suppliers = results[1] as List<SupplierModel>;
      });
    } catch (_) {}
  }

  Future<void> _pickDate({required bool isReturn}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => isReturn ? _retDate = picked : _depDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_depDate == null) {
      _showSnack('اختر تاريخ المغادرة');
      return;
    }

    setState(() => _saving = true);
    try {
      final booking = BookingModel(
        id: const Uuid().v4(),
        pnr: _pnrCtrl.text.trim().toUpperCase(),
        ticketNumber: _ticketCtrl.text.trim().isEmpty ? null : _ticketCtrl.text.trim(),
        airline: _airlineCtrl.text.trim().isEmpty ? null : _airlineCtrl.text.trim(),
        flightNumber: _flightNumCtrl.text.trim().isEmpty ? null : _flightNumCtrl.text.trim(),
        departureAirport: _depAirportCtrl.text.trim().toUpperCase().isEmpty
            ? null : _depAirportCtrl.text.trim().toUpperCase(),
        arrivalAirport: _arrAirportCtrl.text.trim().toUpperCase().isEmpty
            ? null : _arrAirportCtrl.text.trim().toUpperCase(),
        departureDate: _depDate!,
        returnDate: _retDate,
        passengerName: _passengerCtrl.text.trim(),
        passengerPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
        supplierId: _selectedSupplier?.id,
        supplierName: _selectedSupplier?.name,
        costPrice: _cost,
        salePrice: _sale,
        paymentStatus: PaymentStatus.unpaid,
        bookingStatus: _status,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await _repo.createBooking(booking);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      _showSnack('فشل الحفظ: تحقق من الاتصال');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
            // ── بيانات التذكرة ──────────────────────────────
            _SectionCard(title: 'بيانات التذكرة', icon: Icons.confirmation_number_outlined, children: [
              Row(children: [
                Expanded(child: _field(_pnrCtrl, 'PNR *',
                    icon: Icons.tag_rounded, required_: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_ticketCtrl, 'رقم التذكرة',
                    icon: Icons.airplane_ticket_outlined)),
              ]),
              Row(children: [
                Expanded(child: _field(_airlineCtrl, 'شركة الطيران',
                    icon: Icons.flight_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _field(_flightNumCtrl, 'رقم الرحلة',
                    icon: Icons.numbers_rounded)),
              ]),
            ]),
            const SizedBox(height: 14),

            // ── مسار الرحلة ─────────────────────────────────
            _SectionCard(title: 'مسار الرحلة', icon: Icons.map_outlined, children: [
              Row(children: [
                Expanded(child: _field(_depAirportCtrl, 'مطار المغادرة (IATA)',
                    icon: Icons.flight_takeoff_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _field(_arrAirportCtrl, 'مطار الوصول (IATA)',
                    icon: Icons.flight_land_rounded)),
              ]),
              Row(children: [
                Expanded(child: _datePicker('تاريخ المغادرة *', _depDate,
                    () => _pickDate(isReturn: false))),
                const SizedBox(width: 10),
                Expanded(child: _datePicker('تاريخ العودة (اختياري)', _retDate,
                    () => _pickDate(isReturn: true))),
              ]),
            ]),
            const SizedBox(height: 14),

            // ── بيانات المسافر ──────────────────────────────
            _SectionCard(title: 'بيانات المسافر', icon: Icons.person_outline_rounded, children: [
              _field(_passengerCtrl, 'اسم المسافر *',
                  icon: Icons.person_rounded, required_: true),
              _field(_phoneCtrl, 'رقم الهاتف',
                  icon: Icons.phone_rounded, numeric: true),
              // اختيار العميل
              DropdownButtonFormField<CustomerModel?>(
                value: _selectedCustomer,
                decoration: _deco('حساب العميل (اختياري)',
                    icon: Icons.people_outline_rounded),
                items: [
                  const DropdownMenuItem(value: null,
                      child: Text('— بدون حساب —',
                          style: TextStyle(color: AppColors.textMuted))),
                  ..._customers.map((c) => DropdownMenuItem(
                      value: c, child: Text('${c.name} • ${c.phone ?? ""}',
                          style: const TextStyle(fontSize: 13)))),
                ],
                onChanged: (v) => setState(() => _selectedCustomer = v),
              ),
              const SizedBox(height: 12),
            ]),
            const SizedBox(height: 14),

            // ── المورد ──────────────────────────────────────
            _SectionCard(title: 'المورد', icon: Icons.business_outlined, children: [
              DropdownButtonFormField<SupplierModel?>(
                value: _selectedSupplier,
                decoration: _deco('شركة الطيران / المكتب',
                    icon: Icons.local_airport_outlined),
                items: [
                  const DropdownMenuItem(value: null,
                      child: Text('— اختر مورداً —',
                          style: TextStyle(color: AppColors.textMuted))),
                  ..._suppliers.map((s) => DropdownMenuItem(
                      value: s, child: Text(s.name,
                          style: const TextStyle(fontSize: 13)))),
                ],
                onChanged: (v) => setState(() => _selectedSupplier = v),
              ),
              const SizedBox(height: 12),
            ]),
            const SizedBox(height: 14),

            // ── الأسعار ─────────────────────────────────────
            _SectionCard(title: 'الأسعار', icon: Icons.payments_outlined, children: [
              Row(children: [
                Expanded(child: _field(_costCtrl, 'سعر الشراء *',
                    icon: Icons.shopping_cart_outlined,
                    numeric: true, required_: true,
                    onChanged: (_) => setState(() {}))),
                const SizedBox(width: 10),
                Expanded(child: _field(_saleCtrl, 'سعر البيع *',
                    icon: Icons.sell_outlined,
                    numeric: true, required_: true,
                    onChanged: (_) => setState(() {}))),
              ]),
              // ملخص الربح اللحظي
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (_profit >= 0
                      ? AppColors.success : AppColors.error).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(
                    _profit >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: _profit >= 0 ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'هامش الربح: ${_money.format(_profit)} ج.م',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14,
                      color: _profit >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              // حالة الحجز
              DropdownButtonFormField<BookingStatus>(
                value: _status,
                decoration: _deco('حالة الحجز', icon: Icons.flag_outlined),
                items: BookingStatus.values.map((s) =>
                    DropdownMenuItem(value: s,
                        child: Text(s.labelAr,
                            style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 12),
            ]),
            const SizedBox(height: 14),

            // ── ملاحظات ─────────────────────────────────────
            _SectionCard(title: 'ملاحظات', icon: Icons.notes_rounded, children: [
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: _deco('ملاحظات إضافية', icon: Icons.edit_note_rounded),
              ),
              const SizedBox(height: 4),
            ]),
            const SizedBox(height: 24),

            // زر الحفظ
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ الحجز',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────
  Widget _field(TextEditingController ctrl, String label, {
    required IconData icon, bool numeric = false,
    bool required_ = false, ValueChanged<String>? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))] : null,
      decoration: _deco(label, icon: icon),
      validator: required_
          ? (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null : null,
      onChanged: onChanged,
    ),
  );

  Widget _datePicker(String label, DateTime? value, VoidCallback onTap) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: _deco(label, icon: Icons.calendar_today_outlined),
          child: Text(
            value == null
                ? 'اختر التاريخ'
                : DateFormat('d MMM yyyy', 'ar').format(value),
            style: TextStyle(
                fontSize: 14,
                color: value == null ? AppColors.textMuted : AppColors.textDark),
          ),
        ),
      ),
    );

  InputDecoration _deco(String label, {required IconData icon}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: kCardShadow,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ]),
      const SizedBox(height: 16),
      ...children,
    ]),
  );
}
