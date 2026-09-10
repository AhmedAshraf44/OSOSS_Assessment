import 'package:flutter/material.dart';

/// The app's single accent color and its supporting neutrals. A light,
/// near-white surface with one accent color — used consistently instead of
/// scattering hex values through widgets.
class AppColors {
  const AppColors._();

  static const Color accent = Color(0xFF2563EB); // brand blue
  static const Color accentDark = Color(0xFF1D4ED8);

  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEFF2F6);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  // Domain-meaningful colors: kept distinct from the single brand accent so
  // "counted / discrepancy / conflict" states stay scannable at a glance in
  // the product list.
  static const Color success = Color(0xFF16A34A); // counted, matches system
  static const Color warning = Color(0xFFD97706); // counted, differs
  static const Color danger = Color(0xFFDC2626); // sync failed / conflict
  static const Color pending = Color(0xFF6366F1); // pending sync / syncing
}
