import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../models/finance_model.dart';
import '../theme/app_theme.dart';

final _money = NumberFormat('#,##0', 'ar');

/// كارت الحجز الواحد - حسب المواصفات التصميمية
class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final FinanceModel? finance;

  const BookingCard({super.key, required this.booking, this.finance});

  /// لون الحالة حسب نوعها
  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return AppColors.green;
      case BookingStatus.refunded:
        return AppColors.orange;
      case BookingStatus.cancelled:
        return AppColors.softRed;
      case BookingStatus.pending:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('d MMM yyyy', 'ar').format(booking.flightDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== رأس الكارت: الحالة + التاريخ =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status.labelAr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ===== المنتصف: اسم المسافر + PNR + رقم التذكرة =====
          Text(
            booking.passengerName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'PNR: ${booking.pnr}   •   تذكرة: ${booking.ticketNumber}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),

          // ===== مسار الرحلة =====
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(booking.departureCity,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy)),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.textMuted)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.flight,
                              size: 18, color: AppColors.navy),
                        ),
                        Expanded(child: Divider(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                Text(booking.arrivalCity,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ===== التذييل: سعر البيع + هامش الربح =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FooterItem(
                label: 'سعر البيع',
                value: finance?.sellingPrice ?? 0,
                color: AppColors.textDark,
              ),
              _FooterItem(
                label: 'هامش الربح',
                value: finance?.profitMargin ?? 0,
                color: AppColors.green,
                bold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;

  const _FooterItem({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          '${_money.format(value)} ج.م',
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
