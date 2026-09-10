import 'package:flutter/material.dart';

/// Bundles the three things almost every screen reaches for —
/// `Theme.of(context)`, its text styles/colors, and `MediaQuery` — behind
/// short getters so widgets read `context.textTheme` instead of repeating
/// `Theme.of(context).textTheme` everywhere.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  EdgeInsets get viewPadding => mediaQuery.padding;
}
