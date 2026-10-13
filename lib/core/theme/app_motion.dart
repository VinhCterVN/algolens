import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const page = Duration(milliseconds: 260);
  static const curve = Curves.easeOutCubic;
  static const pageOffset = Offset(0, 0.035);
  static const pressScale = 0.985;

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) || MediaQuery.of(context).accessibleNavigation;

  static Duration duration(BuildContext context, Duration normal) => reduced(context) ? Duration.zero : normal;
}
