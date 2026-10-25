import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/services/update_service.dart';
import '../../core/theme/colors.dart';
import '../../widgets/apple_widgets.dart';

class UpdateScreen extends StatefulWidget {
  final AppReleaseInfo releaseInfo;
  final VoidCallback? onProceedAnyway;

  const UpdateScreen({
    super.key,
    required this.releaseInfo,
    this.onProceedAnyway,
  });

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool _isDownloading = false;

  Future<void> _handleUpdate() async {
    AppleHaptics.mediumImpact();
    setState(() => _isDownloading = true);
    await UpdateService.instance.launchDownload(widget.releaseInfo.downloadUrl);
    if (mounted) {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    return Scaffold(
      backgroundColor: isDark ? BotanicalColors.darkBackground : BotanicalColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 24),
                    // App Icon with update badge
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: isDark ? BotanicalColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                CupertinoIcons.arrow_down_circle_fill,
                                size: 44,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: BotanicalColors.alertRed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title & Version
                    Center(
                      child: Text(
                        'Update Required',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                            ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Version ${widget.releaseInfo.version}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        widget.releaseInfo.releaseTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // What's New Section
                    const AppleSectionHeader('What\'s in this update'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                          width: 0.75,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.releaseInfo.changelog.isEmpty)
                            const Text('Exciting enhancements, bug fixes, and performance updates.')
                          else
                            ...widget.releaseInfo.changelog.map((log) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      CupertinoIcons.checkmark_alt_circle_fill,
                                      size: 17,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        log,
                                        style: const TextStyle(fontSize: 14, height: 1.35),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Safe update reassurance
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder,
                          width: 0.75,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.lock_shield_fill, size: 20, color: primaryColor),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Seamless Update: Your existing tasks, notes, workspaces, and reflections remain 100% safe.',
                              style: TextStyle(fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Update Action
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(CupertinoIcons.arrow_down_to_line, size: 20),
                      label: Text(
                        _isDownloading ? 'Opening Installer...' : 'Download & Update APK',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isDownloading ? null : _handleUpdate,
                    ),
                  ),
                  if (widget.onProceedAnyway != null && !widget.releaseInfo.isMandatory) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        AppleHaptics.selection();
                        widget.onProceedAnyway!();
                      },
                      child: Text(
                        'Remind me later',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
