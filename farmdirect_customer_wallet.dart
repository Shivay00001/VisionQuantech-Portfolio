// =============================================
// CUSTOMER PROVIDER
// =============================================

// lib/features/customer/providers/customer_provider.dart
import 'package:flutter/material.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/logging/logger.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/order_model.dart';

class CustomerProvider extends ChangeNotifier {
  final SupabaseClientService _supabase;
  
  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;
  
  CustomerProvider(this._supabase);
  
  List<ProductModel> get products {
    var filtered = _products.where((p) => p.isActive).toList();
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    
    return filtered;
  }
  
  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  Future<void> loadProducts() async {
    _setLoading(true);
    try {
      final data = await _supabase.from('products').select().eq('is_active', true);
      _products = data.map((json) => ProductModel.fromJson(json)).toList();
      _error = null;
    } catch (e, stack) {
      AppLogger.error('Load products failed', error: e, stackTrace: stack);
      _error = e.toString();
    }
    _setLoading(false);
  }
  
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final data = await _supabase.select('products', filters: {'id': productId});
      if (data.isNotEmpty) {
        return ProductModel.fromJson(data.first);
      }
    } catch (e, stack) {
      AppLogger.error('Get product failed', error: e, stackTrace: stack);
    }
    return null;
  }
  
  Future<void> loadOrders(String customerId) async {
    _setLoading(true);
    try {
      final data = await _supabase.select('orders', filters: {'customer_id': customerId});
      _orders = data.map((json) => OrderModel.fromJson(json)).toList();
      _error = null;
    } catch (e, stack) {
      AppLogger.error('Load orders failed', error: e, stackTrace: stack);
      _error = e.toString();
    }
    _setLoading(false);
  }
  
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final data = await _supabase.select('orders', filters: {'id': orderId});
      if (data.isNotEmpty) {
        return OrderModel.fromJson(data.first);
      }
    } catch (e, stack) {
      AppLogger.error('Get order failed', error: e, stackTrace: stack);
    }
    return null;
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

// =============================================
// CART PROVIDER
// =============================================

// lib/features/cart/providers/cart_provider.dart
import 'package:flutter/material.dart';
import '../../../shared/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  
  CartItem({required this.product, this.quantity = 1});
  
  double get subtotal => product.price * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  
  Map<String, CartItem> get items => _items;
  
  int get itemCount => _items.length;
  
  int get totalQuantity => _items.values.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalAmount => _items.values.fold(0, (sum, item) => sum + item.subtotal);
  
  void addItem(ProductModel product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += quantity;
    } else {
      _items[product.id] = CartItem(product: product, quantity: quantity);
    }
    notifyListeners();
  }
  
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }
  
  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        _items.remove(productId);
      } else {
        _items[productId]!.quantity = quantity;
      }
      notifyListeners();
    }
  }
  
  void clear() {
    _items.clear();
    notifyListeners();
  }
}

// =============================================
// WALLET PROVIDER
// =============================================

// lib/features/wallet/providers/wallet_provider.dart
import 'package:flutter/material.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/logging/logger.dart';

class WalletModel {
  final String id;
  final String userId;
  final double balance;
  
  WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
  });
  
  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balance: (json['balance'] as num).toDouble(),
    );
  }
}

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final String method;
  final String status;
  final String? description;
  final DateTime createdAt;
  
  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.method,
    required this.status,
    this.description,
    required this.createdAt,
  });
  
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      method: json['method'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class WalletProvider extends ChangeNotifier {
  final SupabaseClientService _supabase;
  
  WalletModel? _wallet;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;
  
  WalletProvider(this._supabase);
  
  WalletModel? get wallet => _wallet;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get balance => _wallet?.balance ?? 0.0;
  
  Future<void> loadWallet(String userId) async {
    _setLoading(true);
    try {
      final data = await _supabase.select('wallets', filters: {'user_id': userId});
      if (data.isNotEmpty) {
        _wallet = WalletModel.fromJson(data.first);
      }
      await loadTransactions(userId);
      _error = null;
    } catch (e, stack) {
      AppLogger.error('Load wallet failed', error: e, stackTrace: stack);
      _error = e.toString();
    }
    _setLoading(false);
  }
  
  Future<void> loadTransactions(String userId) async {
    try {
      final data = await _supabase.from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      _transactions = data.map((json) => TransactionModel.fromJson(json)).toList();
    } catch (e, stack) {
      AppLogger.error('Load transactions failed', error: e, stackTrace: stack);
    }
  }
  
  Future<bool> addMoney({
    required String userId,
    required double amount,
    required String method,
    String? referenceId,
  }) async {
    _setLoading(true);
    try {
      // Create transaction
      await _supabase.insert('transactions', {
        'user_id': userId,
        'amount': amount,
        'type': 'credit',
        'method': method,
        'reference_id': referenceId,
        'status': 'completed',
        'description': 'Added money via $method',
      });
      
      // Update wallet balance
      final newBalance = balance + amount;
      await _supabase.update('wallets', {'balance': newBalance}, _wallet!.id);
      
      await loadWallet(userId);
      _setLoading(false);
      return true;
    } catch (e, stack) {
      AppLogger.error('Add money failed', error: e, stackTrace: stack);
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }
  
  Future<bool> deductMoney({
    required String userId,
    required double amount,
    required String description,
  }) async {
    if (balance < amount) {
      _error = 'Insufficient balance';
      return false;
    }
    
    try {
      await _supabase.insert('transactions', {
        'user_id': userId,
        'amount': amount,
        'type': 'debit',
        'method': 'wallet',
        'status': 'completed',
        'description': description,
      });
      
      final newBalance = balance - amount;
      await _supabase.update('wallets', {'balance': newBalance}, _wallet!.id);
      
      await loadWallet(userId);
      return true;
    } catch (e, stack) {
      AppLogger.error('Deduct money failed', error: e, stackTrace: stack);
      _error = e.toString();
      return false;
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

// =============================================
// CUSTOMER HOME SCREEN
// =============================================

// lib/features/customer/screens/customer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../../core/constants/app_constants.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});
  
  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<CustomerProvider>().loadProducts());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FarmDirect'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Navigator.pushNamed(context, '/customer/cart'),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    if (cart.itemCount == 0) return const SizedBox();
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 1: Navigator.pushNamed(context, '/customer/orders');
            case 2: Navigator.pushNamed(context, '/wallet');
            case 3: Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search fresh products...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onChanged: (value) {
          context.read<CustomerProvider>().setSearchQuery(value);
        },
      ),
    );
  }
  
  Widget _buildCategoryChips() {
    return Consumer<CustomerProvider>(
      builder: (context, customer, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: customer._selectedCategory == null,
                onSelected: (_) => customer.setCategory(null),
              ),
              const SizedBox(width: 8),
              ...AppConstants.productCategories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: customer._selectedCategory == category,
                  onSelected: (_) => customer.setCategory(category),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildProductGrid() {
    return Consumer<CustomerProvider>(
      builder: (context, customer, _) {
        if (customer.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (customer.products.isEmpty) {
          return const Center(child: Text('No products available'));
        }
        
        return RefreshIndicator(
          onRefresh: customer.loadProducts,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: customer.products.length,
            itemBuilder: (context, index) {
              final product = customer.products[index];
              return _ProductCard(product: product);
            },
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  
  const _ProductCard({required this.product});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/customer/product/detail',
            arguments: product.id,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 48),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price}/${product.unit}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.organicCertified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Organic',
                            style: TextStyle(fontSize: 10, color: Colors.green),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          context.read<CartProvider>().addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to cart'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================
// MAPS SERVICE
// =============================================

// lib/core/maps/maps_service.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../logging/logger.dart';

class MapsService {
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services disabled');
        return null;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      return await Geolocator.getCurrentPosition();
    } catch (e, stack) {
      AppLogger.error('Get location failed', error: e, stackTrace: stack);
      return null;
    }
  }
  
  Future<String?> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
    } catch (e, stack) {
      AppLogger.error('Geocoding failed', error: e, stackTrace: stack);
    }
    return null;
  }
  
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000; // Convert to km
  }
}

// =============================================
// DEPLOYMENT INSTRUCTIONS
// =============================================

/*
DEPLOYMENT GUIDE:

1. SUPABASE SETUP:
   - Create project at supabase.com
   - Run SQL from database schema artifact
   - Enable RLS on all tables
   - Create storage buckets: product-images, profile-images, review-images
   - Get project URL and anon key

2. GOOGLE MAPS:
   - Get API keys from Google Cloud Console
   - Enable Maps SDK for Android/iOS/Web
   - Add keys to android/app/src/main/AndroidManifest.xml
   - Add keys to ios/Runner/AppDelegate.swift

3. FIREBASE:
   - Create Firebase project
   - Add Android/iOS apps
   - Download google-services.json and GoogleService-Info.plist
   - Enable FCM

4. RAZORPAY:
   - Sign up at razorpay.com
   - Get test/live keys
   - Configure webhook URLs

5. BUILD COMMANDS:
   flutter clean
   flutter pub get
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   flutter build web --release  # Web

6. ENVIRONMENT VARIABLES:
   - Copy .env.example to .env
   - Fill in all API keys
   - Never commit .env to git

7. TESTING:
   flutter test
   flutter drive --target=test_driver/app.dart

8. CI/CD (GitHub Actions):
   - Use provided workflow files
   - Add secrets to GitHub repository
*/