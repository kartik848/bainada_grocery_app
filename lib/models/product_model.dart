class PriceTier {
  final int minQty;
  final int? maxQty; // null means 'and above' (e.g. 10+)
  final double rate;

  const PriceTier({
    required this.minQty,
    this.maxQty,
    required this.rate,
  });

  factory PriceTier.fromMap(Map<String, dynamic> map) {
    return PriceTier(
      minQty: (map['minQty'] as num?)?.toInt() ?? 1,
      maxQty: (map['maxQty'] as num?)?.toInt(),
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minQty': minQty,
      if (maxQty != null) 'maxQty': maxQty,
      'rate': rate,
    };
  }

  String get label {
    if (maxQty == null) {
      return '$minQty+ units';
    }
    return '$minQty-$maxQty units';
  }
}

class ProductModel {
  final String id;
  final String name;
  final String? hindiName;
  final String category;
  final String? subCategory;
  final String hsnCode;
  final double wholesalePrice; // Base price excluding GST
  final double mrp;
  final double gstRate; // 0, 5, 12, 18
  final int moq; // Minimum Order Quantity
  final String unit; // kg, bag, cartoon, peti, liter, etc.
  final int unitMultiplier; // Packaging factor (e.g. 1 Carton = 24 pcs, 1 Bag = 50kg)
  final int stockQuantity;
  final String? imageUrl; // Hostinger image link or cloud URL
  final bool isAvailable;
  final List<PriceTier> tierPricing; // Bulk slab pricing

  const ProductModel({
    required this.id,
    required this.name,
    this.hindiName,
    required this.category,
    this.subCategory,
    this.hsnCode = '1006',
    required this.wholesalePrice,
    required this.mrp,
    this.gstRate = 5.0,
    this.moq = 1,
    required this.unit,
    this.unitMultiplier = 1,
    this.stockQuantity = 0,
    this.imageUrl,
    this.isAvailable = true,
    this.tierPricing = const [],
  });

  // Calculate rate based on ordered volume / slabs
  double getPriceForQuantity(int qty) {
    if (tierPricing.isEmpty) return wholesalePrice;

    for (final tier in tierPricing) {
      if (qty >= tier.minQty && (tier.maxQty == null || qty <= tier.maxQty!)) {
        return tier.rate;
      }
    }
    return wholesalePrice;
  }

  // Find lowest tier rate for bulk discount banner
  PriceTier? get bestVolumeTier {
    if (tierPricing.isEmpty) return null;
    PriceTier? best;
    for (final tier in tierPricing) {
      if (tier.rate < wholesalePrice) {
        if (best == null || tier.rate < best.rate) {
          best = tier;
        }
      }
    }
    return best;
  }

  // Total units packed per order item (e.g. 5 Cartons * 24 pcs = 120 individual pieces)
  int calculateTotalPieces(int orderQuantity) => orderQuantity * unitMultiplier;

  // Calculate GST amount per unit
  double get unitGstAmount => wholesalePrice * (gstRate / 100.0);

  // Unit price inclusive of GST
  double get unitPriceWithGst => wholesalePrice + unitGstAmount;

  // Margin for merchant (Kirana profit margin)
  double get profitMargin => mrp > wholesalePrice ? mrp - wholesalePrice : 0.0;

  double get marginPercentage =>
      mrp > 0 ? ((mrp - wholesalePrice) / mrp * 100).clamp(0.0, 100.0) : 0.0;

  bool get isOutOfStock => stockQuantity <= 0 || !isAvailable;

  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 15;

  factory ProductModel.fromMap(Map<String, dynamic> map, [String? id]) {
    final rawTiers = map['tierPricing'];
    List<PriceTier> tiers = [];
    if (rawTiers is List) {
      for (final item in rawTiers) {
        if (item is Map) {
          tiers.add(PriceTier.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return ProductModel(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      hindiName: map['hindiName'],
      category: map['category'] ?? 'General',
      subCategory: map['subCategory'],
      hsnCode: map['hsnCode'] ?? '1006',
      wholesalePrice: (map['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      gstRate: (map['gstRate'] as num?)?.toDouble() ?? 5.0,
      moq: (map['moq'] as num?)?.toInt() ?? 1,
      unit: map['unit'] ?? 'kg',
      unitMultiplier: (map['unitMultiplier'] as num?)?.toInt() ?? 1,
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'],
      isAvailable: map['isAvailable'] ?? true,
      tierPricing: tiers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hindiName': hindiName,
      'category': category,
      'subCategory': subCategory,
      'hsnCode': hsnCode,
      'wholesalePrice': wholesalePrice,
      'mrp': mrp,
      'gstRate': gstRate,
      'moq': moq,
      'unit': unit,
      'unitMultiplier': unitMultiplier,
      'stockQuantity': stockQuantity,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'tierPricing': tierPricing.map((t) => t.toMap()).toList(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? hindiName,
    String? category,
    String? subCategory,
    String? hsnCode,
    double? wholesalePrice,
    double? mrp,
    double? gstRate,
    int? moq,
    String? unit,
    int? unitMultiplier,
    int? stockQuantity,
    String? imageUrl,
    bool? isAvailable,
    List<PriceTier>? tierPricing,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      hindiName: hindiName ?? this.hindiName,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      hsnCode: hsnCode ?? this.hsnCode,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      mrp: mrp ?? this.mrp,
      gstRate: gstRate ?? this.gstRate,
      moq: moq ?? this.moq,
      unit: unit ?? this.unit,
      unitMultiplier: unitMultiplier ?? this.unitMultiplier,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      tierPricing: tierPricing ?? this.tierPricing,
    );
  }
}
