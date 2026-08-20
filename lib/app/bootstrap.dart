import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import '../shared/services/app_config_service.dart';

/// Bootstrap the application — initialize all services before app starts
class Bootstrap {
  Bootstrap._();

  static Future<ProviderContainer> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // System UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F172A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize Supabase
    // NOTE: Replace with your actual Supabase URL and Anon Key
    // In production, use --dart-define-from-file for these values
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://your-project.supabase.co',
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'your-anon-key',
    );

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    AppLogger.info('Supabase initialized', 'Bootstrap');

    // Create provider container
    final container = ProviderContainer();

    // Load app config
    try {
      final configService = container.read(appConfigServiceProvider);
      await configService.loadConfig();
      AppLogger.info('App config loaded', 'Bootstrap');
    } catch (e) {
      AppLogger.warning('Failed to load app config, using defaults', 'Bootstrap');
    }

    // Initialize Firebase (uncomment when google-services.json is added)
    // await Firebase.initializeApp();
    // AppLogger.info('Firebase initialized', 'Bootstrap');

    AppLogger.info('Bootstrap complete ✓', 'Bootstrap');
    return container;
  }
}
