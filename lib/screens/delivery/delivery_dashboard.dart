import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/cash_settlement_model.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/order_alert_service.dart';
import '../../utils/constants.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/bainada_logo.dart';
import '../../widgets/ignito_branding.dart';
import '../../widgets/top_location_bar.dart';
import '../auth/auth_wrapper.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  int _tabIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUserModel != null) {
        Provider.of<OrderProvider>(context, listen: false).listenToOrders(
          role: UserRole.deliveryBoy,
          uid: auth.currentUserModel!.uid,
        );
      }
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch phone dialer for $cleanNumber')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dialing $cleanNumber...')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUserModel;
    final orderProvider = Provider.of<OrderProvider>(context);

    // 1. Ready for Pickup / Approved
    final readyForPickupOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.approved)
        .toList();

    // 2. Live Out for Delivery
    final outForDeliveryOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.outForDelivery)
        .toList();

    // 3. Completed deliveries (Delivered or Cancelled)
    final completedOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled)
        .toList();

    // Total cash collected on COD deliveries
    final double codCashCollected = completedOrders
        .where((o) => o.paymentType == PaymentType.cod && o.isPaid)
        .fold(0.0, (sum, o) => sum + o.grandTotal);

    final double activeCodCash = (user?.pendingCashInHand != null && user!.pendingCashInHand > 0)
        ? user.pendingCashInHand
        : codCashCollected;

    // 🔔 Real-time order alert with ringtone & vibration for Delivery Partner
    if (user != null && orderProvider.orders.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        OrderAlertService().checkOrdersForAlert(context, orderProvider.orders, user.uid);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              color: AppColors.primaryDark,
              child: const BainadaBrandLogo(
                isDarkTheme: true,
                isStacked: false,
                emblemSize: 36,
                showSubtext: true,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF3E5F5),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF4A148C),
                    child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Delivery Partner',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.vehicleNumber != null ? 'Vehicle: ${user!.vehicleNumber}' : 'Dispatch Fleet',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF4A148C), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4A148C)),
                    title: const Text('Ready for Pickup', style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: _tabIndex == 0,
                    onTap: () {
                      setState(() => _tabIndex = 0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_shipping_outlined, color: Color(0xFF4A148C)),
                    title: const Text('Out for Delivery', style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: _tabIndex == 1,
                    onTap: () {
                      setState(() => _tabIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.task_alt_outlined, color: Color(0xFF4A148C)),
                    title: const Text('Completed Trips', style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: _tabIndex == 2,
                    onTap: () {
                      setState(() => _tabIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out from your Delivery Staff account?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        Provider.of<OrderProvider>(context, listen: false).clear();
                        Provider.of<CartProvider>(context, listen: false).clearCart();
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthWrapper()),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: const Center(
                child: IgnitoCorpBranding(
                  isDarkTheme: false,
                  isCompact: false,
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Partner Hub',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              'Partner: ${user?.name ?? "Delivery Staff"}${user?.vehicleNumber != null ? " (${user!.vehicleNumber})" : ""}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          const TopLocationBar(
            backgroundColor: Colors.white24,
            textColor: Colors.white,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out from your Delivery Staff account?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                Provider.of<OrderProvider>(context, listen: false).clear();
                Provider.of<CartProvider>(context, listen: false).clearCart();
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Daily Cash Summary Banner
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Total Cash in Hand (आज का जमा कैश)',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${outForDeliveryOrders.length} Live Route',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    CurrencyFormatter.format(activeCodCash),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '⚠️ Deposit this amount at Godown / Admin office at the end of the shift.',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // 4-Tab Segmented Selector
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: _tabIndex == 0 ? const Color(0xFF4A148C) : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Pickup (${readyForPickupOrders.length})',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _tabIndex == 0 ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: _tabIndex == 1 ? const Color(0xFF4A148C) : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Route (${outForDeliveryOrders.length})',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _tabIndex == 1 ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tabIndex = 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: _tabIndex == 2 ? const Color(0xFF4A148C) : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Done (${completedOrders.length})',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _tabIndex == 2 ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tabIndex = 3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: _tabIndex == 3 ? const Color(0xFF1B5E20) : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Settlements',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _tabIndex == 3 ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: _tabIndex == 0
                  ? _buildActiveDeliveriesList(readyForPickupOrders)
                  : _tabIndex == 1
                      ? _buildActiveDeliveriesList(outForDeliveryOrders)
                      : _tabIndex == 2
                          ? _buildCompletedDeliveriesList(completedOrders)
                          : _buildSettlementHistoryTab(user?.uid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementHistoryTab(String? deliveryBoyId) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUserModel;

    return StreamBuilder<List<CashSettlementModel>>(
      stream: _firestoreService.streamCashSettlements(deliveryBoyId: deliveryBoyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final settlements = snapshot.data ?? [];
        final totalSettled = settlements.fold(0.0, (sum, s) => sum + s.amountSettled);
        final pendingCash = user?.pendingCashInHand ?? 0.0;

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Top Settlement Metrics Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cash in Hand (रोकड़)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(pendingCash),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFE65100)),
                        ),
                        const SizedBox(height: 2),
                        const Text('To deposit at HQ', style: TextStyle(fontSize: 10, color: Color(0xFF8D6E63))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Deposited (जमा)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(totalSettled),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                        ),
                        const SizedBox(height: 2),
                        Text('${settlements.length} Receipts Issued', style: const TextStyle(fontSize: 10, color: Color(0xFF388E3C))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (settlements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 52, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No Cash Settlements Yet',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'When you hand over COD cash to Admin, official deposit receipts will show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...settlements.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receipt #${s.id.length > 8 ? s.id.substring(0, 8).toUpperCase() : s.id}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                '${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year} at ${s.createdAt.hour.toString().padLeft(2, '0')}:${s.createdAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.format(s.amountSettled),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('Mode: ${s.paymentMode}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Approved by: ${s.settledByAdminName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                  if (s.notes != null && s.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Note: ${s.notes}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      );
    },
  );
}

  Widget _buildActiveDeliveriesList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.green),
              SizedBox(height: 12),
              Text(
                'No pending deliveries right now!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Orders assigned to you by Admin will appear here.', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final order = orders[i];

        return _DeliveryOrderCard(
          order: order,
          onCallMerchant: (phone) => _makePhoneCall(phone),
          onStartDelivery: () async {
            await Provider.of<OrderProvider>(context, listen: false).startDelivery(order.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order #${order.invoiceNumber} is now Out for Delivery! 🚚'),
                  backgroundColor: Colors.blue.shade800,
                ),
              );
            }
          },
          onUpdateOutcome: () => _showDeliveryOutcomeModal(order),
        );
      },
    );
  }

  Widget _buildCompletedDeliveriesList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('No deliveries completed yet today.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final order = orders[i];
        return _DeliveryOrderCard(
          order: order,
          onCallMerchant: (phone) => _makePhoneCall(phone),
        );
      },
    );
  }

  void _showDeliveryOutcomeModal(OrderModel order) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUserModel;
    // 0: Delivered (COD / Paid), 1: Shop Closed / Absent, 2: Order Rejected / Not Accepted
    int outcomeType = 0;
    bool isCashCollected = order.paymentType == PaymentType.cod;
    final notesCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Icon(Icons.delivery_dining, color: Color(0xFF4A148C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delivery Outcome: ${order.invoiceNumber}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Shop: ${order.merchantName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),

                  // Outcome Choice Selectable Tiles
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          dense: true,
                          leading: Icon(
                            outcomeType == 0 ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: outcomeType == 0 ? Colors.green : Colors.grey,
                          ),
                          title: const Text('✅ Delivered Successfully', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: const Text('Handed over goods to Kirana shopkeeper', style: TextStyle(fontSize: 11)),
                          onTap: () => setModalState(() => outcomeType = 0),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading: Icon(
                            outcomeType == 1 ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: outcomeType == 1 ? Colors.orange : Colors.grey,
                          ),
                          title: const Text('🚪 Shop Closed / Merchant Absent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                          subtitle: const Text('Cancelled / Not delivered this trip', style: TextStyle(fontSize: 11)),
                          onTap: () => setModalState(() => outcomeType = 1),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading: Icon(
                            outcomeType == 2 ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: outcomeType == 2 ? Colors.red : Colors.grey,
                          ),
                          title: const Text('❌ Order Rejected / Not Accepted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                          subtitle: const Text('Merchant refused delivery / returning goods', style: TextStyle(fontSize: 11)),
                          onTap: () => setModalState(() => outcomeType = 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Cash Collection Switch if Delivered
                  if (outcomeType == 0 && order.paymentType == PaymentType.cod) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCashCollected ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isCashCollected ? Colors.green.shade300 : Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cash Collected on Spot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Amount: ${CurrencyFormatter.format(order.grandTotal)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                          Switch(
                            value: isCashCollected,
                            activeThumbColor: Colors.green,
                            onChanged: (val) => setModalState(() => isCashCollected = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Notes / Remarks
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: outcomeType == 0 ? 'Delivery Notes / Shop Signee' : 'Reason for Non-Delivery*',
                      hintText: outcomeType == 0 ? 'e.g. Received by Ramesh owner' : 'e.g. Shop shutter closed / No answer on call',
                      prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Confirm Outcome Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              try {
                                final OrderStatus newStatus = outcomeType == 0 ? OrderStatus.delivered : OrderStatus.cancelled;

                                await _firestoreService.updateDeliveryOutcome(
                                  orderId: order.id,
                                  status: newStatus,
                                  isPaid: outcomeType == 0 ? (order.paymentType == PaymentType.cod ? isCashCollected : order.isPaid) : false,
                                  outcomeReason: notesCtrl.text.trim().isNotEmpty
                                      ? notesCtrl.text.trim()
                                      : (outcomeType == 0 ? 'Delivered' : (outcomeType == 1 ? 'Shop Closed' : 'Rejected')),
                                  collectedAmount: isCashCollected ? order.grandTotal : null,
                                  merchantId: order.merchantId,
                                  deliveryBoyId: user?.uid,
                                );

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Delivery outcome recorded successfully!'),
                                      backgroundColor: outcomeType == 0 ? Colors.green : Colors.orange.shade800,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                      icon: isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        outcomeType == 0 ? 'Confirm Delivery & Close' : 'Confirm Cancellation Note',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: outcomeType == 0 ? Colors.green.shade700 : Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// DETAILED DELIVERY ORDER CARD WITH PACKAGING BREAKDOWN & CASH HIGHLIGHTS
// ==========================================
class _DeliveryOrderCard extends StatefulWidget {
  final OrderModel order;
  final Function(String phone) onCallMerchant;
  final VoidCallback? onStartDelivery;
  final VoidCallback? onUpdateOutcome;

  const _DeliveryOrderCard({
    required this.order,
    required this.onCallMerchant,
    this.onStartDelivery,
    this.onUpdateOutcome,
  });

  @override
  State<_DeliveryOrderCard> createState() => _DeliveryOrderCardState();
}

class _DeliveryOrderCardState extends State<_DeliveryOrderCard> {
  bool _isExpanded = false;

  String _getPackagingDropSummary(List<CartItem> items) {
    final Map<String, int> unitCounts = {};
    for (final item in items) {
      final unitKey = item.unit.trim().isNotEmpty ? item.unit.trim() : 'pack';
      unitCounts[unitKey] = (unitCounts[unitKey] ?? 0) + item.quantity;
    }
    if (unitCounts.isEmpty) return '0 Units';
    return unitCounts.entries
        .map((e) => '${e.value} ${e.key}${e.value > 1 && !e.key.toLowerCase().endsWith('s') ? 's' : ''}')
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isOutForDelivery = order.status == OrderStatus.outForDelivery;
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;
    final packagingSummary = _getPackagingDropSummary(order.items);
    final isCod = order.paymentType == PaymentType.cod;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Order Invoice ID & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A148C).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long, size: 16, color: Color(0xFF4A148C)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.invoiceNumber,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF4A148C)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDelivered
                        ? Colors.green.shade50
                        : isCancelled
                            ? Colors.red.shade50
                            : isOutForDelivery
                                ? Colors.blue.shade50
                                : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDelivered
                          ? Colors.green.shade200
                          : isCancelled
                              ? Colors.red.shade200
                              : isOutForDelivery
                                  ? Colors.blue.shade200
                                  : Colors.orange.shade200,
                    ),
                  ),
                  child: Text(
                    isDelivered
                        ? 'DELIVERED'
                        : isCancelled
                            ? 'CANCELLED'
                            : isOutForDelivery
                                ? 'OUT FOR DELIVERY'
                                : 'READY FOR PICKUP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDelivered
                          ? Colors.green.shade900
                          : isCancelled
                              ? Colors.red.shade900
                              : isOutForDelivery
                                  ? Colors.blue.shade900
                                  : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 2. High-Visibility Payment Badge Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCod ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCod ? const Color(0xFFFFB300) : const Color(0xFF81C784),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCod ? Icons.payments_rounded : Icons.check_circle_rounded,
                    size: 18,
                    color: isCod ? const Color(0xFFB78103) : const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCod
                          ? 'COLLECT CASH: ${CurrencyFormatter.format(order.grandTotal)} (COD)'
                          : 'ALREADY PAID / KHATA CREDIT (₹0 to Collect)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isCod ? const Color(0xFF8D6200) : const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. Shop & Address Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.merchantName,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.red),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              order.merchantAddress,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 📍 Live Order Location & Google Maps Direct Navigation (Blinkit Style)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gps_fixed_rounded,
                          size: 15, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Text(
                        order.deliveryLatitude != null
                            ? 'Live Order GPS Tagged'
                            : 'Registered Store Location',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      const Spacer(),
                      if (order.deliveryLatitude != null &&
                          order.deliveryLongitude != null)
                        Text(
                          '${order.deliveryLatitude!.toStringAsFixed(4)}, ${order.deliveryLongitude!.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                        ),
                    ],
                  ),
                  if (order.liveLocationAddress != null &&
                      order.liveLocationAddress!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      order.liveLocationAddress!,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF166534)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (order.deliveryLatitude != null &&
                            order.deliveryLongitude != null) {
                          LocationService.openGoogleMapsNavigation(
                            destinationLat: order.deliveryLatitude!,
                            destinationLng: order.deliveryLongitude!,
                            destinationTitle: order.merchantName,
                          );
                        } else {
                          final query = Uri.encodeComponent(
                              '${order.merchantName}, ${order.merchantAddress}');
                          launchUrl(
                            Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=$query'),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.navigation_rounded,
                          size: 16, color: Colors.white),
                      label: const Text(
                        '🗺️ Navigate on Google Maps (रास्ता देखें)',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 4. Packaging Units Highlights Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCE93D8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_rounded, size: 16, color: Color(0xFF4A148C)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF4A148C)),
                        children: [
                          const TextSpan(text: 'Total Drop Units: ', style: TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(
                            text: packagingSummary,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 5. Expandable / Clean Itemized Breakdown
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${order.items.length} Line Items Breakdown (${order.totalItemUnits} packs)',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Text(
                      _isExpanded ? 'Hide' : 'View Details',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                    ),
                  ],
                ),
              ),
            ),

            if (_isExpanded) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final item = order.items[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                if (item.hindiName != null && item.hindiName!.isNotEmpty)
                                  Text(
                                    item.hindiName!,
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                  ),
                                Text(
                                  '${item.quantity} ${item.unit} (${item.unitMultiplier} pcs/pack) @ ${CurrencyFormatter.format(item.unitPrice)}',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(item.totalItemPrice),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const Divider(height: 20),

            // 6. Action Buttons Bar (No RenderFlex Overflow)
            Row(
              children: [
                // Call Merchant Button
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onCallMerchant(order.merchantPhone),
                    icon: const Icon(Icons.phone_in_talk, size: 15, color: Color(0xFF2E7D32)),
                    label: const Text(
                      'Call Merchant',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E7D32), width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Main Delivery Action Button
                if (!isDelivered && !isCancelled)
                  Expanded(
                    flex: 3,
                    child: isOutForDelivery
                        ? ElevatedButton.icon(
                            onPressed: widget.onUpdateOutcome,
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: Text(
                              isCod ? 'Complete / Collect Cash' : 'Complete Delivery',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A148C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: widget.onStartDelivery,
                            icon: const Icon(Icons.local_shipping, size: 16),
                            label: const Text(
                              'Start Delivery',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
