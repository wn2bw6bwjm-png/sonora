import 'package:flutter/material.dart';

/// Шаг сетки 4pt.
abstract final class Sp {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32, huge = 48;
  static const double page = 20;
}

abstract final class Rad {
  static const double sm = 4, md = 8, lg = 12;
  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
}

abstract final class Dur {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 220);
  static const curve = Curves.easeOutCubic;
}

/// Один акцент, без градиентов.
abstract final class SonoraColors {
  static const accentLight = Color(0xFFB5502D);
  static const accentDark = Color(0xFFE0825E);
  static const bgLight = Color(0xFFFAF8F5);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const inkLight = Color(0xFF1A1714);
  static const mutedLight = Color(0xFF7A736B);
  static const lineLight = Color(0xFFE7E2DB);
  static const bgDark = Color(0xFF0E0D0C);
  static const surfaceDark = Color(0xFF181614);
  static const inkDark = Color(0xFFF3EFE9);
  static const mutedDark = Color(0xFF9A9288);
  static const lineDark = Color(0xFF2A2724);
}
