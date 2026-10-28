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
  bool _isLaunching = false;

  Future<void> _handleDownload() async {
    AppleHaptics.mediumImpact();
    setState(() => _isLaunching = true);

    // Mark dismissed so it will not prompt again on subsequent launches
    await UpdateService.instance.markUpdateDismissed(widget.releaseInfo.versionCode);

    // Launch external download
    await UpdateService.instance.launchDownload(widget.releaseInfo.downloadUrl);

    if (mounted) {
      setState(() => _isLaunching = false);
      // Automatically proceed into the app so user is not stuck on this screen
      if (widget.onProceedAnyway != null) {
        widget.onProceedAnyway!();
      }
    }
  }

  Future<void> _handleDismiss() async {
    AppleHaptics.selection();
    // Mark dismissed so app does not bother user until next real release
    await UpdateService.instance.markUpdateDismissed(widget.releaseInfo.versionCode);
    if (widget.onProceedAnyway != null) {
      widget.onProceedAnyway!();
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
                    const SizedBox(height: 16),
                    // App Logo with update badge
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: isDark ? BotanicalColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(24),
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    CupertinoIcons.arrow_down_circle_fill,
                                    size: 44,
                                    color: primaryColor,
                                  ),
                                ),
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
                                'UPDATE',
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
                    const SizedBox(height: 20),

                    // Title & Version
                    Center(
                      child: Text(
                        'New Workbench Available',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
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
                          'Version ${widget.releaseInfo.version} (${widget.releaseInfo.releaseDate})',
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
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Changelog Section
                    const AppleSectionHeader('What\'s New in this Release', padding: EdgeInsets.only(bottom: 8)),
                    AppleGroupedCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      children: [
                        if (widget.releaseInfo.changelog.isEmpty)
                          const Text('Performance enhancements, bug fixes, and stability improvements.')
                        else
                          ...widget.releaseInfo.changelog.map((log) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      CupertinoIcons.checkmark_alt_circle_fill,
                                      size: 16,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      log,
                                      style: const TextStyle(fontSize: 14, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Data Safe Reassurance Card
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
                              'Safe Update: All your existing tasks, notes, workspaces, and reflections remain 100% intact.',
                              style: TextStyle(fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Actions
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: _isLaunching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(CupertinoIcons.arrow_down_to_line, size: 20),
                      label: Text(
                        _isLaunching ? 'Opening Download...' : 'Download Update',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isLaunching ? null : _handleDownload,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _handleDismiss,
                    child: Text(
                      'Remind me later',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
