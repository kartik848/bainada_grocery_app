import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../models/cash_settlement_model.dart';
import '../models/order_model.dart';
import '../models/payment_transaction_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection References
  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _cashSettlementsRef =>
      _firestore.collection('cash_settlements');
  CollectionReference<Map<String, dynamic>> get _ledgersRef =>
      _firestore.collection('ledgers');
  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection('categories');

  // ==========================================
  // PRODUCTS CRUD & STREAMS
  // ==========================================

  Stream<List<ProductModel>> streamProducts({
    String? category,
    bool onlyAvailable = false,
  }) {
    Query<Map<String, dynamic>> query = _productsRef;

    if (category != null &&
        category.isNotEmpty &&
        category != 'All Categories') {
      query = query.where('category', isEqualTo: category);
    }

    if (onlyAvailable) {
      query = query.where('isAvailable', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<ProductModel>> getProducts({String? category}) async {
    Query<Map<String, dynamic>> query = _productsRef;
    if (category != null &&
        category.isNotEmpty &&
        category != 'All Categories') {
      query = query.where('category', isEqualTo: category);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    final doc = await _productsRef.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return ProductModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> addProduct(ProductModel product) async {
    await _productsRef.add(product.toMap());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _productsRef.doc(product.id).update(product.toMap());
  }

  Future<void> updateWholesalePrice(String productId, double newPrice) async {
    await _productsRef.doc(productId).update({
      'wholesalePrice': newPrice,
    });
  }

  Future<void> deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }

  Future<void> updateProductStock(String id, int quantityChange) async {
    await _productsRef.doc(id).update({
      'stockQuantity': FieldValue.increment(quantityChange),
    });
  }

  Stream<List<ProductModel>> streamLowStockProducts({int threshold = 15}) {
    return _productsRef
        .where('stockQuantity', isLessThanOrEqualTo: threshold)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ==========================================
  // CATEGORIES CRUD & STREAMS
  // ==========================================

  Stream<List<String>> streamCategories() {
    return _categoriesRef.snapshots().map((snapshot) {
      final List<String> list = [];
      for (final doc in snapshot.docs) {
        final name = (doc.data()['name'] ?? '').toString().trim();
        if (name.isNotEmpty && !list.contains(name)) {
          list.add(name);
        }
      }
      return list;
    });
  }

  Future<void> addCategory(String categoryName) async {
    final clean = categoryName.trim();
    if (clean.isEmpty) return;
    final docId = clean.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    await _categoriesRef.doc(docId).set({
      'name': clean,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String categoryName) async {
    final clean = categoryName.trim();
    final docId = clean.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    await _categoriesRef.doc(docId).delete();
  }

  // ==========================================
  // ORDERS MANAGEMENT & STATUS PIPELINE
  // ==========================================

  Stream<List<OrderModel>> streamOrders({
    OrderStatus? status,
    String? merchantId,
    String? salesmanId,
    String? deliveryBoyId,
  }) {
    Query<Map<String, dynamic>> query = _ordersRef;

    if (merchantId != null && merchantId.isNotEmpty) {
      query = query.where('merchantId', isEqualTo: merchantId);
    }
    if (salesmanId != null && salesmanId.isNotEmpty) {
      query = query.where('salesmanId', isEqualTo: salesmanId);
    }
    if (deliveryBoyId != null && deliveryBoyId.isNotEmpty) {
      query = query.where('deliveryBoyId', isEqualTo: deliveryBoyId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _ordersRef.doc(orderId).get();
    if (doc.exists && doc.data() != null) {
      return OrderModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Create an order with sequential numbering (BB-01, BB-02, ...) via Firestore Transaction
  Future<String> createOrder(OrderModel order) async {
    return await _firestore.runTransaction<String>((transaction) async {
      final counterRef = _firestore.collection('system_counters').doc('orders');
      final counterSnap = await transaction.get(counterRef);

      int lastOrderNumber = 0;
      if (counterSnap.exists && counterSnap.data() != null) {
        lastOrderNumber =
            (counterSnap.data()!['lastOrderNumber'] as num?)?.toInt() ?? 0;
      }

      final int nextNum = lastOrderNumber + 1;
      final String formattedSeq = 'BB-${nextNum.toString().padLeft(2, '0')}';

      // 1. Update counter in transaction
      transaction.set(
          counterRef,
          {
            'lastOrderNumber': nextNum,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      final docRef = _ordersRef.doc(formattedSeq);

      final finalOrder = order.copyWith(
        id: formattedSeq,
        invoiceNumber: formattedSeq,
      );

      // 2. Write order document
      transaction.set(docRef, finalOrder.toMap());

      // 3. Reduce stock for each item ordered
      for (final item in finalOrder.items) {
        final prodDoc = _productsRef.doc(item.productId);
        transaction.update(prodDoc, {
          'stockQuantity': FieldValue.increment(-item.quantity),
        });
      }

      // 4. If credit order, add to merchant outstanding balance
      if (finalOrder.paymentType == PaymentType.credit && !finalOrder.isPaid) {
        final merchantDoc = _usersRef.doc(finalOrder.merchantId);
        transaction.update(merchantDoc, {
          'outstandingDue': FieldValue.increment(finalOrder.grandTotal),
        });
      }

      return formattedSeq;
    });
  }

  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    bool? isPaid,
    String? deliveryBoyId,
    String? deliveryBoyName,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': newStatus.name,
    };
    if (isPaid != null) {
      updateData['isPaid'] = isPaid;
    }
    if (deliveryBoyId != null) {
      updateData['deliveryBoyId'] = deliveryBoyId;
    }
    if (deliveryBoyName != null) {
      updateData['deliveryBoyName'] = deliveryBoyName;
    }
    if (newStatus == OrderStatus.delivered) {
      updateData['deliveredAt'] = Timestamp.fromDate(DateTime.now());
    }

    await _ordersRef.doc(orderId).update(updateData);
  }

  Future<void> assignDeliveryBoy(
    String orderId,
    String deliveryBoyId,
    String deliveryBoyName,
  ) async {
    await _ordersRef.doc(orderId).update({
      'deliveryBoyId': deliveryBoyId,
      'deliveryBoyName': deliveryBoyName,
      'status': OrderStatus.approved.name,
    });
  }

  Future<void> markOrderDelivered(
    String orderId, {
    required bool isPaid,
  }) async {
    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.delivered.name,
      'isPaid': isPaid,
      'deliveredAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateDeliveryOutcome({
    required String orderId,
    required OrderStatus status,
    required bool isPaid,
    String? outcomeReason,
    double? collectedAmount,
    String? merchantId,
    String? deliveryBoyId,
  }) async {
    final batch = _firestore.batch();
    final Map<String, dynamic> updateData = {
      'status': status.name,
      'isPaid': isPaid,
    };
    if (status == OrderStatus.delivered) {
      updateData['deliveredAt'] = Timestamp.fromDate(DateTime.now());
    }
    if (outcomeReason != null && outcomeReason.isNotEmpty) {
      updateData['notes'] = outcomeReason;
    }
    batch.update(_ordersRef.doc(orderId), updateData);

    // If payment collected on delivery, record to merchant's khata & update delivery partner's COD cash in hand
    if (isPaid && collectedAmount != null && collectedAmount > 0) {
      if (merchantId != null && merchantId.isNotEmpty) {
        batch.update(_usersRef.doc(merchantId), {
          'outstandingDue': FieldValue.increment(-collectedAmount),
        });
        final paymentDoc =
            _usersRef.doc(merchantId).collection('payments').doc();
        batch.set(paymentDoc, {
          'id': paymentDoc.id,
          'amount': collectedAmount,
          'notes': 'COD Collected on Order $orderId',
          'timestamp': Timestamp.fromDate(DateTime.now()),
        });
      }

      if (deliveryBoyId != null && deliveryBoyId.isNotEmpty) {
        batch.update(_usersRef.doc(deliveryBoyId), {
          'pendingCashInHand': FieldValue.increment(collectedAmount),
        });
      }
    }

    await batch.commit();
  }

  Future<void> cancelOrder(String orderId,
      {List<CartItem>? itemsToRestock, String? cancelReason}) async {
    final batch = _firestore.batch();
    final Map<String, dynamic> updateData = {
      'status': OrderStatus.cancelled.name,
    };
    if (cancelReason != null && cancelReason.isNotEmpty) {
      updateData['notes'] = 'Cancelled: $cancelReason';
    }
    batch.update(_ordersRef.doc(orderId), updateData);

    // Restock items if provided
    if (itemsToRestock != null) {
      for (final item in itemsToRestock) {
        batch.update(_productsRef.doc(item.productId), {
          'stockQuantity': FieldValue.increment(item.quantity),
        });
      }
    }
    await batch.commit();
  }

  // ==========================================
  // USERS, MERCHANTS, KHATA & BEAT MANAGEMENT
  // ==========================================

  Stream<List<UserModel>> streamUsersByRole(UserRole role) {
    return streamAllUsers(role: role);
  }

  Stream<List<UserModel>> streamMerchantsBySalesman(String salesmanId) {
    return streamAllUsers(role: UserRole.merchant).map((list) {
      return list.where((u) => u.addedBySalesmanId == salesmanId).toList();
    });
  }

  Stream<List<UserModel>> streamAllUsers({UserRole? role}) {
    return _usersRef.snapshots().asyncMap((snapshot) async {
      final Map<String, UserModel> usersMap = {};
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final user = UserModel.fromMap(data, doc.id);
          usersMap[doc.id] = user;
        } catch (e) {
          debugPrint('Notice: Error parsing user doc ${doc.id}: $e');
        }
      }

      // Also merge any standalone docs from 'merchants' collection if not duplicate
      try {
        final merchantSnap = await _firestore.collection('merchants').get();
        for (final doc in merchantSnap.docs) {
          if (!usersMap.containsKey(doc.id)) {
            try {
              final merchant = UserModel.fromMap(doc.data(), doc.id);
              final exists = usersMap.values.any((u) =>
                  u.uid == merchant.uid ||
                  (u.phone.isNotEmpty && u.phone == merchant.phone) ||
                  (u.email.isNotEmpty &&
                      u.email.toLowerCase().trim() ==
                          merchant.email.toLowerCase().trim()));
              if (!exists) {
                usersMap[doc.id] = merchant;
              }
            } catch (_) {}
          }
        }
      } catch (_) {}

      final List<UserModel> list = usersMap.values.toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (role != null) {
        return list.where((u) => u.role == role).toList();
      }
      return list;
    });
  }

  Future<void> createUser(UserModel user) async {
    if (user.uid.isEmpty) {
      final docRef = _usersRef.doc();
      final newUser = user.copyWith(uid: docRef.id);
      await docRef.set(newUser.toMap());
    } else {
      await _usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    }
  }

  // Create Staff / Merchant Account with Firebase Auth and Firestore record without signing out Admin
  Future<UserModel> createStaffUserWithAuth({
    required UserModel user,
    String? password,
  }) async {
    String assignedUid = user.uid;

    final rawPhone = user.phone.trim();
    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    String sanitizedEmail = user.email.trim().toLowerCase();

    if (sanitizedEmail.isEmpty ||
        !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(sanitizedEmail)) {
      if (cleanPhone.isNotEmpty) {
        sanitizedEmail = '$cleanPhone@bainadabrothers.com';
      } else {
        throw Exception('Valid email format (e.g. user@domain.com) or 10-digit phone is required.');
      }
    }

    if (password != null && password.trim().length >= 6) {
      FirebaseApp? secondaryApp;
      final uniqueName = 'SecondaryAuth_${DateTime.now().millisecondsSinceEpoch}';
      try {
        try {
          secondaryApp = await Firebase.initializeApp(
            name: uniqueName,
            options: Firebase.app().options,
          );
        } catch (_) {
          secondaryApp = await Firebase.initializeApp(
            name: uniqueName,
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }

        final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
        final userCredential =
            await secondaryAuth.createUserWithEmailAndPassword(
          email: sanitizedEmail,
          password: password.trim(),
        );
        if (userCredential.user != null) {
          assignedUid = userCredential.user!.uid;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw Exception(
              'An account with email "$sanitizedEmail" already exists in Firebase Authentication.');
        } else if (e.code == 'weak-password') {
          throw Exception(
              'Password is too weak. Please use at least 6 characters.');
        } else if (e.code == 'invalid-email') {
          throw Exception('The email address format is invalid: "$sanitizedEmail".');
        } else {
          throw Exception(e.message ?? 'Authentication error: ${e.code}');
        }
      } catch (e) {
        debugPrint('Error creating auth user via secondary app: $e');
        throw Exception('Failed to create user auth account: $e');
      } finally {
        try {
          await secondaryApp?.delete();
        } catch (_) {}
      }
    }

    if (assignedUid.isEmpty) {
      assignedUid = _usersRef.doc().id;
    }

    final finalUser = user.copyWith(
      uid: assignedUid,
      email: sanitizedEmail,
    );

    await _usersRef
        .doc(assignedUid)
        .set(finalUser.toMap(), SetOptions(merge: true));

    // Mirror to merchants collection for compatibility if merchant
    if (finalUser.role == UserRole.merchant) {
      try {
        await _firestore
            .collection('merchants')
            .doc(assignedUid)
            .set(finalUser.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Note: merchant mirror write: $e');
      }
    }

    return finalUser;
  }

  Future<void> updateUser(UserModel user) async {
    await _usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    if (user.role == UserRole.merchant) {
      try {
        await _firestore
            .collection('merchants')
            .doc(user.uid)
            .set(user.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> deleteUser(String uid, {String? email, String? phone}) async {
    try {
      // 1. Direct document deletion by UID
      if (uid.isNotEmpty) {
        try {
          await _usersRef.doc(uid).delete();
        } catch (_) {}
        try {
          await _firestore.collection('merchants').doc(uid).delete();
        } catch (_) {}
      }

      // 2. Query and delete any docs with matching email
      if (email != null && email.trim().isNotEmpty) {
        final cleanEmail = email.trim();
        try {
          final uSnap = await _usersRef.where('email', isEqualTo: cleanEmail).get();
          for (final d in uSnap.docs) {
            await d.reference.delete();
          }
        } catch (_) {}
        try {
          final mSnap = await _firestore
              .collection('merchants')
              .where('email', isEqualTo: cleanEmail)
              .get();
          for (final d in mSnap.docs) {
            await d.reference.delete();
          }
        } catch (_) {}
      }

      // 3. Query and delete any docs with matching phone
      if (phone != null && phone.trim().isNotEmpty) {
        final rawPhone = phone.trim();
        final digitsPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
        final phoneVariations = [rawPhone, digitsPhone, '+91$digitsPhone', '91$digitsPhone'];

        for (final p in phoneVariations) {
          if (p.isNotEmpty) {
            try {
              final uSnap = await _usersRef.where('phone', isEqualTo: p).get();
              for (final d in uSnap.docs) {
                await d.reference.delete();
              }
            } catch (_) {}
            try {
              final mSnap = await _firestore
                  .collection('merchants')
                  .where('phone', isEqualTo: p)
                  .get();
              for (final d in mSnap.docs) {
                await d.reference.delete();
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting user $uid: $e');
      rethrow;
    }
  }

  Future<void> resetUserPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      debugPrint('Error sending password reset: ${e.message}');
      throw Exception(e.message ?? 'Failed to send password reset email');
    } catch (e) {
      debugPrint('Error sending password reset: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _usersRef.get();
      final Map<String, UserModel> usersMap = {};
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final user = UserModel.fromMap(data, doc.id);
          usersMap[user.uid] = user;
        } catch (e) {
          debugPrint('Notice: Error parsing user doc ${doc.id}: $e');
        }
      }

      try {
        final merchantSnap = await _firestore.collection('merchants').get();
        for (final doc in merchantSnap.docs) {
          if (!usersMap.containsKey(doc.id)) {
            try {
              final merchant = UserModel.fromMap(doc.data(), doc.id);
              usersMap[doc.id] = merchant;
            } catch (_) {}
          }
        }
      } catch (_) {}

      final List<UserModel> list = usersMap.values.toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('Error in getAllUsers(): $e');
      return [];
    }
  }

  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    final all = await getAllUsers();
    return all.where((u) => u.role == role).toList();
  }

  Future<void> updateUserStatus(String uid, bool isActive) async {
    await _usersRef.doc(uid).update({'isActive': isActive});
  }

  Future<void> updateMerchantApproval(String uid, bool isApproved) async {
    await _usersRef.doc(uid).update({'isApproved': isApproved});
  }

  Future<void> updateCreditLimit(String uid, double newLimit) async {
    await _usersRef.doc(uid).update({'creditLimit': newLimit});
  }

  Future<void> updateOutstandingDue(String merchantId, double dueChange) async {
    await _usersRef.doc(merchantId).update({
      'outstandingDue': FieldValue.increment(dueChange),
    });
  }

  // ==========================================
  // PAYMENTS & KHATA TRANSACTIONS
  // ==========================================

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _firestore.collection('payments');

  Stream<List<PaymentTransactionModel>> streamPaymentsByMerchant(
      String merchantId) {
    return _paymentsRef
        .where('merchantId', isEqualTo: merchantId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PaymentTransactionModel.fromMap(doc.data(), doc.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Stream<List<PaymentTransactionModel>> streamAllPayments() {
    return _paymentsRef.snapshots().map((snap) => snap.docs
        .map((doc) => PaymentTransactionModel.fromMap(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // Record a payment collected from a merchant, reducing their outstanding due
  Future<void> recordMerchantPayment(
    String merchantId,
    double paymentAmount, {
    String? notes,
    String paymentMode = 'Cash',
  }) async {
    final batch = _firestore.batch();
    batch.update(_usersRef.doc(merchantId), {
      'outstandingDue': FieldValue.increment(-paymentAmount),
    });

    final paymentDoc = _paymentsRef.doc();
    final payment = PaymentTransactionModel(
      id: paymentDoc.id,
      merchantId: merchantId,
      amount: paymentAmount,
      paymentMode: paymentMode,
      note: notes ?? 'Payment Received',
      createdAt: DateTime.now(),
      isEdited: false,
    );

    batch.set(paymentDoc, payment.toMap());

    // Also write into ledgers and transactions collections for complete real-time ledger synchronization
    batch.set(_ledgersRef.doc(paymentDoc.id), {
      ...payment.toMap(),
      'type': 'credit_payment',
      'ledgerType': 'payment_received',
    });
    batch.set(_transactionsRef.doc(paymentDoc.id), {
      ...payment.toMap(),
      'type': 'credit_payment',
    });

    // Also write into merchant subcollection for compatibility
    final subDoc =
        _usersRef.doc(merchantId).collection('payments').doc(paymentDoc.id);
    batch.set(subDoc, payment.toMap());

    await batch.commit();
  }

  // Strict 1-Time Edit Payment Transaction
  Future<void> editMerchantPayment({
    required PaymentTransactionModel oldPayment,
    required double newAmount,
    required String newPaymentMode,
    String? newNote,
  }) async {
    if (oldPayment.isEdited) {
      throw Exception(
          'This payment entry has already been edited and is permanently locked.');
    }

    final double difference = newAmount - oldPayment.amount;
    final batch = _firestore.batch();

    // If new amount is higher, due decreases; if lower, due increases
    batch.update(_usersRef.doc(oldPayment.merchantId), {
      'outstandingDue': FieldValue.increment(-difference),
    });

    final updateData = {
      'amount': newAmount,
      'paymentMode': newPaymentMode,
      'note': newNote,
      'isEdited': true,
      'editedAt': Timestamp.fromDate(DateTime.now()),
      'originalAmount': oldPayment.amount,
    };

    final rootDoc = _paymentsRef.doc(oldPayment.id);
    batch.update(rootDoc, updateData);

    final subDoc = _usersRef
        .doc(oldPayment.merchantId)
        .collection('payments')
        .doc(oldPayment.id);
    batch.update(subDoc, updateData);

    await batch.commit();
  }

  // ==========================================
  // CASH SETTLEMENTS (COD HANDOVER TO ADMIN)
  // ==========================================

  Future<void> recordCashSettlement({
    required String deliveryBoyId,
    required String deliveryBoyName,
    required double amountSettled,
    required String paymentMode,
    String? notes,
    required String settledByAdminId,
    required String settledByAdminName,
  }) async {
    final deliveryUserRef = _usersRef.doc(deliveryBoyId);
    final settlementDoc = _cashSettlementsRef.doc();

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(deliveryUserRef);

      double currentPending = 0.0;
      double currentTotalSettled = 0.0;

      if (userSnapshot.exists && userSnapshot.data() != null) {
        final data = userSnapshot.data()!;
        final rawPending = data['pendingCashInHand'] ?? data['cashInHand'];
        if (rawPending is num) {
          currentPending = rawPending.toDouble();
        } else if (rawPending is String) {
          currentPending = double.tryParse(rawPending) ?? 0.0;
        }

        final rawSettled = data['totalCashSettled'] ??
            data['totalSettled'] ??
            data['cashSettled'];
        if (rawSettled is num) {
          currentTotalSettled = rawSettled.toDouble();
        } else if (rawSettled is String) {
          currentTotalSettled = double.tryParse(rawSettled) ?? 0.0;
        }
      }

      final double newPending =
          (currentPending - amountSettled).clamp(0.0, double.infinity);
      final double newTotalSettled = currentTotalSettled + amountSettled;

      // 1. Atomically deduct pending cash and increment total settled on delivery partner
      transaction.update(deliveryUserRef, {
        'pendingCashInHand': newPending,
        'cashInHand': newPending,
        'totalCashSettled': newTotalSettled,
        'totalSettled': newTotalSettled,
        'lastSettlementDate': FieldValue.serverTimestamp(),
      });

      // 2. Create entry in 'cash_settlements' collection
      final settlement = CashSettlementModel(
        id: settlementDoc.id,
        deliveryBoyId: deliveryBoyId,
        deliveryBoyName: deliveryBoyName,
        amountSettled: amountSettled,
        paymentMode: paymentMode,
        notes: notes,
        settledByAdminId: settledByAdminId,
        settledByAdminName: settledByAdminName,
        createdAt: DateTime.now(),
      );
      transaction.set(settlementDoc, settlement.toMap());
    });
  }

  Stream<List<CashSettlementModel>> streamCashSettlements(
      {String? deliveryBoyId}) {
    Query<Map<String, dynamic>> query =
        _cashSettlementsRef.orderBy('createdAt', descending: true);
    if (deliveryBoyId != null && deliveryBoyId.isNotEmpty) {
      query = query.where('deliveryBoyId', isEqualTo: deliveryBoyId);
    }
    return query.snapshots().map((snap) {
      return snap.docs
          .map((doc) => CashSettlementModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<UserModel>> streamDeliveryPartners() {
    return _usersRef
        .where('role', isEqualTo: 'deliveryBoy')
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ==========================================
  // CLEAR ALL FIRESTORE DATA (PURGE DATABASE)
  // ==========================================

  Future<void> clearAllFirestoreData() async {
    try {
      final collections = [
        'products',
        'orders',
        'merchants',
        'cash_settlements',
        'payments',
      ];

      for (final col in collections) {
        final snap = await _firestore.collection(col).get();
        final batch = _firestore.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Reset system order counter to 0
      await _firestore.collection('system_counters').doc('orders').set({
        'lastOrderNumber': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear users collection
      final userSnap = await _firestore.collection('users').get();
      final userBatch = _firestore.batch();
      for (final doc in userSnap.docs) {
        userBatch.delete(doc.reference);
      }
      await userBatch.commit();
    } catch (e) {
      debugPrint('Error clearing Firestore database: $e');
      rethrow;
    }
  }
}
