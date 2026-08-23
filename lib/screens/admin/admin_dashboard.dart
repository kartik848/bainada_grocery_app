import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/bainada_logo.dart';
import '../../widgets/ignito_branding.dart';
import '../../widgets/order_card.dart';
import '../../widgets/product_card.dart';
import '../auth/auth_wrapper.dart';
import 'admin_web_dashboard.dart';
import 'dialogs/add_product_modal.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final bool _showRecentOrders = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUserModel != null) {
        Provider.of<OrderProvider>(context, listen: false).listenToOrders(
          role: UserRole.admin,
          uid: auth.currentUserModel!.uid,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If running on Web or Screen width is greater than 850px, render the dedicated Web Admin Panel
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb || constraints.maxWidth > 850) {
          return const AdminWebDashboard();
        }
        return _buildMobileAdminScaffold(context);
      },
    );
  }

  Widget _buildMobileAdminScaffold(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUserModel;

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
              color: AppColors.primarySurface,
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Text('A',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Admin',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.role.displayName ?? 'Super Admin',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
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
                    leading: const Icon(Icons.dashboard_rounded,
                        color: AppColors.primary),
                    title: const Text('Dashboard Overview',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: _currentIndex == 0,
                    onTap: () {
                      setState(() => _currentIndex = 0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_rounded,
                        color: AppColors.primary),
                    title: const Text('Catalog & Stock',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: _currentIndex == 1,
                    onTap: () {
                      setState(() => _currentIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.primary),
                    title: const Text('Orders Dispatch',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: _currentIndex == 2,
                    onTap: () {
                      setState(() => _currentIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_rounded,
                        color: AppColors.primary),
                    title: const Text('User Directory',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: _currentIndex == 3,
                    onTap: () {
                      setState(() => _currentIndex = 3);
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
                          content: const Text('Are you sure you want to sign out from your Admin account?'),
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
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bainada Brothers Admin',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
            Text(
              user?.name ?? 'Admin Portal',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out from your Admin account?'),
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildOverviewTab(),
          _buildCatalogTab(),
          _buildOrdersTab(),
          _buildDirectoryTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2_rounded),
            label: 'Catalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_rounded),
            label: 'Directory',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW TAB (STATS & METRICS)
  // ==========================================
  Widget _buildOverviewTab() {
    final orderProvider = Provider.of<OrderProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wholesale Business Hub',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Lifetime Revenue: ${CurrencyFormatter.format(orderProvider.totalRevenue)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.trending_up,
                      color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4 Metric Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _buildStatCard(
                title: "Today's Sales",
                value: '${orderProvider.todayOrdersCount}',
                subtitle:
                    'Revenue: ${CurrencyFormatter.format(orderProvider.todayRevenue)}',
                icon: Icons.shopping_bag_outlined,
                color: const Color(0xFF1565C0),
              ),
              _buildStatCard(
                title: 'Pending Approvals',
                value: '${orderProvider.pendingApprovalsCount}',
                subtitle: 'Requires action',
                icon: Icons.pending_actions_outlined,
                color: AppColors.statusPending,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _buildStatCard(
                title: 'Out for Delivery',
                value: '${orderProvider.activeDeliveriesCount}',
                subtitle: 'With delivery boys',
                icon: Icons.local_shipping_outlined,
                color: AppColors.statusDispatched,
              ),
              _buildStatCard(
                title: 'Low Stock Alerts',
                value: '${productProvider.lowStockCount}',
                subtitle: 'Restock needed',
                icon: Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                onTap: () => setState(() => _currentIndex = 1),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Low Stock Alert Banner if any
          if (productProvider.lowStockCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_rounded,
                      color: Colors.red.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${productProvider.lowStockCount} Products Running Low on Stock',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade900,
                          ),
                        ),
                        Text(
                          productProvider.lowStockProducts
                              .map((p) => '${p.name} (${p.stockQuantity})')
                              .take(2)
                              .join(', '),
                          style: TextStyle(
                              fontSize: 11, color: Colors.red.shade800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: const Text('Manage',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_showRecentOrders) ...[
            // Recent Orders Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent B2B Orders',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 2),
                  child: const Text('View All'),
                ),
              ],
            ),

            if (orderProvider.orders.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const Text(
                  'No orders placed yet.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ...orderProvider.orders.take(4).map(
                    (order) => OrderCard(
                      order: order,
                      trailingAction: order.status == OrderStatus.pending
                          ? ElevatedButton(
                              onPressed: () => _showApproveDialog(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                textStyle: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              child: const Text('Approve'),
                            )
                          : null,
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: CATALOG MANAGEMENT TAB
  // ==========================================
  Widget _buildCatalogTab() {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: productProvider.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search wholesale catalog (Hindi / English)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      final isSelected =
                          productProvider.selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label:
                              Text(cat, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          selectedColor: AppColors.primarySurface,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
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

          // Product List
          Expanded(
            child: productProvider.filteredProducts.isEmpty
                ? const Center(child: Text('No products found.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: productProvider.filteredProducts.length,
                    itemBuilder: (ctx, index) {
                      final prod = productProvider.filteredProducts[index];
                      return ProductCard(
                        product: prod,
                        showAdminControls: true,
                        onEdit: () => _showProductDialog(product: prod),
                        onDelete: () => _confirmDeleteProduct(prod),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: ORDERS HUB TAB
  // ==========================================
  Widget _buildOrdersTab() {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Column(
      children: [
        // Status filter chips
        Container(
          height: 48,
          color: Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            children: [
              _buildOrderStatusFilterChip(
                  'All Orders', null, orderProvider.filterStatus == null),
              ...OrderStatus.values.map(
                (status) => _buildOrderStatusFilterChip(
                  status.displayName,
                  status,
                  orderProvider.filterStatus == status,
                ),
              ),
            ],
          ),
        ),

        // Order list
        Expanded(
          child: orderProvider.filteredOrders.isEmpty
              ? const Center(child: Text('No orders in this status.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: orderProvider.filteredOrders.length,
                  itemBuilder: (ctx, i) {
                    final order = orderProvider.filteredOrders[i];
                    return OrderCard(
                      order: order,
                      trailingAction: _buildOrderAdminActions(order),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrderStatusFilterChip(
      String label, OrderStatus? status, bool isSelected) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: AppColors.primarySurface,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => orderProvider.setFilterStatus(status),
      ),
    );
  }

  Widget? _buildOrderAdminActions(OrderModel order) {
    if (order.status == OrderStatus.pending) {
      return ElevatedButton(
        onPressed: () => _showApproveDialog(order),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        child: const Text('Approve & Assign'),
      );
    } else if (order.status == OrderStatus.approved) {
      return ElevatedButton(
        onPressed: () => _showApproveDialog(order),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusDispatched,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        child: const Text('Dispatch'),
      );
    }
    return null;
  }

  // ==========================================
  // TAB 4: DIRECTORY TAB (MERCHANTS & SALESMEN)
  // ==========================================
  Widget _buildDirectoryTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Kirana Merchants'),
                Tab(text: 'Salesmen'),
                Tab(text: 'Delivery Staff'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsersList(UserRole.merchant),
                _buildUsersList(UserRole.salesman),
                _buildUsersList(UserRole.deliveryBoy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(UserRole role) {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.streamUsersByRole(role),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return Center(
            child: Text(
              'No ${role.displayName} records found.',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (ctx, i) {
            final u = users[i];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(
                    role == UserRole.merchant
                        ? Icons.storefront
                        : role == UserRole.salesman
                            ? Icons.badge
                            : Icons.delivery_dining,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  u.shopName != null && u.shopName!.isNotEmpty
                      ? u.shopName!
                      : u.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${u.name} • ${u.phone}',
                        style: const TextStyle(fontSize: 12)),
                    if (u.addedBySalesmanName != null)
                      Text('Onboarded By: ${u.addedBySalesmanName}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.accent)),
                    if (role == UserRole.merchant) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                              'Credit: ${CurrencyFormatter.format(u.creditLimit)}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text(
                              'Due: ${CurrencyFormatter.format(u.outstandingDue)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: u.outstandingDue > 0
                                      ? Colors.red
                                      : Colors.green)),
                        ],
                      ),
                    ],
                  ],
                ),
                trailing: role == UserRole.merchant
                    ? IconButton(
                        icon: const Icon(Icons.edit_note,
                            color: AppColors.primary),
                        tooltip: 'Edit Credit Limit',
                        onPressed: () => _showEditCreditDialog(u),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // DIALOGS & ACTION HELPERS
  // ==========================================
  void _showApproveDialog(OrderModel order) async {
    List<UserModel> deliveryBoys = [];
    try {
      deliveryBoys =
          await _firestoreService.getUsersByRole(UserRole.deliveryBoy);
    } catch (e) {
      debugPrint('Notice: Error fetching delivery boys: $e');
    }
    String? selectedBoyId =
        deliveryBoys.isNotEmpty ? deliveryBoys.first.uid : null;
    String? selectedBoyName = deliveryBoys.isNotEmpty
        ? deliveryBoys.first.name
        : 'Delivery Partner';

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Dispatch Order #${order.invoiceNumber}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Merchant: ${order.merchantName}'),
                Text('Amount: ${CurrencyFormatter.format(order.grandTotal)}'),
                const SizedBox(height: 14),
                const Text('Assign Delivery Partner:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedBoyId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: deliveryBoys
                      .map((db) =>
                          DropdownMenuItem(value: db.uid, child: Text(db.name)))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedBoyId = val;
                      final match = deliveryBoys.where((b) => b.uid == val);
                      if (match.isNotEmpty) {
                        selectedBoyName = match.first.name;
                      }
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (selectedBoyId == null || selectedBoyId!.isEmpty)
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await orderProv.dispatchOrder(
                          order.id,
                          selectedBoyId!,
                          selectedBoyName ?? 'Assigned Delivery Partner',
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text('Order dispatched successfully!')),
                        );
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('Confirm Dispatch',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCreditDialog(UserModel user) {
    final controller =
        TextEditingController(text: user.creditLimit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Credit Limit: ${user.shopName ?? user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Credit Limit (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newLimit =
                  double.tryParse(controller.text.trim()) ?? user.creditLimit;
              await _firestoreService.updateCreditLimit(user.uid, newLimit);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Limit'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
            'Are you sure you want to remove "${product.name}" from the wholesale catalog?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<ProductProvider>(context, listen: false)
                  .deleteProduct(product.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog({ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddProductModal(productToEdit: product),
    );
  }
}
