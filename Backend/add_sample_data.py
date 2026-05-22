#!/usr/bin/env python
"""
Add sample waffle shop data to Django database
Run this script to populate the database with categories and products
"""
import os
import sys
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Main.settings')
django.setup()

from Category.models import Category
from Product.models import Product

def add_sample_data():
    print("Adding sample waffle shop data...")
    
    # Create Categories
    categories_data = [
        "Classic Waffles",
        "Chocolate Waffles", 
        "Fruit Waffles",
        "Premium Specials"
    ]
    
    categories = {}
    for cat_name in categories_data:
        category, created = Category.objects.get_or_create(Name=cat_name)
        categories[cat_name] = category
        if created:
            print(f"✅ Created category: {cat_name}")
        else:
            print(f"📋 Category already exists: {cat_name}")
    
    # Create Products
    products_data = [
        # Classic Waffles
        ("Belgian Classic", 120.00, "Classic Waffles"),
        ("Butter Delight", 100.00, "Classic Waffles"),
        ("Honey Crisp", 110.00, "Classic Waffles"),
        
        # Chocolate Waffles
        ("Choco Lava", 180.00, "Chocolate Waffles"),
        ("Dark Chocolate Supreme", 200.00, "Chocolate Waffles"),
        
        # Fruit Waffles
        ("Strawberry Cream", 160.00, "Fruit Waffles"),
        ("Mixed Berry Bliss", 170.00, "Fruit Waffles"),
        
        # Premium Specials
        ("Caramel Pecan Royale", 250.00, "Premium Specials"),
    ]
    
    for product_name, price, category_name in products_data:
        category = categories[category_name]
        product, created = Product.objects.get_or_create(
            Name=product_name,
            defaults={
                'Price': price,
                'ProductCategory': category,
                'Deleted': False
            }
        )
        if created:
            print(f"✅ Created product: {product_name} - ₹{price}")
        else:
            print(f"📋 Product already exists: {product_name}")
    
    # Print summary
    total_categories = Category.objects.count()
    total_products = Product.objects.filter(Deleted=False).count()
    
    print(f"\n🎉 Sample data added successfully!")
    print(f"📊 Total Categories: {total_categories}")
    print(f"🧇 Total Products: {total_products}")
    print(f"\n🚀 Your Django API is ready for the Flutter app!")

if __name__ == "__main__":
    add_sample_data()