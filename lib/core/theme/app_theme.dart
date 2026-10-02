import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF1F7A5C);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light)
        .copyWith(surfaceContainerHigh: Colors.white);
    return _base(scheme, const Color(0xFFF4F7F5));
  }

  /// True OLED dark: pure #000000 background, near-black cards.
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark)
        .copyWith(
      surface: Colors.black,
      surfaceContainerHigh: const Color(0xFF111111),
      primary: const Color(0xFF4FC3A1),
    );
    return _base(scheme, Colors.black);
  }

  static ThemeData _base(ColorScheme scheme, Color bg) {
    final text = ThemeData(brightness: scheme.brightness)
        .textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: text,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        indicatorColor: scheme.primaryContainer,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Rounded card used across the app.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
      ),
      child: child,
    );
  }
}


/// Colors for the Mushaf page (cream paper in light mode, pure black in OLED).
class MushafColors {
  const MushafColors({
    required this.outerBg,
    required this.page,
    required this.text,
    required this.frameOuter,
    required this.frameInner,
    required this.accent,
    required this.highlight,
  });
  final Color outerBg, page, text, frameOuter, frameInner, accent, highlight;

  static const light = MushafColors(
    outerBg: Color(0xFFFCFAF2),
    page: Color(0xFFFCFAF2),
    text: Color(0xFF111111),
    frameOuter: Color(0xFF2AA6A0),
    frameInner: Color(0xFFD4A94C),
    accent: Color(0xFF1F7A5C),
    highlight: Color(0x66F2C94C),
  );
  static const dark = MushafColors(
    outerBg: Color(0xFF000000),
    page: Color(0xFF000000),
    text: Color(0xFFEDE8D8),
    frameOuter: Color(0xFF1B5E5A),
    frameInner: Color(0xFF8A6D2B),
    accent: Color(0xFFD4AF37),
    highlight: Color(0x55C9A227),
  );

  static MushafColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
