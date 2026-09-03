import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../services/invoice_service.dart';
import '../services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import 'status_badge.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final Widget? trailingAction;
  final bool showMerchantInfo;
  final bool showDeliveryBoy;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.trailingAction,
    this.showMerchantInfo = true,
    this.showDeliveryBoy = true,
  });

  void _confirmCancelOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Cancel Order?'),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel Order #${order.invoiceNumber}? This will restock all wholesale inventory.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No, Keep Order')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await Provider.of<OrderProvider>(context, listen: false).cancelOrder(
                order.id,
                itemsToRestock: order.items,
                reason: 'Cancelled by Merchant',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Order #${order.invoiceNumber} cancelled successfully.' : 'Failed to cancel order.'),
                    backgroundColor: success ? Colors.red.shade800 : Colors.grey,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Yes, Cancel Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap ?? () => _showOrderDetailsDialog(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Invoice Number + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                order.invoiceNumber,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.formatDate(order.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const Divider(height: 18, color: AppColors.divider),

              // Merchant Shop & Location
              if (showMerchantInfo) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.storefront_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.merchantName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${order.merchantPhone} • ${order.merchantAddress}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Items Summary Preview
              Text(
                '${order.items.length} items (${order.totalItemUnits} units) • ${order.items.map((i) => i.productName).take(2).join(', ')}${order.items.length > 2 ? '...' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Bottom Row: Grand Total + Tax info + Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyFormatter.format(order.grandTotal),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'GST: ${CurrencyFormatter.format(order.totalGst)}',
                              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                            ),
                            PaymentTypeBadge(
                              paymentType: order.paymentType,
                              isPaid: order.isPaid,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Only show cancel button if status is pending
                      if (order.status == OrderStatus.pending) ...[
                        OutlinedButton.icon(
                          onPressed: () => _confirmCancelOrder(context),
                          icon: const Icon(Icons.close, size: 13, color: Colors.red),
                          label: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 11.5, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(54, 30),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 20),
                        tooltip: 'View / Print Tax Invoice',
                        onPressed: () => InvoiceService.printOrPreview(context, order),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                      if (trailingAction != null) trailingAction!,
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetailsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Invoice Title & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.invoiceNumber,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                Text(
                  'Date: ${CurrencyFormatter.formatDate(order.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),

                // Merchant Details Card
                const Text(
                  'Buyer Information:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  order.merchantName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Phone: ${order.merchantPhone} | Address: ${order.merchantAddress}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (order.merchantGstin != null && order.merchantGstin!.isNotEmpty) ...[
                  Text(
                    'Buyer GSTIN: ${order.merchantGstin}',
                    style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w700),
                  ),
                ],

                if (order.salesmanName != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Booked By Salesman: ${order.salesmanName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600),
                  ),
                ],

                if (order.deliveryBoyName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Delivery Partner: ${order.deliveryBoyName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                  ),
                ],

                const SizedBox(height: 10),
                // Google Maps Location & Navigation Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (order.deliveryLatitude != null && order.deliveryLongitude != null) {
                        LocationService.openGoogleMapsNavigation(
                          destinationLat: order.deliveryLatitude!,
                          destinationLng: order.deliveryLongitude!,
                          destinationTitle: order.merchantName,
                        );
                      } else {
                        final query = Uri.encodeComponent('${order.merchantName}, ${order.merchantAddress}');
                        launchUrl(
                          Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFF15803D)),
                    label: Text(
                      order.deliveryLatitude != null
                          ? '🗺️ Google Maps Navigation (${order.deliveryLatitude!.toStringAsFixed(3)}, ${order.deliveryLongitude!.toStringAsFixed(3)})'
                          : '🗺️ Open Location on Google Maps',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF86EFAC), width: 1.2),
                      backgroundColor: const Color(0xFFF0FDF4),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(),

                // Items list with HSN & GST
                const Text(
                  'Itemized Wholesale Details:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              Text(
                                '${item.quantity} ${item.unit} @ ${CurrencyFormatter.format(item.unitPrice)} | HSN: ${item.hsnCode} | GST ${item.gstRate.toStringAsFixed(0)}% (₹${item.gstAmount.toStringAsFixed(2)})',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.totalItemPrice),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 24),

                // Bill Breakdown with GST
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Taxable Value (Base)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text(CurrencyFormatter.format(order.taxableAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CGST (Central Tax)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(CurrencyFormatter.format(order.cgst), style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SGST (State Tax)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(CurrencyFormatter.format(order.sgst), style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total GST Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text(CurrencyFormatter.format(order.totalGst), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total (Tax Invoice)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      CurrencyFormatter.format(order.grandTotal),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Payment Terms: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    PaymentTypeBadge(paymentType: order.paymentType, isPaid: order.isPaid),
                  ],
                ),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${order.notes}',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 20),

                // Bottom Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          InvoiceService.printOrPreview(context, order);
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('Download / Print GST Invoice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (order.status == OrderStatus.pending) ...[
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmCancelOrder(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        child: const Text('Cancel Order'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
