import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'core/services/sync_service.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/scroll_control_provider.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/theme_config.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/router_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize push notifications
  await NotificationService().initialize();

  // Initialize Facebook Audience Network
  await AdService().initialize();

  // Request other permissions (Location)
  // Request other permissions (Location)
  await _requestPermissions();

  // Set High Refresh Rate
  await _setHighRefreshRate();

  // Initialize Services
  final syncService = SyncService();
  await syncService.init();

  final languageProvider = LanguageProvider();
  await languageProvider.loadSavedLanguage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScrollControlProvider()),
        ChangeNotifierProvider.value(value: syncService),
        ChangeNotifierProvider.value(value: languageProvider),
      ],
      child: const BloodReqApp(),
    ),
  );
}

class BloodReqApp extends StatelessWidget {
  const BloodReqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: RouterService.router,
          );
        },
      ),
    );
  }
}

Future<void> _requestPermissions() async {
  try {
    // Check and request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  } catch (e) {
    debugPrint('Error requesting permissions: $e');
  }
}

Future<void> _setHighRefreshRate() async {
  try {
    if (Platform.isAndroid) {
      await FlutterDisplayMode.setHighRefreshRate();
    }
  } catch (e) {
    debugPrint('Error setting high refresh rate: $e');
  }
}
