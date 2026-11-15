import 'package:flutter/material.dart';

class AppColors {
  // Primary & Modern Tech Gradients
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo
  static const Color primaryLight = Color(0xFF3B82F6); // Electric Blue
  static const Color accentPurple = Color(0xFF7C3AED); // Modern Violet
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan Accent
  static const Color secondary = Color(0xFF0D9488); // Modern Teal

  // State Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color successLight = Color(0xFFECFDF5);
  static const Color error = Color(0xFFEF4444); // Crimson Red
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFFFBEB);

  // Neutral Backgrounds
  static const Color backgroundLight = Color(0xFFF1F5F9); // Slate 100
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B); // Slate 800

  // Text
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF4F46E5), Color(0xFF7C3AED)],
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
}
