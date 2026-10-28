import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/colors.dart';

/// Centralized Apple Haptics helper for tactile feedback
class AppleHaptics {
  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  static void notificationSuccess() {
    HapticFeedback.mediumImpact();
  }

  static void notificationError() {
    HapticFeedback.heavyImpact();
  }
}

/// Floating Liquid Glass container following Apple HIG (Materials & Liquid Glass)
/// Features backdrop blur, translucent fill, specular hairline highlight, and subtle ambient shadow.
class AppleGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;
  final double opacity;
  final Border? customBorder;

  const AppleGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding,
    this.margin,
    this.blurSigma = 24.0,
    this.opacity = 0.78,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? BotanicalColors.darkSurface.withValues(alpha: opacity)
        : BotanicalColors.lightSurface.withValues(alpha: opacity);

    final borderColor = customBorder ??
        Border.all(
          color: (isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder).withValues(alpha: 0.8),
          width: 0.75,
        );

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor,
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x40000000) : const Color(0x0F000000),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      ),
    );
  }
}

/// Apple iOS-style Grouped Inset Card (used in Settings, Health, Reminders)
class AppleGroupedCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const AppleGroupedCard({
    super.key,
    required this.children,
    this.padding,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.borderRadius = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? BotanicalColors.darkSurface : BotanicalColors.lightSurface;
    final borderColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 0.75),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : const Color(0x08000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Apple iOS-style List Tile with optional squircle colored icon, title, subtitle, trailing, and indented divider
class AppleListTile extends StatelessWidget {
  final Widget? leading;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final double dividerIndent;

  const AppleListTile({
    super.key,
    this.leading,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    this.trailing = const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey2),
    this.onTap,
    this.showDivider = true,
    this.dividerIndent = 58.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? BotanicalColors.darkBorder : BotanicalColors.lightBorder;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && icon != null) {
      final bg = iconBackgroundColor ?? (iconColor ?? BotanicalColors.lightPrimary).withValues(alpha: 0.12);
      final fg = iconColor ?? (isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary);
      leadingWidget = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Icon(icon, size: 18, color: fg),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap != null
              ? () {
                  AppleHaptics.selection();
                  onTap!();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (leadingWidget != null) ...[
                  leadingWidget,
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      title,
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        subtitle!,
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: leadingWidget != null ? dividerIndent : 16),
            child: Divider(
              height: 0.5,
              thickness: 0.5,
              color: dividerColor,
            ),
          ),
      ],
    );
  }
}

/// Apple iOS-style Search Pill Field
class AppleSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String placeholder;

  const AppleSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.placeholder = 'Search',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? BotanicalColors.darkInputBackground : BotanicalColors.lightInputBackground;
    final border = isDark ? BotanicalColors.darkInputBorder : BotanicalColors.lightInputBorder;
    final hintColor = isDark ? BotanicalColors.darkInputPlaceholder : BotanicalColors.lightInputPlaceholder;

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.75),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(CupertinoIcons.search, size: 18, color: hintColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? BotanicalColors.darkTextPrimary : BotanicalColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: hintColor,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                AppleHaptics.lightImpact();
                controller.clear();
                if (onClear != null) onClear!();
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: hintColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.clear_thick,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Apple Section Header (Caps label used above Inset Grouped lists)
class AppleSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const AppleSectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
