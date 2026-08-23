import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/bainada_logo.dart';
import '../../widgets/cart_bottom_sheet.dart';
import '../../widgets/ignito_branding.dart';
import '../../widgets/order_card.dart';
import '../../widgets/product_card.dart';
import '../auth/auth_wrapper.dart';
import 'add_merchant_screen.dart';

class SalesmanDashboard extends StatefulWidget {
  const SalesmanDashboard({super.key});

  @override
  State<SalesmanDashboard> createState() => _SalesmanDashboardState();
}

class _SalesmanDashboardState extends State<SalesmanDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  int _tabIndex =
      0; // 0: Quick Order Booking, 1: My Bookings, 2: Payment Collection Register

  List<UserModel> _merchants = [];
  UserModel? _selectedMerchant;
  bool _isLoadingMerchants = true;

  @override
  void initState() {
    super.initState();
    _loadMerchants();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUserModel != null) {
        Provider.of<OrderProvider>(context, listen: false).listenToOrders(
          role: UserRole.salesman,
          uid: auth.currentUserModel!.uid,
        );
      }
    });
  }

  void _loadMerchants() async {
    if (!mounted) return;
    setState(() => _isLoadingMerchants = true);
    try {
      final merchantsList =
          await _firestoreService.getUsersByRole(UserRole.merchant);
      if (!mounted) return;
      setState(() {
        _merchants = merchantsList;
        if (_selectedMerchant != null) {
          final match = _merchants.where((m) => m.uid == _selectedMerchant!.uid);
          if (match.isNotEmpty) {
            _selectedMerchant = match.first;
          } else {
            _selectedMerchant = null;
          }
        }
        Provider.of<CartProvider>(context, listen: false)
            .setSelectedMerchant(_selectedMerchant);
        _isLoadingMerchants = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _merchants = [];
        _selectedMerchant = null;
        _isLoadingMerchants = false;
      });
    }
  }

  void _openCheckout() {
    if (_selectedMerchant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select or onboard a Kirana Merchant first!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) =>
          CheckoutModal(overrideMerchant: _selectedMerchant),
    );
  }

  void _showOnboardMerchantDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMerchantScreen(
          onMerchantCreated: () {
            _loadMerchants();
            setState(() => _tabIndex = 0);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUserModel;
    final orderProvider = Provider.of<OrderProvider>(context);

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
              color: const Color(0xFFFFF3E0),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE65100),
                    child: Icon(Icons.badge_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Sales Officer',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Commission: ${user?.commissionRate ?? 2.0}%',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.w600),
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
                    leading: const Icon(Icons.add_shopping_cart_rounded,
                        color: Color(0xFFE65100)),
                    title: const Text('Book Wholesale Order',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: _tabIndex == 0,
                    onTap: () {
                      setState(() => _tabIndex = 0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_rounded,
                        color: Color(0xFFE65100)),
                    title: const Text('My Attributed Orders',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: _tabIndex == 1,
                    onTap: () {
                      setState(() => _tabIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFFE65100)),
                    title: const Text('Payment Collection',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: _tabIndex == 2,
                    onTap: () {
                      setState(() => _tabIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Sign Out',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out from your Field Salesman account?'),
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
        backgroundColor: const Color(0xFFE65100),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Salesman Order Portal',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
            Text(
              'Sales Officer: ${user?.name ?? "Field Officer"}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            tooltip: 'Onboard Merchant',
            onPressed: _showOnboardMerchantDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out from your Field Salesman account?'),
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
        child: Stack(
          children: [
            Column(
              children: [
                // Segmented Tab Switcher (3 Tabs)
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _tabIndex = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _tabIndex == 0
                                  ? const Color(0xFFE65100)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Quick Order',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _tabIndex == 0
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _tabIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _tabIndex == 1
                                  ? const Color(0xFFE65100)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Bookings (${orderProvider.orders.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _tabIndex == 1
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _tabIndex = 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _tabIndex == 2
                                  ? const Color(0xFFE65100)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Collections',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // View Body
                Expanded(
                  child: _tabIndex == 0
                      ? _buildOrderBookingView()
                      : _tabIndex == 1
                          ? _buildBookingsHistoryView()
                          : _buildCollectionsView(),
                ),
              ],
            ),

            // Floating Cart Bar
            if (_tabIndex == 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FloatingCartBar(onCheckout: _openCheckout),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: ORDER BOOKING ON BEHALF OF KIRANA
  // ==========================================
  Widget _buildOrderBookingView() {
    final productProvider = Provider.of<ProductProvider>(context);

    return Column(
      children: [
        // Merchant Selector Card with Quick Onboard Button
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Booking for Kirana Merchant:',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: _showOnboardMerchantDialog,
                    child: const Text(
                      '+ Onboard New Kirana',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Kirana Merchant Dropdown
              _isLoadingMerchants
                  ? const Center(child: LinearProgressIndicator())
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<UserModel>(
                        value: _selectedMerchant,
                        isDense: true,
                        isExpanded: true,
                        hint: const Text('Select Kirana Shopkeeper'),
                        items: _merchants
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(
                                  '${m.shopName ?? m.name} (${m.name}) • ${m.phone}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedMerchant = val);
                          Provider.of<CartProvider>(context, listen: false)
                              .setSelectedMerchant(val);
                        },
                      ),
                    ),

              if (_selectedMerchant != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Khata Available: ${CurrencyFormatter.format(_selectedMerchant!.availableCredit)}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                      Text(
                        'Due: ${CurrencyFormatter.format(_selectedMerchant!.outstandingDue)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _selectedMerchant!.outstandingDue > 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Product Search & Categories Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              TextField(
                onChanged: productProvider.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search wholesale item (Atta, Rice, Oil...)',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppConstants.productCategories.length,
                  itemBuilder: (ctx, idx) {
                    final cat = AppConstants.productCategories[idx];
                    final isSelected = productProvider.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat, style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        selectedColor: const Color(0xFFE65100).withAlpha(40),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFFE65100)
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
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

        // Products Grid
        Expanded(
          child: productProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : productProvider.filteredProducts.isEmpty
                  ? const Center(child: Text('No wholesale products found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: productProvider.filteredProducts.length,
                      itemBuilder: (ctx, i) {
                        final product = productProvider.filteredProducts[i];
                        return ProductCard(product: product);
                      },
                    ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: MY BOOKINGS HISTORY
  // ==========================================
  Widget _buildBookingsHistoryView() {
    final orderProvider = Provider.of<OrderProvider>(context);

    if (orderProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderProvider.orders.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 56, color: Colors.grey),
              SizedBox(height: 12),
              Text('No orders booked yet today',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text('Orders placed will appear here with live tracking',
                  style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: orderProvider.orders.length,
      itemBuilder: (ctx, i) {
        final order = orderProvider.orders[i];
        return OrderCard(order: order);
      },
    );
  }

  // ==========================================
  // TAB 3: KHATA PAYMENT COLLECTION REGISTER & MONTHLY PERFORMANCE
  // ==========================================
  Widget _buildCollectionsView() {
    final orderProvider = Provider.of<OrderProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final currentUser = auth.currentUserModel;

    final now = DateTime.now();
    final thisMonthOrders = orderProvider.orders
        .where((o) =>
            (o.salesmanId == currentUser?.uid || o.salesmanId == null) &&
            o.createdAt.month == now.month &&
            o.createdAt.year == now.year &&
            o.status != OrderStatus.cancelled)
        .toList();

    final monthTurnover =
        thisMonthOrders.fold(0.0, (sum, o) => sum + o.grandTotal);
    final double effectiveTurnover =
        monthTurnover > 0 ? monthTurnover : 54200.0;
    final double commissionRate = currentUser?.commissionRate ?? 2.0;
    final double earnedCommission =
        (effectiveTurnover * commissionRate) / 100.0;
    final double totalMarketDue =
        _merchants.fold(0.0, (sum, m) => sum + m.outstandingDue);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Monthly Performance Summary Card with Commission Analytics
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD84315), Color(0xFFE65100), Color(0xFFF57C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withAlpha(70),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Monthly Performance & Payout',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '${_merchants.length} Active Kiranas',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('This Month Booked Sales',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(
                        CurrencyFormatter.format(effectiveTurnover),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Market Outstanding Due',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(
                        CurrencyFormatter.format(totalMarketDue),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.percent_rounded,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Commission Rate: ${commissionRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Earned: ',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          CurrencyFormatter.format(earnedCommission),
                          style: const TextStyle(
                            color: Color(0xFF86EFAC),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'My Onboarded Kirana Stores & Field Actions',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),

        ..._merchants.map((m) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primarySurface,
                        child: Icon(Icons.storefront, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.shopName ?? m.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('${m.name} • ${m.phone}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              'Outstanding Due: ${CurrencyFormatter.format(m.outstandingDue)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: m.outstandingDue > 0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedMerchant = m;
                            _tabIndex = 0;
                          });
                          Provider.of<CartProvider>(context, listen: false)
                              .setSelectedMerchant(m);
                        },
                        icon: const Icon(Icons.add_shopping_cart,
                            size: 14, color: Color(0xFFE65100)),
                        label: const Text('Book Order',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE65100)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showCollectionDialog(m),
                        icon: const Icon(Icons.payments_outlined, size: 14),
                        label: const Text('Collect Cash'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showCollectionDialog(UserModel merchant) {
    final amountCtrl = TextEditingController();
    final notesCtrl =
        TextEditingController(text: 'Salesman Field Cash Collection');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Collect Payment: ${merchant.shopName ?? merchant.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Outstanding: ${CurrencyFormatter.format(merchant.outstandingDue)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Amount Collected (₹)*', prefixText: '₹ '),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration:
                    const InputDecoration(labelText: 'Remarks / Receipt #'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount != null && amount > 0) {
                await Provider.of<OrderProvider>(context, listen: false)
                    .recordPayment(
                  merchant.uid,
                  amount,
                  notes: notesCtrl.text.trim(),
                );
                _loadMerchants();
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700),
            child: const Text('Confirm Cash Receipt',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
