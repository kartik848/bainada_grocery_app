import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  salesman,
  merchant,
  deliveryBoy,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.salesman:
        return 'salesman';
      case UserRole.merchant:
        return 'merchant';
      case UserRole.deliveryBoy:
        return 'deliveryBoy';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin / Owner';
      case UserRole.salesman:
        return 'Field Salesman';
      case UserRole.merchant:
        return 'Kirana Merchant';
      case UserRole.deliveryBoy:
        return 'Delivery Partner';
    }
  }
}

class UserModel {
  final String uid;
  final String name; // Owner name / Contact name
  final String phone;
  final String email;
  final UserRole role;
  final String? shopName;
  final String? gstin;
  final String? address;
  final String? landmark;
  final String? city;
  final String? state;
  final String? addedBySalesmanId;
  final String? addedBySalesmanName;
  final double creditLimit;
  final double outstandingDue;
  final double minOrderLimit; // Minimum Basket Order Limit in ₹
  final double commissionRate; // For Salesmen - Commission percentage (e.g. 1.5 for 1.5%, 2.0 for 2.0%)
  final double? dailyTarget; // For Salesmen
  final String? vehicleNumber; // For Delivery Boy
  final String? licenseNumber; // For Delivery Boy
  final double pendingCashInHand; // For Delivery Boy: COD cash currently held
  final double totalCashSettled; // For Delivery Boy: Total cash handed over to Admin
  final bool isApproved;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.shopName,
    this.gstin,
    this.address,
    this.landmark,
    this.city = 'Jaipur',
    this.state = 'Rajasthan',
    this.addedBySalesmanId,
    this.addedBySalesmanName,
    this.creditLimit = 0.0,
    this.outstandingDue = 0.0,
    this.minOrderLimit = 0.0,
    this.commissionRate = 0.0,
    this.dailyTarget,
    this.vehicleNumber,
    this.licenseNumber,
    this.pendingCashInHand = 0.0,
    this.totalCashSettled = 0.0,
    this.isApproved = true,
    this.isActive = true,
    required this.createdAt,
  });

  String get ownerName => name;

  // Available credit calculation
  double get availableCredit => (creditLimit - outstandingDue).clamp(0.0, creditLimit);

  // Check if merchant has exceeded credit limit
  bool get hasExceededCreditLimit => outstandingDue > creditLimit && creditLimit > 0;

  factory UserModel.fromMap(Map<String, dynamic>? map, [String? id]) {
    if (map == null) {
      return UserModel(
        uid: id ?? '',
        name: 'Unnamed User',
        phone: '',
        email: '',
        role: UserRole.merchant,
        createdAt: DateTime.now(),
      );
    }

    DateTime parsedCreatedAt;
    final rawCreatedAt = map['createdAt'] ?? map['created_at'] ?? map['timestamp'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else if (rawCreatedAt is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else {
      parsedCreatedAt = DateTime.now();
    }

    UserRole parsedRole;
    final rawRole = (map['role'] ?? 'merchant').toString().toLowerCase().trim();
    final roleCleaned = rawRole.replaceAll('_', '').replaceAll(' ', '').replaceAll('-', '');
    switch (roleCleaned) {
      case 'admin':
      case 'superadmin':
      case 'owner':
        parsedRole = UserRole.admin;
        break;
      case 'salesman':
      case 'sales':
      case 'salesperson':
      case 'fieldagent':
        parsedRole = UserRole.salesman;
        break;
      case 'deliveryboy':
      case 'delivery':
      case 'deliverypartner':
      case 'driver':
      case 'courier':
        parsedRole = UserRole.deliveryBoy;
        break;
      case 'merchant':
      case 'kirana':
      case 'store':
      case 'retailer':
      case 'customer':
      default:
        parsedRole = UserRole.merchant;
        break;
    }

    double parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    bool parseBool(dynamic value, [bool defaultValue = true]) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final s = value.toLowerCase().trim();
        if (s == 'true' || s == '1' || s == 'yes') return true;
        if (s == 'false' || s == '0' || s == 'no') return false;
      }
      return defaultValue;
    }

    String uid = id ?? map['uid']?.toString() ?? map['id']?.toString() ?? '';
    String name = (map['ownerName'] ?? map['name'] ?? map['fullName'] ?? map['userName'] ?? '').toString().trim();
    if (name.isEmpty && map['shopName'] != null) {
      name = map['shopName'].toString().trim();
    }
    if (name.isEmpty) {
      name = uid.isNotEmpty ? 'User ${uid.length > 6 ? uid.substring(0, 6) : uid}' : 'Unnamed User';
    }

    String phone = (map['phone'] ?? map['mobile'] ?? map['phoneNumber'] ?? map['contact'] ?? '').toString().trim();
    String email = (map['email'] ?? map['emailAddress'] ?? '').toString().trim();

    return UserModel(
      uid: uid,
      name: name,
      phone: phone,
      email: email,
      role: parsedRole,
      shopName: map['shopName']?.toString() ?? map['firmName']?.toString() ?? map['storeName']?.toString(),
      gstin: map['gstin']?.toString() ?? map['gst']?.toString() ?? map['gstNumber']?.toString(),
      address: map['address']?.toString() ?? map['street']?.toString(),
      landmark: map['landmark']?.toString(),
      city: map['city']?.toString() ?? 'Jaipur',
      state: map['state']?.toString() ?? 'Rajasthan',
      addedBySalesmanId: (map['addedBySalesmanId'] ?? map['assignedSalesmanId'] ?? map['salesmanId'])?.toString(),
      addedBySalesmanName: (map['addedBySalesmanName'] ?? map['salesmanName'])?.toString(),
      creditLimit: parseDouble(map['creditLimit'] ?? map['khataLimit'], 0.0),
      outstandingDue: parseDouble(map['outstandingDue'] ?? map['due'] ?? map['khataBalance'] ?? map['pendingDue'], 0.0),
      minOrderLimit: parseDouble(map['minOrderLimit'] ?? map['minOrder'], 0.0),
      commissionRate: parseDouble(map['commissionRate'] ?? map['commission'], 0.0),
      dailyTarget: map['dailyTarget'] != null ? parseDouble(map['dailyTarget']) : null,
      vehicleNumber: (map['vehicleNumber'] ?? map['vehicleNo'])?.toString(),
      licenseNumber: (map['licenseNumber'] ?? map['licenseNo'])?.toString(),
      pendingCashInHand: parseDouble(map['pendingCashInHand'] ?? map['cashInHand'], 0.0),
      totalCashSettled: parseDouble(map['totalCashSettled'] ?? map['cashSettled'], 0.0),
      isApproved: parseBool(map['isApproved'], true),
      isActive: parseBool(map['isActive'], true),
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'ownerName': name,
      'phone': phone,
      'email': email,
      'role': role.name,
      'shopName': shopName,
      'gstin': gstin,
      'address': address,
      'landmark': landmark,
      'city': city,
      'state': state,
      'addedBySalesmanId': addedBySalesmanId,
      'addedBySalesmanName': addedBySalesmanName,
      'creditLimit': creditLimit,
      'outstandingDue': outstandingDue,
      'khataBalance': outstandingDue,
      'minOrderLimit': minOrderLimit,
      'commissionRate': commissionRate,
      'dailyTarget': dailyTarget,
      'vehicleNumber': vehicleNumber,
      'licenseNumber': licenseNumber,
      'pendingCashInHand': pendingCashInHand,
      'totalCashSettled': totalCashSettled,
      'isApproved': isApproved,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    String? shopName,
    String? gstin,
    String? address,
    String? landmark,
    String? city,
    String? state,
    String? addedBySalesmanId,
    String? addedBySalesmanName,
    double? creditLimit,
    double? outstandingDue,
    double? minOrderLimit,
    double? commissionRate,
    double? dailyTarget,
    String? vehicleNumber,
    String? licenseNumber,
    double? pendingCashInHand,
    double? totalCashSettled,
    bool? isApproved,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      shopName: shopName ?? this.shopName,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      addedBySalesmanId: addedBySalesmanId ?? this.addedBySalesmanId,
      addedBySalesmanName: addedBySalesmanName ?? this.addedBySalesmanName,
      creditLimit: creditLimit ?? this.creditLimit,
      outstandingDue: outstandingDue ?? this.outstandingDue,
      minOrderLimit: minOrderLimit ?? this.minOrderLimit,
      commissionRate: commissionRate ?? this.commissionRate,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      pendingCashInHand: pendingCashInHand ?? this.pendingCashInHand,
      totalCashSettled: totalCashSettled ?? this.totalCashSettled,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
