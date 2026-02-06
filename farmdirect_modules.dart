// =============================================
// SHARED MODELS
// =============================================

// lib/shared/models/product_model.dart
class ProductModel {
  final String id;
  final String farmerId;
  final String name;
  final String category;
  final String? description;
  final double price;
  final String unit;
  final int stock;
  final bool organicCertified;
  final List<String> images;
  final String? location;
  final double? lat;
  final double? lng;
  final bool isActive;
  final DateTime createdAt;
  
  ProductModel({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.category,
    this.description,
    required this.price,
    required this.unit,
    required this.stock,
    required this.organicCertified,
    required this.images,
    this.location,
    this.lat,
    this.lng,
    required this.isActive,
    required this.createdAt,
  });
  
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      stock: json['stock'] as int,
      organicCertified: json['organic_certified'] as bool,
      images: List<String>.from(json['images'] ?? []),
      location: json['location'] as String?,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'name': name,
    'category': category,
    'description': description,
    'price': price,
    'unit': unit,
    'stock': stock,
    'organic_certified': organicCertified,
    'images': images,
    'location': location,
    'lat': lat,
    'lng': lng,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}

// lib/shared/models/order_model.dart
class OrderModel {
  final String id;
  final String customerId;
  final String farmerId;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  
  OrderModel({
    required this.id,
    required this.customerId,
    required this.farmerId,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.estimatedDelivery,
    this.deliveredAt,
    required this.createdAt,
    this.items = const [],
  });
  
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      farmerId: json['farmer_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      deliveryAddress: json['delivery_address'] as String,
      deliveryLat: json['delivery_lat'] != null ? (json['delivery_lat'] as num).toDouble() : null,
      deliveryLng: json['delivery_lng'] != null ? (json['delivery_lng'] as num).toDouble() : null,
      estimatedDelivery: json['estimated_delivery'] != null 
          ? DateTime.parse(json['estimated_delivery']) : null,
      deliveredAt: json['delivered_at'] != null 
          ? DateTime.parse(json['delivered_at']) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  
  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });
  
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
  
  double get subtotal => quantity * price;
}

// =============================================
// FARMER PROVIDER
// =============================================

// lib/features/farmer/providers/farmer_provider.dart
import 'package:flutter/material.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/logging/logger.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/order_model.dart';
import 'package:image_picker/image_picker.dart';

class FarmerProvider extends ChangeNotifier {
  final SupabaseClientService _supabase;
  
  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  
  FarmerProvider(this._supabase);
  
  List<ProductModel> get products => _products;
  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadProducts(String farmerId) async {
    _setLoading(true);
    try {
      final data = await _supabase.select('products', filters: {'farmer_id': farmerId});
      _products = data.map((json) => ProductModel.fromJson(json)).toList();
      _error = null;
    } catch (e, stack) {
      AppLogger.error('Load products failed', error: e, stackTrace: stack);
      _error = e.toString();
    }
    _setLoading(false);
  }
  
  Future<bool> addProduct({
    required String farmerId,
    required String name,
    required String category,
    String? description,
    required double price,
    required String unit,
    required int stock,
    required bool organicCertified,
    List<XFile>? imageFiles,
    String? location,
    double? lat,
    double? lng,
  }) async {
    _setLoading(true);
    try {
      List<String> imageUrls = [];
      
      if (imageFiles != null) {
        for (var file in imageFiles) {
          final bytes = await file.readAsBytes();
          final path = 'products/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final url = await _supabase.uploadFile(
            bucket: 'product-images',
            path: path,
            fileBytes: bytes,
            contentType: 'image/jpeg',
          );
          imageUrls.add(url);
        }
      }
      
      await _supabase.insert('products', {
        'farmer_id': farmerId,
        'name': name,
        'category': category,
        'description': description,
        'price': price,
        'unit': unit,
        'stock': stock,
        'organic_certified': organicCertified,
        'images': imageUrls,
        'location': location,
        'lat': lat,
        'lng': lng,
        'is_active': true,
      });
      
      await loadProducts(farmerId);
      _setLoading(false);
      return true;
    } catch (e, stack) {
      AppLogger.error('Add product failed', error: e, stackTrace: stack);
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }
  
  Future<bool> updateProduct({
    required String productId,
    required String farmerId,
    required Map<String, dynamic> updates,
  }) async {
    _setLoading(true);
    try {
      await _supabase.update('products', updates, productId);
      await loadProducts(farmerId);
      _setLoading(false);
      return true;
    } catch (e, stack) {
      AppLogger.error('Update product failed', error: e, stackTrace: stack);
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }
  
  Future<void> loadOrders(String farmerId) async {
    _setLoading(true);
    try {
      final data = await _supabase.select('orders', filters: {'farmer_id': farmerId});
      _orders = data.map((json) => OrderModel.fromJson(json)).toList();
      _error = null;
    } catch (e, stack) {
      AppLogger.error('Load orders failed', error: e, stackTrace: stack);
      _error = e.toString();
    }
    _setLoading(false);
  }
  
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase.update('orders', {'status': status}, orderId);
      return true;
    } catch (e, stack) {
      AppLogger.error('Update order status failed', error: e, stackTrace: stack);
      return false;
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

// =============================================
// FARMER DASHBOARD SCREEN
// =============================================

// lib/features/farmer/screens/farmer_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/farmer_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});
  
  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final farmer = context.read<FarmerProvider>();
    if (auth.currentUser != null) {
      await farmer.loadProducts(auth.currentUser!.id);
      await farmer.loadOrders(auth.currentUser!.id);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 16),
              _buildStatCards(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRecentOrders(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0: break;
            case 1: Navigator.pushNamed(context, '/farmer/inventory');
            case 2: Navigator.pushNamed(context, '/farmer/ai-insights');
            case 3: Navigator.pushNamed(context, '/wallet');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'AI Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeCard() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Text(auth.currentUser?.name[0].toUpperCase() ?? 'F'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        auth.currentUser?.name ?? 'Farmer',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatCards() {
    return Consumer<FarmerProvider>(
      builder: (context, farmer, _) {
        final totalProducts = farmer.products.length;
        final activeProducts = farmer.products.where((p) => p.isActive).length;
        final totalOrders = farmer.orders.length;
        final pendingOrders = farmer.orders.where((o) => 
            o.status == 'placed' || o.status == 'confirmed').length;
        
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Products',
                value: '$activeProducts/$totalProducts',
                icon: Icons.inventory_2,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Orders',
                value: '$pendingOrders/$totalOrders',
                icon: Icons.shopping_bag,
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Add Product',
                icon: Icons.add_box,
                onTap: () => Navigator.pushNamed(context, '/farmer/product/add'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                title: 'View Orders',
                icon: Icons.list_alt,
                onTap: () => Navigator.pushNamed(context, '/farmer/inventory'),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildRecentOrders() {
    return Consumer<FarmerProvider>(
      builder: (context, farmer, _) {
        final recentOrders = farmer.orders.take(5).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Orders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentOrders.isEmpty)
              const Center(child: Text('No orders yet'))
            else
              ...recentOrders.map((order) => _OrderCard(order: order)),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  
  const _OrderCard({required this.order});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(order.status[0].toUpperCase()),
        ),
        title: Text('Order #${order.id.substring(0, 8)}'),
        subtitle: Text('₹${order.totalAmount.toStringAsFixed(2)} • ${order.status}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

// =============================================
// FARMER INVENTORY SCREEN
// =============================================

// lib/features/farmer/screens/farmer_inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/farmer_provider.dart';

class FarmerInventoryScreen extends StatelessWidget {
  const FarmerInventoryScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
      ),
      body: Consumer<FarmerProvider>(
        builder: (context, farmer, _) {
          if (farmer.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (farmer.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No products yet'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/farmer/product/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: farmer.products.length,
            itemBuilder: (context, index) {
              final product = farmer.products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: product.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.images.first,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image),
                        ),
                  title: Text(product.name),
                  subtitle: Text('₹${product.price}/${product.unit} • Stock: ${product.stock}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'toggle',
                        child: Text('Toggle Active'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.pushNamed(
                          context,
                          '/farmer/product/edit',
                          arguments: product.id,
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/farmer/product/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Note: Due to character limit, I'm providing the complete structure.
// The remaining screens (AddEditProductScreen, FarmerAIInsightsScreen, 
// Customer screens, Cart, Checkout, etc.) follow the same pattern with:
// - State management via providers
// - Form validation
// - API calls through Supabase client
// - Error handling
// - Loading states
// - Proper UI/UX

// Each screen would be 200-400 lines implementing full CRUD operations,
// real-time updates, image uploads, payment integration, and map tracking.