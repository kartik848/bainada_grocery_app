import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/constants.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/cart_bottom_sheet.dart';
import '../../widgets/ignito_branding.dart';
import '../../widgets/order_card.dart';
import '../../widgets/product_card.dart';
import '../auth/auth_wrapper.dart';

class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({super.key});

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  int _currentTabIndex = 0;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmittingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUserModel != null) {
        Provider.of<OrderProvider>(context, listen: false).listenToOrders(
          role: UserRole.merchant,
          uid: auth.currentUserModel!.uid,
        );
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _openCheckoutSheet() {
    setState(() => _currentTabIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUserModel;
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.shopName ?? user?.name ?? 'Kirana Store',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user?.address != null && user!.address!.isNotEmpty)
                    Text(
                      user.address!,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: () => setState(() => _currentTabIndex = 1),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: () async {
              final orderProv = Provider.of<OrderProvider>(context, listen: false);
              final cartProv = Provider.of<CartProvider>(context, listen: false);
              final nav = Navigator.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out from your Kirana Merchant account?'),
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
              if (confirm == true) {
                orderProv.clear();
                cartProv.clearCart();
                await auth.logout();
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildCatalogTab(user),
            _buildCartAndCheckoutTab(user, cart),
            _buildOrdersTab(),
            _buildKhataProfileTab(user, auth),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: AppColors.primarySurface,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: AppColors.primary),
            label: 'Catalog',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cart.itemCount > 0,
              label: Text('${cart.itemCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cart.itemCount > 0,
              label: Text('${cart.itemCount}'),
              child: const Icon(Icons.shopping_cart, color: AppColors.primary),
            ),
            label: 'My Cart',
          ),
          Consumer<OrderProvider>(
            builder: (context, orderProv, _) {
              return NavigationDestination(
                icon: Badge(
                  isLabelVisible: orderProv.orders.isNotEmpty,
                  label: Text('${orderProv.orders.length}'),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: orderProv.orders.isNotEmpty,
                  label: Text('${orderProv.orders.length}'),
                  child: const Icon(Icons.receipt_long, color: AppColors.primary),
                ),
                label: 'My Orders',
              );
            },
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.primary),
            label: 'Khata & Profile',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: WHOLESALE CATALOG / HOME
  // ==========================================
  Widget _buildCatalogTab(UserModel? user) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Stack(
      children: [
        Column(
          children: [
            // Merchant Khata Quick Status Banner
            if (user != null) _buildMerchantKhataBanner(user),

            // Search Bar & Horizontal Category Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                children: [
                  TextField(
                    onChanged: productProvider.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search wholesale items (चावल, दाल, तेल, मसाले, आटा)...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppConstants.productCategories.length,
                      itemBuilder: (ctx, i) {
                        final cat = AppConstants.productCategories[i];
                        final isSelected = productProvider.selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(cat, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            selectedColor: AppColors.primarySurface,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) => productProvider.setCategory(cat),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Wholesale Products List
            Expanded(
              child: productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : productProvider.filteredProducts.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  'No wholesale products match your search/category.',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                const Text('Try searching with Hindi transliteration or clear the filters.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 90),
                          itemCount: productProvider.filteredProducts.length,
                          itemBuilder: (ctx, index) {
                            final product = productProvider.filteredProducts[index];
                            return ProductCard(product: product);
                          },
                        ),
            ),
          ],
        ),

        // Floating Bottom Cart Bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FloatingCartBar(onCheckout: _openCheckoutSheet),
        ),
      ],
    );
  }

  Widget _buildMerchantKhataBanner(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Khata Credit Limit', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text(
                    CurrencyFormatter.format(user.creditLimit),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
          Container(height: 24, width: 1, color: AppColors.border),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Market Outstanding Due', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text(
                CurrencyFormatter.format(user.outstandingDue),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: user.outstandingDue > 0 ? Colors.red.shade800 : Colors.green.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: MY CART & WHOLESALE CHECKOUT
  // ==========================================
  Widget _buildCartAndCheckoutTab(UserModel? user, CartProvider cart) {
    if (cart.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.remove_shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Your Wholesale Cart is Empty',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Browse the wholesale catalog and add bulk items to place your order.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => setState(() => _currentTabIndex = 0),
                icon: const Icon(Icons.storefront_rounded),
                label: const Text('Browse Wholesale Catalog'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final double minOrderLimit = user?.minOrderLimit ?? 0.0;
    final bool isBelowMinOrder = minOrderLimit > 0 && cart.grandTotal < minOrderLimit;
    final double remainingForMin = minOrderLimit - cart.grandTotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimum Order Limit Banner
          if (minOrderLimit > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isBelowMinOrder ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isBelowMinOrder ? const Color(0xFFF59E0B) : const Color(0xFF16A34A)),
              ),
              child: Row(
                children: [
                  Icon(
                    isBelowMinOrder ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                    color: isBelowMinOrder ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isBelowMinOrder
                          ? 'Minimum order basket for your account is ${CurrencyFormatter.format(minOrderLimit)}. Please add ${CurrencyFormatter.format(remainingForMin)} more.'
                          : 'Minimum order requirement of ${CurrencyFormatter.format(minOrderLimit)} met! 🎉',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isBelowMinOrder ? const Color(0xFF92400E) : const Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Cart Items Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cart Items (${cart.itemCount} products • ${cart.totalUnits} units)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              TextButton.icon(
                onPressed: () => cart.clearCart(),
                icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.red),
                label: const Text('Clear Cart', style: TextStyle(fontSize: 12, color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Cart Items List
          ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: cart.itemList.length,
            itemBuilder: (context, index) {
              final item = cart.itemList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Leading Product Info (Expanded)
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
                            '${CurrencyFormatter.format(item.unitPrice)} / ${item.unit}  •  GST ${item.gstRate.toInt()}%',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 2. Quantity Selector (+/-) (Compact 100-110px)
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

                    // 3. Item Price (Right aligned)
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
            },
          ),
          const SizedBox(height: 14),

          // Payment Type Selection
          const Text('Select Payment Terms', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => cart.setPaymentType(PaymentType.cod),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: cart.paymentType == PaymentType.cod ? AppColors.primarySurface : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cart.paymentType == PaymentType.cod ? AppColors.primary : AppColors.border,
                        width: cart.paymentType == PaymentType.cod ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          color: cart.paymentType == PaymentType.cod ? AppColors.primary : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cash on Delivery',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cart.paymentType == PaymentType.cod ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => cart.setPaymentType(PaymentType.credit),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: cart.paymentType == PaymentType.credit ? AppColors.primarySurface : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cart.paymentType == PaymentType.credit ? AppColors.primary : AppColors.border,
                        width: cart.paymentType == PaymentType.credit ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: cart.paymentType == PaymentType.credit ? AppColors.primary : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Khata Credit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cart.paymentType == PaymentType.credit ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Delivery Notes
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Add wholesale delivery remarks / notes...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // Bill Summary Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Taxable Value (Base)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text(CurrencyFormatter.format(cart.taxableAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                      Text('-${CurrencyFormatter.format(cart.totalVolumeSavings)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32))),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CGST (Central Tax)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(CurrencyFormatter.format(cart.cgst), style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SGST (State Tax)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(CurrencyFormatter.format(cart.sgst), style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total GST Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Text(CurrencyFormatter.format(cart.totalGst), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total (GST Inclusive)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(
                      CurrencyFormatter.format(cart.grandTotal),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Confirm & Place Order Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isSubmittingOrder || isBelowMinOrder)
                  ? null
                  : () async {
                      if (user == null) return;
                      setState(() => _isSubmittingOrder = true);
                      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

                      final orderId = await orderProvider.placeOrder(
                        merchant: user,
                        items: cart.itemList,
                        taxableAmount: cart.taxableAmount,
                        cgst: cart.cgst,
                        sgst: cart.sgst,
                        totalGst: cart.totalGst,
                        grandTotal: cart.grandTotal,
                        paymentType: cart.paymentType,
                        notes: _notesController.text.trim(),
                      );

                      setState(() => _isSubmittingOrder = false);

                      if (!mounted) return;

                      if (orderId != null) {
                        cart.clearCart();
                        _notesController.clear();
                        setState(() => _currentTabIndex = 2);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Order #$orderId placed successfully! Status: Pending Approval.'),
                            backgroundColor: const Color(0xFF16A34A),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmittingOrder
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      isBelowMinOrder ? 'Min Order Basket: ₹${minOrderLimit.toInt()}' : 'Confirm & Place Order',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: MERCHANT ORDERS & TRACKING
  // ==========================================
  Widget _buildOrdersTab() {
    final orderProvider = Provider.of<OrderProvider>(context);

    if (orderProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderProvider.orders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text('No orders placed yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              const Text('Start adding wholesale products from the catalog to place orders.', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _currentTabIndex = 0),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Browse Catalog', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: orderProvider.orders.length,
      itemBuilder: (ctx, i) {
        final order = orderProvider.orders[i];
        return OrderCard(order: order, showMerchantInfo: false);
      },
    );
  }

  // ==========================================
  // TAB 4: KHATA LEDGER & STORE PROFILE
  // ==========================================
  Widget _buildKhataProfileTab(UserModel? user, AuthProvider auth) {
    if (user == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Identity Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(Icons.storefront_rounded, size: 28, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.shopName ?? user.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text('Proprietor: ${user.name}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('Mobile: ${user.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (user.gstin != null && user.gstin!.isNotEmpty)
                        Text('GSTIN: ${user.gstin}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Khata Financial Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D2818), Color(0xFF1B4D3E)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Khata Credit Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
                  ],
                ),
                const Divider(color: Colors.white24, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Credit Limit', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text(
                          CurrencyFormatter.format(user.creditLimit),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Available Credit', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text(
                          CurrencyFormatter.format(user.availableCredit),
                          style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Market Due', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text(
                          CurrencyFormatter.format(user.outstandingDue),
                          style: TextStyle(
                            color: user.outstandingDue > 0 ? const Color(0xFFFCA5A5) : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Attribution & Store Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Store & Account Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildInfoRow('Onboarded By Field Salesman', user.addedBySalesmanName ?? 'Bainada Direct Admin'),
                _buildInfoRow('Store Address', user.address?.isNotEmpty == true ? user.address! : '—'),
                if (user.landmark != null) _buildInfoRow('Landmark', user.landmark!),
                _buildInfoRow('Minimum Order Basket', CurrencyFormatter.format(user.minOrderLimit)),
                _buildInfoRow('Account Status', user.isActive ? 'Active Verified Merchant ✅' : 'Inactive / Suspended ❌'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final orderProv = Provider.of<OrderProvider>(context, listen: false);
                final cartProv = Provider.of<CartProvider>(context, listen: false);
                final nav = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out from your Kirana Merchant account?'),
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
                if (confirm == true) {
                  orderProv.clear();
                  cartProv.clearCart();
                  await auth.logout();
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Developer Branding Footer
          const IgnitoCorpBranding(isDarkTheme: false, isCompact: false),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
