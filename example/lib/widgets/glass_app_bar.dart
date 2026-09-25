import 'dart:ui';

import 'package:flutter/material.dart';

/// A custom AppBar with Apple's Liquid Glass effect (frosted glass blur)
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double elevation;
  final Color? backgroundColor;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation = 0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    // Base color with slight opacity
    final baseColor =
        backgroundColor ??
        colors.surface.withValues(alpha: isDark ? 0.72 : 0.82);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? colors.outlineVariant.withValues(alpha: 0.5)
                : colors.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20.0,
            sigmaY: 20.0,
            tileMode: TileMode.mirror,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: baseColor,
              // Subtle gradient for more depth
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [baseColor, baseColor.withValues(alpha: 0.95)],
              ),
            ),
            child: AppBar(
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              leading: leading,
              actions: actions,
              automaticallyImplyLeading: automaticallyImplyLeading,
              elevation: elevation,
              backgroundColor: colors.surface.withValues(alpha: 0),
              surfaceTintColor: colors.surface.withValues(alpha: 0),
              centerTitle: true,
              iconTheme: IconThemeData(color: colors.onSurface),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
