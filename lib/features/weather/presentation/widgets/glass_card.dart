import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:weather_app/core/theme/weather_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.15,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weatherTheme = theme.extension<WeatherThemeExtension>();

    // Fallbacks in case the theme extension is not present
    final isDark = theme.brightness == Brightness.dark;
    final fallbackCardColor = theme.colorScheme.surface.withValues(
      alpha: isDark ? opacity + 0.1 : opacity,
    );
    final fallbackBorderColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.12 : 0.25,
    );

    final cardColor = weatherTheme?.glassCardColor ?? fallbackCardColor;
    final borderColor = weatherTheme?.glassCardBorderColor ?? fallbackBorderColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 24.0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
