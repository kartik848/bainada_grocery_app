import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import 'add_product_modal.dart';

class EditProductDialog extends StatelessWidget {
  final ProductModel product;

  const EditProductDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return AddProductModal(productToEdit: product);
  }
}
