import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum OrderStatus {
  pending,
  approved,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.approved:
        return 'approved';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending Approval';
      case OrderStatus.approved:
        return 'Approved & Assigned';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.approved:
        return AppColors.statusApproved;
      case OrderStatus.outForDelivery:
        return AppColors.statusDispatched;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_top_rounded;
      case OrderStatus.approved:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.outForDelivery:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.verified_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

enum PaymentType {
  cod,
  credit,
  online,
}

extension PaymentTypeExtension on PaymentType {
  String get name {
    switch (this) {
      case PaymentType.cod:
        return 'cod';
      case PaymentType.credit:
        return 'credit';
      case PaymentType.online:
        return 'online';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentType.cod:
        return 'Cash on Delivery (COD)';
      case PaymentType.credit:
        return 'Khata Credit';
      case PaymentType.online:
        return 'UPI / Online';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentType.cod:
        return Icons.local_atm_outlined;
      case PaymentType.credit:
        return Icons.account_balance_wallet_outlined;
      case PaymentType.online:
        return Icons.qr_code_2_rounded;
    }
  }
}

class CartItem {
  final String productId;
  final String productName;
  final String? hindiName;
  final String hsnCode;
  final String unit;
  final int quantity;
  final int unitMultiplier;
  final double originalUnitPrice; // Base standard wholesale rate
  final double unitPrice; // Effective rate after slab/tier discount
  final double mrp;
  final double gstRate;
  final double gstAmount;
  final double totalItemPrice;
  final String? imageUrl;

  const CartItem({
    required this.productId,
    required this.productName,
    this.hindiName,
    required this.hsnCode,
    required this.unit,
    required this.quantity,
    this.unitMultiplier = 1,
    double? originalUnitPrice,
    required this.unitPrice,
    this.mrp = 0.0,
    required this.gstRate,
    required this.gstAmount,
    required this.totalItemPrice,
    this.imageUrl,
  }) : originalUnitPrice = originalUnitPrice ?? unitPrice;

  double get taxableTotal => totalItemPrice - gstAmount;
  int get totalPieces => quantity * unitMultiplier;

  bool get isTieredDiscountApplied => originalUnitPrice > unitPrice;
  double get volumeSavings => isTieredDiscountApplied
      ? (originalUnitPrice - unitPrice) * quantity
      : 0.0;

  CartItem copyWith({
    String? productId,
    String? productName,
    String? hindiName,
    String? hsnCode,
    String? unit,
    int? quantity,
    int? unitMultiplier,
    double? originalUnitPrice,
    double? unitPrice,
    double? mrp,
    double? gstRate,
    double? gstAmount,
    double? totalItemPrice,
    String? imageUrl,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      hindiName: hindiName ?? this.hindiName,
      hsnCode: hsnCode ?? this.hsnCode,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitMultiplier: unitMultiplier ?? this.unitMultiplier,
      originalUnitPrice: originalUnitPrice ?? this.originalUnitPrice,
      unitPrice: unitPrice ?? this.unitPrice,
      mrp: mrp ?? this.mrp,
      gstRate: gstRate ?? this.gstRate,
      gstAmount: gstAmount ?? this.gstAmount,
      totalItemPrice: totalItemPrice ?? this.totalItemPrice,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final double effectivePrice = (map['unitPrice'] as num?)?.toDouble() ?? 0.0;
    final double basePrice =
        (map['originalUnitPrice'] as num?)?.toDouble() ?? effectivePrice;

    return CartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      hindiName: map['hindiName'],
      hsnCode: map['hsnCode'] ?? '',
      unit: map['unit'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitMultiplier: (map['unitMultiplier'] as num?)?.toInt() ?? 1,
      originalUnitPrice: basePrice,
      unitPrice: effectivePrice,
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      gstRate: (map['gstRate'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (map['gstAmount'] as num?)?.toDouble() ?? 0.0,
      totalItemPrice: (map['totalItemPrice'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'hindiName': hindiName,
      'hsnCode': hsnCode,
      'unit': unit,
      'quantity': quantity,
      'unitMultiplier': unitMultiplier,
      'originalUnitPrice': originalUnitPrice,
      'unitPrice': unitPrice,
      'mrp': mrp,
      'gstRate': gstRate,
      'gstAmount': gstAmount,
      'totalItemPrice': totalItemPrice,
      'imageUrl': imageUrl,
    };
  }
}

class OrderModel {
  final String id;
  final String invoiceNumber;
  final String merchantId;
  final String merchantName;
  final String merchantPhone;
  final String? merchantGstin;
  final String merchantAddress;
  final String? salesmanId;
  final String? salesmanName;
  final String? deliveryBoyId;
  final String? deliveryBoyName;
  final List<CartItem> items;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalGst;
  final double grandTotal;
  final OrderStatus status;
  final PaymentType paymentType;
  final bool isPaid;
  final String? cancelReason;
  final String? notes;
  final double? deliveryLatitude; // Live GPS Latitude captured at order placement
  final double? deliveryLongitude; // Live GPS Longitude captured at order placement
  final String? liveLocationAddress; // Live reverse-geocoded delivery address
  final DateTime? liveLocationCapturedAt;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? deliveredAt;

  const OrderModel({
    required this.id,
    required this.invoiceNumber,
    required this.merchantId,
    required this.merchantName,
    required this.merchantPhone,
    this.merchantGstin,
    required this.merchantAddress,
    this.salesmanId,
    this.salesmanName,
    this.deliveryBoyId,
    this.deliveryBoyName,
    required this.items,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    this.igst = 0.0,
    required this.totalGst,
    required this.grandTotal,
    required this.status,
    required this.paymentType,
    this.isPaid = false,
    this.cancelReason,
    this.notes,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.liveLocationAddress,
    this.liveLocationCapturedAt,
    required this.createdAt,
    this.approvedAt,
    this.deliveredAt,
  });

  int get totalItemUnits =>
      items.fold(0, (total, item) => total + item.quantity);

  String get orderNumber => invoiceNumber.isNotEmpty ? invoiceNumber : id;

  factory OrderModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    DateTime? parsedApprovedAt;
    final rawApprovedAt = map['approvedAt'];
    if (rawApprovedAt is Timestamp) {
      parsedApprovedAt = rawApprovedAt.toDate();
    } else if (rawApprovedAt is DateTime) {
      parsedApprovedAt = rawApprovedAt;
    } else if (rawApprovedAt is String) {
      parsedApprovedAt = DateTime.tryParse(rawApprovedAt);
    }

    DateTime? parsedDeliveredAt;
    final rawDeliveredAt = map['deliveredAt'];
    if (rawDeliveredAt is Timestamp) {
      parsedDeliveredAt = rawDeliveredAt.toDate();
    } else if (rawDeliveredAt is DateTime) {
      parsedDeliveredAt = rawDeliveredAt;
    } else if (rawDeliveredAt is String) {
      parsedDeliveredAt = DateTime.tryParse(rawDeliveredAt);
    }

    final rawItems = map['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
        .toList();

    OrderStatus parsedStatus;
    final statusStr = (map['status'] ?? 'pending').toString().toLowerCase();
    switch (statusStr) {
      case 'approved':
      case 'packed':
        parsedStatus = OrderStatus.approved;
        break;
      case 'dispatched':
      case 'out_for_delivery':
      case 'outfordelivery':
        parsedStatus = OrderStatus.outForDelivery;
        break;
      case 'delivered':
        parsedStatus = OrderStatus.delivered;
        break;
      case 'cancelled':
        parsedStatus = OrderStatus.cancelled;
        break;
      case 'pending':
      default:
        parsedStatus = OrderStatus.pending;
        break;
    }

    PaymentType parsedPaymentType;
    final paymentStr =
        (map['paymentType'] ?? 'credit').toString().toLowerCase();
    switch (paymentStr) {
      case 'cod':
        parsedPaymentType = PaymentType.cod;
        break;
      case 'online':
        parsedPaymentType = PaymentType.online;
        break;
      case 'credit':
      default:
        parsedPaymentType = PaymentType.credit;
        break;
    }

    final String resolvedId = id ?? map['id'] ?? map['orderId'] ?? '';
    final String rawInvoice = (map['invoiceNumber'] as String?)?.trim() ?? '';
    final String rawOrderId = (map['orderId'] as String?)?.trim() ?? '';
    final String resolvedInvoice = rawInvoice.isNotEmpty
        ? rawInvoice
        : (rawOrderId.isNotEmpty
            ? rawOrderId
            : (resolvedId.isNotEmpty ? resolvedId : 'BB-01'));

    return OrderModel(
      id: resolvedId,
      invoiceNumber: resolvedInvoice,
      merchantId: map['merchantId'] ?? '',
      merchantName: map['merchantName'] ?? '',
      merchantPhone: map['merchantPhone'] ?? '',
      merchantGstin: map['merchantGstin'],
      merchantAddress: map['merchantAddress'] ?? '',
      salesmanId: map['salesmanId'],
      salesmanName: map['salesmanName'],
      deliveryBoyId: map['deliveryBoyId'],
      deliveryBoyName: map['deliveryBoyName'],
      items: parsedItems,
      taxableAmount: (map['taxableAmount'] as num?)?.toDouble() ?? 0.0,
      cgst: (map['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (map['sgst'] as num?)?.toDouble() ?? 0.0,
      igst: (map['igst'] as num?)?.toDouble() ?? 0.0,
      totalGst: (map['totalGst'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      status: parsedStatus,
      paymentType: parsedPaymentType,
      isPaid: map['isPaid'] ?? false,
      cancelReason: map['cancelReason'],
      notes: map['notes'],
      deliveryLatitude: (map['deliveryLatitude'] as num?)?.toDouble() ??
          (map['latitude'] as num?)?.toDouble() ??
          (map['lat'] as num?)?.toDouble(),
      deliveryLongitude: (map['deliveryLongitude'] as num?)?.toDouble() ??
          (map['longitude'] as num?)?.toDouble() ??
          (map['lng'] as num?)?.toDouble(),
      liveLocationAddress: map['liveLocationAddress']?.toString() ??
          map['locationAddress']?.toString() ??
          map['geoAddress']?.toString(),
      liveLocationCapturedAt: map['liveLocationCapturedAt'] is Timestamp
          ? (map['liveLocationCapturedAt'] as Timestamp).toDate()
          : (map['liveLocationCapturedAt'] is String
              ? DateTime.tryParse(map['liveLocationCapturedAt'])
              : null),
      createdAt: parsedCreatedAt,
      approvedAt: parsedApprovedAt,
      deliveredAt: parsedDeliveredAt,
    );
  }

  Map<String, dynamic> toMap() {
    final String invNo = invoiceNumber.isNotEmpty
        ? invoiceNumber
        : (id.isNotEmpty ? id : 'BB-01');
    return {
      'id': id.isNotEmpty ? id : invNo,
      'orderId': id.isNotEmpty ? id : invNo,
      'invoiceNumber': invNo,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'merchantPhone': merchantPhone,
      'merchantGstin': merchantGstin,
      'merchantAddress': merchantAddress,
      'salesmanId': salesmanId,
      'salesmanName': salesmanName,
      'deliveryBoyId': deliveryBoyId,
      'deliveryBoyName': deliveryBoyName,
      'items': items.map((item) => item.toMap()).toList(),
      'taxableAmount': taxableAmount,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'totalGst': totalGst,
      'grandTotal': grandTotal,
      'status': status.name,
      'paymentType': paymentType.name,
      'isPaid': isPaid,
      'cancelReason': cancelReason,
      'notes': notes,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'latitude': deliveryLatitude,
      'longitude': deliveryLongitude,
      'liveLocationAddress': liveLocationAddress,
      'liveLocationCapturedAt': liveLocationCapturedAt != null
          ? Timestamp.fromDate(liveLocationCapturedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    };
  }

  OrderModel copyWith({
    String? id,
    String? invoiceNumber,
    String? merchantId,
    String? merchantName,
    String? merchantPhone,
    String? merchantGstin,
    String? merchantAddress,
    String? salesmanId,
    String? salesmanName,
    String? deliveryBoyId,
    String? deliveryBoyName,
    List<CartItem>? items,
    double? taxableAmount,
    double? cgst,
    double? sgst,
    double? igst,
    double? totalGst,
    double? grandTotal,
    OrderStatus? status,
    PaymentType? paymentType,
    bool? isPaid,
    String? cancelReason,
    String? notes,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? liveLocationAddress,
    DateTime? liveLocationCapturedAt,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? deliveredAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      merchantPhone: merchantPhone ?? this.merchantPhone,
      merchantGstin: merchantGstin ?? this.merchantGstin,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      salesmanId: salesmanId ?? this.salesmanId,
      salesmanName: salesmanName ?? this.salesmanName,
      deliveryBoyId: deliveryBoyId ?? this.deliveryBoyId,
      deliveryBoyName: deliveryBoyName ?? this.deliveryBoyName,
      items: items ?? this.items,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
      totalGst: totalGst ?? this.totalGst,
      grandTotal: grandTotal ?? this.grandTotal,
      status: status ?? this.status,
      paymentType: paymentType ?? this.paymentType,
      isPaid: isPaid ?? this.isPaid,
      cancelReason: cancelReason ?? this.cancelReason,
      notes: notes ?? this.notes,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      liveLocationAddress: liveLocationAddress ?? this.liveLocationAddress,
      liveLocationCapturedAt:
          liveLocationCapturedAt ?? this.liveLocationCapturedAt,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
