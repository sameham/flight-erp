import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_repository.dart';
import '../models/booking_model.dart';
import '../theme/app_theme.dart';
import '../widgets/booking_card.dart';
import 'add_booking_screen.dart';

final _money = NumberFormat('#,##0', 'ar');

/// الشاشة الرئيسية - Dashboard
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// الفلتر المحدد حالياً
  _BookingFilter _filter = _BookingFilter.all;

  /// تطبيق الفلتر على قائمة الحجوزات
  List<BookingModel> get _filteredBookings {
    final now = DateTime.now();
    switch (_filter) {
      case _BookingFilter.upcoming:
        return MockRepository.bookings
            .where((b) =>
                b.flightDate.isAfter(now) &&
                b.status != BookingStatus.refunded &&
                b.status != BookingStatus.cancelled)
            .toList();
      case _BookingFilter.past:
        return MockRepository.bookings
            .where((b) =>
                b.flightDate.isBefore(now) &&
                b.status != BookingStatus.refunded)
            .toList();
      case _BookingFilter.refunds:
        return MockRepository.bookings
            .where((b) => b.status == BookingStatus.refunded)
            .toList();
      case _BookingFilter.all:
        return MockRepository.bookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ===== (a) الشريط العلوي =====
      appBar: AppBar(
        title: const Text('إدارة حجوزات الطيران'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'الإشعارات',
            onPressed: () {
              // TODO: شاشة الإشعارات
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      // زر إضافة حجز جديد
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('حجز جديد',
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddBookingScreen()),
          );
          if (saved == true && mounted) {
            setState(() {}); // تحديث القائمة والملخص المالي
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم حفظ الحجز بنجاح ✓')),
            );
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ===== (b) قسم الملخص المالي =====
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'إجمالي الأرباح',
                  value: MockRepository.totalProfit,
                  color: AppColors.green,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'المديونيات',
                  value: MockRepository.totalDue,
                  color: AppColors.softRed,
                  icon: Icons.trending_down_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'مرتجعات معلقة',
                  value: MockRepository.totalPendingRefunds,
                  color: AppColors.orange,
                  icon: Icons.replay_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ===== (c) الفلاتر السريعة =====
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _BookingFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _BookingFilter.values[i];
                final selected = f == _filter;
                return ChoiceChip(
                  label: Text(f.labelAr),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: AppColors.navy,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? AppColors.navy : Colors.grey.shade200,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ===== (d) قائمة كروت الحجوزات =====
          if (_filteredBookings.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: Text(
                  'لا توجد حجوزات في هذا التصنيف',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ..._filteredBookings.map(
              (b) => BookingCard(
                booking: b,
                finance: MockRepository.financeOf(b.id),
              ),
            ),
        ],
      ),
    );
  }
}

/// فلاتر العرض
enum _BookingFilter {
  all,
  upcoming,
  past,
  refunds;

  String get labelAr {
    switch (this) {
      case _BookingFilter.all:
        return 'الكل';
      case _BookingFilter.upcoming:
        return 'رحلات قادمة';
      case _BookingFilter.past:
        return 'رحلات سابقة';
      case _BookingFilter.refunds:
        return 'مرتجعات';
    }
  }
}

/// كارت الملخص المالي الصغير
class _SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              '${_money.format(value)} ج.م',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
