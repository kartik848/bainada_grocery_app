import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: TextStyle(
              color: status.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentTypeBadge extends StatelessWidget {
  final PaymentType paymentType;
  final bool isPaid;

  const PaymentTypeBadge({
    super.key,
    required this.paymentType,
    this.isPaid = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = paymentType.displayName;

    if (isPaid) {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
      label = '$label (Paid)';
    } else {
      switch (paymentType) {
        case PaymentType.credit:
          bg = const Color(0xFFFFF3E0);
          fg = const Color(0xFFE65100);
          break;
        case PaymentType.online:
          bg = const Color(0xFFE3F2FD);
          fg = const Color(0xFF1565C0);
          break;
        case PaymentType.cod:
          bg = const Color(0xFFF3E5F5);
          fg = const Color(0xFF6A1B9A);
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(paymentType.icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
