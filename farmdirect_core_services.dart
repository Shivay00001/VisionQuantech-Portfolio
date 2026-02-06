// =============================================
// lib/core/logging/logger.dart
// =============================================
import 'package:logger/logger.dart';

class AppLogger {
  static late Logger _logger;
  
  static void init() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
  }
  
  static void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }
  
  static void info(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }
  
  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }
  
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}

// =============================================
// lib/core/network/supabase_client.dart
// =============================================
import 'package:supabase_flutter/supabase_flutter.dart';
import '../logging/logger.dart';

class SupabaseClientService {
  final SupabaseClient _client = Supabase.instance.client;
  
  SupabaseClient get client => _client;
  
  // Auth methods
  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;
  
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      
      if (response.user != null) {
        await _createUserProfile(response.user!.id, userData);
      }
      
      return response;
    } catch (e, stack) {
      AppLogger.error('Sign up failed', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<void> _createUserProfile(String userId, Map<String, dynamic> userData) async {
    await _client.from('users').insert({
      'id': userId,
      'email': userData['email'],
      'name': userData['name'],
      'role': userData['role'],
      'phone': userData['phone'],
      'address': userData['address'],
    });
  }
  
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e, stack) {
      AppLogger.error('Sign in failed', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e, stack) {
      AppLogger.error('Sign out failed', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  // Database methods
  PostgrestFilterBuilder<List<Map<String, dynamic>>> from(String table) {
    return _client.from(table);
  }
  
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = _client.from(table).select(columns);
      
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }
      
      return await query;
    } catch (e, stack) {
      AppLogger.error('Select failed from $table', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.from(table).insert(data).select().single();
      return response;
    } catch (e, stack) {
      AppLogger.error('Insert failed into $table', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<void> update(
    String table,
    Map<String, dynamic> data,
    String id,
  ) async {
    try {
      await _client.from(table).update(data).eq('id', id);
    } catch (e, stack) {
      AppLogger.error('Update failed in $table', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<void> delete(String table, String id) async {
    try {
      await _client.from(table).delete().eq('id', id);
    } catch (e, stack) {
      AppLogger.error('Delete failed from $table', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  // Storage methods
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    String? contentType,
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );
      
      return _client.storage.from(bucket).getPublicUrl(path);
    } catch (e, stack) {
      AppLogger.error('File upload failed', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e, stack) {
      AppLogger.error('File delete failed', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  // Real-time subscription
  RealtimeChannel subscribe(
    String table,
    void Function(PostgresChangePayload) callback,
  ) {
    return _client
        .channel('$table-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: callback,
        )
        .subscribe();
  }
}

// =============================================
// lib/core/network/http_client.dart
// =============================================
import 'package:dio/dio.dart';
import '../logging/logger.dart';

class HttpClient {
  late final Dio _dio;
  
  HttpClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => AppLogger.debug(obj.toString()),
    ));
  }
  
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e, stack) {
      AppLogger.error('GET request failed: $path', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e, stack) {
      AppLogger.error('POST request failed: $path', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e, stack) {
      AppLogger.error('PUT request failed: $path', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e, stack) {
      AppLogger.error('DELETE request failed: $path', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

// =============================================
// lib/core/network/api_response.dart
// =============================================
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;
  
  ApiResponse.success(this.data)
      : success = true,
        error = null;
  
  ApiResponse.error(this.error)
      : success = false,
        data = null;
}

// =============================================
// lib/core/constants/app_constants.dart
// =============================================
class AppConstants {
  // API Keys (load from environment)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );
  
  static const String googleMapsKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'your-maps-key',
  );
  
  static const String razorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_key',
  );
  
  static const String openWeatherKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: 'your-weather-key',
  );
  
  static const String huggingFaceKey = String.fromEnvironment(
    'HUGGINGFACE_API_KEY',
    defaultValue: 'your-hf-key',
  );
  
  // API Endpoints
  static const String huggingFaceUrl = 'https://api-inference.huggingface.co';
  static const String openWeatherUrl = 'https://api.openweathermap.org/data/2.5';
  static const String translationUrl = 'https://libretranslate.com/translate';
  
  // Storage Buckets
  static const String productImagesBucket = 'product-images';
  static const String profileImagesBucket = 'profile-images';
  static const String reviewImagesBucket = 'review-images';
  
  // App Config
  static const int itemsPerPage = 20;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const double defaultLat = 28.6139; // Delhi
  static const double defaultLng = 77.2090;
  
  // Product Categories
  static const List<String> productCategories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Pulses',
    'Dairy',
    'Eggs',
    'Honey',
    'Spices',
  ];
  
  // Units
  static const List<String> units = [
    'kg',
    'gram',
    'liter',
    'piece',
    'dozen',
    'bunch',
  ];
  
  // Order Status
  static const List<String> orderStatuses = [
    'placed',
    'confirmed',
    'preparing',
    'out_for_delivery',
    'delivered',
    'cancelled',
  ];
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'wallet',
    'razorpay',
    'upi',
    'cod',
  ];
}

// =============================================
// lib/core/utils/validators.dart
// =============================================
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }
  
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }
  
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Enter a valid price';
    }
    return null;
  }
  
  static String? stock(String? value) {
    if (value == null || value.isEmpty) {
      return 'Stock is required';
    }
    final stock = int.tryParse(value);
    if (stock == null || stock < 0) {
      return 'Enter a valid stock quantity';
    }
    return null;
  }
}