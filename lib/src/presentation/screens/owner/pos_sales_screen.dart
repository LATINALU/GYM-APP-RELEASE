import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/quantum_colors.dart';
import '../../../domain/entities/pos_product.dart';
import '../../../domain/entities/pos_sale.dart';

class PosSalesScreen extends StatefulWidget {
  const PosSalesScreen({super.key});

  @override
  State<PosSalesScreen> createState() => _PosSalesScreenState();
}

class _PosSalesScreenState extends State<PosSalesScreen> {
  final _firestore = FirebaseFirestore.instance;
  final Map<String, int> _cart = {}; // productId -> quantity
  final Map<String, PosProduct> _products = {}; // productId -> product
  String _paymentMethod = 'cash';

  double get _subtotal {
    return _cart.entries.fold(0.0, (acc, entry) {
      final product = _products[entry.key];
      if (product == null) return acc;
      return acc + (product.price * entry.value);
    });
  }

  double get _tax => _subtotal * 0.16; // 16% IVA
  double get _total => _subtotal + _tax;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body: Row(
        children: [
          Expanded(flex: 2, child: _buildProductList()),
          Container(width: 1, color: Colors.white.withValues(alpha: 0.1)),
          Expanded(child: _buildCart()),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                QuantumColors.quantumBlue.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.point_of_sale_rounded, color: QuantumColors.quantumBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PUNTO DE VENTA', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, color: Colors.white54, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Vendedor: ${AuthStateNotifier.instance.profile?.displayName ?? "Usuario"}',
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: QuantumColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: QuantumColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: QuantumColors.success, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateTime.now().toString().substring(11, 16),
                      style: const TextStyle(color: QuantumColors.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('pos_products')
                .where('gymId', isEqualTo: gymId)
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final product = PosProduct.fromJson({...data, 'id': doc.id});
                _products[doc.id] = product;
                return product;
              }).where((p) => p.inStock).toList();

              if (products.isEmpty) {
                return const Center(
                  child: Text('No hay productos disponibles', style: TextStyle(color: Colors.white54)),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) => _buildProductTile(products[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductTile(PosProduct product) {
    final inCart = _cart.containsKey(product.id);

    return GestureDetector(
      onTap: () => _addToCart(product),
      child: Container(
        decoration: BoxDecoration(
          color: inCart ? QuantumColors.quantumBlue.withValues(alpha: 0.1) : QuantumColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: inCart ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.1),
            width: inCart ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(product.category),
              size: 48,
              color: inCart ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                product.name,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(color: QuantumColors.success, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Stock: ${product.stock}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCart() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
          ),
          child: const Row(
            children: [
              Icon(Icons.shopping_cart_rounded, color: QuantumColors.quantumBlue, size: 24),
              SizedBox(width: 12),
              Text('CARRITO', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: _cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      const Text('Carrito vacío', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final productId = _cart.keys.elementAt(index);
                    final quantity = _cart[productId]!;
                    final product = _products[productId]!;
                    return _buildCartItem(product, quantity);
                  },
                ),
        ),
        if (_cart.isNotEmpty) _buildCheckoutSection(),
      ],
    );
  }

  Widget _buildCartItem(PosProduct product, int quantity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(_getCategoryIcon(product.category), color: QuantumColors.quantumBlue, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('\$${product.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                onPressed: () => _removeFromCart(product.id),
              ),
              Text('$quantity', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: QuantumColors.success),
                onPressed: () => _addToCart(product),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', _subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('IVA (16%)', _tax),
          const Divider(color: Colors.white24, height: 24),
          _buildSummaryRow('TOTAL', _total, isTotal: true),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _paymentMethod,
            dropdownColor: const Color(0xFF1A1A2E),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Método de pago',
              labelStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.payment, color: QuantumColors.quantumBlue),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
              DropdownMenuItem(value: 'card', child: Text('Tarjeta')),
              DropdownMenuItem(value: 'transfer', child: Text('Transferencia')),
            ],
            onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _cart.clear()),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _completeSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuantumColors.quantumBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('COMPLETAR VENTA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.white70,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isTotal ? QuantumColors.success : Colors.white,
            fontSize: isTotal ? 24 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Toallas':
        return Icons.dry_cleaning_rounded;
      case 'Agua':
        return Icons.water_drop_rounded;
      case 'Suplementos':
        return Icons.medication_rounded;
      case 'Accesorios':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _addToCart(PosProduct product) {
    setState(() {
      final currentQty = _cart[product.id] ?? 0;
      if (currentQty < product.stock) {
        _cart[product.id] = currentQty + 1;
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      final currentQty = _cart[productId] ?? 0;
      if (currentQty > 1) {
        _cart[productId] = currentQty - 1;
      } else {
        _cart.remove(productId);
      }
    });
  }

  Future<void> _completeSale() async {
    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      final staffName = AuthStateNotifier.instance.profile?.displayName;

      final items = _cart.entries.map((entry) {
        final product = _products[entry.key]!;
        return SaleItem(
          productId: entry.key,
          productName: product.name,
          unitPrice: product.price,
          quantity: entry.value,
          subtotal: product.price * entry.value,
        );
      }).toList();

      await _firestore.collection('pos_sales').add({
        'gymId': gymId,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': _subtotal,
        'tax': _tax,
        'total': _total,
        'paymentMethod': _paymentMethod,
        'staffName': staffName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (var entry in _cart.entries) {
        final product = _products[entry.key]!;
        await _firestore.collection('pos_products').doc(entry.key).update({
          'stock': product.stock - entry.value,
        });
      }

      setState(() => _cart.clear());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Venta completada'), backgroundColor: QuantumColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
