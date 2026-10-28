import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'rota_colors.dart';

/// Rota teması (Material 3): açık, koyu ve sistem varsayılanı.
abstract final class AppTheme {
  /// Test ortamında ağdan yazı tipi çekilmez (testler ağa çıkmamalı).
  static bool get _useGoogleFonts {
    final binding = WidgetsBinding.instance.runtimeType.toString();
    return !binding.contains('Test');
  }

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ColorScheme _scheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final base = ColorScheme.fromSeed(
      seedColor: RotaColors.ember,
      brightness: brightness,
    );
    if (isLight) {
      return base.copyWith(
        primary: RotaColors.ink,
        onPrimary: RotaColors.paper,
        primaryContainer: RotaColors.sun,
        onPrimaryContainer: RotaColors.ink,
        secondary: RotaColors.ember,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFFBE3D4),
        onSecondaryContainer: RotaColors.ink,
        tertiary: RotaColors.plum,
        onTertiary: Colors.white,
        surface: RotaColors.paper,
        onSurface: RotaColors.ink,
        onSurfaceVariant: RotaColors.inkSoft,
        surfaceContainerLowest: RotaColors.card,
        surfaceContainerLow: RotaColors.card,
        surfaceContainer: RotaColors.field,
        surfaceContainerHigh: RotaColors.field,
        surfaceContainerHighest: RotaColors.field,
        outline: RotaColors.inkSoft,
        outlineVariant: RotaColors.line,
      );
    }
    return base.copyWith(
      primary: RotaColors.nightInk,
      onPrimary: RotaColors.ink,
      primaryContainer: RotaColors.sun,
      onPrimaryContainer: RotaColors.ink,
      secondary: RotaColors.ember,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF5A2A12),
      onSecondaryContainer: RotaColors.nightInk,
      tertiary: const Color(0xFFC9A6F2),
      onTertiary: RotaColors.ink,
      surface: RotaColors.nightPaper,
      onSurface: RotaColors.nightInk,
      onSurfaceVariant: RotaColors.nightInkSoft,
      surfaceContainerLowest: RotaColors.nightCard,
      surfaceContainerLow: RotaColors.nightCard,
      surfaceContainer: RotaColors.nightField,
      surfaceContainerHigh: RotaColors.nightField,
      surfaceContainerHighest: RotaColors.nightField,
      outline: RotaColors.nightInkSoft,
      outlineVariant: RotaColors.nightLine,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final scheme = _scheme(brightness);
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    final textTheme = _useGoogleFonts
        ? GoogleFonts.nunitoTextTheme(base.textTheme).apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          )
        : base.textTheme;
    // Başlıklar kalın ve sıkı: Rota'nın canlı görünümünün büyük kısmı bu.
    final headings = textTheme.copyWith(
      headlineLarge: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
      headlineMedium: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      headlineSmall: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );

    const pill = StadiumBorder();
    final buttonLabel = headings.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
    );

    return base.copyWith(
      textTheme: headings,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: headings.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: pill,
          textStyle: buttonLabel,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: pill,
          textStyle: buttonLabel,
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: buttonLabel?.copyWith(letterSpacing: 0.2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLowest,
        labelStyle: headings.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: RotaColors.sun,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          headings.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? RotaColors.ink : scheme.onSurfaceVariant,
          );
        }),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.secondary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: TextStyle(color: scheme.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  /// Tüm form alanlarında aynı görünüm için ortak dekorasyon (kenarlıklar temadan gelir).
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
    );
  }
}
