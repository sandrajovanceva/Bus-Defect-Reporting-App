import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/status_pill.dart';
import 'app_theme.dart';

/// Frosted-glass surface treatment, scoped to the service worker's work-order
/// queue.
///
/// Light, like the rest of the app: a cool daylight field with two soft blooms
/// so the panes above have something to refract, white glass, and the existing
/// [AppColors] ink and status palette so contrast stays workshop-legible.
///
/// Kept separate from [AppTheme] so the other screens are unaffected; the
/// queue screen wraps itself in [GlassTheme.data].
class GlassColors {
  const GlassColors._();

  // --- field ---------------------------------------------------------------
  // The app's own warm paper, deepened slightly towards the bottom so the
  // panes have a tonal range to sit against. Same family as
  // [AppColors.background] and [AppColors.surfaceElevated] — this screen is
  // not allowed its own identity, only its own surface.
  static const Color paperHigh = AppColors.background;
  static const Color paperLow = Color(0xFFEDEAE0);

  /// JSP livery red — the accent, unchanged from [AppColors.accent].
  static const Color livery = AppColors.accent;

  /// The blooms behind the glass. Both warm: the livery red, and the sand of
  /// the app's own elevated surface. No cool tones on the field — they were
  /// what made this screen stop looking like the rest of the app.
  static const Color bloomLivery = AppColors.accent;
  static const Color bloomSand = Color(0xFFD8CFB4);

  // --- glass ---------------------------------------------------------------
  /// Fill of a frosted pane. High enough alpha to carry dark text.
  static const Color paneFill = Color(0xBFFFFFFF);
  static const Color paneFillStrong = Color(0xE6FFFFFF);

  /// Chrome (app bar / tab strip) sits slightly denser than a card.
  static const Color chromeFill = Color(0xADFFFFFF);

  /// A real pane catches light on its top edge and loses it at the bottom.
  static const Color edgeLit = Color(0xE6FFFFFF);

  /// The app's own border colour, so panes are edged like every other
  /// surface in the product.
  static const Color edgeShade = AppColors.border;

  // --- ink -----------------------------------------------------------------
  // Straight from the light theme, so this screen is no harder to read than
  // the rest of the app.
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = Color(0xFF837E75);
}

/// The colour a defect's status glows through the glass. These are the light
/// theme's status colours — they were already tuned for dark ink on a pale
/// surface, which is exactly what a white pane is.
extension GlassStatusColor on DefectStatus {
  Color get glassColor => color;
}

class GlassTheme {
  const GlassTheme._();

  /// A work order never stretches wider than this, however wide the window is.
  /// Long measures are unreadable and a single card spanning a monitor reads
  /// as an empty screen with a band across it.
  static const double contentWidth = 860;

  /// Radius used by every pane. Generous, because frosted glass reads as a
  /// physical object and sharp corners fight that.
  static const double radius = 18;

  /// Blur strength for a pane.
  static const double blur = 24;

  static TextTheme _textTheme() {
    final mono = GoogleFonts.ibmPlexMono;
    final sans = GoogleFonts.ibmPlexSans;

    return TextTheme(
      // Fleet numbers. The one place type gets big — it is what a mechanic
      // scans for first, so it is set as a plate, not a heading.
      displaySmall: mono(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: GlassColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.0,
      ),
      titleLarge: sans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: GlassColors.textPrimary,
        height: 1.2,
      ),
      titleMedium: sans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: GlassColors.textPrimary,
      ),
      bodyMedium: sans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: GlassColors.textSecondary,
        height: 1.5,
      ),
      bodySmall: sans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: GlassColors.textSecondary,
        height: 1.45,
      ),
      labelLarge: mono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: GlassColors.textPrimary,
        letterSpacing: 1.4,
      ),
      labelMedium: mono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: GlassColors.textSecondary,
        letterSpacing: 1.4,
      ),
      labelSmall: mono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: GlassColors.textMuted,
        letterSpacing: 1.4,
      ),
    );
  }

  static ThemeData get data {
    final textTheme = _textTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: GlassColors.livery,
        onPrimary: Colors.white,
        secondary: GlassColors.livery,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: GlassColors.textPrimary,
        error: GlassColors.livery,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      iconTheme: const IconThemeData(
        color: GlassColors.textSecondary,
        size: 20,
      ),
      dividerTheme: const DividerThemeData(
        color: GlassColors.edgeShade,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: GlassColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.labelLarge?.copyWith(letterSpacing: 2.2),
        toolbarHeight: 64,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: GlassColors.edgeShade),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: GlassColors.textPrimary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: GlassColors.edgeShade),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0A1A1815),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: textTheme.bodySmall?.copyWith(color: GlassColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GlassColors.edgeShade),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GlassColors.edgeShade),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GlassColors.livery, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GlassColors.livery,
          textStyle: textTheme.labelMedium?.copyWith(
            color: GlassColors.livery,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: GlassColors.livery,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GlassColors.textPrimary,
        contentTextStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
