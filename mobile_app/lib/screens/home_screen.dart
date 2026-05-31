import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/pos_widgets.dart';
import '../models/menu.dart';

class HomePage extends StatefulWidget {
  final void Function(ProductData) onAddToCart;
  final List<CartItemModel> cartItems;

  const HomePage({
    super.key,
    required this.onAddToCart,
    required this.cartItems,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedCategory = 0;
  bool isLoading = true;
  String? errorMessage;
  List<CategoryData> categories = [];
  List<ProductData> products = [];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      final menu = await ApiService.getMenu();
      final allCategories = menu.allIceStickCategories;

      final builtCategories = [
        const CategoryData(id: 0, label: 'All', icon: Icons.grid_view_rounded),
        ...allCategories.map(
          (category) => CategoryData(
            id: category.categoryId,
            label: category.name,
            icon: _iconForCategory(category.name),
          ),
        ),
      ];

      final builtProducts = allCategories
          .expand(
            (category) => category.products.map((product) {
              final parsedId = int.tryParse(product.productId);
              return ProductData(
                id: parsedId,
                categoryId: category.categoryId,
                name: product.name,
                price: product.priceDouble,
                color: _colorForProduct(parsedId ?? 0),
              );
            }),
          )
          .toList();

      setState(() {
        categories = builtCategories;
        products = builtProducts;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  IconData _iconForCategory(String name) {
    final key = name.toLowerCase();
    if (key.contains('waffle')) {
      return Icons.emoji_food_beverage_rounded;
    }
    if (key.contains('pancake')) {
      return Icons.cake_rounded;
    }
    if (key.contains('drink')) {
      return Icons.local_cafe_rounded;
    }
    if (key.contains('dessert')) {
      return Icons.icecream_rounded;
    }
    return Icons.local_dining_rounded;
  }

  Color _colorForProduct(int id) {
    switch (id % 4) {
      case 1:
        return const Color(0xFFFDE3C2);
      case 2:
        return const Color(0xFFE9D7C1);
      case 3:
        return const Color(0xFFFFF0D7);
      default:
        return const Color(0xFFDAD4E5);
    }
  }

  List<ProductData> get _visibleProducts {
    if (selectedCategory == 0) {
      return products;
    }
    return products.where((p) => p.categoryId == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFE67E22)),
        ),
      );
    }

    if (errorMessage != null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFFD23E3E)),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: hook this to your complete order flow
                    },
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: Color(0xFFE67E22),
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryChip(
                    data: category,
                    isSelected: selectedCategory == category.id,
                    onTap: () => setState(() {
                      selectedCategory = category.id;
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 26),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Waffles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2B1A00),
                  ),
                ),
                Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE67E22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_visibleProducts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    'No products found for this category.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF8B4513)),
                  ),
                ),
              )
            else
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.75,
                ),
                itemCount: _visibleProducts.length,
                itemBuilder: (context, index) {
                  final item = _visibleProducts[index];
                  final cartItem = widget.cartItems
                      .where((c) => c.id == item.id)
                      .toList();
                  final quantity = cartItem.isNotEmpty
                      ? cartItem.first.quantity
                      : 0;
                  return ProductCard(
                    product: item,
                    quantity: quantity,
                    onAdd: () => widget.onAddToCart(item),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
