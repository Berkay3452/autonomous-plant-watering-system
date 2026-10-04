import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tasarımdaki (docs/design) renkler. Açık ve koyu tema için ayrı paletler var;
/// ekranlarda `context.palette` ile okunur. Tasarım değişirse yalnızca bu
/// dosya güncellenir.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.bg,
    required this.blob,
    required this.card,
    required this.tile,
    required this.sheet,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.text,
    required this.textMuted,
    required this.control,
    required this.track,
    required this.warnBg,
    required this.warnFg,
    required this.warnTile,
    required this.warnButton,
    required this.onWarnButton,
    required this.okBg,
    required this.okFg,
    required this.heroInner,
    required this.ring,
    required this.ringTrack,
    required this.chartLine,
    required this.chartFill,
    required this.chartGrid,
    required this.bar,
    required this.barHighlight,
  });

  final bool isDark;

  /// Ekran zemini.
  final Color bg;

  /// Sol üstteki büyük yuvarlak dekor.
  final Color blob;

  /// Kart yüzeyi.
  final Color card;

  /// Kart içindeki küçük kutular.
  final Color tile;

  /// Alt sayfa ve pencere zemini.
  final Color sheet;

  /// Ana eylem rengi (düğme, seçili sekme, simgeler).
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color onAccent;
  final Color text;
  final Color textMuted;

  /// Segment kontrollerinin zemini.
  final Color control;

  /// İlerleme çubuğu zemini.
  final Color track;

  /// Uyarı (turuncu) renkleri.
  final Color warnBg;
  final Color warnFg;
  final Color warnTile;
  final Color warnButton;
  final Color onWarnButton;

  /// Olumlu durum (lime) renkleri.
  final Color okBg;
  final Color okFg;

  /// Ana sayfadaki bitki halkası.
  final Color heroInner;
  final Color ring;
  final Color ringTrack;

  /// Geçmiş grafikleri.
  final Color chartLine;
  final Color chartFill;
  final Color chartGrid;
  final Color bar;
  final Color barHighlight;

  /// Uyarı metni rengi (koyu zeminde de okunur).
  Color get warnText => isDark ? warnBg : warnButton;

  /// Şeftali rengi uyarı zemininin üzerindeki simge rengi (iki temada da koyu turuncu).
  Color get warnButtonOnLight => const Color(0xFFB8500E);

  static const light = AppPalette(
    isDark: false,
    bg: Color(0xFFF3F8E8),
    blob: Color(0xFFE6F3BF),
    card: Color(0xFFFFFFFF),
    tile: Color(0xFFF0F6E5),
    sheet: Color(0xFFFFFFFF),
    primary: Color(0xFF2B7337),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFCDE460),
    onAccent: Color(0xFF12301C),
    text: Color(0xFF12301C),
    textMuted: Color(0xFF4F6B55),
    control: Color(0xFFE6F3BF),
    track: Color(0xFFE1EBD2),
    warnBg: Color(0xFFFCE3CC),
    warnFg: Color(0xFF7A3412),
    warnTile: Color(0xFFFDF1E4),
    warnButton: Color(0xFFB8500E),
    onWarnButton: Color(0xFFFFFFFF),
    okBg: Color(0xFFE6F3BF),
    okFg: Color(0xFF2B7337),
    heroInner: Color(0xFFBFE6CB),
    ring: Color(0xFF2B7337),
    ringTrack: Color(0xFFC3D9A5),
    chartLine: Color(0xFF2B7337),
    chartFill: Color(0xFFD6F0DD),
    chartGrid: Color(0xFFD3E4BE),
    bar: Color(0xFF6FCF8F),
    barHighlight: Color(0xFF2B7337),
  );

  static const dark = AppPalette(
    isDark: true,
    bg: Color(0xFF2B7337),
    blob: Color(0xFF318044),
    card: Color(0xFF498753),
    tile: Color(0xFF5A935F),
    sheet: Color(0xFF3A8546),
    primary: Color(0xFFCDE460),
    onPrimary: Color(0xFF12301C),
    accent: Color(0xFFCDE460),
    onAccent: Color(0xFF12301C),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xFFDCEBC8),
    control: Color(0xFF4F8F5B),
    track: Color(0xFF7BA886),
    warnBg: Color(0xFFFCE3CC),
    warnFg: Color(0xFF7A3412),
    warnTile: Color(0xFFFCE3CC),
    warnButton: Color(0xFFCDE460),
    onWarnButton: Color(0xFF12301C),
    okBg: Color(0xFFE6F3BF),
    okFg: Color(0xFF2B7337),
    heroInner: Color(0xFFE6F3BF),
    ring: Color(0xFFCDE460),
    ringTrack: Color(0xFF64A072),
    chartLine: Color(0xFFCDE460),
    chartFill: Color(0xFF6A9C57),
    chartGrid: Color(0xFF83AE8B),
    bar: Color(0xFF8DB592),
    barHighlight: Color(0xFFCDE460),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// Tasarımdaki boşluk ve köşe yuvarlaklıkları.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Ekran kenar boşluğu.
  static const double page = 18;
}

class AppRadius {
  AppRadius._();

  static const double card = 28;
  static const double tile = 20;
  static const double sheet = 28;
}

class AppTheme {
  AppTheme._();

  /// [googleFonts] kapalıyken sistem yazı tipi kullanılır (testlerde).
  static ThemeData light({bool googleFonts = true}) =>
      _build(AppPalette.light, Brightness.light, googleFonts);

  static ThemeData dark({bool googleFonts = true}) =>
      _build(AppPalette.dark, Brightness.dark, googleFonts);

  static TextTheme _textTheme(AppPalette p, bool gf) {
    // Başlık yazı tipi. Tasarımdaki Fredoka'da Türkçe "ş / Ş" harfi düzgün
    // çizilmediği için, ona çok benzeyen ve Türkçe harflerin tamamını içeren
    // Baloo 2 kullanılıyor.
    TextStyle display(double size, FontWeight w) => gf
        ? GoogleFonts.baloo2(fontSize: size, fontWeight: w, color: p.text, height: 1.1)
        : TextStyle(fontSize: size, fontWeight: w, color: p.text, height: 1.1);
    TextStyle body(double size, FontWeight w, [Color? color]) => gf
        ? GoogleFonts.nunito(fontSize: size, fontWeight: w, color: color ?? p.text, height: 1.3)
        : TextStyle(fontSize: size, fontWeight: w, color: color ?? p.text, height: 1.3);

    return TextTheme(
      headlineLarge: display(30, FontWeight.w700),
      headlineMedium: display(27, FontWeight.w700),
      headlineSmall: display(22, FontWeight.w700),
      titleLarge: display(20, FontWeight.w700),
      titleMedium: display(17, FontWeight.w700),
      titleSmall: display(15, FontWeight.w600),
      bodyLarge: body(15, FontWeight.w500),
      bodyMedium: body(13.5, FontWeight.w500),
      bodySmall: body(12, FontWeight.w500, p.textMuted),
      labelLarge: display(16, FontWeight.w700),
      labelMedium: body(12.5, FontWeight.w700),
      labelSmall: body(11, FontWeight.w700),
    );
  }

  static ThemeData _build(AppPalette p, Brightness brightness, bool gf) {
    final text = _textTheme(p, gf);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.accent,
      onSecondary: p.onAccent,
      error: p.warnButton,
      onError: p.onWarnButton,
      surface: p.sheet,
      onSurface: p.text,
      onSurfaceVariant: p.textMuted,
      outline: p.textMuted,
      outlineVariant: p.track,
      primaryContainer: p.control,
      onPrimaryContainer: p.text,
      secondaryContainer: p.control,
      onSecondaryContainer: p.text,
      surfaceContainerHighest: p.control,
      surfaceContainerHigh: p.tile,
      surfaceContainer: p.tile,
      surfaceContainerLow: p.card,
      surfaceContainerLowest: p.card,
    );
    const stadium = StadiumBorder();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      textTheme: text,
      primaryTextTheme: text,
      extensions: [p],
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.text,
        titleTextStyle: text.headlineSmall,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.control,
          disabledForegroundColor: p.textMuted,
          minimumSize: const Size(64, 54),
          shape: stadium,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary, width: 2),
          minimumSize: const Size(64, 54),
          shape: stadium,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: text.labelLarge?.copyWith(fontSize: 14),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onPrimary : p.card,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.track,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 12,
        activeTrackColor: p.primary,
        inactiveTrackColor: p.track,
        thumbColor: p.primary,
        overlayColor: p.primary.withValues(alpha: 0.15),
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
        valueIndicatorColor: p.primary,
        valueIndicatorTextStyle: text.labelMedium?.copyWith(color: p.onPrimary),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.sheet,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.textMuted.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: text.bodyLarge,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.control,
        selectedColor: p.primary,
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(color: p.onPrimary),
        side: BorderSide.none,
        shape: stadium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.tile,
        labelStyle: text.bodyMedium?.copyWith(color: p.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF12301C),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: const Color(0xFFCDE460),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: p.track.withValues(alpha: 0.6), space: 1, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: p.primary,
        textColor: p.text,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.track,
      ),
    );
  }
}
