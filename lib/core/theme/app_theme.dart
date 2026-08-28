/// OR-001.3 — Production Material 3 [ThemeData] for Oracly.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/immersive/immersive_transition.dart';
import '../design_system/oracly_design_system.dart';
import 'app_decorations.dart';

/// Opacity tokens for interactive and overlay states.
abstract final class _ThemeOpacity {
  _ThemeOpacity._();

  static const double indicator = 0.18;
  static const double scrollbar = 0.45;
  static const double switchTrack = 0.55;
  static const double sliderInactive = 0.45;
  static const double sliderOverlay = 0.12;
  static const double progressTrack = 0.35;
  static const double disabled = 0.35;
  static const double selection = 0.28;
  static const double hover = 0.08;
  static const double focus = 0.12;
}

/// Shared page transition builders for all platforms.
abstract final class _AppPageTransitions {
  _AppPageTransitions._();

  static final PageTransitionsTheme theme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ImmersivePageTransitionsBuilder(),
      TargetPlatform.iOS: ImmersivePageTransitionsBuilder(),
      TargetPlatform.macOS: ImmersivePageTransitionsBuilder(),
      TargetPlatform.windows: ImmersivePageTransitionsBuilder(),
      TargetPlatform.linux: ImmersivePageTransitionsBuilder(),
    },
  );
}

/// Extension registration point — add [ThemeExtension] implementations here.
abstract final class AppThemeExtensions {
  AppThemeExtensions._();

  static List<ThemeExtension<dynamic>> forPalette(AppColorPalette palette) =>
      const [OraclyDesignTokens.standard];
}

/// Production theme factory — dark default, light ready, brightness-switchable.
abstract final class AppTheme {
  AppTheme._();

  /// Default production theme.
  static ThemeData get darkTheme => _build(AppColors.dark);

  /// Fully configured light theme.
  static ThemeData get lightTheme => _build(AppColors.light);

  /// Backward-compatible alias for [darkTheme].
  static ThemeData get dark => darkTheme;

  /// Backward-compatible alias for [lightTheme].
  static ThemeData get light => lightTheme;

  /// Resolves the correct theme for runtime brightness switching.
  static ThemeData forBrightness(Brightness brightness) =>
      brightness == Brightness.light ? lightTheme : darkTheme;

  static ThemeData _build(AppColorPalette palette) {
    final brightness =
        palette == AppColors.light ? Brightness.light : Brightness.dark;
    final scheme = AppColors.colorScheme(palette);
    final textTheme = AppTextStyles.textTheme(palette);
    final buttonPadding = AppDecorations.contentPadding();
    final iconSize = AppSpacing.md + AppSpacing.sm;
    final chipPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.sm + AppSpacing.xs,
      vertical: AppSpacing.xs,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
      colorScheme: scheme,
      fontFamily: AppTextStyles.bodyFontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      disabledColor: AppColors.textMuted.withValues(alpha: _ThemeOpacity.disabled),
      dividerColor: palette.divider,
      shadowColor: AppColors.black,
      highlightColor: AppColors.transparent,
      hoverColor: palette.gold.withValues(alpha: _ThemeOpacity.hover),
      focusColor: palette.gold.withValues(alpha: _ThemeOpacity.focus),
      splashFactory: NoSplash.splashFactory,
      // ORACLY owns click/haptic — never Material SystemSound.click.
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(enableFeedback: false),
      ),
      pageTransitionsTheme: _AppPageTransitions.theme,
      appBarTheme: _appBarTheme(palette, brightness, iconSize),
      cardTheme: _cardTheme(palette),
      filledButtonTheme: _filledButtonTheme(palette, buttonPadding),
      outlinedButtonTheme: _outlinedButtonTheme(palette, buttonPadding),
      textButtonTheme: _textButtonTheme(palette, buttonPadding),
      navigationBarTheme: _navigationBarTheme(palette),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(palette),
      bottomSheetTheme: _bottomSheetTheme(palette),
      dialogTheme: _dialogTheme(palette),
      snackBarTheme: _snackBarTheme(palette),
      dividerTheme: _dividerTheme(palette),
      iconTheme: IconThemeData(color: palette.icon, size: iconSize),
      inputDecorationTheme: _inputDecorationTheme(palette, buttonPadding),
      chipTheme: _chipTheme(palette, chipPadding),
      checkboxTheme: _checkboxTheme(palette),
      switchTheme: _switchTheme(palette),
      radioTheme: _radioTheme(palette),
      sliderTheme: _sliderTheme(palette),
      scrollbarTheme: _scrollbarTheme(palette),
      progressIndicatorTheme: _progressIndicatorTheme(palette),
      listTileTheme: _listTileTheme(palette, iconSize),
      popupMenuTheme: _popupMenuTheme(palette),
      navigationRailTheme: _navigationRailTheme(palette),
      navigationDrawerTheme: _navigationDrawerTheme(palette),
      textSelectionTheme: _textSelectionTheme(palette),
      extensions: AppThemeExtensions.forPalette(palette),
    );
  }

  static AppBarTheme _appBarTheme(
    AppColorPalette palette,
    Brightness brightness,
    double iconSize,
  ) {
    return AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.transparent,
      foregroundColor: palette.textPrimary,
      titleTextStyle: AppTextStyles.titleLarge.copyWith(
        color: palette.textPrimary,
      ),
      iconTheme: IconThemeData(color: palette.icon, size: iconSize),
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    );
  }

  static CardThemeData _cardTheme(AppColorPalette palette) {
    return CardThemeData(
      color: palette.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: AppColors.black,
      shape: RoundedRectangleBorder(
        borderRadius: OraclyComponentTokens.cardRadius,
        side: BorderSide(
          color: palette.gold.withValues(alpha: 0.24),
          width: AppBorderWidth.hairline,
        ),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(
    AppColorPalette palette,
    EdgeInsets padding,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.gold,
        foregroundColor: palette.background,
        disabledBackgroundColor:
            AppColors.textMuted.withValues(alpha: _ThemeOpacity.disabled),
        disabledForegroundColor: AppColors.textHint,
        elevation: 0,
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        textStyle: AppTextStyles.labelLarge,
        enableFeedback: false,
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(
    AppColorPalette palette,
    EdgeInsets padding,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.goldLight,
        disabledForegroundColor: AppColors.textHint,
        side: BorderSide(color: palette.gold, width: AppBorderWidth.gold),
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        textStyle: AppTextStyles.labelLarge,
        enableFeedback: false,
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(
    AppColorPalette palette,
    EdgeInsets padding,
  ) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.goldLight,
        disabledForegroundColor: AppColors.textHint,
        padding: padding,
        textStyle: AppTextStyles.labelLarge,
        enableFeedback: false,
      ),
    );
  }

  static NavigationBarThemeData _navigationBarTheme(AppColorPalette palette) {
    return NavigationBarThemeData(
      backgroundColor: palette.secondary,
      indicatorColor: palette.gold.withValues(alpha: _ThemeOpacity.indicator),
      labelTextStyle: WidgetStatePropertyAll(
        AppTextStyles.labelSmall.copyWith(color: palette.textSecondary),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? palette.goldLight : AppColors.textHint,
          size: AppSpacing.lg,
        );
      }),
    );
  }

  static BottomNavigationBarThemeData _bottomNavigationBarTheme(
    AppColorPalette palette,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: palette.secondary,
      selectedItemColor: palette.goldLight,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      enableFeedback: false,
      selectedLabelStyle: AppTextStyles.labelSmall,
      unselectedLabelStyle: AppTextStyles.labelSmall,
    );
  }

  static BottomSheetThemeData _bottomSheetTheme(AppColorPalette palette) {
    return BottomSheetThemeData(
      backgroundColor: palette.surface,
      modalBackgroundColor: palette.surface,
      elevation: 0,
      dragHandleColor: palette.textSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlValue),
        ),
        side: BorderSide(
          color: AppColors.matteBorder,
          width: AppBorderWidth.thin,
        ),
      ),
    );
  }

  static DialogThemeData _dialogTheme(AppColorPalette palette) {
    return DialogThemeData(
      backgroundColor: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xl,
        side: BorderSide(
          color: AppColors.matteBorder,
          width: AppBorderWidth.thin,
        ),
      ),
      titleTextStyle: AppTextStyles.headlineLarge.copyWith(
        color: palette.textPrimary,
      ),
      contentTextStyle: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.grey100,
      ),
    );
  }

  static SnackBarThemeData _snackBarTheme(AppColorPalette palette) {
    return SnackBarThemeData(
      backgroundColor: AppColors.surfaceElevated,
      contentTextStyle: AppTextStyles.bodyLarge.copyWith(
        color: palette.textPrimary,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      actionTextColor: palette.goldLight,
    );
  }

  static DividerThemeData _dividerTheme(AppColorPalette palette) {
    return DividerThemeData(
      color: palette.divider,
      thickness: AppBorderWidth.hairline,
      space: AppSpacing.md,
    );
  }

  static InputDecorationTheme _inputDecorationTheme(
    AppColorPalette palette,
    EdgeInsets padding,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      contentPadding: padding,
      border: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: AppColors.matteBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: palette.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(
          color: palette.gold,
          width: AppBorderWidth.gold,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: palette.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(
          color: palette.error,
          width: AppBorderWidth.gold,
        ),
      ),
      hintStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textHint),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: palette.textSecondary,
      ),
      errorStyle: AppTextStyles.labelSmall.copyWith(color: palette.error),
    );
  }

  static ChipThemeData _chipTheme(
    AppColorPalette palette,
    EdgeInsets padding,
  ) {
    return ChipThemeData(
      backgroundColor: palette.secondary,
      selectedColor: palette.gold.withValues(alpha: _ThemeOpacity.indicator),
      disabledColor: AppColors.textMuted.withValues(alpha: _ThemeOpacity.disabled),
      labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.grey100),
      secondaryLabelStyle: AppTextStyles.labelSmall.copyWith(
        color: palette.goldLight,
      ),
      side: BorderSide(color: AppColors.matteBorder),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.round),
      padding: padding,
    );
  }

  static CheckboxThemeData _checkboxTheme(AppColorPalette palette) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.gold;
        return AppColors.transparent;
      }),
      checkColor: WidgetStatePropertyAll(palette.background),
      side: BorderSide(
        color: AppColors.textHint,
        width: AppBorderWidth.thin,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xs),
    );
  }

  static SwitchThemeData _switchTheme(AppColorPalette palette) {
    return SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(palette.textPrimary),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return palette.gold.withValues(alpha: _ThemeOpacity.switchTrack);
        }
        return AppColors.textMuted;
      }),
    );
  }

  static RadioThemeData _radioTheme(AppColorPalette palette) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.gold;
        return AppColors.textHint;
      }),
    );
  }

  static SliderThemeData _sliderTheme(AppColorPalette palette) {
    return SliderThemeData(
      activeTrackColor: palette.gold,
      inactiveTrackColor:
          AppColors.textMuted.withValues(alpha: _ThemeOpacity.sliderInactive),
      thumbColor: palette.goldLight,
      overlayColor: palette.gold.withValues(alpha: _ThemeOpacity.sliderOverlay),
    );
  }

  static ScrollbarThemeData _scrollbarTheme(AppColorPalette palette) {
    return ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        palette.gold.withValues(alpha: _ThemeOpacity.scrollbar),
      ),
      radius: Radius.circular(AppRadius.smValue),
      thickness: WidgetStatePropertyAll(AppShadowMetrics.thumbThickness),
    );
  }

  static ProgressIndicatorThemeData _progressIndicatorTheme(
    AppColorPalette palette,
  ) {
    return ProgressIndicatorThemeData(
      color: palette.gold,
      linearTrackColor:
          AppColors.textMuted.withValues(alpha: _ThemeOpacity.progressTrack),
      circularTrackColor:
          AppColors.textMuted.withValues(alpha: _ThemeOpacity.progressTrack),
    );
  }

  static ListTileThemeData _listTileTheme(
    AppColorPalette palette,
    double iconSize,
  ) {
    return ListTileThemeData(
      tileColor: AppColors.transparent,
      iconColor: palette.icon,
      textColor: palette.textPrimary,
      enableFeedback: false,
      contentPadding: AppSpacing.screenHorizontal,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      titleTextStyle: AppTextStyles.titleMedium.copyWith(
        color: palette.textPrimary,
      ),
      subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
        color: palette.textSecondary,
      ),
      leadingAndTrailingTextStyle: AppTextStyles.labelMedium.copyWith(
        color: palette.textSecondary,
      ),
      minLeadingWidth: AppSpacing.lg,
      minVerticalPadding: AppSpacing.sm,
      dense: false,
    );
  }

  static PopupMenuThemeData _popupMenuTheme(AppColorPalette palette) {
    return PopupMenuThemeData(
      color: AppColors.surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: BorderSide(
          color: AppColors.matteBorder,
          width: AppBorderWidth.thin,
        ),
      ),
      textStyle: AppTextStyles.bodyMedium.copyWith(color: palette.textPrimary),
      labelTextStyle: WidgetStatePropertyAll(
        AppTextStyles.bodyMedium.copyWith(color: palette.textPrimary),
      ),
    );
  }

  static NavigationRailThemeData _navigationRailTheme(AppColorPalette palette) {
    return NavigationRailThemeData(
      backgroundColor: palette.secondary,
      indicatorColor: palette.gold.withValues(alpha: _ThemeOpacity.indicator),
      selectedIconTheme: IconThemeData(
        color: palette.goldLight,
        size: AppSpacing.lg,
      ),
      unselectedIconTheme: IconThemeData(
        color: AppColors.textHint,
        size: AppSpacing.lg,
      ),
      selectedLabelTextStyle: AppTextStyles.labelSmall.copyWith(
        color: palette.goldLight,
      ),
      unselectedLabelTextStyle: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textHint,
      ),
      labelType: NavigationRailLabelType.all,
      minWidth: AppSpacing.xxl,
      groupAlignment: AppSpacing.sm,
    );
  }

  static NavigationDrawerThemeData _navigationDrawerTheme(
    AppColorPalette palette,
  ) {
    return NavigationDrawerThemeData(
      backgroundColor: palette.secondary,
      indicatorColor: palette.gold.withValues(alpha: _ThemeOpacity.indicator),
      elevation: 0,
      shadowColor: AppColors.black,
      surfaceTintColor: AppColors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        AppTextStyles.labelLarge.copyWith(color: palette.textPrimary),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: palette.icon, size: AppSpacing.lg),
      ),
    );
  }

  static TextSelectionThemeData _textSelectionTheme(AppColorPalette palette) {
    return TextSelectionThemeData(
      cursorColor: palette.gold,
      selectionColor: palette.gold.withValues(alpha: _ThemeOpacity.selection),
      selectionHandleColor: palette.goldLight,
    );
  }
}
