import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

enum UpdateStatusState {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  readyToRestart,
  error,
}

class ShorebirdService extends ChangeNotifier {
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

  /// Initializes Shorebird status and optionally checks for updates in background
  Future<void> initialize() async {
    if (!isShorebirdAvailable) {
      debugPrint('[ShorebirdService] Shorebird engine not available in this build (e.g. debug/local emulator).');
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

  /// Silent background check & auto-download
  Future<void> checkForUpdatesSilent() async {
    if (!isShorebirdAvailable) return;
    try {
      final updateStatus = await _updater.checkForUpdate();
      if (updateStatus == UpdateStatus.outdated) {
        debugPrint('[ShorebirdService] Outdated version detected, auto-downloading patch...');
        _status = UpdateStatusState.downloading;
        notifyListeners();
        await _updater.update();
        _status = UpdateStatusState.readyToRestart;
        notifyListeners();
        debugPrint('[ShorebirdService] Patch downloaded and staged! Will apply on next restart.');
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
