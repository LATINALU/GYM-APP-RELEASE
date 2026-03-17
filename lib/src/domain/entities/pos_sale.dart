import 'package:equatable/equatable.dart';

/// Sale item in a transaction
class SaleItem extends Equatable {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  const SaleItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  SaleItem copyWith({
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    double? subtotal,
  }) {
    return SaleItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  @override
  List<Object?> get props => [productId, productName, unitPrice, quantity, subtotal];

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'subtotal': subtotal,
      };

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        quantity: json['quantity'] as int,
        subtotal: (json['subtotal'] as num).toDouble(),
      );
}

/// Complete sale transaction
class PosSale extends Equatable {
  final String id;
  final String gymId;
  final List<SaleItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod; // 'cash', 'card', 'transfer'
  final String? staffId;
  final String? staffName;
  final String? notes;
  final DateTime createdAt;

  const PosSale({
    required this.id,
    required this.gymId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.staffId,
    this.staffName,
    this.notes,
    required this.createdAt,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  PosSale copyWith({
    String? id,
    String? gymId,
    List<SaleItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? paymentMethod,
    String? staffId,
    String? staffName,
    String? notes,
    DateTime? createdAt,
  }) {
    return PosSale(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        gymId,
        items,
        subtotal,
        tax,
        total,
        paymentMethod,
        staffId,
        staffName,
        notes,
        createdAt,
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'gymId': gymId,
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'paymentMethod': paymentMethod,
        'staffId': staffId,
        'staffName': staffName,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PosSale.fromJson(Map<String, dynamic> json) => PosSale(
        id: json['id'] as String,
        gymId: json['gymId'] as String,
        items: (json['items'] as List)
            .map((item) => SaleItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num).toDouble(),
        tax: (json['tax'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        paymentMethod: json['paymentMethod'] as String,
        staffId: json['staffId'] as String?,
        staffName: json['staffName'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
