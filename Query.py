import random
from datetime import datetime, timedelta

# =========================================================
# WOFL SHOP - COMPLETE DATABASE DUMMY DATA GENERATOR
# =========================================================

YEARS = 1
ORDERS_PER_DAY = (8, 10)

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
    "#2ECC71",
]
for color in colors:
    queries.append(f"INSERT INTO Auxiliary_color (HexCode) VALUES ('{color}');")

# =========================================================
# EMOJIS
# =========================================================
emojis = ["🧇", "😍", "🔥", "😋", "❤️", "🥞", "☕", "🍫"]
for emoji in emojis:
    queries.append(f"INSERT INTO Auxiliary_emoji (Emoji) VALUES ('{emoji}');")

# =========================================================
# CATEGORIES
# =========================================================
categories = [
    "Classic WOFLs",
    "Chocolate WOFLs",
    "Premium WOFLs",
    "Ice Cream WOFLs",
    "Beverages",
    "Milkshakes",
    "Coffee",
    "Combo Offers",
]
for category in categories:
    queries.append(f"INSERT INTO Category_category (Name) VALUES ('{category}');")

# =========================================================
# PRODUCTS (Revenue Stream Catalog)
# =========================================================
products = [
    ("Belgian WOFL", 120, 1),
    ("Nutella WOFL", 180, 2),
    ("Dark Fantasy WOFL", 220, 2),
    ("Brownie Blast WOFL", 250, 3),
    ("Oreo Crunch WOFL", 210, 3),
    ("Strawberry Ice Cream WOFL", 260, 4),
    ("Vanilla Ice Cream WOFL", 240, 4),
    ("Cold Coffee", 110, 5),
    ("Hot Chocolate", 140, 5),
    ("KitKat Milkshake", 170, 6),
    ("Oreo Milkshake", 180, 6),
    ("Cappuccino", 130, 7),
    ("Espresso", 100, 7),
    ("WOFL Combo", 350, 8),
]

product_objects = []
for index, product in enumerate(products, start=1):
    name = product[0]
    price = product[1]
    category_id = product[2]
    product_objects.append({"id": index, "price": price})

    queries.append(f"""
INSERT INTO Product_product (Name, Price, ProductCategory_id, Deleted)
VALUES ('{name}', {price}, {category_id}, 0);
""")

# =========================================================
# RAW MATERIALS (Expense Stream Master Catalog)
# =========================================================
# Tuple layout: (Material Name, Unit Type, Baseline Market Price per unit)
raw_materials = [
    ("WOFL Premix Flour", "kg", 140.00),
    ("Premium Nutella Spread", "kg", 650.00),
    ("Dark Chocolate Chips", "kg", 320.00),
    ("Unsalted Cooking Butter", "kg", 420.00),
    ("Whole Dairy Milk", "liters", 68.00),
    ("Vanilla Bean Ice Cream Tub", "kg", 210.00),
    ("Roasted Coffee Beans Blend", "kg", 850.00),
    ("Whipped Cream Aerosol Can", "pcs", 190.00),
    ("Sugar Crystals", "kg", 45.00),
    ("Cardboard Takeaway Packaging boxes", "pcs", 12.00),
]

material_objects = []
for index, mat in enumerate(raw_materials, start=1):
    mat_name, mat_unit, mat_price = mat[0], mat[1], mat[2]
    material_objects.append({"id": index, "name": mat_name, "price": mat_price})
    queries.append(f"""
INSERT INTO Materials_rawmaterial (id, name, unit, base_price, is_active, created_at, updated_at)
VALUES ({index}, '{mat_name}', '{mat_unit}', {mat_price}, 1, NOW(), NOW());
""")

# =========================================================
# TIMELINE ENGINE: SYSTEM REVENUE & EXPENSE CO-GENERATION
# =========================================================
current_order_id = 1
current_purchase_record_id = 1
today = datetime.now()

for year_back in range(YEARS):
    current_year = today.year - year_back
    start_date = datetime(current_year, 1, 1)

    for day in range(365):
        current_date = start_date + timedelta(days=day)

        # Skip date formatting generations if landing on future dates in year loops
        if current_date > today:
            continue

        daily_orders = random.randint(ORDERS_PER_DAY[0], ORDERS_PER_DAY[1])
        day_total_revenue = 0
        order_item_queries = []

        # Generate separate discrete ticket orders for the active day
        for _ in range(daily_orders):
            created_at = current_date.replace(
                hour=random.randint(9, 23),
                minute=random.randint(0, 59),
                second=random.randint(0, 59),
            )

            selected_products = random.sample(product_objects, random.randint(1, 5))
            total_quantity = 0
            total_amount = 0

            for product in selected_products:
                quantity = random.randint(1, 3)
                subtotal = quantity * product["price"]
                total_quantity += quantity
                total_amount += subtotal

                item_query = f"""
INSERT INTO Order_orderitem (OrderId_id, ProductID_id, Quantity, PriceAtPurchase)
VALUES ({current_order_id}, {product["id"]}, {quantity}, {product["price"]});
"""
                order_item_queries.append(item_query)

            # Split ticket transaction channels
            payment_mode = random.choice(["cash", "upi", "split"])
            if payment_mode == "cash":
                cash_amount, upi_amount = total_amount, 0
            elif payment_mode == "upi":
                cash_amount, upi_amount = 0, total_amount
            else:
                split = round(total_amount * random.uniform(0.3, 0.7), 2)
                cash_amount = split
                upi_amount = total_amount - split

            order_query = f"""
INSERT INTO Order_order (id, ColorId_id, EmojiId_id, TotalQuantity, UpiAmount, CashAmount, Completed, CreatedAt, UpdatedAt)
VALUES ({current_order_id}, {random.randint(1, len(colors))}, {random.randint(1, len(emojis))}, {total_quantity}, {upi_amount}, {cash_amount}, 1, '{created_at.strftime("%Y-%m-%d %H:%M:%S")}', '{created_at.strftime("%Y-%m-%d %H:%M:%S")}');
"""
            queries.append(order_query)
            queries.extend(order_item_queries)

            day_total_revenue += total_amount
            current_order_id += 1

        # =========================================================
        # REALISTIC EXPENSE ENGINE (Proportional Consumption)
        # =========================================================
        # Procurement scale factors mimic operational ingredient runout costs
        # Baseline material costs run around 30% to 45% of gross incoming sales revenue
        base_expense_target = day_total_revenue * random.uniform(0.30, 0.45)
        day_total_procurement_cost = 0
        purchase_items_queries = []

        # Iterate through catalog to generate daily restocking log lines
        for material in material_objects:
            # Randomize baseline ingredient acquisition weights per day
            # Essential components (Flour/Milk/Boxes) are added almost daily
            if (
                material["name"]
                in [
                    "WOFL Premix Flour",
                    "Whole Dairy Milk",
                    "Cardboard Takeaway Packaging boxes",
                ]
                or random.random() > 0.4
            ):
                # Base volume scale factor pegged directly to total sales traffic
                sales_scale_factor = (day_total_revenue / 4000.0) + 0.2
                quantity_purchased = round(
                    random.uniform(1.0, 5.0) * sales_scale_factor, 3
                )

                # Introduce slight historical purchasing price fluctuations (market deviation variance up to +/- 5%)
                market_price_variance = random.uniform(0.95, 1.05)
                snapshot_price = round(
                    float(material["price"]) * market_price_variance, 2
                )
                item_subtotal = round(snapshot_price * quantity_purchased, 2)

                day_total_procurement_cost += item_subtotal

                item_expense_query = f"""
INSERT INTO Materials_purchaseitem (record_id, raw_material_id, material_name, base_price_snapshot, quantity, subtotal)
VALUES ({current_purchase_record_id}, {material["id"]}, '{material["name"]}', {snapshot_price}, {quantity_purchased}, {item_subtotal});
"""
                purchase_items_queries.append(item_expense_query)

        # Build day level parent header tracking invoice block record
        date_str = current_date.strftime("%Y-%m-%d")
        purchase_record_query = f"""
INSERT INTO Materials_purchaserecord (id, target_date, total_cost, is_locked, notes, created_at, updated_at)
VALUES ({current_purchase_record_id}, '{date_str}', {round(day_total_procurement_cost, 2)}, 1, 'Automated end-of-day batch inventory restocking sequence logs.', NOW(), NOW());
"""
        queries.append(purchase_record_query)
        queries.extend(purchase_items_queries)

        current_purchase_record_id += 1

# =========================================================
# WRITE OUTPUT TRANSACTIONS TO DISK
# =========================================================
with open("WOFL_shop_dummy_data.txt", "w", encoding="utf-8") as file:
    file.write("SET FOREIGN_KEY_CHECKS=0;\n\n")
    for query in queries:
        file.write(query)
        file.write("\n")
    file.write("\nSET FOREIGN_KEY_CHECKS=1;")

print("=========================================================")
print("  ✓ WOFL SHOP UNIFIED BALANCED DUMMY DATA GENERATED  ")
print("  ↳ Output ledger: WOFL_shop_dummy_data.txt")
print("  ↳ Generated complete operational timelines for Order & Materials apps.")
print("=========================================================")
