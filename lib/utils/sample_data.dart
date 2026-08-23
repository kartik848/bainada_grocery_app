import '../models/cash_settlement_model.dart';
import '../models/order_model.dart';
import '../models/payment_transaction_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

/// Pure empty data structure. All application screens stream 100% live data exclusively from Cloud Firestore.
class SampleData {
  static List<ProductModel> getInitialProducts() => const [];
  static List<UserModel> getDemoMerchants() => const [];
  static List<UserModel> getDemoSalesmen() => const [];
  static List<UserModel> getDemoDeliveryPartners() => const [];
  static List<OrderModel> getDemoOrders() => const [];
  static List<CashSettlementModel> getDemoCashSettlements() => const [];
  static List<PaymentTransactionModel> getDemoTransactions() => const [];
}
