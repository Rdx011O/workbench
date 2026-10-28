import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/database_service.dart';

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

  // Remote GitHub repository raw config endpoints
  static String updateCheckUrl = 'https://raw.githubusercontent.com/Rdx011O/workbench/main/version.json';
  static String fallbackUpdateCheckUrl = 'https://raw.githubusercontent.com/Rdx011O/workbench/main/botanical_planner/version.json';

  Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }

  /// Checks remote GitHub endpoint for new releases.
  /// When [force] is false (e.g. startup / splash), it respects user dismissal
  /// and only shows the update screen ONCE. It will never bother the user again
  /// until a genuinely new update version is published.
  Future<AppReleaseInfo?> checkForUpdate({bool force = false, String? customUrl}) async {
    try {
      final targetUrl = customUrl ?? updateCheckUrl;
      final uri = Uri.parse(targetUrl);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(responseBody) as Map<String, dynamic>;
        final remoteRelease = AppReleaseInfo.fromJson(data);

        final packageInfo = await getPackageInfo();
        final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

        // If the current app build is already >= remote version code, no update needed!
        if (currentBuildNumber >= remoteRelease.versionCode) {
          return null;
        }

        // Check if user already dismissed or acknowledged this version
        if (!force) {
          final dismissedCodeStr = await DatabaseService.instance.getPreference('dismissed_update_version_code');
          final dismissedCode = int.tryParse(dismissedCodeStr ?? '0') ?? 0;
          if (dismissedCode >= remoteRelease.versionCode) {
            // Already shown once to the user; do not bother them on startup!
            return null;
          }
        }

        return remoteRelease;
      } else if (customUrl == null && targetUrl != fallbackUpdateCheckUrl) {
        return await checkForUpdate(force: force, customUrl: fallbackUpdateCheckUrl);
      }
    } catch (e) {
      debugPrint('Update check error: $e');
      if (customUrl == null) {
        return await checkForUpdate(force: force, customUrl: fallbackUpdateCheckUrl);
      }
    }
    return null;
  }

  /// Records that the user has seen/acknowledged this update so it never blocks or bothers them again
  Future<void> markUpdateDismissed(int versionCode) async {
    try {
      await DatabaseService.instance.setPreference('dismissed_update_version_code', '$versionCode');
    } catch (e) {
      debugPrint('Error storing dismissed update version: $e');
    }
  }

  /// Standard external download launcher (opens release download in browser)
  Future<bool> launchDownload(String downloadUrl) async {
    if (downloadUrl.isEmpty) return false;
    final uri = Uri.parse(downloadUrl);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
