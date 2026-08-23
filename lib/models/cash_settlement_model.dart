import 'package:cloud_firestore/cloud_firestore.dart';

class CashSettlementModel {
  final String id;
  final String deliveryBoyId;
  final String deliveryBoyName;
  final double amountSettled;
  final String paymentMode; // Cash, UPI Transfer, Bank Deposit
  final String? notes;
  final String settledByAdminId;
  final String settledByAdminName;
  final DateTime createdAt;

  const CashSettlementModel({
    required this.id,
    required this.deliveryBoyId,
    required this.deliveryBoyName,
    required this.amountSettled,
    this.paymentMode = 'Cash',
    this.notes,
    required this.settledByAdminId,
    required this.settledByAdminName,
    required this.createdAt,
  });

  factory CashSettlementModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parsedCreatedAt;
    final rawDate = map['createdAt'] ?? map['timestamp'];
    if (rawDate is Timestamp) {
      parsedCreatedAt = rawDate.toDate();
    } else if (rawDate is String) {
      parsedCreatedAt = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return CashSettlementModel(
      id: id ?? map['id'] ?? map['settlementId'] ?? '',
      deliveryBoyId: map['deliveryBoyId'] ?? '',
      deliveryBoyName: map['deliveryBoyName'] ?? 'Delivery Partner',
      amountSettled: (map['amountSettled'] as num?)?.toDouble() ?? (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['paymentMode'] ?? 'Cash',
      notes: map['notes'],
      settledByAdminId: map['settledByAdminId'] ?? 'admin',
      settledByAdminName: map['settledByAdminName'] ?? 'Master Admin',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'settlementId': id,
      'deliveryBoyId': deliveryBoyId,
      'deliveryBoyName': deliveryBoyName,
      'amountSettled': amountSettled,
      'paymentMode': paymentMode,
      'notes': notes,
      'settledByAdminId': settledByAdminId,
      'settledByAdminName': settledByAdminName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CashSettlementModel copyWith({
    String? id,
    String? deliveryBoyId,
    String? deliveryBoyName,
    double? amountSettled,
    String? paymentMode,
    String? notes,
    String? settledByAdminId,
    String? settledByAdminName,
    DateTime? createdAt,
  }) {
    return CashSettlementModel(
      id: id ?? this.id,
      deliveryBoyId: deliveryBoyId ?? this.deliveryBoyId,
      deliveryBoyName: deliveryBoyName ?? this.deliveryBoyName,
      amountSettled: amountSettled ?? this.amountSettled,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      settledByAdminId: settledByAdminId ?? this.settledByAdminId,
      settledByAdminName: settledByAdminName ?? this.settledByAdminName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
