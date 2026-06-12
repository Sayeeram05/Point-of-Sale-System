import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/WOFL_theme.dart';
import '../widgets/widgets.dart';
import '../models/category.dart' as models;
import '../models/product.dart';
import '../providers/providers.dart';

/// Product Management screen - main focus of the application
/// Displays categories and products with full CRUD functionality
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WOFLTheme.background,
      body: Consumer2<CategoryProvider, ProductProvider>(
        builder: (context, categoryProvider, productProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(WOFLTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(categoryProvider, productProvider),
                const SizedBox(height: WOFLTheme.spacingXL),
                if (categoryProvider.isLoading || productProvider.isLoading)
                  _buildLoadingState()
                else if (categoryProvider.hasError || productProvider.hasError)
                  _buildErrorState(categoryProvider.error ?? productProvider.error ?? 'Unknown error')
                else
                  _buildCategoriesGrid(categoryProvider.categories, productProvider.productsByCategory),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(CategoryProvider categoryProvider, ProductProvider productProvider) {
    return Row(
      children: [
        Expanded(
          child: WOFLCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [WOFLTheme.primary, WOFLTheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: WOFLTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Management',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: WOFLTheme.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: WOFLTheme.spacingXS),
                          Text(
                            'Manage WOFL categories and products efficiently',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: WOFLTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WOFLTheme.spacingL),
                Row(
                  children: [
                    WOFLButton(
                      text: 'Add Category',
                      icon: Icons.add,
                      onPressed: _showAddCategoryDialog,
                    ),
                    const SizedBox(width: WOFLTheme.spacingM),
                    WOFLButton(
                      text: 'Refresh',
                      icon: Icons.refresh,
                      type: WOFLButtonType.outline,
                      onPressed: () => _refreshData(categoryProvider, productProvider),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: WOFLTheme.spacingL),
        _buildStatsCard(categoryProvider.categories, productProvider.productsByCategory),
      ],
    );
  }

  Widget _buildStatsCard(List<models.Category> categories, Map<String, List<Product>> productsByCategory) {
    final totalProducts = productsByCategory.values
        .fold<int>(0, (sum, products) => sum + products.length);
    
    return WOFLCard(
      width: 200,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: WOFLTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.analytics_outlined,
                color: WOFLTheme.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: WOFLTheme.spacingL),
          _buildStatItem('Categories', categories.length.toString()),
          const SizedBox(height: WOFLTheme.spacingM),
          _buildStatItem('Products', totalProducts.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: WOFLTheme.textLight,
            fontSize: 14,
          ),
        ),
        WOFLBadge.count(int.tryParse(value) ?? 0, isSmall: true),
      ],
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: WOFLTheme.spacingL,
        mainAxisSpacing: WOFLTheme.spacingL,
        childAspectRatio: 0.8,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => _buildLoadingSkeleton(),
    );
  }

  Widget _buildLoadingSkeleton() {
    return WOFLCard(
      enableHover: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: WOFLTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: WOFLTheme.spacingM),
          Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: WOFLTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: WOFLTheme.spacingL),
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: WOFLTheme.spacingS),
            child: Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: WOFLTheme.border.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return WOFLCard(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: WOFLTheme.error,
            size: 48,
          ),
          const SizedBox(height: WOFLTheme.spacingM),
          Text(
            'Failed to load data',
            style: TextStyle(
              color: WOFLTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: WOFLTheme.spacingS),
          Text(
            error,
            style: TextStyle(
              color: WOFLTheme.textLight,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WOFLTheme.spacingL),
          WOFLButton(
            text: 'Retry',
            icon: Icons.refresh,
            onPressed: () {
              context.read<CategoryProvider>().refresh();
              context.read<ProductProvider>().refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(List<models.Category> categories, Map<String, List<Product>> productsByCategory) {
    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: WOFLTheme.spacingL,
        mainAxisSpacing: WOFLTheme.spacingL,
        childAspectRatio: 0.8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final products = productsByCategory[category.id] ?? [];
        return _buildCategoryCard(category, products);
      },
    );
  }

  Widget _buildEmptyState() {
    return WOFLCard(
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            color: WOFLTheme.textLight,
            size: 64,
          ),
          const SizedBox(height: WOFLTheme.spacingL),
          Text(
            'No categories found',
            style: TextStyle(
              color: WOFLTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: WOFLTheme.spacingS),
          Text(
            'Start by adding your first WOFL category',
            style: TextStyle(
              color: WOFLTheme.textLight,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: WOFLTheme.spacingL),
          WOFLButton(
            text: 'Add Category',
            icon: Icons.add,
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(models.Category category, List<Product> products) {
    return WOFLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                category.iconData,
                color: WOFLTheme.primary,
                size: 24,
              ),
              const SizedBox(width: WOFLTheme.spacingS),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: WOFLTheme.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              WOFLBadge.count(products.length, isSmall: true),
              const SizedBox(width: WOFLTheme.spacingS),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: WOFLTheme.textLight,
                  size: 20,
                ),
                onSelected: (value) => _handleCategoryAction(value, category),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_product',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 8),
                        Text('Add Product'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit Category'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: WOFLTheme.spacingL),
          Expanded(
            child: products.isEmpty
                ? _buildEmptyProductList(category)
                : _buildProductList(products),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProductList(models.Category category) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.restaurant_outlined,
          color: WOFLTheme.textLight,
          size: 32,
        ),
        const SizedBox(height: WOFLTheme.spacingS),
        Text(
          'No products yet',
          style: TextStyle(
            color: WOFLTheme.textLight,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(List<Product> products) {
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: WOFLTheme.spacingS),
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductItem(product);
      },
    );
  }

  Widget _buildProductItem(Product product) {
    return Container(
      padding: const EdgeInsets.all(WOFLTheme.spacingS),
      decoration: BoxDecoration(
        color: WOFLTheme.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WOFLTheme.border.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: product.isAvailable ? WOFLTheme.success : WOFLTheme.error,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: WOFLTheme.spacingS),
          Expanded(
            child: Text(
              product.name,
              style: TextStyle(
                color: WOFLTheme.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          WOFLBadge.price(product.price, isSmall: true),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: WOFLTheme.textLight, size: 16),
            padding: EdgeInsets.zero,
            onSelected: (value) => _handleProductAction(value, product),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit Product'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  void _refreshData(CategoryProvider categoryProvider, ProductProvider productProvider) {
    categoryProvider.refresh();
    productProvider.refresh();
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddCategoryDialog(),
    );
  }

  void _handleCategoryAction(String action, models.Category category) {
    switch (action) {
      case 'add_product':
        _showAddProductDialog(category);
        break;
      case 'edit':
        _showEditCategoryDialog(category);
        break;
      case 'delete':
        _showDeleteCategoryDialog(category);
        break;
    }
  }

  void _showAddProductDialog(models.Category category) {
    showDialog(
      context: context,
      builder: (context) => _AddProductDialog(category: category),
    );
  }

  void _handleProductAction(String action, Product product) {
    switch (action) {
      case 'edit':
        _showEditProductDialog(product);
        break;
      case 'delete':
        _showDeleteProductDialog(product);
        break;
    }
  }

  void _showEditProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => _EditProductDialog(product: product),
    );
  }

  void _showDeleteProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => _DeleteProductDialog(product: product),
    );
  }

  void _showEditCategoryDialog(models.Category category) {
    showDialog(
      context: context,
      builder: (context) => _EditCategoryDialog(category: category),
    );
  }

  void _showDeleteCategoryDialog(models.Category category) {
    showDialog(
      context: context,
      builder: (context) => _DeleteCategoryDialog(category: category),
    );
  }
}

// CRUD Dialog Widgets

class _AddCategoryDialog extends StatefulWidget {
  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Classic WOFLs',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCategory,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = models.CategoryRequest(
      name: _nameController.text.trim(),
      icon: 'restaurant', // Default icon
    );

    final success = await context.read<CategoryProvider>().createCategory(request);

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category created successfully!')),
        );
        // Refresh products to update counts
        context.read<ProductProvider>().refresh();
      } else {
        final error = context.read<CategoryProvider>().error ?? 'Failed to create category';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }
}

class _EditCategoryDialog extends StatefulWidget {
  final models.Category category;

  const _EditCategoryDialog({required this.category});

  @override
  State<_EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<_EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateCategory,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = models.CategoryRequest(
      name: _nameController.text.trim(),
      icon: widget.category.icon,
    );

    final success = await context.read<CategoryProvider>().updateCategory(widget.category.id, request);

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully!')),
        );
      } else {
        final error = context.read<CategoryProvider>().error ?? 'Failed to update category';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }
}

class _DeleteCategoryDialog extends StatefulWidget {
  final models.Category category;

  const _DeleteCategoryDialog({required this.category});

  @override
  State<_DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<_DeleteCategoryDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to delete "${widget.category.name}"?'),
          const SizedBox(height: 8),
          const Text(
            'This action cannot be undone and will also delete all products in this category.',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _deleteCategory,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _deleteCategory() async {
    setState(() => _isLoading = true);

    final success = await context.read<CategoryProvider>().deleteCategory(widget.category.id);

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully!')),
        );
        // Refresh products to update the list
        context.read<ProductProvider>().refresh();
      } else {
        final error = context.read<CategoryProvider>().error ?? 'Failed to delete category';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }
}

class _AddProductDialog extends StatefulWidget {
  final models.Category category;

  const _AddProductDialog({required this.category});

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageFileName = picked.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Product to ${widget.category.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g., Belgian Classic',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  hintText: 'e.g., 120.00',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Tap to upload image', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createProduct,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = ProductRequest(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      categoryId: widget.category.id,
      isAvailable: true,
      imageBytes: _imageBytes,
      imageFileName: _imageFileName,
    );

    final success = await context.read<ProductProvider>().createProduct(request);

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product created successfully!')),
        );
      } else {
        final error = context.read<ProductProvider>().error ?? 'Failed to create product';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }
}

class _EditProductDialog extends StatefulWidget {
  final Product product;

  const _EditProductDialog({required this.product});

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late bool _isAvailable;
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _isAvailable = widget.product.isAvailable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageFileName = picked.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final existingImageUrl = widget.product.imageUrl;
    return AlertDialog(
      title: const Text('Edit Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (₹)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Available'),
                  const Spacer(),
                  Switch(
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : existingImageUrl != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(existingImageUrl, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Tap to change', style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('Tap to upload image', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateProduct,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = ProductRequest(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      categoryId: widget.product.categoryId,
      description: widget.product.description,
      imageUrl: widget.product.imageUrl,
      isAvailable: _isAvailable,
      imageBytes: _imageBytes,
      imageFileName: _imageFileName,
    );

    final success = await context.read<ProductProvider>().updateProduct(widget.product.id, request);

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!')),
        );
      } else {
        final error = context.read<ProductProvider>().error ?? 'Failed to update product';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }
}

class _DeleteProductDialog extends StatefulWidget {
  final Product product;

  const _DeleteProductDialog({required this.product});

  @override
  State<_DeleteProductDialog> createState() => _DeleteProductDialogState();
}

class _DeleteProductDialogState extends State<_DeleteProductDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Product'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to delete "${widget.product.name}"?'),
          const SizedBox(height: 8),
          const Text(
            'This action cannot be undone.',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _deleteProduct,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _deleteProduct() async {
    setState(() => _isLoading = true);

    final success = await context.read<ProductProvider>().deleteProduct(widget.product.id);

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
      } else {
        final error = context.read<ProductProvider>().error ?? 'Failed to delete product';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }
}