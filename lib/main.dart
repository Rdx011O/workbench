import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/shorebird_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase (wrapped with try-catch so it won't crash if google-services.json is pending)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize SQLite database and pre-populate initial data
  await DatabaseService.instance.database;

  // Initialize Auth service session
  await AuthService.instance.initialize(DatabaseService.instance);

  // Initialize local notifications service & channels
  await NotificationService.instance.initialize();

  // Initialize Shorebird OTA code push updater
  unawaited(ShorebirdService.instance.initialize());

  runApp(
    const ProviderScope(
      child: WorkbenchApp(),
    ),
  );
}

class WorkbenchApp extends ConsumerWidget {
  const WorkbenchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Workbench',
      debugShowCheckedModeBanner: false,
      theme: WorkbenchTheme.lightTheme,
      darkTheme: WorkbenchTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const AnimatedSplashScreen(),
    );
  }
}
