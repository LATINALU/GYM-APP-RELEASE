import 'package:equatable/equatable.dart';

/// Product entity for Point of Sale system
class PosProduct extends Equatable {
  final String id;
  final String name;
  final String category; // 'Toallas', 'Agua', 'Suplementos', etc.
  final double price;
  final int stock;
  final String? imageUrl;
  final String? description;
  final String? barcode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PosProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.description,
    this.barcode,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  bool get inStock => stock > 0;
  bool get lowStock => stock > 0 && stock <= 5;

  PosProduct copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    int? stock,
    String? imageUrl,
    String? description,
    String? barcode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PosProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        price,
        stock,
        imageUrl,
        description,
        barcode,
        isActive,
        createdAt,
        updatedAt,
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'imageUrl': imageUrl,
        'description': description,
        'barcode': barcode,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory PosProduct.fromJson(Map<String, dynamic> json) => PosProduct(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        stock: json['stock'] as int,
        imageUrl: json['imageUrl'] as String?,
        description: json['description'] as String?,
        barcode: json['barcode'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}
