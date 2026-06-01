import 'package:flutter/material.dart';
import '../models/waffle_product_model.dart';
import '../themes/waffle_theme.dart';

class WaffleProductCard extends StatelessWidget {
  final WaffleProduct product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const WaffleProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: WaffleTheme.secondaryColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Icon(
                  Icons.local_cafe,
                  size: 46,
                  color: WaffleTheme.accentColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: WaffleTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: WaffleTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            quantity == 0
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WaffleTheme.primaryColor,
                      ),
                      child: const Text('Add'),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: WaffleTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: onDecrease,
                              icon: const Icon(Icons.remove),
                              splashRadius: 18,
                              padding: EdgeInsets.zero,
                            ),
                            Text(
                              quantity.toString(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              onPressed: onIncrease,
                              icon: const Icon(Icons.add),
                              splashRadius: 18,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_shopping_cart),
                        color: WaffleTheme.primaryColor,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
