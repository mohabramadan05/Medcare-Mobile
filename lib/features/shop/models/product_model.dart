class ProductModel {
  final String id;
  final String? slug;
  final String? category;
  final String? categoryLabel;
  final String name;
  final String? description;
  final double? rating;
  final int? reviewsCount;
  final double price;
  final String? iconKey;
  final bool isActive;

  const ProductModel({
    required this.id,
    this.slug,
    this.category,
    this.categoryLabel,
    required this.name,
    this.description,
    this.rating,
    this.reviewsCount,
    required this.price,
    this.iconKey,
    this.isActive = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      slug: json['slug'] as String?,
      category: json['category'] as String?,
      categoryLabel: json['category_label'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewsCount: json['reviews_count'] as int?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      iconKey: json['icon_key'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class CartItemModel {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final ProductModel? product;

  const CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.product,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int? ?? 1,
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'] as Map<String, dynamic>)
          : null,
    );
  }

  double get total => (product?.price ?? 0) * quantity;
}
