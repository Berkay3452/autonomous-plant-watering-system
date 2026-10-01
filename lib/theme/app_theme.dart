import 'package:flutter/material.dart';

import '../models/pot.dart';

/// Uygulamanın tüm renk ve biçim ayarları burada. Tasarım güncellenirken
/// önce bu dosya değiştirilir.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF2E7D32);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Ekran kenar boşluğu.
  static const double page = 16;
}

class AppRadius {
  AppRadius._();

  static const double card = 20;
  static const double chip = 999;
}

/// Ölçüm türlerine ve durumlara özel renkler.
class AppColors {
  AppColors._();

  static const Color moisture = Color(0xFF1E88E5);
  static const Color temperature = Color(0xFFF4511E);
  static const Color humidity = Color(0xFF00897B);
  static const Color water = Color(0xFF039BE5);
  static const Color ideal = Color(0xFF43A047);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFE53935);

  static Color forStatus(PotStatus status, ColorScheme scheme) {
    switch (status) {
      case PotStatus.dry:
        return danger;
      case PotStatus.low:
        return warning;
      case PotStatus.ideal:
        return ideal;
      case PotStatus.wet:
        return moisture;
      case PotStatus.noPlant:
      case PotStatus.unknown:
        return scheme.outline;
    }
  }

  static IconData iconForStatus(PotStatus status) {
    switch (status) {
      case PotStatus.dry:
        return Icons.warning_amber_rounded;
      case PotStatus.low:
        return Icons.trending_down;
      case PotStatus.ideal:
        return Icons.check_circle_outline;
      case PotStatus.wet:
        return Icons.water;
      case PotStatus.noPlant:
        return Icons.add_circle_outline;
      case PotStatus.unknown:
        return Icons.help_outline;
    }
  }
}
