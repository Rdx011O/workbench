import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppReleaseInfo {
  final String version;
  final int versionCode;
  final String releaseTitle;
  final List<String> changelog;
  final String downloadUrl;
  final String releaseDate;
  final bool isMandatory;

  AppReleaseInfo({
    required this.version,
    required this.versionCode,
    required this.releaseTitle,
    required this.changelog,
    required this.downloadUrl,
    required this.releaseDate,
    this.isMandatory = false,
  });

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    List<String> logs = [];
    if (json['changelog'] is List) {
      logs = (json['changelog'] as List).map((e) => e.toString()).toList();
    } else if (json['changelog'] is String) {
      logs = (json['changelog'] as String).split('\n').where((l) => l.trim().isNotEmpty).toList();
    }

    return AppReleaseInfo(
      version: json['version'] as String? ?? '1.2.0',
      versionCode: json['versionCode'] as int? ?? 3,
      releaseTitle: json['releaseTitle'] as String? ?? 'Workbench Update',
      changelog: logs,
      downloadUrl: json['downloadUrl'] as String? ?? '',
      releaseDate: json['releaseDate'] as String? ?? '',
      isMandatory: json['isMandatory'] as bool? ?? false,
    );
  }
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const MethodChannel _installerChannel = MethodChannel('com.workbench.app/installer');

  // Remote GitHub repository raw config endpoints
  static String updateCheckUrl = 'https://raw.githubusercontent.com/Rdx011O/workbench/main/version.json';
  static String fallbackUpdateCheckUrl = 'https://raw.githubusercontent.com/Rdx011O/workbench/main/botanical_planner/version.json';

  Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }

  /// Checks remote GitHub endpoint for new releases.
  /// Compares both versionCode and semantic versioning (major.minor.patch).
  Future<AppReleaseInfo?> checkForUpdate({String? customUrl}) async {
    try {
      final targetUrl = customUrl ?? updateCheckUrl;
      final uri = Uri.parse(targetUrl);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(responseBody) as Map<String, dynamic>;
        final remoteRelease = AppReleaseInfo.fromJson(data);

        final packageInfo = await getPackageInfo();
        final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;
        final currentVersion = packageInfo.version;

        if (remoteRelease.versionCode > currentBuildNumber ||
            _isRemoteVersionHigher(remoteRelease.version, currentVersion)) {
          return remoteRelease;
        }
        return null;
      } else if (customUrl == null && targetUrl != fallbackUpdateCheckUrl) {
        return await checkForUpdate(customUrl: fallbackUpdateCheckUrl);
      }
    } catch (e) {
      debugPrint('Update check error: $e');
      if (customUrl == null) {
        return await checkForUpdate(customUrl: fallbackUpdateCheckUrl);
      }
    }
    return null;
  }

  /// Semantic version comparison (returns true if remote > current)
  bool _isRemoteVersionHigher(String remote, String current) {
    try {
      final remoteParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final r = i < remoteParts.length ? remoteParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Downloads the APK file entirely within the app (no redirecting to GitHub web pages)
  /// and automatically invokes the native Android Package Installer.
  Future<void> downloadAndInstallApk({
    required String downloadUrl,
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
    required void Function(String statusMessage) onStatus,
    required void Function(String errorMessage) onError,
    required VoidCallback onCompleted,
  }) async {
    if (downloadUrl.isEmpty) {
      onError('Download URL is empty.');
      return;
    }

    try {
      onStatus('Connecting to secure download server...');
      final uri = Uri.parse(downloadUrl);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 25);

      final request = await client.getUrl(uri);
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await request.close();
      if (response.statusCode != 200) {
        onError('Server responded with HTTP ${response.statusCode}');
        return;
      }

      final contentLength = response.contentLength;
      onStatus('Downloading update package...');

      // Save APK in app temporary / cache directory
      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/workbench_update.apk');
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final sink = apkFile.openWrite();
      int receivedBytes = 0;

      await for (final chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);

        final progress = contentLength > 0 ? (receivedBytes / contentLength) : 0.0;
        onProgress(progress.clamp(0.0, 1.0), receivedBytes, contentLength);
      }

      await sink.flush();
      await sink.close();

      onStatus('Verifying package integrity...');
      if (!await apkFile.exists() || await apkFile.length() == 0) {
        onError('Downloaded package is empty or corrupted.');
        return;
      }

      onStatus('Starting native installer...');
      onCompleted();

      // Trigger native in-app installation
      if (Platform.isAndroid) {
        await _installerChannel.invokeMethod('installApk', {
          'filePath': apkFile.path,
        });
      } else {
        // Fallback for desktop testing
        await launchUrl(Uri.file(apkFile.path), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('In-app update download error: $e');
      onError('Failed to download update: ${e.toString()}');
    }
  }

  /// External browser fallback if desired
  Future<bool> launchDownloadExternal(String downloadUrl) async {
    if (downloadUrl.isEmpty) return false;
    final uri = Uri.parse(downloadUrl);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
