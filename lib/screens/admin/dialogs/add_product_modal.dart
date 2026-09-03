import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../../services/image_upload_service.dart';
import '../../../utils/constants.dart';

class AddProductModal extends StatefulWidget {
  final ProductModel? productToEdit;

  const AddProductModal({super.key, this.productToEdit});

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _hindiCtrl;
  late TextEditingController _hsnCtrl;
  late TextEditingController _wholesalePriceCtrl;
  late TextEditingController _mrpCtrl;
  late TextEditingController _gstCtrl;
  late TextEditingController _moqCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _imageCtrl;
  late String _selectedCategory;
  late String _selectedUnit;

  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  String? _uploadStatusMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _hindiCtrl = TextEditingController(text: p?.hindiName ?? '');
    _hsnCtrl = TextEditingController(text: p?.hsnCode ?? '1006');
    _wholesalePriceCtrl = TextEditingController(
        text: p != null ? p.wholesalePrice.toString() : '');
    _mrpCtrl = TextEditingController(text: p != null ? p.mrp.toString() : '');
    _gstCtrl = TextEditingController(
      text: p != null
          ? (p.gstRate % 1 == 0
              ? p.gstRate.toInt().toString()
              : p.gstRate.toString())
          : '5',
    );
    _moqCtrl = TextEditingController(text: p?.moq.toString() ?? '1');
    _stockCtrl =
        TextEditingController(text: p?.stockQuantity.toString() ?? '100');
    _imageCtrl = TextEditingController(text: p?.imageUrl ?? '');
    _selectedCategory = p?.category ?? AppConstants.productCategories[1];
    _selectedUnit = p?.unit ?? AppConstants.packagingUnits[0];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hindiCtrl.dispose();
    _hsnCtrl.dispose();
    _wholesalePriceCtrl.dispose();
    _mrpCtrl.dispose();
    _gstCtrl.dispose();
    _moqCtrl.dispose();
    _stockCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final isEditing = widget.productToEdit != null;
    final double gstRate = double.tryParse(_gstCtrl.text.trim()) ?? 5.0;

    final product = ProductModel(
      id: widget.productToEdit?.id ?? '',
      name: _nameCtrl.text.trim(),
      hindiName:
          _hindiCtrl.text.trim().isNotEmpty ? _hindiCtrl.text.trim() : null,
      category: _selectedCategory,
      hsnCode: _hsnCtrl.text.trim(),
      wholesalePrice: double.tryParse(_wholesalePriceCtrl.text.trim()) ?? 0.0,
      mrp: double.tryParse(_mrpCtrl.text.trim()) ?? 0.0,
      gstRate: gstRate,
      moq: int.tryParse(_moqCtrl.text.trim()) ?? 1,
      unit: _selectedUnit,
      stockQuantity: int.tryParse(_stockCtrl.text.trim()) ?? 0,
      imageUrl:
          _imageCtrl.text.trim().isNotEmpty ? _imageCtrl.text.trim() : null,
      isAvailable: true,
      tierPricing: widget.productToEdit?.tierPricing ?? const [],
    );

    final productProv = Provider.of<ProductProvider>(context, listen: false);
    if (isEditing) {
      await productProv.updateProduct(product);
    } else {
      await productProv.addProduct(product);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Updated "${product.name}"'
              : 'Added "${product.name}" to catalog!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;
    final productProvider = Provider.of<ProductProvider>(context);
    final categoriesList = List<String>.from(productProvider.rawCategories);
    if (!categoriesList.contains(_selectedCategory) && _selectedCategory.isNotEmpty) {
      categoriesList.insert(0, _selectedCategory);
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing
                    ? 'Edit Wholesale Product'
                    : 'Add New Wholesale Product',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Product Name (English)*',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _hindiCtrl,
                decoration: const InputDecoration(
                    labelText: 'Product Name (Hindi)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                          tooltip: 'Add new category',
                          onPressed: () => _showAddCategoryDialog(context),
                        ),
                      ),
                      items: categoriesList
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                  style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(
                          labelText: 'Unit', border: OutlineInputBorder()),
                      items: AppConstants.packagingUnits
                          .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u,
                                  style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hsnCtrl,
                      decoration: const InputDecoration(
                          labelText: 'HSN Code*', border: OutlineInputBorder()),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter HSN' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _gstCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'GST Rate Percentage (%) / जीएसटी दर (%)*',
                        hintText: 'e.g. 0, 5, 12, 18, 28',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final g = double.tryParse(v?.trim() ?? '');
                        if (g == null || g < 0) return 'Enter valid GST %';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _wholesalePriceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Wholesale Base Price (₹)*',
                          prefixText: '₹ ',
                          border: OutlineInputBorder()),
                      validator: (v) {
                        final p = double.tryParse(v?.trim() ?? '');
                        if (p == null || p <= 0) return 'Enter price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _mrpCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'MRP (₹)*',
                          prefixText: '₹ ',
                          border: OutlineInputBorder()),
                      validator: (v) {
                        final m = double.tryParse(v?.trim() ?? '');
                        if (m == null || m <= 0) return 'Enter MRP';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _moqCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Min Order Qty (MOQ)*',
                          border: OutlineInputBorder()),
                      validator: (v) {
                        final q = int.tryParse(v?.trim() ?? '');
                        if (q == null || q <= 0) return 'Enter MOQ';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Stock Units*',
                          border: OutlineInputBorder()),
                      validator: (v) {
                        final s = int.tryParse(v?.trim() ?? '');
                        if (s == null || s < 0) return 'Enter stock';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              // ImgBB Cloud Photo Upload Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBE7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC5E1A5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_upload_rounded,
                            color: Color(0xFF33691E), size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Product Photo (ImgBB Cloud Direct)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF33691E)),
                          ),
                        ),
                        if (_imageCtrl.text.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('✓ Attached',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Upload Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _isUploadingImage
                            ? null
                            : () async {
                                setState(() {
                                  _isUploadingImage = true;
                                  _uploadStatusMessage = null;
                                });
                                final url = await ImageUploadService
                                    .pickAndUploadImage();
                                if (!mounted) return;
                                setState(() {
                                  _isUploadingImage = false;
                                  if (url != null && url.isNotEmpty) {
                                    _imageCtrl.text = url;
                                    _uploadStatusMessage =
                                        'Image uploaded successfully! ✓';
                                  } else {
                                    _uploadStatusMessage =
                                        'Upload cancelled or failed.';
                                  }
                                });
                              },
                        icon: _isUploadingImage
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.add_a_photo_rounded, size: 18),
                        label: Text(
                          _isUploadingImage
                              ? 'Uploading photo to cloud...'
                              : '📷 Upload Product Photo / फोटो अपलोड करें',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF558B2F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),

                    if (_uploadStatusMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _uploadStatusMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _uploadStatusMessage!.contains('✓')
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ],

                    if (_imageCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              _imageCtrl.text,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image,
                                    size: 24, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _imageCtrl.text,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _imageCtrl.clear()),
                                  style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 24)),
                                  child: const Text('Remove Photo',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _imageCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 11),
                      decoration: const InputDecoration(
                        labelText: 'Or Paste Direct Image Link (Optional)',
                        hintText: 'https://i.ibb.co/...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: Text(
                    isEditing ? 'Update Product' : 'Add to Catalog',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final catCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Category / नई श्रेणी',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: catCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Dry Fruits, Pooja Items, etc.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = catCtrl.text.trim();
              if (val.isEmpty) return;
              final p = Provider.of<ProductProvider>(context, listen: false);
              await p.addCategory(val);
              setState(() => _selectedCategory = val);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add & Select'),
          ),
        ],
      ),
    );
  }
}
