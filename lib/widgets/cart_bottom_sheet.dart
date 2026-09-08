import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';

class FloatingCartBar extends StatelessWidget {
  final VoidCallback onCheckout;

  const FloatingCartBar({super.key, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${cart.itemCount} Items (${cart.totalUnits} Units)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (cart.totalGst > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'GST: ${CurrencyFormatter.format(cart.totalGst)}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(cart.grandTotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onCheckout,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('View Cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CheckoutModal extends StatefulWidget {
  final UserModel? overrideMerchant; // If salesman is placing order for a merchant

  const CheckoutModal({super.key, this.overrideMerchant});

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

enum DeliveryLocationChoice {
  liveGps,
  savedShop,
  manualAddress,
}

class _CheckoutModalState extends State<CheckoutModal> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _manualAddressController = TextEditingController();
  DeliveryLocationChoice _locationChoice = DeliveryLocationChoice.liveGps;
  double? _liveLat;
  double? _liveLng;
  String? _liveAddress;
  bool _isDetectingLiveGps = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _detectLiveLocation();
  }

  Future<void> _detectLiveLocation() async {
    setState(() => _isDetectingLiveGps = true);
    try {
      final loc = await LocationService().getLiveLocationDetails();
      if (loc != null && mounted) {
        setState(() {
          _liveLat = loc.latitude;
          _liveLng = loc.longitude;
          _liveAddress = loc.address;
        });
      }
    } catch (e) {
      debugPrint('[CheckoutModal] Live GPS error: $e');
    } finally {
      if (mounted) setState(() => _isDetectingLiveGps = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _manualAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final effectiveMerchant = widget.overrideMerchant ?? auth.currentUserModel;

    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (effectiveMerchant == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Center(
              child: Text('Please select or log in as a Kirana Merchant to proceed.'),
            ),
          );
        }

        final double availableCredit = effectiveMerchant.availableCredit;
        final bool creditExceeded = cart.paymentType == PaymentType.credit &&
            effectiveMerchant.creditLimit > 0 &&
            cart.grandTotal > availableCredit;

        final double minOrderLimit = effectiveMerchant.minOrderLimit;
        final bool isBelowMinOrder = minOrderLimit > 0 && cart.grandTotal < minOrderLimit;
        final double remainingForMin = minOrderLimit - cart.grandTotal;

        return DraggableScrollableSheet(
          initialChildSize: 0.90,
          minChildSize: 0.60,
          maxChildSize: 0.96,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Wholesale Cart & Checkout',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              '${cart.itemCount} Unique Items • ${cart.totalUnits} Units',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                          tooltip: 'Clear Cart',
                          onPressed: () {
                            cart.clearCart();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Minimum Order Limit Banner (If applicable)
                  if (minOrderLimit > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: isBelowMinOrder ? Colors.amber.shade100 : Colors.green.shade50,
                      child: Row(
                        children: [
                          Icon(
                            isBelowMinOrder ? Icons.warning_amber_rounded : Icons.check_circle,
                            size: 18,
                            color: isBelowMinOrder ? Colors.amber.shade900 : Colors.green.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isBelowMinOrder
                                  ? 'Minimum order limit for your account is ${CurrencyFormatter.format(minOrderLimit)}. Add ${CurrencyFormatter.format(remainingForMin)} more to place order.'
                                  : 'Minimum order limit of ${CurrencyFormatter.format(minOrderLimit)} reached! 🎉',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isBelowMinOrder ? Colors.amber.shade900 : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Body Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Buyer Shop Details
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.store, color: AppColors.primary, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      effectiveMerchant.shopName ?? effectiveMerchant.name,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Owner: ${effectiveMerchant.name} • ${effectiveMerchant.phone}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              if (effectiveMerchant.gstin != null && effectiveMerchant.gstin!.isNotEmpty) ...[
                                Text(
                                  'GSTIN: ${effectiveMerchant.gstin}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.bold),
                                ),
                              ],
                              if (effectiveMerchant.address != null) ...[
                                Text(
                                  effectiveMerchant.address!,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                              if (effectiveMerchant.creditLimit > 0) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: creditExceeded ? Colors.red.shade50 : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Credit Limit: ${CurrencyFormatter.format(effectiveMerchant.creditLimit)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: creditExceeded ? Colors.red.shade800 : Colors.blue.shade800,
                                        ),
                                      ),
                                      Text(
                                        'Available: ${CurrencyFormatter.format(availableCredit)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: creditExceeded ? Colors.red.shade800 : Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 📍 DELIVERY LOCATION SELECTION (3 Options: Live GPS, Saved Shop, Manual/Google Search)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: Color(0xFF16A34A), size: 18),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'डिलीवरी की लोकेशन चुनें (Select Location)',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF15803D)),
                                  ),
                                  const Spacer(),
                                  if (_isDetectingLiveGps)
                                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A))),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Option 1: Live GPS Location (Blinkit Style)
                              InkWell(
                                onTap: () => setState(() => _locationChoice = DeliveryLocationChoice.liveGps),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _locationChoice == DeliveryLocationChoice.liveGps ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _locationChoice == DeliveryLocationChoice.liveGps ? const Color(0xFF16A34A) : AppColors.border,
                                      width: _locationChoice == DeliveryLocationChoice.liveGps ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _locationChoice == DeliveryLocationChoice.liveGps ? Icons.radio_button_checked : Icons.radio_button_off,
                                        color: _locationChoice == DeliveryLocationChoice.liveGps ? const Color(0xFF16A34A) : AppColors.textMuted,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('📍 वर्तमान लाइव लोकेशन (Live GPS Detect)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Text(
                                              _liveAddress != null && _liveAddress!.isNotEmpty
                                                  ? _liveAddress!
                                                  : (_isDetectingLiveGps ? 'GPS से लोकेशन खोजी जा रही है...' : 'लाइव GPS लोकेशन टैग होगी'),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                            if (_liveLat != null && _liveLng != null) ...[
                                              const SizedBox(height: 2),
                                              Text('Coordinates: ${_liveLat!.toStringAsFixed(4)}, ${_liveLng!.toStringAsFixed(4)}',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF16A34A)),
                                        tooltip: 'Re-detect GPS',
                                        onPressed: _detectLiveLocation,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Option 2: Saved Shop Address
                              InkWell(
                                onTap: () => setState(() => _locationChoice = DeliveryLocationChoice.savedShop),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _locationChoice == DeliveryLocationChoice.savedShop ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _locationChoice == DeliveryLocationChoice.savedShop ? const Color(0xFF16A34A) : AppColors.border,
                                      width: _locationChoice == DeliveryLocationChoice.savedShop ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _locationChoice == DeliveryLocationChoice.savedShop ? Icons.radio_button_checked : Icons.radio_button_off,
                                        color: _locationChoice == DeliveryLocationChoice.savedShop ? const Color(0xFF16A34A) : AppColors.textMuted,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('🏠 रजिस्टर्ड दुकान का पता (Saved Shop Address)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Text(
                                              effectiveMerchant.address != null && effectiveMerchant.address!.isNotEmpty
                                                  ? effectiveMerchant.address!
                                                  : '${effectiveMerchant.shopName ?? effectiveMerchant.name}, Jaipur',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Option 3: Manual / Google Maps Search
                              InkWell(
                                onTap: () => setState(() => _locationChoice = DeliveryLocationChoice.manualAddress),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _locationChoice == DeliveryLocationChoice.manualAddress ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _locationChoice == DeliveryLocationChoice.manualAddress ? const Color(0xFF16A34A) : AppColors.border,
                                      width: _locationChoice == DeliveryLocationChoice.manualAddress ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _locationChoice == DeliveryLocationChoice.manualAddress ? Icons.radio_button_checked : Icons.radio_button_off,
                                            color: _locationChoice == DeliveryLocationChoice.manualAddress ? const Color(0xFF16A34A) : AppColors.textMuted,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('✏️ नया पता / गूगल मैप सर्च (Manual Address)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      if (_locationChoice == DeliveryLocationChoice.manualAddress) ...[
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _manualAddressController,
                                          decoration: InputDecoration(
                                            hintText: 'गली, मोहल्ला, दुकान नंबर या लैंडमार्क दर्ज करें...',
                                            hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Items in cart
                        const Text(
                          'Order Items & HSN Breakdown',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),

                        ...cart.itemList.map((item) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: AppColors.textPrimary,
                                          height: 1.25,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Rate: ${CurrencyFormatter.format(item.unitPrice)} / ${item.unit} (including tax) | GST: ${item.gstRate.toInt()}%',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.salesmanIncentive > 0) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '🎁 Salesman Incentive: ${CurrencyFormatter.format(item.totalSalesmanIncentive)} (${CurrencyFormatter.format(item.salesmanIncentive)}/${item.unit})',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFE65100),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withAlpha(120)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          final prod = Provider.of<ProductProvider>(context, listen: false).findById(item.productId);
                                          if (prod != null) {
                                            cart.decrement(prod);
                                          } else {
                                            cart.updateQuantity(item.productId, item.quantity - 1);
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                          child: Icon(Icons.remove, size: 15, color: AppColors.primary),
                                        ),
                                      ),
                                      Container(
                                        constraints: const BoxConstraints(minWidth: 32),
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        color: Colors.white,
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          final prod = Provider.of<ProductProvider>(context, listen: false).findById(item.productId);
                                          if (prod != null) {
                                            cart.increment(prod);
                                          } else {
                                            cart.updateQuantity(item.productId, item.quantity + 1);
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                          child: Icon(Icons.add, size: 15, color: AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 68,
                                  child: Text(
                                    CurrencyFormatter.format(item.totalItemPrice),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),

                        // Payment Type Selection
                        const Text(
                          'Select Payment Terms',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: PaymentType.values.map((type) {
                            final isSelected = cart.paymentType == type;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => cart.setPaymentType(type),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primarySurface : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        type == PaymentType.cod
                                            ? Icons.local_atm_outlined
                                            : type == PaymentType.credit
                                                ? Icons.account_balance_wallet_outlined
                                                : Icons.qr_code_2_rounded,
                                        size: 20,
                                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        type == PaymentType.cod
                                            ? 'Cash On Delivery'
                                            : type == PaymentType.credit
                                                ? 'Kirana Credit'
                                                : 'UPI / Online',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        if (creditExceeded) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Order exceeds available credit limit of ${CurrencyFormatter.format(availableCredit)}. Admin approval required.',
                                    style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Order Notes TextField
                        TextField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            hintText: 'Add special wholesale instructions / delivery remarks...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.note_alt_outlined, size: 18, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Price Summary with GST details
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Taxable Value (Base)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  Text(CurrencyFormatter.format(cart.taxableAmount),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              if (cart.totalVolumeSavings > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.local_offer_rounded, size: 14, color: Color(0xFF2E7D32)),
                                        SizedBox(width: 4),
                                        Text('Volume Slab Discount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                                      ],
                                    ),
                                    Text('-${CurrencyFormatter.format(cart.totalVolumeSavings)}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32))),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('CGST (Central Tax)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Text(CurrencyFormatter.format(cart.cgst),
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('SGST (State Tax)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Text(CurrencyFormatter.format(cart.sgst),
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total GST', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  Text(CurrencyFormatter.format(cart.totalGst),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Grand Total (including tax)',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(cart.grandTotal),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (cart.totalSalesmanIncentive > 0) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFFB74D)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.stars_rounded, size: 16, color: Color(0xFFE65100)),
                                          SizedBox(width: 6),
                                          Text(
                                            'सेल्समैन ऑफर इंसेंटिव कमाई:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFBF360C),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '+${CurrencyFormatter.format(cart.totalSalesmanIncentive)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFE65100),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Selected Location Confirmation Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _locationChoice == DeliveryLocationChoice.liveGps
                                    ? Icons.gps_fixed_rounded
                                    : (_locationChoice == DeliveryLocationChoice.savedShop
                                        ? Icons.storefront_rounded
                                        : Icons.edit_location_alt_rounded),
                                size: 15,
                                color: const Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _locationChoice == DeliveryLocationChoice.liveGps
                                      ? 'Delivery: वर्तमान लाइव GPS लोकेशन पर होगी'
                                      : (_locationChoice == DeliveryLocationChoice.savedShop
                                          ? 'Delivery: रजिस्टर्ड दुकान के पते पर होगी'
                                          : 'Delivery: दर्ज किए गए नए पते पर होगी'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF15803D),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Place Order Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (_isSubmitting || isBelowMinOrder)
                                ? null
                                : () async {
                                    setState(() => _isSubmitting = true);
                                    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                                    final isSalesman = auth.isSalesman;

                                    // Resolve Delivery Location based on user's choice
                                    String resolvedAddress = effectiveMerchant.address ?? 'Jaipur, Rajasthan';
                                    double? resolvedLat;
                                    double? resolvedLng;
                                    String? resolvedLiveLoc;

                                    switch (_locationChoice) {
                                      case DeliveryLocationChoice.liveGps:
                                        resolvedLat = _liveLat ?? effectiveMerchant.latitude;
                                        resolvedLng = _liveLng ?? effectiveMerchant.longitude;
                                        resolvedAddress = _liveAddress ?? effectiveMerchant.address ?? 'Jaipur, Rajasthan';
                                        resolvedLiveLoc = _liveAddress ?? effectiveMerchant.address;
                                        break;
                                      case DeliveryLocationChoice.savedShop:
                                        resolvedLat = effectiveMerchant.latitude;
                                        resolvedLng = effectiveMerchant.longitude;
                                        resolvedAddress = effectiveMerchant.address ?? 'Jaipur, Rajasthan';
                                        resolvedLiveLoc = effectiveMerchant.locationAddress ?? effectiveMerchant.address;
                                        break;
                                      case DeliveryLocationChoice.manualAddress:
                                        final typed = _manualAddressController.text.trim();
                                        resolvedAddress = typed.isNotEmpty ? typed : (effectiveMerchant.address ?? 'Jaipur, Rajasthan');
                                        resolvedLiveLoc = typed.isNotEmpty ? typed : null;
                                        resolvedLat = null;
                                        resolvedLng = null;
                                        break;
                                    }

                                    final orderId = await orderProvider.placeOrder(
                                      merchant: effectiveMerchant,
                                      salesman: isSalesman ? auth.currentUserModel : null,
                                      items: cart.itemList,
                                      taxableAmount: cart.taxableAmount,
                                      cgst: cart.cgst,
                                      sgst: cart.sgst,
                                      totalGst: cart.totalGst,
                                      grandTotal: cart.grandTotal,
                                      paymentType: cart.paymentType,
                                      notes: _notesController.text.trim(),
                                      deliveryLatitude: resolvedLat,
                                      deliveryLongitude: resolvedLng,
                                      liveLocationAddress: resolvedLiveLoc,
                                      deliveryAddressOverride: resolvedAddress,
                                      salesmanIncentiveAmount: cart.totalSalesmanIncentive,
                                    );

                                    setState(() => _isSubmitting = false);

                                    if (!context.mounted) return;

                                    if (orderId != null) {
                                      cart.clearCart();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Order #$orderId placed successfully! Status: Pending Approval'),
                                          backgroundColor: AppColors.primary,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(orderProvider.errorMessage ?? 'Failed to place order.'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBelowMinOrder ? Colors.grey.shade400 : AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    isBelowMinOrder
                                        ? 'Min. Order Limit: ₹${minOrderLimit.toInt()}'
                                        : 'Confirm Wholesale GST Order',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
