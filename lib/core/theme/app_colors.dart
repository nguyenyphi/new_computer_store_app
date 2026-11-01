import 'package:flutter/material.dart';

/// Bảng màu hiện đại cho ứng dụng Cửa hàng máy tính (Computer Store)
/// Thiết kế theo phong cách Hi-Tech, sang trọng, tinh tế.
class AppColors {
  AppColors._();

  // Primary colors (Deep Blue & Electric Cyan)
  static const Color primary = Color(0xFF0F62FE); // Blue Tech
  static const Color primaryDark = Color(0xFF3388FF);
  static const Color primaryContainer = Color(0xFFEDF5FF);
  static const Color primaryContainerDark = Color(0xFF1B2A4A);

  // Secondary colors (Electric Violet / Cyan Accent)
  static const Color secondary = Color(0xFF00B4D8);
  static const Color secondaryDark = Color(0xFF48CAE4);

  // Status colors
  static const Color success = Color(0xFF198754);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFD7E14);
  static const Color info = Color(0xFF0DCAF0);

  // Light Theme Neutrals
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE9ECEF);
  static const Color lightTextPrimary = Color(0xFF212529);
  static const Color lightTextSecondary = Color(0xFF6C757D);

  // Dark Theme Neutrals
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF1F242C);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);

  // Discount badge tag
  static const Color discountBadge = Color(0xFFE63946);
  static const Color outOfStockBadge = Color(0xFF6C757D);
}
