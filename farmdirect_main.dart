import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/network/supabase_client.dart';
import 'core/notifications/fcm_service.dart';
import 'core/logging/logger.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/farmer/providers/farmer_provider.dart';
import 'features/customer/providers/customer_provider.dart';
import 'features/wallet/providers/wallet_provider.dart';
import 'features/cart/providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize logger
  AppLogger.init();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    AppLogger.info('Firebase initialized');
    
    // Initialize Supabase
    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://your-project.supabase.co',
      ),
      anonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'your-anon-key',
      ),
    );
    AppLogger.info('Supabase initialized');
    
    // Initialize FCM
    final fcmService = FCMService();
    await fcmService.initialize();
    AppLogger.info('FCM initialized');
    
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    runApp(FarmDirectApp(
      supabaseClient: SupabaseClientService(),
      fcmService: fcmService,
      sharedPreferences: prefs,
    ));
  } catch (e, stack) {
    AppLogger.error('Failed to initialize app', error: e, stackTrace: stack);
    runApp(ErrorApp(error: e.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}