import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  UserModel? _selectedMerchant; // Used by Salesman placing orders for Kirana shopkeeper
  PaymentType _paymentType = PaymentType.cod;
  String _notes = '';
  double _discount = 0.0;

  Map<String, CartItem> get items => {..._items};
  List<CartItem> get itemList => _items.values.toList();
  UserModel? get selectedMerchant => _selectedMerchant;
  PaymentType get paymentType => _paymentType;
  String get notes => _notes;
  double get discount => _discount;

  int get itemCount => _items.length;

  int get totalUnits => _items.values.fold(0, (sum, item) => sum + item.quantity);

  // Total taxable base amount (Extracted from inclusive GST wholesale prices)
  double get taxableAmount => _items.values.fold(0.0, (sum, item) => sum + (item.totalItemPrice - item.gstAmount));

  // SubTotal alias (Total with GST)
  double get subTotal => _items.values.fold(0.0, (sum, item) => sum + item.totalItemPrice);

  // Total GST calculation (Included inside wholesale price)
  double get totalGst => _items.values.fold(0.0, (sum, item) => sum + item.gstAmount);

  // CGST (50% of total GST for intra-state Rajasthan supply)
  double get cgst => totalGst / 2.0;

  // SGST (50% of total GST for intra-state Rajasthan supply)
  double get sgst => totalGst / 2.0;

  // Retail MRP total
  double get totalMrp => _items.values.fold(0.0, (sum, item) => sum + (item.mrp * item.quantity));

  // Savings / Retail Margin for shopkeeper (Retail MRP vs Grand Total)
  double get totalSavings => (totalMrp > grandTotal) ? totalMrp - grandTotal : 0.0;

  // Bulk Tier Volume Discount savings
  double get totalVolumeSavings =>
      _items.values.fold(0.0, (sum, item) => sum + item.volumeSavings);

  // Final Net Invoice Grand Total (Wholesale rate is ALREADY inclusive of GST)
  double get grandTotal {
    final net = subTotal - _discount;
    return net > 0 ? net : 0.0;
  }

  bool get isEmpty => _items.isEmpty;

  bool containsProduct(String productId) => _items.containsKey(productId);

  int getProductQuantity(String productId) => _items[productId]?.quantity ?? 0;

  // Add item with MOQ enforcement & GST-inclusive pricing
  void addItem(ProductModel product, {int? quantity}) {
    final moq = product.moq > 0 ? product.moq : 1;
    final int qtyToAdd = quantity ?? moq;

    if (_items.containsKey(product.id)) {
      final currentQty = _items[product.id]!.quantity;
      final newQty = (currentQty + (quantity ?? 1))
          .clamp(moq, product.stockQuantity > 0 ? product.stockQuantity : 9999);
      final double effectiveRate = product.getPriceForQuantity(newQty);
      final double totalLinePrice = effectiveRate * newQty;
      final double taxableBase = totalLinePrice / (1.0 + (product.gstRate / 100.0));
      final double gstForLine = totalLinePrice - taxableBase;

      _items[product.id] = _items[product.id]!.copyWith(
        quantity: newQty,
        originalUnitPrice: product.wholesalePrice,
        unitPrice: effectiveRate,
        gstAmount: gstForLine,
        totalItemPrice: totalLinePrice,
      );
    } else {
      final int finalQty = qtyToAdd < moq ? moq : qtyToAdd;
      final double effectiveRate = product.getPriceForQuantity(finalQty);
      final double totalLinePrice = effectiveRate * finalQty;
      final double taxableBase = totalLinePrice / (1.0 + (product.gstRate / 100.0));
      final double gstForLine = totalLinePrice - taxableBase;

      _items[product.id] = CartItem(
        productId: product.id,
        productName: product.name,
        hindiName: product.hindiName,
        hsnCode: product.hsnCode,
        unit: product.unit,
        quantity: finalQty,
        unitMultiplier: product.unitMultiplier,
        originalUnitPrice: product.wholesalePrice,
        unitPrice: effectiveRate,
        gstRate: product.gstRate,
        gstAmount: gstForLine,
        totalItemPrice: totalLinePrice,
        mrp: product.mrp,
        imageUrl: product.imageUrl,
      );
    }
    notifyListeners();
  }

  // Increment item quantity with live slab calculation
  void increment(ProductModel product) {
    if (_items.containsKey(product.id)) {
      final currentQty = _items[product.id]!.quantity;
      if (product.stockQuantity > 0 && currentQty >= product.stockQuantity) {
        return; // Stock limit reached
      }
      final newQty = currentQty + 1;
      final double effectiveRate = product.getPriceForQuantity(newQty);
      final double totalLinePrice = effectiveRate * newQty;
      final double taxableBase = totalLinePrice / (1.0 + (product.gstRate / 100.0));
      final double gstForLine = totalLinePrice - taxableBase;

      _items[product.id] = _items[product.id]!.copyWith(
        quantity: newQty,
        originalUnitPrice: product.wholesalePrice,
        unitPrice: effectiveRate,
        gstAmount: gstForLine,
        totalItemPrice: totalLinePrice,
      );
      notifyListeners();
    } else {
      addItem(product);
    }
  }

  // Decrement item quantity respecting MOQ and updating slab
  void decrement(ProductModel product) {
    if (!_items.containsKey(product.id)) return;

    final currentQty = _items[product.id]!.quantity;
    final moq = product.moq > 0 ? product.moq : 1;

    if (currentQty <= moq) {
      removeItem(product.id);
    } else {
      final newQty = currentQty - 1;
      final double effectiveRate = product.getPriceForQuantity(newQty);
      final double totalLinePrice = effectiveRate * newQty;
      final double taxableBase = totalLinePrice / (1.0 + (product.gstRate / 100.0));
      final double gstForLine = totalLinePrice - taxableBase;

      _items[product.id] = _items[product.id]!.copyWith(
        quantity: newQty,
        originalUnitPrice: product.wholesalePrice,
        unitPrice: effectiveRate,
        gstAmount: gstForLine,
        totalItemPrice: totalLinePrice,
      );
      notifyListeners();
    }
  }

  // Update specific quantity with optional product tier calculation
  void updateQuantity(
    String productId,
    int newQuantity, {
    int moq = 1,
    int maxStock = 9999,
    double rate = 0,
    double gstRate = 5,
    ProductModel? product,
  }) {
    if (!_items.containsKey(productId)) return;

    if (newQuantity <= 0 || newQuantity < moq) {
      _items.remove(productId);
    } else {
      final finalQty = newQuantity > maxStock ? maxStock : newQuantity;
      final item = _items[productId]!;
      final double effectiveRate = product != null
          ? product.getPriceForQuantity(finalQty)
          : (rate > 0 ? rate : item.unitPrice);
      final double baseRate =
          product?.wholesalePrice ?? item.originalUnitPrice;
      final effectiveGstRate = gstRate > 0 ? gstRate : item.gstRate;
      final double totalLinePrice = effectiveRate * finalQty;
      final double taxableBase = totalLinePrice / (1.0 + (effectiveGstRate / 100.0));
      final double gstForLine = totalLinePrice - taxableBase;

      _items[productId] = item.copyWith(
        quantity: finalQty,
        originalUnitPrice: baseRate,
        unitPrice: effectiveRate,
        gstRate: effectiveGstRate,
        gstAmount: gstForLine,
        totalItemPrice: totalLinePrice,
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _discount = 0.0;
    _notes = '';
    _selectedMerchant = null;
    _paymentType = PaymentType.cod;
    notifyListeners();
  }

  void setSelectedMerchant(UserModel? merchant) {
    _selectedMerchant = merchant;
    notifyListeners();
  }

  void setPaymentType(PaymentType type) {
    _paymentType = type;
    notifyListeners();
  }

  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  void setDiscount(double discount) {
    _discount = discount;
    notifyListeners();
  }
}
