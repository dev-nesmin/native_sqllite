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

    // Base color with slight opacity
    final baseColor =
        backgroundColor ??
        (isDark
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.7));

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
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
                colors: [baseColor, baseColor.withOpacity(0.95)],
              ),
            ),
            child: AppBar(
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              leading: leading,
              actions: actions,
              automaticallyImplyLeading: automaticallyImplyLeading,
              elevation: elevation,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              iconTheme: IconThemeData(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
