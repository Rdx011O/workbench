import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'widgets/app_scaffold.dart';

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

  // Initialize SQLite database and pre-populate demo data
  await DatabaseService.instance.database;

  // Initialize local notifications service
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: BotanicalPlannerApp(),
    ),
  );
}

class BotanicalPlannerApp extends ConsumerWidget {
  const BotanicalPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Botanical Ink Planner',
      debugShowCheckedModeBanner: false,
      theme: BotanicalTheme.lightTheme,
      darkTheme: BotanicalTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const AppScaffold(),
    );
  }
}
