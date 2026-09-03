import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../models/order_model.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';

class OrderAlertService {
  static final OrderAlertService _instance = OrderAlertService._internal();
  factory OrderAlertService() => _instance;
  OrderAlertService._internal();

  final Set<String> _alertedOrderIds = {};
  bool _isPlaying = false;
  Timer? _vibrationTimer;

  bool get isPlaying => _isPlaying;

  /// Play ringtone and loop vibration until stopped
  Future<void> startOrderAlert() async {
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      // 1. Play loud notification/ringtone
      FlutterRingtonePlayer().play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.electronic,
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );

      // 2. Loop vibration pattern
      _vibrationTimer?.cancel();
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
        HapticFeedback.heavyImpact();
      });
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('[OrderAlertService] Error playing sound: $e');
    }
  }

  /// Stop ringtone and vibration
  Future<void> stopAlert() async {
    _isPlaying = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    try {
      await FlutterRingtonePlayer().stop();
    } catch (_) {}
  }

  /// Check new incoming orders and trigger alert if a new one is assigned
  void checkOrdersForAlert(BuildContext context, List<OrderModel> orders, String deliveryBoyUid) {
    for (final order in orders) {
      // Order assigned to this delivery partner and in pending/approved/dispatch state
      final isAssigned = order.deliveryBoyId == deliveryBoyUid;
      final isNew = !_alertedOrderIds.contains(order.id) &&
          (order.status == OrderStatus.approved || order.status == OrderStatus.outForDelivery);

      if (isAssigned && isNew && order.id.isNotEmpty) {
        _alertedOrderIds.add(order.id);
        _showNewOrderIncomingDialog(context, order);
        break;
      }
    }
  }

  /// Show prominent full-screen alert dialog with sound and vibration
  void _showNewOrderIncomingDialog(BuildContext context, OrderModel order) {
    startOrderAlert();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          stopAlert();
          Navigator.of(dialogCtx).pop();
        },
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF81C784), width: 2),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF2E7D32),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '🔔 नया डिलीवरी आर्डर आया है!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Order #${order.invoiceNumber.isNotEmpty ? order.invoiceNumber : order.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.merchantName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.merchantAddress,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('आर्डर राशि (Amount):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            CurrencyFormatter.format(order.grandTotal),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('भुगतान (Payment):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            order.paymentType == PaymentType.cod ? 'COD Cash Collect' : 'Prepaid Online',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: order.paymentType == PaymentType.cod ? Colors.orange.shade800 : Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (order.deliveryLatitude != null && order.deliveryLongitude != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            stopAlert();
                            LocationService.openGoogleMapsNavigation(
                              destinationLat: order.deliveryLatitude!,
                              destinationLng: order.deliveryLongitude!,
                              destinationTitle: order.merchantName,
                            );
                          },
                          icon: const Icon(Icons.map_rounded, size: 18),
                          label: const Text('मैप देखें'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    if (order.deliveryLatitude != null && order.deliveryLongitude != null)
                      const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          stopAlert();
                          Navigator.of(dialogCtx).pop();
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text('स्वीकार करें (Accept)', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
