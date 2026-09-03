import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/payment_transaction_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class OrderProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  StreamSubscription<List<PaymentTransactionModel>>? _paymentsSubscription;

  List<OrderModel> _orders = [];
  List<PaymentTransactionModel> _payments = [];
  OrderStatus? _filterStatus;
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  List<PaymentTransactionModel> get payments => _payments;
  OrderStatus? get filterStatus => _filterStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<PaymentTransactionModel> getPaymentsForMerchant(String merchantId) {
    return _payments.where((p) => p.merchantId == merchantId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<OrderModel> get filteredOrders {
    if (_filterStatus == null) return _orders;
    return _orders.where((o) => o.status == _filterStatus).toList();
  }

  // Segmented orders for strict lifecycle: pending, approved, outForDelivery, delivered, cancelled
  List<OrderModel> get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).toList();

  List<OrderModel> get approvedOrders =>
      _orders.where((o) => o.status == OrderStatus.approved).toList();

  List<OrderModel> get outForDeliveryOrders =>
      _orders.where((o) => o.status == OrderStatus.outForDelivery).toList();

  List<OrderModel> get dispatchedOrders => outForDeliveryOrders; // Backward compatibility alias

  List<OrderModel> get deliveredOrders =>
      _orders.where((o) => o.status == OrderStatus.delivered).toList();

  List<OrderModel> get cancelledOrders =>
      _orders.where((o) => o.status == OrderStatus.cancelled).toList();

  // Metrics for Admin Dashboard
  double get totalRevenue => _orders
      .where((o) => o.status == OrderStatus.delivered || o.isPaid)
      .fold(0.0, (sum, o) => sum + o.grandTotal);

  double get todayRevenue {
    final now = DateTime.now();
    return _orders
        .where((o) =>
            o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day &&
            o.status != OrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + o.grandTotal);
  }

  int get todayOrdersCount {
    final now = DateTime.now();
    return _orders.where((o) =>
        o.createdAt.year == now.year &&
        o.createdAt.month == now.month &&
        o.createdAt.day == now.day).length;
  }

  int get pendingApprovalsCount => pendingOrders.length;

  int get activeDeliveriesCount =>
      (approvedOrders.length + outForDeliveryOrders.length);

  // Listen to orders according to active user role
  void listenToOrders({
    required UserRole role,
    required String uid,
  }) {
    _ordersSubscription?.cancel();
    _paymentsSubscription?.cancel();

    String? merchantId;
    String? salesmanId;
    String? deliveryBoyId;

    if (role == UserRole.merchant) {
      merchantId = uid;
    } else if (role == UserRole.salesman) {
      salesmanId = uid;
    } else if (role == UserRole.deliveryBoy) {
      deliveryBoyId = uid;
    }

    _ordersSubscription = _firestoreService
        .streamOrders(
          merchantId: merchantId,
          salesmanId: salesmanId,
          deliveryBoyId: deliveryBoyId,
        )
        .listen(
          (ordersList) {
            _orders = ordersList;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );

    // Stream payments
    if (merchantId != null) {
      _paymentsSubscription = _firestoreService
          .streamPaymentsByMerchant(merchantId)
          .listen((paymentList) {
        _payments = paymentList;
        notifyListeners();
      });
    } else {
      _paymentsSubscription = _firestoreService
          .streamAllPayments()
          .listen((paymentList) {
        _payments = paymentList;
        notifyListeners();
      });
    }
  }

  void setFilterStatus(OrderStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  // STEP 1: Place Order (Status = pending)
  Future<String?> placeOrder({
    required UserModel merchant,
    UserModel? salesman,
    required List<CartItem> items,
    required double taxableAmount,
    required double cgst,
    required double sgst,
    double igst = 0.0,
    required double totalGst,
    required double grandTotal,
    required PaymentType paymentType,
    String? notes,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? liveLocationAddress,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final double? finalLat = deliveryLatitude ?? merchant.latitude;
      final double? finalLng = deliveryLongitude ?? merchant.longitude;
      final String? finalLocationAddr =
          liveLocationAddress ?? merchant.locationAddress;

      final newOrder = OrderModel(
        id: '',
        invoiceNumber: '',
        merchantId: merchant.uid,
        merchantName: merchant.shopName != null && merchant.shopName!.isNotEmpty
            ? '${merchant.shopName} (${merchant.name})'
            : merchant.name,
        merchantPhone: merchant.phone,
        merchantGstin: merchant.gstin,
        merchantAddress: merchant.address ?? '${merchant.city}, Rajasthan',
        salesmanId: salesman?.uid ?? merchant.addedBySalesmanId,
        salesmanName: salesman?.name ?? merchant.addedBySalesmanName,
        items: items,
        taxableAmount: taxableAmount,
        cgst: cgst,
        sgst: sgst,
        igst: igst,
        totalGst: totalGst,
        grandTotal: grandTotal,
        status: OrderStatus.pending,
        paymentType: paymentType,
        isPaid: paymentType == PaymentType.online,
        notes: notes,
        deliveryLatitude: finalLat,
        deliveryLongitude: finalLng,
        liveLocationAddress: finalLocationAddr,
        liveLocationCapturedAt:
            (finalLat != null && finalLng != null) ? DateTime.now() : null,
        createdAt: DateTime.now(),
      );

      final orderId = await _firestoreService.createOrder(newOrder);
      _isLoading = false;
      notifyListeners();
      return orderId;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // STEP 2: Admin assigns delivery partner -> Status = approved
  Future<bool> assignDeliveryPartner(String orderId, String deliveryBoyId, String deliveryBoyName) async {
    try {
      await _firestoreService.assignDeliveryBoy(orderId, deliveryBoyId, deliveryBoyName);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Backward compatibility alias
  Future<bool> dispatchOrder(String orderId, String deliveryBoyId, String deliveryBoyName) =>
      assignDeliveryPartner(orderId, deliveryBoyId, deliveryBoyName);

  // STEP 3: Delivery Boy starts delivery -> Status = outForDelivery
  Future<bool> startDelivery(String orderId) async {
    try {
      await _firestoreService.updateOrderStatus(orderId, OrderStatus.outForDelivery);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // STEP 4: Final Outcome (delivered / cancelled with reason)
  Future<bool> markDelivered(String orderId, {required bool isPaid}) async {
    try {
      await _firestoreService.markOrderDelivered(orderId, isPaid: isPaid);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId, {List<CartItem>? itemsToRestock, String? reason}) async {
    try {
      await _firestoreService.cancelOrder(orderId, itemsToRestock: itemsToRestock, cancelReason: reason);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordPayment(
    String merchantId,
    double amount, {
    String? notes,
    String paymentMode = 'Cash',
  }) async {
    try {
      await _firestoreService.recordMerchantPayment(
        merchantId,
        amount,
        notes: notes,
        paymentMode: paymentMode,
      );
      // Optimistic local add
      _payments.insert(
        0,
        PaymentTransactionModel(
          id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
          merchantId: merchantId,
          amount: amount,
          paymentMode: paymentMode,
          note: notes,
          createdAt: DateTime.now(),
          isEdited: false,
        ),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // STRICT 1-TIME PAYMENT EDIT
  Future<bool> editPayment({
    required PaymentTransactionModel oldPayment,
    required double newAmount,
    required String newPaymentMode,
    String? newNote,
  }) async {
    if (oldPayment.isEdited) {
      _errorMessage = 'This payment entry has already been edited and is permanently locked.';
      notifyListeners();
      return false;
    }

    try {
      await _firestoreService.editMerchantPayment(
        oldPayment: oldPayment,
        newAmount: newAmount,
        newPaymentMode: newPaymentMode,
        newNote: newNote,
      );

      // Optimistic update in local list
      final index = _payments.indexWhere((p) => p.id == oldPayment.id);
      if (index != -1) {
        _payments[index] = oldPayment.copyWith(
          amount: newAmount,
          paymentMode: newPaymentMode,
          note: newNote,
          isEdited: true,
          editedAt: DateTime.now(),
          originalAmount: oldPayment.amount,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _ordersSubscription?.cancel();
    _paymentsSubscription?.cancel();
    _orders = [];
    _payments = [];
    _filterStatus = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
