import random
from datetime import datetime, timedelta

# =========================================================
# WAFFLE SHOP - COMPLETE DATABASE DUMMY DATA GENERATOR
# =========================================================

YEARS = 3
ORDERS_PER_DAY = (8, 30)

queries = []

# =========================================================
# COLORS
# =========================================================

colors = [
    "#FF5733",
    "#33FF57",
    "#3357FF",
    "#F39C12",
    "#9B59B6",
    "#1ABC9C",
    "#E74C3C",
    "#2ECC71"
]

for color in colors:

    queries.append(f"""
INSERT INTO Auxiliary_color (HexCode)
VALUES ('{color}');
""")

# =========================================================
# EMOJIS
# =========================================================

emojis = [
    "🧇",
    "😍",
    "🔥",
    "😋",
    "❤️",
    "🥞",
    "☕",
    "🍫"
]

for emoji in emojis:

    queries.append(f"""
INSERT INTO Auxiliary_emoji (Emoji)
VALUES ('{emoji}');
""")

# =========================================================
# CATEGORIES
# =========================================================

categories = [
    "Classic Waffles",
    "Chocolate Waffles",
    "Premium Waffles",
    "Ice Cream Waffles",
    "Beverages",
    "Milkshakes",
    "Coffee",
    "Combo Offers"
]

for category in categories:

    queries.append(f"""
INSERT INTO Category_category (Name)
VALUES ('{category}');
""")

# =========================================================
# PRODUCTS
# =========================================================

products = [
    ("Belgian Waffle", 120, 1),
    ("Nutella Waffle", 180, 2),
    ("Dark Fantasy Waffle", 220, 2),
    ("Brownie Blast Waffle", 250, 3),
    ("Oreo Crunch Waffle", 210, 3),
    ("Strawberry Ice Cream Waffle", 260, 4),
    ("Vanilla Ice Cream Waffle", 240, 4),
    ("Cold Coffee", 110, 5),
    ("Hot Chocolate", 140, 5),
    ("KitKat Milkshake", 170, 6),
    ("Oreo Milkshake", 180, 6),
    ("Cappuccino", 130, 7),
    ("Espresso", 100, 7),
    ("Waffle Combo", 350, 8),
]

product_objects = []

for index, product in enumerate(products, start=1):

    name = product[0]
    price = product[1]
    category_id = product[2]

    product_objects.append({
        "id": index,
        "price": price
    })

    queries.append(f"""
INSERT INTO Product_product
(
    Name,
    Price,
    ProductCategory_id,
    Deleted
)
VALUES
(
    '{name}',
    {price},
    {category_id},
    0
);
""")

# =========================================================
# ORDERS + ORDER ITEMS
# =========================================================

current_order_id = 1

today = datetime.now()

for year_back in range(YEARS):

    current_year = today.year - year_back

    start_date = datetime(current_year, 1, 1)

    for day in range(365):

        current_date = start_date + timedelta(days=day)

        daily_orders = random.randint(
            ORDERS_PER_DAY[0],
            ORDERS_PER_DAY[1]
        )

        for _ in range(daily_orders):

            created_at = current_date.replace(
                hour=random.randint(9, 23),
                minute=random.randint(0, 59),
                second=random.randint(0, 59)
            )

            selected_products = random.sample(
                product_objects,
                random.randint(1, 5)
            )

            total_quantity = 0
            total_amount = 0

            order_item_queries = []

            for product in selected_products:

                quantity = random.randint(1, 3)

                subtotal = quantity * product["price"]

                total_quantity += quantity
                total_amount += subtotal

                item_query = f"""
INSERT INTO Order_orderitem
(
    OrderId_id,
    ProductID_id,
    Quantity,
    PriceAtPurchase
)
VALUES
(
    {current_order_id},
    {product["id"]},
    {quantity},
    {product["price"]}
);
"""

                order_item_queries.append(item_query)

            # =============================================
            # PAYMENT LOGIC
            # =============================================

            payment_mode = random.choice([
                "cash",
                "upi",
                "split"
            ])

            if payment_mode == "cash":

                cash_amount = total_amount
                upi_amount = 0

            elif payment_mode == "upi":

                cash_amount = 0
                upi_amount = total_amount

            else:

                split = round(total_amount * random.uniform(0.3, 0.7), 2)

                cash_amount = split
                upi_amount = total_amount - split

            # =============================================
            # ORDER QUERY
            # =============================================

            order_query = f"""
INSERT INTO Order_order
(
    ColorId_id,
    EmojiId_id,
    TotalQuantity,
    UpiAmount,
    CashAmount,
    Completed,
    CreatedAt,
    UpdatedAt
)
VALUES
(
    {random.randint(1, len(colors))},
    {random.randint(1, len(emojis))},
    {total_quantity},
    {upi_amount},
    {cash_amount},
    1,
    '{created_at.strftime('%Y-%m-%d %H:%M:%S')}',
    '{created_at.strftime('%Y-%m-%d %H:%M:%S')}'
);
"""

            queries.append(order_query)

            queries.extend(order_item_queries)

            current_order_id += 1

# =========================================================
# SAVE TO TXT FILE
# =========================================================

with open("waffle_shop_dummy_data.txt", "w", encoding="utf-8") as file:

    file.write("SET FOREIGN_KEY_CHECKS=0;\n\n")

    for query in queries:

        file.write(query)
        file.write("\n")

    file.write("\nSET FOREIGN_KEY_CHECKS=1;")

print("====================================")
print("WAFFLE SHOP DUMMY DATA GENERATED")
print("File: waffle_shop_dummy_data.txt")
print("====================================")