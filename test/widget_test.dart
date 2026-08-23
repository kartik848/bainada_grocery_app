import 'package:flutter_test/flutter_test.dart';
import 'package:bainada_grocery_app/models/cash_settlement_model.dart';
import 'package:bainada_grocery_app/models/order_model.dart';
import 'package:bainada_grocery_app/models/payment_transaction_model.dart';
import 'package:bainada_grocery_app/models/product_model.dart';
import 'package:bainada_grocery_app/models/user_model.dart';
import 'package:bainada_grocery_app/providers/cart_provider.dart';
import 'package:bainada_grocery_app/services/invoice_service.dart';

void main() {
  group('Bainada Grocery B2B Full Architecture Tests', () {
    test('ProductModel unitMultiplier and profit margin calculations', () {
      const product = ProductModel(
        id: 'prod_carton_1',
        name: 'Detergent Powder Carton',
        category: 'Soaps & Detergents',
        wholesalePrice: 1800.0,
        mrp: 2200.0,
        gstRate: 18.0,
        moq: 2,
        unit: 'cartoon (24 pcs)',
        unitMultiplier: 24,
        stockQuantity: 50,
      );

      expect(product.unitMultiplier, 24);
      expect(product.calculateTotalPieces(3), 72); // 3 cartons * 24 pcs = 72 pcs
      expect(product.unitGstAmount, 324.0); // 18% of 1800
      expect(product.unitPriceWithGst, 2124.0);
      expect(product.profitMargin, 400.0);
    });

    test('CartProvider MOQ enforcement and live GST calculation', () {
      final cart = CartProvider();

      const product = ProductModel(
        id: 'prod_atta',
        name: 'MP Sharbati Atta',
        category: 'Flours & Atta',
        wholesalePrice: 1500.0,
        mrp: 1800.0,
        gstRate: 5.0,
        moq: 5,
        unit: 'bag (50kg)',
        unitMultiplier: 50,
        stockQuantity: 100,
      );

      // Adding product enforces MOQ of 5
      cart.addItem(product);
      expect(cart.getProductQuantity(product.id), 5);
      expect(cart.taxableAmount, 7500.0); // 1500 * 5
      expect(cart.totalGst, 375.0); // 5% of 7500
      expect(cart.cgst, 187.5); // 50% of total GST
      expect(cart.sgst, 187.5); // 50% of total GST
      expect(cart.grandTotal, 7875.0); // 7500 + 375
    });

    test('UserModel approval, credit limit, and minOrderLimit verification', () {
      final merchant = UserModel(
        uid: 'm_1',
        name: 'Demo Merchant',
        phone: '9829012345',
        email: 'merchant@bainada.com',
        role: UserRole.merchant,
        shopName: 'Demo Kirana Store',
        gstin: '08AAAAA0000A1Z5',
        creditLimit: 50000.0,
        outstandingDue: 15000.0,
        minOrderLimit: 10000.0,
        isApproved: true,
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(merchant.isApproved, true);
      expect(merchant.availableCredit, 35000.0);
      expect(merchant.hasExceededCreditLimit, false);
      expect(merchant.minOrderLimit, 10000.0);
      expect(merchant.commissionRate, 0.0);

      final salesman = merchant.copyWith(
        role: UserRole.salesman,
        commissionRate: 2.5,
      );
      expect(salesman.commissionRate, 2.5);
    });

    test('InvoiceService numberToWords conversion for Indian Rupees', () {
      expect(InvoiceService.numberToWords(0), 'Zero Rupees Only');
      expect(InvoiceService.numberToWords(7875), 'Rupees Seven Thousand Eight Hundred Seventy Five Only');
      expect(InvoiceService.numberToWords(125000), 'Rupees One Lakh Twenty Five Thousand Only');
    });

    test('OrderModel serialization with outForDelivery status and unitMultiplier', () {
      final order = OrderModel(
        id: 'ord_123',
        invoiceNumber: 'BB-001',
        merchantId: 'm_1',
        merchantName: 'Demo Kirana Store',
        merchantPhone: '9829012345',
        merchantAddress: 'Shop 14, Mandi Yard, Jaipur',
        merchantGstin: '08AAAAA0000A1Z5',
        items: [
          const CartItem(
            productId: 'prod_1',
            productName: 'Royal Basmati Rice',
            hsnCode: '1006',
            unit: 'bag (50kg)',
            quantity: 2,
            unitMultiplier: 50,
            unitPrice: 4000.0,
            gstRate: 5.0,
            gstAmount: 400.0,
            totalItemPrice: 8400.0,
          )
        ],
        taxableAmount: 8000.0,
        cgst: 200.0,
        sgst: 200.0,
        totalGst: 400.0,
        grandTotal: 8400.0,
        status: OrderStatus.outForDelivery,
        paymentType: PaymentType.cod,
        createdAt: DateTime(2026, 8, 19),
      );

      final map = order.toMap();
      final reconstructed = OrderModel.fromMap(map, order.id);

      expect(reconstructed.status, OrderStatus.outForDelivery);
      expect(reconstructed.invoiceNumber, 'BB-001');
      expect(reconstructed.taxableAmount, 8000.0);
      expect(reconstructed.totalGst, 400.0);
      expect(reconstructed.grandTotal, 8400.0);
      expect(reconstructed.items.first.unitMultiplier, 50);
      expect(reconstructed.items.first.totalPieces, 100);
    });

    test('PaymentTransactionModel 1-time edit flag and serialization', () {
      final payment = PaymentTransactionModel(
        id: 'pay_001',
        merchantId: 'm_1',
        amount: 15000.0,
        paymentMode: 'Bank Transfer',
        note: 'RTGS Mandi Advance',
        createdAt: DateTime(2026, 8, 19),
        isEdited: false,
      );

      expect(payment.isEdited, false);
      expect(payment.originalAmount, null);

      final edited = payment.copyWith(
        amount: 18000.0,
        isEdited: true,
        editedAt: DateTime(2026, 8, 19, 12),
        originalAmount: 15000.0,
        note: 'Adjusted after bank statement reconciliation',
      );

      expect(edited.isEdited, true);
      expect(edited.amount, 18000.0);
      expect(edited.originalAmount, 15000.0);

      final map = edited.toMap();
      final fromMap = PaymentTransactionModel.fromMap(map, edited.id);

      expect(fromMap.id, 'pay_001');
      expect(fromMap.amount, 18000.0);
      expect(fromMap.originalAmount, 15000.0);
      expect(fromMap.isEdited, true);
      expect(fromMap.paymentMode, 'Bank Transfer');
    });

    test('Salesman commission payout and minOrderLimit calculation logic', () {
      const double turnover = 150000.0;
      const double commissionRate = 2.5;
      const double payout = (turnover * commissionRate) / 100.0;
      expect(payout, 3750.0);

      const double minOrderLimit = 20000.0;
      const double cartTotal1 = 15000.0;
      const double cartTotal2 = 25000.0;

      expect(cartTotal1 < minOrderLimit, true); // Should block checkout
      expect(minOrderLimit - cartTotal1, 5000.0); // Remaining amount to add
      expect(cartTotal2 >= minOrderLimit, true); // Allowed to checkout
    });

    test('Delivery status transitions and outcome types', () {
      expect(OrderStatus.values.contains(OrderStatus.approved), true);
      expect(OrderStatus.values.contains(OrderStatus.outForDelivery), true);
      expect(OrderStatus.values.contains(OrderStatus.delivered), true);
      expect(OrderStatus.values.contains(OrderStatus.cancelled), true);
    });

    test('CashSettlementModel serialization and delivery partner ledger logic', () {
      final settlement = CashSettlementModel(
        id: 'settle_101',
        deliveryBoyId: 'del_001',
        deliveryBoyName: 'Mukesh Kumar',
        amountSettled: 12500.0,
        paymentMode: 'Cash',
        notes: 'Shift closing cash deposit',
        settledByAdminId: 'admin_1',
        settledByAdminName: 'Ajay Meena',
        createdAt: DateTime(2026, 8, 19, 18, 30),
      );

      expect(settlement.id, 'settle_101');
      expect(settlement.amountSettled, 12500.0);
      expect(settlement.paymentMode, 'Cash');
      expect(settlement.settledByAdminName, 'Ajay Meena');

      final map = settlement.toMap();
      final fromMap = CashSettlementModel.fromMap(map, settlement.id);

      expect(fromMap.id, 'settle_101');
      expect(fromMap.deliveryBoyId, 'del_001');
      expect(fromMap.amountSettled, 12500.0);
      expect(fromMap.paymentMode, 'Cash');

      // Ledger logic: Pending Cash - Settled Amount
      double pendingCash = 15000.0;
      double settledCash = 0.0;

      pendingCash -= settlement.amountSettled;
      settledCash += settlement.amountSettled;

      expect(pendingCash, 2500.0);
      expect(settledCash, 12500.0);
    });

    test('ProductModel PriceTier volume slab discount and CartProvider dynamic calculation', () {
      const productWithTiers = ProductModel(
        id: 'prod_oil_tin',
        name: 'Fortune Sunflower Oil 15L Tin',
        category: 'Edible Oils & Ghee',
        wholesalePrice: 1950.0,
        mrp: 2250.0,
        gstRate: 5.0,
        moq: 1,
        unit: 'tin',
        stockQuantity: 100,
        tierPricing: [
          PriceTier(minQty: 1, maxQty: 4, rate: 1950.0),
          PriceTier(minQty: 5, maxQty: 9, rate: 1910.0),
          PriceTier(minQty: 10, rate: 1870.0),
        ],
      );

      // Verify ProductModel getPriceForQuantity
      expect(productWithTiers.getPriceForQuantity(1), 1950.0);
      expect(productWithTiers.getPriceForQuantity(4), 1950.0);
      expect(productWithTiers.getPriceForQuantity(5), 1910.0); // Tier 2
      expect(productWithTiers.getPriceForQuantity(9), 1910.0); // Tier 2
      expect(productWithTiers.getPriceForQuantity(10), 1870.0); // Tier 3
      expect(productWithTiers.getPriceForQuantity(25), 1870.0); // Tier 3 (open-ended)

      // Test CartProvider dynamic recalculation on quantity changes
      final cart = CartProvider();
      cart.addItem(productWithTiers, quantity: 2);
      expect(cart.taxableAmount, 3900.0); // 2 * 1950
      expect(cart.totalVolumeSavings, 0.0);

      // Increase quantity to 5 (activates Tier 2: ₹1910 instead of ₹1950)
      cart.updateQuantity(productWithTiers.id, 5, product: productWithTiers);
      expect(cart.items[productWithTiers.id]!.unitPrice, 1910.0);
      expect(cart.items[productWithTiers.id]!.originalUnitPrice, 1950.0);
      expect(cart.taxableAmount, 9550.0); // 5 * 1910
      expect(cart.totalVolumeSavings, 200.0); // (1950 - 1910) * 5 = 200
      expect(cart.totalGst, 477.5); // 5% of 9550
      expect(cart.grandTotal, 10027.5); // 9550 + 477.5

      // Increase quantity to 10 (activates Tier 3: ₹1870 instead of ₹1950)
      cart.updateQuantity(productWithTiers.id, 10, product: productWithTiers);
      expect(cart.items[productWithTiers.id]!.unitPrice, 1870.0);
      expect(cart.taxableAmount, 18700.0); // 10 * 1870
      expect(cart.totalVolumeSavings, 800.0); // (1950 - 1870) * 10 = 800
      expect(cart.totalGst, 935.0); // 5% of 18700
      expect(cart.grandTotal, 19635.0); // 18700 + 935
    });
  });
}
