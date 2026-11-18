import 'package:material_ui/material_ui.dart';

class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentIndigo = Color(0xFF6366F1);

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color cardDarkElevated = Color(0xFF334155);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppMetrics {
  static const double radiusCard = 20.0;
  static const double radiusControl = 14.0;
  static const double page = 16.0;
  static const double gap = 12.0;
}
