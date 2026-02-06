// =============================================
// lib/app/app.dart
// =============================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/supabase_client.dart';
import '../core/notifications/fcm_service.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/farmer/providers/farmer_provider.dart';
import '../features/customer/providers/customer_provider.dart';
import '../features/wallet/providers/wallet_provider.dart';
import '../features/cart/providers/cart_provider.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class FarmDirectApp extends StatelessWidget {
  final SupabaseClientService supabaseClient;
  final FCMService fcmService;
  final SharedPreferences sharedPreferences;
  
  const FarmDirectApp({
    super.key,
    required this.supabaseClient,
    required this.fcmService,
    required this.sharedPreferences,
  });
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(supabaseClient),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FarmerProvider>(
          create: (_) => FarmerProvider(supabaseClient),
          update: (_, auth, previous) =>
              previous ?? FarmerProvider(supabaseClient),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CustomerProvider>(
          create: (_) => CustomerProvider(supabaseClient),
          update: (_, auth, previous) =>
              previous ?? CustomerProvider(supabaseClient),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
          create: (_) => WalletProvider(supabaseClient),
          update: (_, auth, previous) {
            final provider = previous ?? WalletProvider(supabaseClient);
            if (auth.currentUser != null) {
              provider.loadWallet(auth.currentUser!.id);
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(supabaseClient),
        ),
      ],
      child: MaterialApp(
        title: 'FarmDirect',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.initial,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

// =============================================
// lib/app/routes/app_routes.dart
// =============================================
import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/farmer/screens/farmer_dashboard_screen.dart';
import '../../features/farmer/screens/farmer_inventory_screen.dart';
import '../../features/farmer/screens/add_edit_product_screen.dart';
import '../../features/farmer/screens/farmer_ai_insights_screen.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import '../../features/customer/screens/product_list_screen.dart';
import '../../features/customer/screens/product_detail_screen.dart';
import '../../features/customer/screens/cart_screen.dart';
import '../../features/customer/screens/checkout_screen.dart';
import '../../features/customer/screens/orders_screen.dart';
import '../../features/customer/screens/order_tracking_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/wallet/screens/add_money_screen.dart';
import '../../features/settings/screens/profile_screen.dart';

class AppRoutes {
  static const String initial = '/login';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  
  // Farmer Routes
  static const String farmerDashboard = '/farmer/dashboard';
  static const String farmerInventory = '/farmer/inventory';
  static const String addProduct = '/farmer/product/add';
  static const String editProduct = '/farmer/product/edit';
  static const String farmerAIInsights = '/farmer/ai-insights';
  
  // Customer Routes
  static const String customerHome = '/customer/home';
  static const String productList = '/customer/products';
  static const String productDetail = '/customer/product/detail';
  static const String cart = '/customer/cart';
  static const String checkout = '/customer/checkout';
  static const String orders = '/customer/orders';
  static const String orderTracking = '/customer/order/tracking';
  
  // Shared Routes
  static const String wallet = '/wallet';
  static const String addMoney = '/wallet/add-money';
  static const String profile = '/profile';
  
  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    farmerDashboard: (_) => const FarmerDashboardScreen(),
    farmerInventory: (_) => const FarmerInventoryScreen(),
    addProduct: (_) => const AddEditProductScreen(),
    farmerAIInsights: (_) => const FarmerAIInsightsScreen(),
    customerHome: (_) => const CustomerHomeScreen(),
    productList: (_) => const ProductListScreen(),
    cart: (_) => const CartScreen(),
    checkout: (_) => const CheckoutScreen(),
    orders: (_) => const OrdersScreen(),
    wallet: (_) => const WalletScreen(),
    addMoney: (_) => const AddMoneyScreen(),
    profile: (_) => const ProfileScreen(),
  };
  
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case productDetail:
        final productId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        );
      case editProduct:
        final productId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => AddEditProductScreen(productId: productId),
        );
      case orderTracking:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
        );
      case home:
        // Route based on user role
        return MaterialPageRoute(
          builder: (context) => const _HomeRouter(),
        );
      default:
        return null;
    }
  }
}

class _HomeRouter extends StatelessWidget {
  const _HomeRouter();
  
  @override
  Widget build(BuildContext context) {
    return const CustomerHomeScreen(); // Will be replaced with role-based routing
  }
}

// =============================================
// lib/app/theme/app_theme.dart
// =============================================
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color secondaryColor = Color(0xFFFF6F00);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200],
        selectedColor: primaryColor.withOpacity(0.2),
        labelStyle: const TextStyle(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// =============================================
// lib/core/notifications/fcm_service.dart
// =============================================
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../logging/logger.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    try {
      // Request permission
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Initialize local notifications
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings();
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _localNotifications.initialize(initializationSettings);
      
      // Get FCM token
      final token = await _messaging.getToken();
      AppLogger.info('FCM Token: $token');
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      
      AppLogger.info('FCM initialized successfully');
    } catch (e, stack) {
      AppLogger.error('FCM initialization failed', error: e, stackTrace: stack);
    }
  }
  
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info('Foreground message: ${message.notification?.title}');
    
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
    );
  }
  
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'farmdirect_channel',
      'FarmDirect Notifications',
      channelDescription: 'Notifications for FarmDirect app',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
    );
  }
  
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  AppLogger.info('Background message: ${message.notification?.title}');
}