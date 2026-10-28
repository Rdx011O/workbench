import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import 'apple_widgets.dart';

class MoodItem {
  final int value;
  final String key;
  final String label;
  final String emoji;
  final Color color;

  const MoodItem({
    required this.value,
    required this.key,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

class MoodSlider extends StatefulWidget {
  final double initialValue; // 0.0 to 4.0
  final ValueChanged<MoodItem> onMoodChanged;

  const MoodSlider({
    super.key,
    this.initialValue = 2.0,
    required this.onMoodChanged,
  });

  static const List<MoodItem> moods = [
    MoodItem(
      value: 0,
      key: 'bad',
      label: 'Bad',
      emoji: '😞',
      color: Color(0xFFC76B6B), // Muted Crimson / Rose
    ),
    MoodItem(
      value: 1,
      key: 'low',
      label: 'Low',
      emoji: '🙁',
      color: Color(0xFFD48B62), // Terracotta
    ),
    MoodItem(
      value: 2,
      key: 'neutral',
      label: 'Neutral',
      emoji: '😐',
      color: Color(0xFF7F7A8B), // Slate Mauve
    ),
    MoodItem(
      value: 3,
      key: 'happy',
      label: 'Happy',
      emoji: '😊',
      color: Color(0xFF5E8B7E), // Sage Botanical
    ),
    MoodItem(
      value: 4,
      key: 'super_happy',
      label: 'Super Happy',
      emoji: '🤩',
      color: Color(0xFF7A58A5), // Radiant Aubergine Violet
    ),
  ];

  static MoodItem fromMoodString(String? mood) {
    if (mood == null) return moods[2];
    final normalized = mood.toLowerCase().replaceAll(' ', '_');
    for (final m in moods) {
      if (m.key == normalized || m.label.toLowerCase() == mood.toLowerCase()) {
        return m;
      }
    }
    // Fallback aliases
    if (normalized.contains('bad') || normalized.contains('sad') || normalized.contains('angry')) {
      return moods[0];
    }
    if (normalized.contains('super')) {
      return moods[4];
    }
    if (normalized.contains('happy') || normalized.contains('grateful') || normalized.contains('rested')) {
      return moods[3];
    }
    return moods[2];
  }

  @override
  State<MoodSlider> createState() => _MoodSliderState();
}

class _MoodSliderState extends State<MoodSlider> with SingleTickerProviderStateMixin {
  late double _currentValue;
  int _lastHapticStep = -1;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.clamp(0.0, 4.0);
    _lastHapticStep = _currentValue.round();
  }

  MoodItem get currentMood => MoodSlider.moods[_currentValue.round().clamp(0, 4)];

  void _updateValue(double val) {
    setState(() => _currentValue = val);
    final rounded = val.round().clamp(0, 4);
    if (rounded != _lastHapticStep) {
      _lastHapticStep = rounded;
      AppleHaptics.selection();
    }
    widget.onMoodChanged(MoodSlider.moods[rounded]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeMood = currentMood;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? BotanicalColors.darkSurface.withValues(alpha: 0.8)
            : BotanicalColors.lightSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: activeMood.color.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: activeMood.color.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Dynamic Mood Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mood Today',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Container(
                  key: ValueKey<int>(activeMood.value),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: activeMood.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: activeMood.color.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(activeMood.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        activeMood.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: activeMood.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Central Interactive Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: activeMood.color,
              inactiveTrackColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.06),
              thumbColor: activeMood.color,
              overlayColor: activeMood.color.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13, elevation: 3),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Slider(
              value: _currentValue,
              min: 0.0,
              max: 4.0,
              divisions: 4,
              onChanged: _updateValue,
            ),
          ),

          // Labels: "Bad" on left, "Super Happy" on right
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _updateValue(0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '😞 Bad',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _currentValue.round() == 0 ? FontWeight.w700 : FontWeight.w500,
                          color: _currentValue.round() == 0
                              ? const Color(0xFFC76B6B)
                              : (isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _updateValue(2.0),
                  child: Text(
                    '😐 Neutral',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _currentValue.round() == 2 ? FontWeight.w700 : FontWeight.w500,
                      color: _currentValue.round() == 2
                          ? activeMood.color
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _updateValue(4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Super Happy 🤩',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _currentValue.round() == 4 ? FontWeight.w700 : FontWeight.w500,
                          color: _currentValue.round() == 4
                              ? const Color(0xFF7A58A5)
                              : (isDark ? BotanicalColors.darkTextSecondary : BotanicalColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
