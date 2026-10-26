import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// Clean user avatar that derives initials according to Part F rules:
/// - Aaditya Battin -> AB
/// - Aaditya -> A
/// - Aaditya Shriniwas Battin -> AB
/// Displays image if available; otherwise displays initials centered on
/// a restrained Slate & Lavender circular background.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 38.0,
    this.onTap,
  });

  static String getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Q';

    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'Q';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = getInitials(name);

    Widget avatarContent;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      avatarContent = ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(context, initials, isDark),
        ),
      );
    } else {
      avatarContent = _buildInitials(context, initials, isDark);
    }

    if (onTap == null) return avatarContent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: avatarContent,
    );
  }

  Widget _buildInitials(BuildContext context, String initials, bool isDark) {
    final bgColor = isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSecondarySurface;
    final textColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.40,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
