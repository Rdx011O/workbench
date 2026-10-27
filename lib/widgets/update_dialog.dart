import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/services/update_service.dart';
import '../core/theme/colors.dart';
import '../views/update/update_screen.dart';
import 'apple_widgets.dart';

class UpdateDialog extends StatelessWidget {
  final AppReleaseInfo releaseInfo;

  const UpdateDialog({super.key, required this.releaseInfo});

  static Future<void> show(BuildContext context, AppReleaseInfo releaseInfo) {
    AppleHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UpdateDialog(releaseInfo: releaseInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Apple Grabber
            Center(
              child: Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A443E) : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Header with Icon & Version
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      CupertinoIcons.arrow_down_circle_fill,
                      color: primaryColor,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Update Available',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: BotanicalColors.lightAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'v${releaseInfo.version}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: BotanicalColors.lightAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        releaseInfo.releaseTitle,
                        style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Inset Grouped Changelog Card
            const AppleSectionHeader('Update Log & What\'s New', padding: EdgeInsets.only(bottom: 8)),
            AppleGroupedCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                if (releaseInfo.changelog.isEmpty)
                  const Text('General enhancements, performance optimizations, and bug fixes.')
                else
                  ...releaseInfo.changelog.map((log) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            size: 16,
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
            const SizedBox(height: 14),

            // Reassurance Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 0.75),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.lock_shield, size: 18, color: primaryColor),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Safe update: All your existing tasks, notes, reflections, and settings will remain completely intact.',
                      style: TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
              ElevatedButton.icon(
                icon: const Icon(CupertinoIcons.cloud_download, size: 18),
                label: const Text('Update In-App Now'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  AppleHaptics.mediumImpact();
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UpdateScreen(
                        releaseInfo: releaseInfo,
                        onProceedAnyway: () => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
              ),

            if (!releaseInfo.isMandatory) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  AppleHaptics.selection();
                  Navigator.of(context).pop();
                },
                child: const Text('Remind Me Later'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
