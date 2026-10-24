import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import 'apple_widgets.dart';

/// Apple HIG compliant circular task checkbox.
/// Guarantees a minimum 44x44 pt touch target with responsive tactile haptics
/// and a crisp spring completion animation.
class CircularCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  const CircularCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? BotanicalColors.darkPrimary : BotanicalColors.lightPrimary;
    final borderColor = isDark ? BotanicalColors.darkBorder : const Color(0xFFC7CAC2);
    final surfaceColor = isDark ? BotanicalColors.darkSecondarySurface : BotanicalColors.lightSurface;

    return Semantics(
      checked: value,
      label: 'Toggle task completion',
      child: InkWell(
        onTap: () {
          AppleHaptics.mediumImpact();
          onChanged(!value);
        },
        borderRadius: BorderRadius.circular(22),
        // Ensure 44x44 minimum touch target per Apple HIG Lens 1
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? primaryColor : surfaceColor,
              border: Border.all(
                color: value ? primaryColor : borderColor,
                width: 1.5,
              ),
              boxShadow: value
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedScale(
              scale: value ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: const Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
