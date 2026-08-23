import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentTransactionModel {
  final String id;
  final String merchantId;
  final double amount;
  final String paymentMode; // 'Cash', 'UPI', 'Bank Transfer', 'Cheque'
  final String? note;
  final DateTime createdAt;
  final bool isEdited; // STRICT 1-TIME EDIT FLAG
  final DateTime? editedAt;
  final double? originalAmount;

  const PaymentTransactionModel({
    required this.id,
    required this.merchantId,
    required this.amount,
    this.paymentMode = 'Cash',
    this.note,
    required this.createdAt,
    this.isEdited = false,
    this.editedAt,
    this.originalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchantId': merchantId,
      'amount': amount,
      'paymentMode': paymentMode,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'originalAmount': originalAmount,
    };
  }

  factory PaymentTransactionModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parsedCreatedAt;
    final rawCreatedAt = map['createdAt'] ?? map['timestamp'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    DateTime? parsedEditedAt;
    final rawEditedAt = map['editedAt'];
    if (rawEditedAt is Timestamp) {
      parsedEditedAt = rawEditedAt.toDate();
    } else if (rawEditedAt is DateTime) {
      parsedEditedAt = rawEditedAt;
    } else if (rawEditedAt is String) {
      parsedEditedAt = DateTime.tryParse(rawEditedAt);
    }

    return PaymentTransactionModel(
      id: id ?? map['id'] ?? '',
      merchantId: map['merchantId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['paymentMode'] ?? 'Cash',
      note: map['note'] ?? map['notes'],
      createdAt: parsedCreatedAt,
      isEdited: map['isEdited'] as bool? ?? false,
      editedAt: parsedEditedAt,
      originalAmount: (map['originalAmount'] as num?)?.toDouble(),
    );
  }

  PaymentTransactionModel copyWith({
    String? id,
    String? merchantId,
    double? amount,
    String? paymentMode,
    String? note,
    DateTime? createdAt,
    bool? isEdited,
    DateTime? editedAt,
    double? originalAmount,
  }) {
    return PaymentTransactionModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      originalAmount: originalAmount ?? this.originalAmount,
    );
  }
}
