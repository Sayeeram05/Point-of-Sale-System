import 'package:flutter/material.dart';

/// Category model representing waffle categories
/// Connects to Django Category API backend
class Category {
  final String id;
  final String name;
  final String icon;
  final int productCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.productCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Category from JSON (Django API response)
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'restaurant',
      productCount: json['product_count']?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convert Category to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'product_count': productCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Category with updated fields
  Category copyWith({
    String? id,
    String? name,
    String? icon,
    int? productCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get IconData for the category icon
  IconData get iconData {
    switch (icon.toLowerCase()) {
      case 'classic':
      case 'restaurant':
        return Icons.restaurant;
      case 'chocolate':
      case 'cake':
        return Icons.cake;
      case 'fruit':
      case 'apple':
        return Icons.apple;
      case 'premium':
      case 'star':
        return Icons.star;
      case 'coffee':
        return Icons.coffee;
      case 'breakfast':
        return Icons.breakfast_dining;
      default:
        return Icons.restaurant;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, icon: $icon, productCount: $productCount)';
  }
}

/// Request model for creating/updating categories
class CategoryRequest {
  final String name;
  final String icon;

  const CategoryRequest({
    required this.name,
    required this.icon,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
    };
  }

  /// Create from form data
  factory CategoryRequest.fromForm({
    required String name,
    required String icon,
  }) {
    return CategoryRequest(
      name: name.trim(),
      icon: icon.trim(),
    );
  }
}