import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum UpdateStatusState {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  readyToRestart,
  error,
}

class ShorebirdService extends ChangeNotifier with WidgetsBindingObserver {
  ShorebirdService._();
  static final ShorebirdService instance = ShorebirdService._();

  final ShorebirdUpdater _updater = ShorebirdUpdater();

  Patch? _currentPatch;
  Patch? get currentPatch => _currentPatch;

  UpdateStatusState _status = UpdateStatusState.idle;
  UpdateStatusState get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isShorebirdAvailable => _updater.isAvailable;

  int? get currentPatchNumber => _currentPatch?.number;

  bool _initialized = false;
  DateTime? _lastCheckTime;

  /// Initializes Shorebird status, lifecycle observer, and performs background update check
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);

    if (!isShorebirdAvailable) {
      debugPrint('[ShorebirdService] Shorebird engine not active in debug/local mode.');
      return;
    }

    try {
      _currentPatch = await _updater.readCurrentPatch();
      notifyListeners();
      debugPrint('[ShorebirdService] Current patch: ${_currentPatch?.number ?? 'Base Release'}');
    } catch (e) {
      debugPrint('[ShorebirdService] Failed to read current patch: $e');
    }

    // Perform silent background update check without blocking
    unawaited(checkForUpdatesSilent());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Throttle checks to once every 10 minutes when app is resumed
      final now = DateTime.now();
      if (_lastCheckTime == null || now.difference(_lastCheckTime!) > const Duration(minutes: 10)) {
        unawaited(checkForUpdatesSilent());
      }
    }
  }

  /// Silent background check & auto-download
  Future<void> checkForUpdatesSilent() async {
    if (!isShorebirdAvailable) return;
    _lastCheckTime = DateTime.now();

    try {
      final updateStatus = await _updater.checkForUpdate();
      if (updateStatus == UpdateStatus.outdated) {
        debugPrint('[ShorebirdService] Outdated version detected, auto-downloading patch...');
        _status = UpdateStatusState.downloading;
        notifyListeners();
        await _updater.update();
        _status = UpdateStatusState.readyToRestart;
        notifyListeners();
        debugPrint('[ShorebirdService] Patch downloaded! Showing prompt.');

        // Show a non-intrusive in-app banner to alert user
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            backgroundColor: const Color(0xFF1B4332),
            duration: const Duration(seconds: 10),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workbench Updated',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'New update ready. Reopen app to apply.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        _status = UpdateStatusState.upToDate;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ShorebirdService] Silent update check failed: $e');
    }
  }

  /// Explicit check triggered by user action
  Future<void> checkManually() async {
    if (!isShorebirdAvailable) {
      _status = UpdateStatusState.idle;
      _errorMessage = 'Shorebird OTA is active in release builds.';
      notifyListeners();
      return;
    }

    _status = UpdateStatusState.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      final updateStatus = await _updater.checkForUpdate();
      if (updateStatus == UpdateStatus.outdated) {
        _status = UpdateStatusState.updateAvailable;
      } else {
        _status = UpdateStatusState.upToDate;
      }
    } catch (e) {
      _status = UpdateStatusState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Explicit download triggered by user
  Future<bool> downloadPatch() async {
    if (!isShorebirdAvailable) return false;

    _status = UpdateStatusState.downloading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _updater.update();
      _status = UpdateStatusState.readyToRestart;
      notifyListeners();
      return true;
    } catch (e) {
      _status = UpdateStatusState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
