import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Generates the next sequential invoice number (BB-01, BB-02, ...) atomically
  Future<String> generateNextInvoiceNumber() async {
    final DocumentReference counterRef =
        _firestore.collection('system_counters').doc('orders');

    return await _firestore.runTransaction<String>((transaction) async {
      final DocumentSnapshot snapshot = await transaction.get(counterRef);

      int currentCount = 0;
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        currentCount = (data['lastOrderNumber'] as num?)?.toInt() ?? 0;
      }

      final int nextCount = currentCount + 1;
      transaction.set(
        counterRef,
        {
          'lastOrderNumber': nextCount,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Pad to 2 digits: BB-01, BB-02, ... BB-99
      final String invoiceId = 'BB-${nextCount.toString().padLeft(2, '0')}';
      return invoiceId;
    });
  }

  /// Creates an order using an atomic Firestore transaction to generate sequential invoice IDs (BB-01, BB-02, etc.)
  Future<String> createOrderAtomic(OrderModel order) async {
    return await _firestore.runTransaction<String>((transaction) async {
      final DocumentReference counterRef =
          _firestore.collection('system_counters').doc('orders');
      final DocumentSnapshot counterSnapshot =
          await transaction.get(counterRef);

      int currentNumber = 0;
      if (counterSnapshot.exists && counterSnapshot.data() != null) {
        final data = counterSnapshot.data() as Map<String, dynamic>;
        currentNumber = (data['lastOrderNumber'] as num?)?.toInt() ?? 0;
      }
      final int nextNumber = currentNumber + 1;

      // Format as BB-01, BB-02, ... BB-99
      final String formattedInvoiceNo =
          'BB-${nextNumber.toString().padLeft(2, '0')}';

      // 1. Update counter in transaction
      transaction.set(
        counterRef,
        {
          'lastOrderNumber': nextNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final DocumentReference docRef = _ordersRef.doc(formattedInvoiceNo);

      final finalOrder = order.copyWith(
        id: formattedInvoiceNo,
        invoiceNumber: formattedInvoiceNo,
      );

      // 2. Write order document
      transaction.set(docRef, finalOrder.toMap());

      // 3. Batch reduce stock for each item ordered
      for (final item in finalOrder.items) {
        final prodDoc = _productsRef.doc(item.productId);
        transaction.update(prodDoc, {
          'stockQuantity': FieldValue.increment(-item.quantity),
        });
      }

      // 4. If credit order, increment merchant's outstanding Khata balance
      if (finalOrder.paymentType == PaymentType.credit && !finalOrder.isPaid) {
        final merchantDoc = _usersRef.doc(finalOrder.merchantId);
        transaction.update(merchantDoc, {
          'outstandingDue': FieldValue.increment(finalOrder.grandTotal),
        });
      }

      return formattedInvoiceNo;
    });
  }
}
