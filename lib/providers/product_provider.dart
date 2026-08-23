import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

class ProductProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<ProductModel>>? _productsSubscription;

  List<ProductModel> _allProducts = [];
  String _selectedCategory = 'All Categories';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  List<ProductModel> get allProducts => _allProducts;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered products based on category and search query
  List<ProductModel> get filteredProducts {
    return _allProducts.where((product) {
      final matchesCategory = _selectedCategory == 'All Categories' ||
          product.category.toLowerCase() == _selectedCategory.toLowerCase();

      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          (product.hindiName != null &&
              product.hindiName!.toLowerCase().contains(query)) ||
          product.category.toLowerCase().contains(query) ||
          product.hsnCode.contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Low stock products
  List<ProductModel> get lowStockProducts =>
      _allProducts.where((p) => p.isLowStock || p.isOutOfStock).toList();

  int get lowStockCount => lowStockProducts.length;

  ProductProvider() {
    _initProducts();
  }

  void _initProducts() {
    _isLoading = true;
    notifyListeners();

    _productsSubscription?.cancel();
    _productsSubscription = FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList(),
        )
        .listen(
      (products) {
        _allProducts = products;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _allProducts = [];
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = 'All Categories';
    _searchQuery = '';
    notifyListeners();
  }

  Future<bool> addProduct(ProductModel product) async {
    try {
      await _firestoreService.addProduct(product);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _firestoreService.updateProduct(product);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWholesalePrice(String productId, double newPrice) async {
    try {
      await _firestoreService.updateWholesalePrice(productId, newPrice);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _firestoreService.deleteProduct(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateStock(String id, int delta) async {
    try {
      await _firestoreService.updateProductStock(id, delta);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePrice(String id, double newPrice) async {
    try {
      final product = findById(id);
      if (product != null) {
        await updateProduct(product.copyWith(wholesalePrice: newPrice));
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  ProductModel? findById(String id) {
    try {
      return _allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }
}
