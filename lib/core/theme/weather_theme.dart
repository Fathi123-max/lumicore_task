import 'package:flutter/material.dart';

class WeatherThemeExtension extends ThemeExtension<WeatherThemeExtension> {
  final List<Color> gradientColors;
  final Color glassCardColor;
  final Color glassCardBorderColor;

  const WeatherThemeExtension({
    required this.gradientColors,
    required this.glassCardColor,
    required this.glassCardBorderColor,
  });

  @override
  ThemeExtension<WeatherThemeExtension> copyWith({
    List<Color>? gradientColors,
    Color? glassCardColor,
    Color? glassCardBorderColor,
  }) {
    return WeatherThemeExtension(
      gradientColors: gradientColors ?? this.gradientColors,
      glassCardColor: glassCardColor ?? this.glassCardColor,
      glassCardBorderColor: glassCardBorderColor ?? this.glassCardBorderColor,
    );
  }

  @override
  ThemeExtension<WeatherThemeExtension> lerp(
    covariant ThemeExtension<WeatherThemeExtension>? other,
    double t,
  ) {
    if (other is! WeatherThemeExtension) {
      return this;
    }
    return WeatherThemeExtension(
      gradientColors: t < 0.5 ? gradientColors : other.gradientColors,
      glassCardColor: Color.lerp(glassCardColor, other.glassCardColor, t) ?? glassCardColor,
      glassCardBorderColor: Color.lerp(glassCardBorderColor, other.glassCardBorderColor, t) ?? glassCardBorderColor,
    );
  }
}

class WeatherThemeBuilder {
  static ThemeData build({
    required String condition,
    required Brightness brightness,
  }) {
    final cond = condition.toLowerCase();
    final isDark = brightness == Brightness.dark;

    // Determine Seed Color and Gradient based on weather condition
    Color seedColor;
    List<Color> gradientColors;

    if (isDark) {
      if (cond.contains('sunny') || cond.contains('clear')) {
        seedColor = const Color(0xFF1E2235);
        gradientColors = [const Color(0xFF1A1C29), const Color(0xFF233550)];
      } else if (cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower')) {
        seedColor = const Color(0xFF0F1524);
        gradientColors = [const Color(0xFF0F1524), const Color(0xFF1D283C)];
      } else if (cond.contains('snow') || cond.contains('blizzard') || cond.contains('sleet')) {
        seedColor = const Color(0xFF161E2E);
        gradientColors = [const Color(0xFF161E2E), const Color(0xFF2C3E50)];
      } else {
        seedColor = const Color(0xFF0F111E);
        gradientColors = [const Color(0xFF0F111E), const Color(0xFF1E2235)];
      }
    } else {
      if (cond.contains('sunny') || cond.contains('clear')) {
        seedColor = const Color(0xFFFFB74D);
        gradientColors = [const Color(0xFFFFE082), const Color(0xFFFFB74D)];
      } else if (cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower')) {
        seedColor = const Color(0xFF90A4AE);
        gradientColors = [const Color(0xFFCFD8DC), const Color(0xFF90A4AE)];
      } else if (cond.contains('snow') || cond.contains('blizzard') || cond.contains('sleet')) {
        seedColor = const Color(0xFFB0BEC5);
        gradientColors = [const Color(0xFFECEFF1), const Color(0xFFB0BEC5)];
      } else {
        seedColor = const Color(0xFF80DEEA);
        gradientColors = [const Color(0xFFE0F7FA), const Color(0xFF80DEEA)];
      }
    }

    // Determine card decoration colors
    final Color glassCardColor = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.2);

    final Color glassCardBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.3);

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
      extensions: [
        WeatherThemeExtension(
          gradientColors: gradientColors,
          glassCardColor: glassCardColor,
          glassCardBorderColor: glassCardBorderColor,
        ),
      ],
    );
  }
}
