import 'package:flutter/widgets.dart';

import 'en.dart';

/// Desteklenen diller.
enum AppLang {
  tr('tr', 'TR', 'tr_TR', 'Türkçe'),
  en('en', 'US', 'en_US', 'English');

  const AppLang(this.code, this.country, this.localeName, this.label);

  final String code;
  final String country;

  /// `intl` paketinin tarih biçimleri için kullandığı ad ("tr_TR").
  final String localeName;

  /// Ayarlar ekranında gösterilen ad (kendi dilinde).
  final String label;

  Locale get locale => Locale(code, country);

  static AppLang fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => AppLang.tr);
}

/// Çeviri altyapısı.
///
/// Metinler kodda Türkçe yazılır ve [t] ile çağrılır; Türkçe metin aynı
/// zamanda çeviri anahtarıdır. İngilizce karşılıkları `en.dart` içindedir.
/// Metindeki `{0}`, `{1}` yer tutucuları [args] ile doldurulur.
///
/// Yeni bir metin eklerken `en.dart` dosyasına da karşılığını ekle;
/// `test/l10n_test.dart` eksik çevirileri yakalar.
class Strings {
  Strings._();

  /// Seçili dil. Ayarlar değişince [SettingsProvider] günceller.
  static AppLang lang = AppLang.tr;

  static String get localeName => lang.localeName;

  static String t(String tr, [List<Object?> args = const []]) {
    var text = lang == AppLang.tr ? tr : (enStrings[tr] ?? tr);
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      text = text.replaceAll('{$i}', arg is Msg ? arg.resolve() : '$arg');
    }
    return text;
  }
}

/// Henüz çevrilmemiş, yer tutuculu bir metin. Cihazdan gelen uyarılar gibi
/// dili sonradan değişebilecek mesajlar bunu taşır; gösterilirken [resolve]
/// o anki dile çevirir. [args] içinde başka bir [Msg] de olabilir.
class Msg {
  const Msg(this.key, [this.args = const []]);

  final String key;
  final List<Object?> args;

  String resolve() => Strings.t(key, args);
}

extension StringsContext on BuildContext {
  /// Metni seçili dile çevirir. Dil değişince bu widget'ın yeniden çizilmesini
  /// sağlamak için yerel ayara bağlanır.
  String t(String tr, [List<Object?> args = const []]) {
    Localizations.localeOf(this);
    return Strings.t(tr, args);
  }
}
