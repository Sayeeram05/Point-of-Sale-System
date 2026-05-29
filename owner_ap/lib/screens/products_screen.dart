import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/waffle_theme.dart';
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
      backgroundColor: WaffleTheme.background,
      body: Consumer2<CategoryProvider, ProductProvider>(
        builder: (context, categoryProvider, productProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(WaffleTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(categoryProvider, productProvider),
                const SizedBox(height: WaffleTheme.spacingXL),
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
          child: WaffleCard(
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
                          colors: [WaffleTheme.primary, WaffleTheme.secondary],
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
                    const SizedBox(width: WaffleTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Management',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: WaffleTheme.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: WaffleTheme.spacingXS),
                          Text(
                            'Manage waffle categories and products efficiently',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: WaffleTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WaffleTheme.spacingL),
                Row(
                  children: [
                    WaffleButton(
                      text: 'Add Category',
                      icon: Icons.add,
                      onPressed: _showAddCategoryDialog,
                    ),
                    const SizedBox(width: WaffleTheme.spacingM),
                    WaffleButton(
                      text: 'Refresh',
                      icon: Icons.refresh,
                      type: WaffleButtonType.outline,
                      onPressed: () => _refreshData(categoryProvider, productProvider),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: WaffleTheme.spacingL),
        _buildStatsCard(categoryProvider.categories, productProvider.productsByCategory),
      ],
    );
  }

  Widget _buildStatsCard(List<models.Category> categories, Map<String, List<Product>> productsByCategory) {
    final totalProducts = productsByCategory.values
        .fold<int>(0, (sum, products) => sum + products.length);
    
    return WaffleCard(
      width: 200,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: WaffleTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.analytics_outlined,
                color: WaffleTheme.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: WaffleTheme.spacingL),
          _buildStatItem('Categories', categories.length.toString()),
          const SizedBox(height: WaffleTheme.spacingM),
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
            color: WaffleTheme.textLight,
            fontSize: 14,
          ),
        ),
        WaffleBadge.count(int.tryParse(value) ?? 0, isSmall: true),
      ],
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: WaffleTheme.spacingL,
        mainAxisSpacing: WaffleTheme.spacingL,
        childAspectRatio: 0.8,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => _buildLoadingSkeleton(),
    );
  }

  Widget _buildLoadingSkeleton() {
    return WaffleCard(
      enableHover: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: WaffleTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingM),
          Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: WaffleTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingL),
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: WaffleTheme.spacingS),
            child: Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: WaffleTheme.border.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return WaffleCard(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: WaffleTheme.error,
            size: 48,
          ),
          const SizedBox(height: WaffleTheme.spacingM),
          Text(
            'Failed to load data',
            style: TextStyle(
              color: WaffleTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingS),
          Text(
            error,
            style: TextStyle(
              color: WaffleTheme.textLight,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WaffleTheme.spacingL),
          WaffleButton(
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
        crossAxisSpacing: WaffleTheme.spacingL,
        mainAxisSpacing: WaffleTheme.spacingL,
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
    return WaffleCard(
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            color: WaffleTheme.textLight,
            size: 64,
          ),
          const SizedBox(height: WaffleTheme.spacingL),
          Text(
            'No categories found',
            style: TextStyle(
              color: WaffleTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingS),
          Text(
            'Start by adding your first waffle category',
            style: TextStyle(
              color: WaffleTheme.textLight,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingL),
          WaffleButton(
            text: 'Add Category',
            icon: Icons.add,
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(models.Category category, List<Product> products) {
    return WaffleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                category.iconData,
                color: WaffleTheme.primary,
                size: 24,
              ),
              const SizedBox(width: WaffleTheme.spacingS),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: WaffleTheme.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              WaffleBadge.count(products.length, isSmall: true),
              const SizedBox(width: WaffleTheme.spacingS),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: WaffleTheme.textLight,
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
          const SizedBox(height: WaffleTheme.spacingL),
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
          color: WaffleTheme.textLight,
          size: 32,
        ),
        const SizedBox(height: WaffleTheme.spacingS),
        Text(
          'No products yet',
          style: TextStyle(
            color: WaffleTheme.textLight,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(List<Product> products) {
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: WaffleTheme.spacingS),
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductItem(product);
      },
    );
  }

  Widget _buildProductItem(Product product) {
    return Container(
      padding: const EdgeInsets.all(WaffleTheme.spacingS),
      decoration: BoxDecoration(
        color: WaffleTheme.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WaffleTheme.border.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: product.isAvailable ? WaffleTheme.success : WaffleTheme.error,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: WaffleTheme.spacingS),
          Expanded(
            child: Text(
              product.name,
              style: TextStyle(
                color: WaffleTheme.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          WaffleBadge.price(product.price, isSmall: true),
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
                hintText: 'e.g., Classic Waffles',
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
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Product to ${widget.category.name}'),
      content: Form(
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
          ],
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

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = ProductRequest(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      categoryId: widget.category.id,
      isAvailable: true,
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