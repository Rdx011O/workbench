import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/update_service.dart';
import '../core/theme/colors.dart';
import '../views/update/update_screen.dart';
import 'app_scaffold.dart';

class AppUpdateGate extends ConsumerStatefulWidget {
  const AppUpdateGate({super.key});

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate> {
  bool _isChecking = true;
  AppReleaseInfo? _neededUpdate;
  bool _proceedAnyway = false;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    try {
      final release = await UpdateService.instance
          .checkForUpdate()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      if (mounted) {
        setState(() {
          _neededUpdate = release;
          _isChecking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _neededUpdate = null;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark ? BotanicalColors.darkBackground : BotanicalColors.lightBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? BotanicalColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.leaf_arrow_circlepath,
                    size: 32,
                    color: Color(0xFF6B5E8A),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const CupertinoActivityIndicator(radius: 11),
            ],
          ),
        ),
      );
    }

    // If app needed update, ONLY show the update page!
    if (_neededUpdate != null && !_proceedAnyway) {
      return UpdateScreen(
        releaseInfo: _neededUpdate!,
        onProceedAnyway: () {
          setState(() => _proceedAnyway = true);
        },
      );
    }

    // Otherwise show the app!
    return const AppScaffold();
  }
}
