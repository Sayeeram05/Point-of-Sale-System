import 'package:flutter/material.dart';



class CategoryData {

  final int id;

  final String label;

  final IconData icon;



  const CategoryData({

    required this.id,

    required this.label,

    required this.icon,

  });

}



class ProductData {

  final int? id;

  final int? categoryId;

  final String name;

  final double price;

  final Color color;



  const ProductData({

    this.id,

    this.categoryId,

    required this.name,

    required this.price,

    required this.color,

  });



  String get priceLabel => '₹${price.toStringAsFixed(0)}';

}



class CategoryChip extends StatelessWidget {

  final CategoryData data;

  final bool isSelected;

  final VoidCallback onTap;



  const CategoryChip({

    super.key,

    required this.data,

    required this.isSelected,

    required this.onTap,

  });



  @override

  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: AnimatedContainer(

        duration: const Duration(milliseconds: 180),

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

        decoration: BoxDecoration(

          color: isSelected ? const Color(0xFFFFF0E0) : Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: const Color(0xFFF2DFD0)),

          boxShadow: isSelected

              ? [

                  BoxShadow(

                    color: Colors.black.withOpacity(0.04),

                    blurRadius: 12,

                    offset: const Offset(0, 8),

                  ),

                ]

              : null,

        ),

        child: Row(

          children: [

            Icon(data.icon, size: 18, color: const Color(0xFFE67E22)),

            const SizedBox(width: 8),

            Text(

              data.label,

              style: TextStyle(

                fontSize: 14,

                fontWeight: FontWeight.w600,

                color: isSelected

                    ? const Color(0xFF2B1A00)

                    : const Color(0xFF8B4513),

              ),

            ),

          ],

        ),

      ),

    );

  }

}



class ProductCard extends StatelessWidget {

  final ProductData product;

  final int quantity;

  final VoidCallback? onAdd;



  const ProductCard({

    super.key,

    required this.product,

    this.quantity = 0,

    this.onAdd,

  });



  @override

  Widget build(BuildContext context) {

    return LayoutBuilder(

      builder: (context, constraints) {

        final cardWidth = constraints.maxWidth;

        final imageHeight = (cardWidth * 0.65).clamp(80.0, 140.0);

        final buttonSize = (cardWidth * 0.22).clamp(32.0, 48.0);

        final iconSize = (buttonSize * 0.5).clamp(16.0, 24.0);

        final titleFontSize = (cardWidth * 0.085).clamp(12.0, 17.0);

        final priceFontSize = (cardWidth * 0.08).clamp(11.0, 16.0);

    return Container(

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.04),

            blurRadius: 18,

            offset: const Offset(0, 10),

          ),

        ],

      ),

      padding: EdgeInsets.all(cardWidth * 0.07),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(

            height: imageHeight,

            decoration: BoxDecoration(

              color: product.color,

              borderRadius: BorderRadius.circular(22),

            ),

            child: Center(

              child: Text(

                product.name.split(' ').map((word) => word[0]).join(),

                style: TextStyle(

                  fontSize: imageHeight * 0.28,

                  fontWeight: FontWeight.w800,

                  color: const Color(0xFFB66F1A),

                ),

              ),

            ),

          ),

          const SizedBox(height: 14),

          Text(

            product.name,

            maxLines: 2,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(

              fontSize: titleFontSize,

              fontWeight: FontWeight.w700,

              color: const Color(0xFF2B1A00),

            ),

          ),

          const SizedBox(height: 6),

          Text(

            product.priceLabel,

            style: TextStyle(

              fontSize: priceFontSize,

              fontWeight: FontWeight.w700,

              color: const Color(0xFFE67E22),

            ),

          ),

          const SizedBox(height: 8),

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              if (quantity > 0)

                Flexible(

                  child: Container(

                    padding: const EdgeInsets.symmetric(

                      horizontal: 8,

                      vertical: 6,

                    ),

                    decoration: BoxDecoration(

                      color: const Color(0xFFFFF0E0),

                      borderRadius: BorderRadius.circular(12),

                    ),

                    child: Text(

                      'x$quantity',

                      style: TextStyle(

                        fontSize: priceFontSize - 1,

                        fontWeight: FontWeight.w700,

                        color: const Color(0xFFE67E22),

                      ),

                    ),

                  ),

                )

              else

                const SizedBox.shrink(),

              GestureDetector(

                onTap: onAdd,

                child: Container(

                  width: buttonSize,

                  height: buttonSize,

                  decoration: BoxDecoration(

                    color: const Color(0xFFE67E22),

                    borderRadius: BorderRadius.circular(buttonSize * 0.35),

                  ),

                  child: Icon(

                    Icons.add_shopping_cart_rounded,

                    color: Colors.white,

                    size: iconSize,

                  ),

                ),

              ),

            ],

          ),

        ],

      ),

    );

      },

    );

  }

}



class CartItemCardWidget extends StatelessWidget {

  final String name;

  final String subtitle;

  final String price;

  final int quantity;

  final VoidCallback? onIncrease;

  final VoidCallback? onDecrease;

  final VoidCallback? onRemove;



  const CartItemCardWidget({

    super.key,

    required this.name,

    required this.subtitle,

    required this.price,

    required this.quantity,

    this.onIncrease,

    this.onDecrease,

    this.onRemove,

  });



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.04),

            blurRadius: 16,

            offset: const Offset(0, 10),

          ),

        ],

      ),

      child: Row(

        children: [

          SizedBox(

            width: 60,

            height: 60,

            child: DecoratedBox(

              decoration: BoxDecoration(

                color: const Color(0xFFFFF0E0),

                borderRadius: BorderRadius.circular(16),

              ),

              child: const Icon(

                Icons.emoji_food_beverage_rounded,

                color: Color(0xFFE67E22),

                size: 28,

              ),

            ),

          ),

          const SizedBox(width: 14),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  name,

                  style: const TextStyle(

                    fontSize: 16,

                    fontWeight: FontWeight.w700,

                    color: Color(0xFF2B1A00),

                  ),

                ),

                const SizedBox(height: 4),

                Text(

                  subtitle,

                  style: const TextStyle(

                    fontSize: 13,

                    color: Color(0xFF8B4513),

                  ),

                ),

                const SizedBox(height: 12),

                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

                    Row(

                      children: [

                        GestureDetector(

                          onTap: onDecrease,

                          child: Container(

                            width: 32,

                            height: 32,

                            decoration: BoxDecoration(

                              color: const Color(0xFFFFF0E0),

                              borderRadius: BorderRadius.circular(10),

                            ),

                            child: const Icon(

                              Icons.remove_rounded,

                              size: 18,

                              color: Color(0xFFE67E22),

                            ),

                          ),

                        ),

                        const SizedBox(width: 8),

                        Text(

                          '$quantity',

                          style: const TextStyle(

                            fontSize: 14,

                            fontWeight: FontWeight.w700,

                            color: Color(0xFF2B1A00),

                          ),

                        ),

                        const SizedBox(width: 8),

                        GestureDetector(

                          onTap: onIncrease,

                          child: Container(

                            width: 32,

                            height: 32,

                            decoration: BoxDecoration(

                              color: const Color(0xFFE67E22),

                              borderRadius: BorderRadius.circular(10),

                            ),

                            child: const Icon(

                              Icons.add_rounded,

                              size: 18,

                              color: Colors.white,

                            ),

                          ),

                        ),

                      ],

                    ),

                    Text(

                      price,

                      style: const TextStyle(

                        fontSize: 16,

                        fontWeight: FontWeight.w700,

                        color: Color(0xFF2B1A00),

                      ),

                    ),

                  ],

                ),

              ],

            ),

          ),

          const SizedBox(width: 10),

          GestureDetector(

            onTap: onRemove,

            child: Container(

              decoration: BoxDecoration(

                color: const Color(0xFFFFF0E0),

                borderRadius: BorderRadius.circular(14),

              ),

              padding: const EdgeInsets.all(10),

              child: const Icon(

                Icons.delete_outline_rounded,

                color: Color(0xFFE67E22),

                size: 20,

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class OrderSummaryCard extends StatelessWidget {

  final String orderId;

  final String date;

  final List<String> items;

  final String total;

  final String status;

  final Color statusColor;



  const OrderSummaryCard({

    super.key,

    required this.orderId,

    required this.date,

    required this.items,

    required this.total,

    required this.status,

    required this.statusColor,

  });



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.04),

            blurRadius: 18,

            offset: const Offset(0, 12),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    'Order $orderId',

                    style: const TextStyle(

                      fontSize: 16,

                      fontWeight: FontWeight.w700,

                      color: Color(0xFF2B1A00),

                    ),

                  ),

                  const SizedBox(height: 4),

                  Text(

                    date,

                    style: const TextStyle(

                      fontSize: 12,

                      color: Color(0xFF8B4513),

                    ),

                  ),

                ],

              ),

              Container(

                padding: const EdgeInsets.symmetric(

                  horizontal: 12,

                  vertical: 8,

                ),

                decoration: BoxDecoration(

                  color: statusColor.withOpacity(0.12),

                  borderRadius: BorderRadius.circular(16),

                ),

                child: Text(

                  status,

                  style: TextStyle(

                    fontSize: 12,

                    fontWeight: FontWeight.w700,

                    color: statusColor,

                  ),

                ),

              ),

            ],

          ),

          const SizedBox(height: 14),

          ...items.map(

            (item) => Padding(

              padding: const EdgeInsets.only(bottom: 6),

              child: Text(

                item,

                style: const TextStyle(fontSize: 14, color: Color(0xFF5F3B18)),

              ),

            ),

          ),

          const SizedBox(height: 14),

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              const Text(

                'Total Amount',

                style: TextStyle(fontSize: 14, color: Color(0xFF8B4513)),

              ),

              Text(

                total,

                style: const TextStyle(

                  fontSize: 16,

                  fontWeight: FontWeight.w800,

                  color: Color(0xFFE67E22),

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }

}



class ProfileOptionTile extends StatelessWidget {

  final IconData icon;

  final String title;

  final Color trailingColor;



  const ProfileOptionTile({

    super.key,

    required this.icon,

    required this.title,

    this.trailingColor = const Color(0xFF8B4513),

  });



  @override

  Widget build(BuildContext context) {

    return Container(

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.04),

            blurRadius: 14,

            offset: const Offset(0, 10),

          ),

        ],

      ),

      child: ListTile(

        leading: Container(

          width: 40,

          height: 40,

          decoration: BoxDecoration(

            color: const Color(0xFFFFF0E0),

            borderRadius: BorderRadius.circular(12),

          ),

          child: Icon(icon, color: const Color(0xFFE67E22)),

        ),

        title: Text(

          title,

          style: const TextStyle(

            fontSize: 15,

            fontWeight: FontWeight.w700,

            color: Color(0xFF2B1A00),

          ),

        ),

        trailing: Icon(Icons.chevron_right_rounded, color: trailingColor),

        onTap: () {},

      ),

    );

  }

}

