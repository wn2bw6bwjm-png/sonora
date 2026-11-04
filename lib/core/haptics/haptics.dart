import 'package:flutter/services.dart';

/// Единая точка тактильной обратной связи. Можно отключить в настройках.
abstract final class Haptics {
  static bool enabled = true;
  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }
}
