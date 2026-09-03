import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/cash_settlement_model.dart';
import '../../../models/order_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/currency_formatter.dart';

class CashSettlementTab extends StatefulWidget {
  const CashSettlementTab({super.key});

  @override
  State<CashSettlementTab> createState() => _CashSettlementTabState();
}

class _CashSettlementTabState extends State<CashSettlementTab> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final currentAdmin = auth.currentUserModel;

    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.streamUsersByRole(UserRole.deliveryBoy),
      builder: (context, deliverySnap) {
        if (deliverySnap.connectionState == ConnectionState.waiting &&
            !deliverySnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final deliveryPartners = deliverySnap.data ?? [];

        return StreamBuilder<List<CashSettlementModel>>(
          stream: _firestoreService.streamCashSettlements(),
          builder: (context, settlementSnap) {
            if (settlementSnap.connectionState == ConnectionState.waiting &&
                !settlementSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final settlements = settlementSnap.data ?? [];
            final allOrders = orderProvider.orders;
            final now = DateTime.now();

            if (deliveryPartners.isEmpty && settlements.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payments_outlined,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No cash settlements or delivery partners found.',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            final totalPendingCash = deliveryPartners.fold(0.0, (acc, d) {
              final double cash = d.pendingCashInHand > 0
                  ? d.pendingCashInHand
                  : allOrders
                      .where((o) =>
                          o.deliveryBoyId == d.uid &&
                          o.status == OrderStatus.delivered &&
                          o.paymentType == PaymentType.cod &&
                          o.isPaid)
                      .fold(0.0, (s, o) => s + o.grandTotal);
              return acc + cash;
            });

            final totalSettled = settlements.isNotEmpty
                ? settlements.fold(0.0, (acc, s) => acc + s.amountSettled)
                : deliveryPartners.fold(
                    0.0, (acc, d) => acc + d.totalCashSettled);

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                // 1. Top Header Banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withAlpha(40),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payments_rounded,
                                    color: Colors.white, size: 26),
                                SizedBox(width: 10),
                                Text(
                                  'COD Cash Settlements & Fleet Handover',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Reconcile, accept, and record daily cash collections deposited by delivery partners.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_shipping_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Active Fleet: ${deliveryPartners.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Top 3 Metric Cards (Aligned)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth > 800
                        ? (constraints.maxWidth - 32) / 3
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _buildMetricCard(
                            title: 'Total Pending Cash in Hand',
                            value: CurrencyFormatter.format(totalPendingCash),
                            subtitle: 'Unsettled COD collections held by fleet',
                            color: const Color(0xFFE65100),
                            bg: const Color(0xFFFFF3E0),
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _buildMetricCard(
                            title: 'Total Cash Settled Till Date',
                            value: CurrencyFormatter.format(totalSettled),
                            subtitle: 'Deposited & verified at Godown/HQ',
                            color: const Color(0xFF1B5E20),
                            bg: const Color(0xFFE8F5E9),
                            icon: Icons.check_circle_rounded,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _buildMetricCard(
                            title: 'Settlement Receipts Issued',
                            value: '${settlements.length} Receipts',
                            subtitle: 'Official signed cash deposit records',
                            color: const Color(0xFF4A148C),
                            bg: const Color(0xFFF3E5F5),
                            icon: Icons.receipt_long_rounded,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 3. SECTION 1: Delivery Partner Live Cash Overview Table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.local_shipping_rounded,
                                    color: AppColors.primary, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Delivery Partner Live Cash Status',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${deliveryPartners.length} Active Partners',
                                style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                          height: 1, thickness: 1, color: AppColors.border),
                      if (deliveryPartners.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                              child: Text('No delivery partners active.',
                                  style: TextStyle(color: Colors.grey))),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const minTableWidth = 1160.0;
                            final tableWidth =
                                constraints.maxWidth < minTableWidth
                                    ? minTableWidth
                                    : constraints.maxWidth;
                            const headerStyle = TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF475569),
                            );

                            Widget cell(Widget child, int flex) {
                              return Expanded(
                                flex: flex,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: child,
                                ),
                              );
                            }

                            final header = Container(
                              color: const Color(0xFFF8FAFC),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 14),
                              child: Row(
                                children: [
                                  cell(
                                      const Text('DELIVERY PARTNER',
                                          style: headerStyle),
                                      20),
                                  cell(
                                      const Text('CONTACT & VEHICLE',
                                          style: headerStyle),
                                      16),
                                  cell(
                                      const Text('TODAY DELIVERIES',
                                          style: headerStyle),
                                      12),
                                  cell(
                                      const Text('PENDING CASH IN HAND (₹)',
                                          style: headerStyle),
                                      16),
                                  cell(
                                      const Text('TOTAL SETTLED (₹)',
                                          style: headerStyle),
                                      14),
                                  cell(const Text('ACTION', style: headerStyle),
                                      22),
                                ],
                              ),
                            );

                            final rows = deliveryPartners.map((partner) {
                              final todayDeliveries = allOrders
                                  .where((o) =>
                                      o.deliveryBoyId == partner.uid &&
                                      o.status == OrderStatus.delivered &&
                                      o.createdAt.day == now.day &&
                                      o.createdAt.month == now.month &&
                                      o.createdAt.year == now.year)
                                  .length;

                              final double partnerCash = partner
                                          .pendingCashInHand >
                                      0
                                  ? partner.pendingCashInHand
                                  : allOrders
                                      .where((o) =>
                                          o.deliveryBoyId == partner.uid &&
                                          o.status == OrderStatus.delivered &&
                                          o.paymentType == PaymentType.cod &&
                                          o.isPaid)
                                      .fold(0.0, (s, o) => s + o.grandTotal);

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                decoration: const BoxDecoration(
                                  border: Border(
                                      top: BorderSide(color: AppColors.border)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    cell(
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 17,
                                            backgroundColor:
                                                const Color(0xFF1B5E20)
                                                    .withAlpha(25),
                                            child: Text(
                                              partner.name.isNotEmpty
                                                  ? partner.name[0]
                                                      .toUpperCase()
                                                  : 'D',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1B5E20),
                                                  fontSize: 13),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                partner.name,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color:
                                                        AppColors.textPrimary),
                                              ),
                                              Text(
                                                partner.email,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      20,
                                    ),
                                    cell(
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(partner.phone,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12)),
                                          Text(
                                            partner.vehicleNumber ??
                                                'RJ-14-Tempo',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                      16,
                                    ),
                                    cell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$todayDeliveries Trips',
                                          style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade900),
                                        ),
                                      ),
                                      12,
                                    ),
                                    cell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: partnerCash > 0
                                              ? const Color(0xFFFFF3E0)
                                              : Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: partnerCash > 0
                                                ? const Color(0xFFFFB74D)
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          CurrencyFormatter.format(partnerCash),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13.5,
                                            color: partnerCash > 0
                                                ? const Color(0xFFE65100)
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                      16,
                                    ),
                                    cell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xFFA5D6A7)),
                                        ),
                                        child: Text(
                                          CurrencyFormatter.format(
                                              partner.totalCashSettled),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF1B5E20),
                                              fontSize: 13),
                                        ),
                                      ),
                                      14,
                                    ),
                                    cell(
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _showAcceptCashDepositDialog(
                                                partner,
                                                partnerCash,
                                                currentAdmin),
                                        icon: const Icon(
                                            Icons.price_check_rounded,
                                            size: 16),
                                        label:
                                            const Text('Accept Cash Deposit'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: partnerCash > 0
                                              ? const Color(0xFF1B5E20)
                                              : AppColors.primary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          textStyle: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      22,
                                    ),
                                  ],
                                ),
                              );
                            }).toList();

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: Column(
                                  children: [header, ...rows],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. SECTION 2: Past Settlements Audit Ledger (Aligned)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.history_edu_rounded,
                                    color: Color(0xFF1B5E20), size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Cash Settlement Audit Ledger',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${settlements.length} Recorded Handovers',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1B5E20),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                          height: 1, thickness: 1, color: AppColors.border),
                      if (settlements.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(36),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 10),
                                Text(
                                  'No Cash Settlement Receipts Recorded Yet',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            horizontalMargin: 20,
                            columnSpacing: 28,
                            headingRowHeight: 46,
                            dataRowMinHeight: 56,
                            dataRowMaxHeight: 56,
                            headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFF8FAFC)),
                            columns: const [
                              DataColumn(
                                  label: Text('RECEIPT ID',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF475569)))),
                              DataColumn(
                                  label: Text('DATE & TIME',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF475569)))),
                              DataColumn(
                                  label: Text('DELIVERY PARTNER',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF475569)))),
                              DataColumn(
                                  label: Text('AMOUNT DEPOSITED',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF475569)))),
                              DataColumn(
                                  label: Text('PAYMENT MODE',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF475569)))),
                              DataColumn(
                                  label: Text('VERIFIED BY ADMIN',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF475569)))),
                              DataColumn(
                                  label: Text('NOTES / REMARKS',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF475569)))),
                            ],
                            rows: settlements.map((s) {
                              final receiptDisplay = s.id.startsWith('BB-CS')
                                  ? s.id
                                  : (s.id.length > 8
                                      ? '#${s.id.substring(0, 8).toUpperCase()}'
                                      : '#${s.id}');

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: const Color(0xFFA5D6A7)),
                                      ),
                                      child: Text(
                                        receiptDisplay,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                            color: Color(0xFF1B5E20)),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.schedule,
                                            size: 14,
                                            color: AppColors.textMuted),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${s.createdAt.day.toString().padLeft(2, '0')}/${s.createdAt.month.toString().padLeft(2, '0')}/${s.createdAt.year} ${s.createdAt.hour.toString().padLeft(2, '0')}:${s.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      s.deliveryBoyName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textPrimary),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        CurrencyFormatter.format(
                                            s.amountSettled),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF1B5E20),
                                            fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: s.paymentMode
                                                .toLowerCase()
                                                .contains('upi')
                                            ? Colors.purple.shade50
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: s.paymentMode
                                                  .toLowerCase()
                                                  .contains('upi')
                                              ? Colors.purple.shade200
                                              : Colors.green.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        s.paymentMode,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: s.paymentMode
                                                  .toLowerCase()
                                                  .contains('upi')
                                              ? Colors.purple.shade800
                                              : Colors.green.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.verified_user,
                                            size: 14, color: AppColors.primary),
                                        const SizedBox(width: 5),
                                        Text(
                                          s.settledByAdminName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      s.notes != null && s.notes!.isNotEmpty
                                          ? s.notes!
                                          : '—',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAcceptCashDepositDialog(
      UserModel partner, double pendingCash, UserModel? admin) {
    final amountCtrl = TextEditingController(
      text: pendingCash > 0 ? pendingCash.toStringAsFixed(0) : '',
    );
    final notesCtrl = TextEditingController();
    String selectedMode = 'Cash';
    bool isSaving = false;
    String? amountError;

    // Initial limit check
    final initialVal = double.tryParse(amountCtrl.text.trim());
    if (initialVal != null && pendingCash > 0 && initialVal > pendingCash) {
      amountError =
          'Amount cannot exceed pending cash in hand (${CurrencyFormatter.format(pendingCash)})';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final double? currentEntered =
              double.tryParse(amountCtrl.text.trim());
          final bool isOverLimit = currentEntered != null &&
              pendingCash > 0 &&
              currentEntered > pendingCash;
          final bool isNegativeOrZero =
              currentEntered == null || currentEntered <= 0;
          final bool canSubmit = !isSaving && !isOverLimit && !isNegativeOrZero;

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B5E20).withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.price_check_rounded,
                                  color: Color(0xFF1B5E20), size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Accept COD Cash Deposit',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary),
                                ),
                                Text(
                                  'Issue verified signed deposit receipt',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Partner Info Box (Aligned)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(partner.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('Ph: ${partner.phone}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Pending In Hand',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted)),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.format(pendingCash),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: Color(0xFFE65100)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deposit Amount Input
                    const Text('Deposit Amount (₹)*',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        final v = double.tryParse(val.trim());
                        setModalState(() {
                          if (v == null || v <= 0) {
                            amountError =
                                'Please enter a valid deposit amount > ₹0';
                          } else if (pendingCash > 0 && v > pendingCash) {
                            amountError =
                                'Amount cannot exceed pending cash in hand (${CurrencyFormatter.format(pendingCash)})';
                          } else {
                            amountError = null;
                          }
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter amount handed over',
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        errorText: amountError,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Mode Dropdown
                    const Text('Payment Mode Handed Over',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMode,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Cash',
                            child: Text('💵 Physical Cash Handover')),
                        DropdownMenuItem(
                            value: 'UPI Transfer / QR Code',
                            child: Text('📱 UPI Transfer / QR Code')),
                        DropdownMenuItem(
                            value: 'Bank Deposit / NEFT',
                            child: Text('🏦 Direct Bank Deposit / NEFT')),
                      ],
                      onChanged: (val) =>
                          setModalState(() => selectedMode = val ?? 'Cash'),
                    ),
                    const SizedBox(height: 14),

                    // Remarks / Notes
                    const Text('Admin Remarks / Godown Notes',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Verified by godown manager',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit & Cancel Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: !canSubmit
                              ? null
                              : () async {
                                  final enteredAmount =
                                      double.tryParse(amountCtrl.text.trim());
                                  if (enteredAmount == null ||
                                      enteredAmount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please enter a valid deposit amount > ₹0'),
                                          backgroundColor: Colors.red),
                                    );
                                    return;
                                  }

                                  if (pendingCash > 0 &&
                                      enteredAmount > pendingCash) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Amount cannot exceed pending cash in hand (${CurrencyFormatter.format(pendingCash)})'),
                                          backgroundColor: Colors.red),
                                    );
                                    return;
                                  }

                                  setModalState(() => isSaving = true);
                                  try {
                                    await _firestoreService
                                        .recordCashSettlement(
                                      deliveryBoyId: partner.uid,
                                      deliveryBoyName: partner.name,
                                      amountSettled: enteredAmount,
                                      paymentMode: selectedMode,
                                      notes: notesCtrl.text.trim().isNotEmpty
                                          ? notesCtrl.text.trim()
                                          : null,
                                      settledByAdminId: admin?.uid ?? 'admin',
                                      settledByAdminName:
                                          admin?.name ?? 'Master Admin',
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Cash deposit of ${CurrencyFormatter.format(enteredAmount)} accepted and receipt issued!'),
                                          backgroundColor:
                                              const Color(0xFF1B5E20),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setModalState(() => isSaving = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Error recording settlement: $e'),
                                            backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_outline),
                          label: const Text('Confirm & Accept Deposit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color bg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
