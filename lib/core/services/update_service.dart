import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
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
      version: json['version'] as String? ?? '1.0.0',
      versionCode: json['versionCode'] as int? ?? 1,
      releaseTitle: json['releaseTitle'] as String? ?? 'New Botanical Update',
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

  // Remote GitHub repository raw config endpoint:
  static String updateCheckUrl = 'https://raw.githubusercontent.com/Rdx011O/workbench/main/version.json';
  static String fallbackUpdateCheckUrl = 'https://raw.githubusercontent.com/Rdx011O/workbench/main/botanical_planner/version.json';

  Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }

  /// Checks remote server / GitHub for any new release.
  /// Returns [AppReleaseInfo] if a newer version is available, or null if up to date.
  Future<AppReleaseInfo?> checkForUpdate({String? customUrl}) async {
    try {
      final targetUrl = customUrl ?? updateCheckUrl;
      final uri = Uri.parse(targetUrl);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(responseBody) as Map<String, dynamic>;
        final remoteRelease = AppReleaseInfo.fromJson(data);

        final packageInfo = await getPackageInfo();
        final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

        if (remoteRelease.versionCode > currentBuildNumber) {
          return remoteRelease;
        }
        return null;
      } else if (customUrl == null && targetUrl != fallbackUpdateCheckUrl) {
        // Try fallback URL (in case version.json is inside botanical_planner/)
        return await checkForUpdate(customUrl: fallbackUpdateCheckUrl);
      }
    } catch (_) {
      if (customUrl == null) {
        return await checkForUpdate(customUrl: fallbackUpdateCheckUrl);
      }
    }
    return null;
  }

  /// Launches the APK download URL in browser or package installer
  Future<bool> launchDownload(String downloadUrl) async {
    if (downloadUrl.isEmpty) return false;
    final uri = Uri.parse(downloadUrl);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
