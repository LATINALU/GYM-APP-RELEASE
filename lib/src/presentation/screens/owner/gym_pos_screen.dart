import 'package:flutter/material.dart';
import '../../theme/gym_design_system.dart';
import '../../theme/gym_widgets.dart';

class GymPosScreen extends StatefulWidget {
  const GymPosScreen({super.key});

  @override
  State<GymPosScreen> createState() => _GymPosScreenState();
}

class _GymPosScreenState extends State<GymPosScreen> {
  final List<Map<String, dynamic>> _cart = [];
  String _searchQuery = '';
  
  final List<Map<String, dynamic>> _products = [
    {'id': '1', 'name': 'Proteína Whey 2kg', 'price': 55.0, 'stock': 12, 'category': 'Suplementos', 'image': '💊'},
    {'id': '2', 'name': 'Creatina Monohidratada', 'price': 25.0, 'stock': 8, 'category': 'Suplementos', 'image': '🧪'},
    {'id': '3', 'name': 'Agua Mineral 500ml', 'price': 1.5, 'stock': 45, 'category': 'Bebidas', 'image': '💧'},
    {'id': '4', 'name': 'Bebida Isotónica', 'price': 2.5, 'stock': 30, 'category': 'Bebidas', 'image': '⚡'},
    {'id': '5', 'name': 'Toalla de Microfibra', 'price': 12.0, 'stock': 20, 'category': 'Accesorios', 'image': '🧣'},
    {'id': '6', 'name': 'Guantes Pro Grip', 'price': 18.0, 'stock': 15, 'category': 'Accesorios', 'image': '🧤'},
  ];

  double get _total => _cart.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymColors.background,
      appBar: const GymAppBar(
        title: 'Punto de Venta (POS)',
        showBackButton: true,
      ),
      body: Row(
        children: [
          // Catálogo de Productos
          Expanded(
            flex: 2,
            child: _buildCatalog(),
          ),
          
          // Carrito de Compras
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: GymColors.surface,
              border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: _buildCartSidebar(),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalog() {
    final filtered = _products.where((p) => 
      p['name'].toLowerCase().contains(_searchQuery.toLowerCase()) || 
      p['category'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchAndFilters(),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.8,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildProductCard(filtered[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar productos o categorías...',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildFilterChip('Todos', true),
        _buildFilterChip('Suplementos', false),
        _buildFilterChip('Bebidas', false),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (v) {},
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: GymColors.primary.withValues(alpha: 0.2),
        checkmarkColor: GymColors.primary,
        labelStyle: TextStyle(color: isSelected ? GymColors.primary : Colors.white70),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GymCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _addToCart(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Text(product['image'], style: const TextStyle(fontSize: 48)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['category'].toUpperCase(), 
                    style: const TextStyle(color: GymColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(product['name'], 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${product['price']}', 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('${product['stock']} und', 
                        style: const TextStyle(color: Colors.white24, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }

  Widget _buildCartSidebar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Resumen de Venta', 
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_cart.isNotEmpty)
                IconButton(
                  onPressed: () => setState(() => _cart.clear()),
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                ),
            ],
          ),
        ),
        Expanded(
          child: _cart.isEmpty 
            ? _buildEmptyCart()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _cart.length,
                itemBuilder: (context, index) => _buildCartItem(_cart[index]),
              ),
        ),
        _buildCheckoutSection(),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, color: Colors.white10, size: 80),
          SizedBox(height: 16),
          Text('El carrito está vacío', style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white10,
            child: Text(item['image']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('\$${item['price']} x ${item['quantity']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              _cartQtyBtn(Icons.remove, () => _updateQty(item, -1)),
              const SizedBox(width: 12),
              Text('${item['quantity']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              _cartQtyBtn(Icons.add, () => _updateQty(item, 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cartQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', '\$${_total.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _summaryRow('Impuestos (0%)', '\$0.00'),
          const Divider(height: 32, color: Colors.white10),
          _summaryRow('TOTAL', '\$${_total.toStringAsFixed(2)}', isTotal: true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GymButton(
              text: 'FINALIZAR VENTA',
              style: GymButtonStyle.primary,
              onPressed: _cart.isEmpty ? null : _processSale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.white54, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: Colors.white, fontSize: isTotal ? 24 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final index = _cart.indexWhere((item) => item['id'] == product['id']);
      if (index >= 0) {
        _cart[index]['quantity']++;
      } else {
        _cart.add({...product, 'quantity': 1});
      }
    });
  }

  void _updateQty(Map<String, dynamic> item, int delta) {
    setState(() {
      final index = _cart.indexOf(item);
      _cart[index]['quantity'] += delta;
      if (_cart[index]['quantity'] <= 0) {
        _cart.removeAt(index);
      }
    });
  }

  void _processSale() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Confirmar Venta', style: TextStyle(color: Colors.white)),
        content: Text('¿Desea procesar el pago de \$${_total.toStringAsFixed(2)}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          GymButton(
            text: 'CONFIRMAR',
            size: GymButtonSize.small,
            onPressed: () {
              Navigator.pop(ctx);
              _showReceipt();
            },
          ),
        ],
      ),
    );
  }

  void _showReceipt() {
    setState(() => _cart.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Venta procesada con éxito. Ticket enviado al cliente.')),
    );
  }
}
