import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/quantum_colors.dart';
import '../../../domain/entities/pos_product.dart';

class PosInventoryScreen extends StatefulWidget {
  const PosInventoryScreen({super.key});

  @override
  State<PosInventoryScreen> createState() => _PosInventoryScreenState();
}

class _PosInventoryScreenState extends State<PosInventoryScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'Todos';
  final List<String> _categories = ['Todos', 'Toallas', 'Agua', 'Suplementos', 'Accesorios', 'Otros'];

  @override
  Widget build(BuildContext context) {
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;

    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('pos_products')
                  .where('gymId', isEqualTo: gymId)
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var products = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return PosProduct.fromJson({...data, 'id': doc.id});
                }).toList();

                if (_selectedCategory != 'Todos') {
                  products = products.where((p) => p.category == _selectedCategory).toList();
                }

                if (products.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => _buildProductCard(products[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        child: ElevatedButton.icon(
          onPressed: () => _showAddProductDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: QuantumColors.quantumBlue,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
          ),
          icon: const Icon(Icons.add_circle_outline, color: Colors.black, size: 24),
          label: const Text(
            'AGREGAR PRODUCTO',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
            child: const Icon(Icons.inventory_2_rounded, color: QuantumColors.quantumBlue, size: 28),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INVENTARIO', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Gestiona tus productos', style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(PosProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(product.imageUrl!, fit: BoxFit.cover),
                    )
                  : Center(
                      child: Icon(
                        _getCategoryIcon(product.category),
                        size: 64,
                        color: QuantumColors.quantumBlue.withValues(alpha: 0.3),
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(color: QuantumColors.quantumBlue, fontSize: 12),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(color: QuantumColors.success, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.lowStock
                              ? Colors.orange.withValues(alpha: 0.2)
                              : product.inStock
                                  ? QuantumColors.success.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Stock: ${product.stock}',
                          style: TextStyle(
                            color: product.lowStock
                                ? Colors.orange
                                : product.inStock
                                    ? QuantumColors.success
                                    : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No hay productos', style: TextStyle(color: Colors.white54, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Agrega tu primer producto', style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
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

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'Toallas';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Agregar Producto', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField('Nombre del producto', Icons.shopping_bag, nameCtrl),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.category, color: QuantumColors.quantumBlue, size: 20),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    items: _categories.skip(1).map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (v) => setDialogState(() => selectedCategory = v ?? 'Toallas'),
                  ),
                  const SizedBox(height: 12),
                  _dialogField('Precio', Icons.attach_money, priceCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _dialogField('Stock inicial', Icons.inventory, stockCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _dialogField('Descripción (opcional)', Icons.description, descCtrl, maxLines: 3),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty || stockCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa todos los campos requeridos'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _addProduct(nameCtrl.text, selectedCategory, double.parse(priceCtrl.text), int.parse(stockCtrl.text), descCtrl.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: QuantumColors.quantumBlue),
              child: const Text('Agregar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(String label, IconData icon, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: QuantumColors.quantumBlue, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _addProduct(String name, String category, double price, int stock, String description) async {
    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      await _firestore.collection('pos_products').add({
        'gymId': gymId,
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'description': description.isEmpty ? null : description,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Producto agregado'), backgroundColor: QuantumColors.success),
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
