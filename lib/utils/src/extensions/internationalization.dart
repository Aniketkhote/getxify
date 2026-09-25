import 'dart:ui';

import '../../../core/core.dart';

/// The CLDR plural categories used to pick the correct plural form of a
/// translation key for a given count.
///
/// Not every language uses every category: English only distinguishes
/// [one] and [other], while Arabic uses all six and Russian uses [one],
/// [few], [many] and [other].
enum PluralCase {
  /// The form used for zero items in languages that have one (e.g. Arabic).
  zero,

  /// The singular form (e.g. English `1 song`, Russian `21 песня`).
  one,

  /// The dual form in languages that have one (e.g. Arabic).
  two,

  /// The paucal form (e.g. Russian counts ending in 2-4, except 12-14).
  few,

  /// The form for large quantities in languages that distinguish it
  /// (e.g. Arabic 11-99, Russian counts ending in 0 or 5-9).
  many,

  /// The general plural form; also the fallback when no more specific
  /// category matches.
  other,
}

/// Maps a [count] under [locale] to the [PluralCase] whose translation
/// should be used. Installed through [LocalesIntl.pluralResolver].
typedef PluralResolver = PluralCase Function(int count, Locale? locale);

class _IntlHost {
  Locale? locale;

  Locale? fallbackLocale;

  PluralResolver? pluralResolver;

  Map<String, Map<String, String>> translations = {};
}

extension LocalesIntl on GetInterface {
  static final _intlHost = _IntlHost();

  Locale? get locale => _intlHost.locale;

  Locale? get fallbackLocale => _intlHost.fallbackLocale;

  set locale(Locale? newLocale) => _intlHost.locale = newLocale;

  set fallbackLocale(Locale? newLocale) => _intlHost.fallbackLocale = newLocale;

  /// The plural rule used by [Trans.trPluralCases] and
  /// [Trans.trPluralCasesParams] to map a count to a [PluralCase].
  ///
  /// When null (the default), the two-form English rule is applied:
  /// `count == 1` resolves to [PluralCase.one], anything else to
  /// [PluralCase.other]. Install a custom resolver for languages with
  /// richer plural rules:
  ///
  /// ```dart
  /// Get.pluralResolver = (count, locale) {
  ///   if (locale?.languageCode == 'ru') {
  ///     if (count % 10 == 1 && count % 100 != 11) return PluralCase.one;
  ///     if (count % 10 >= 2 && count % 10 <= 4 &&
  ///         (count % 100 < 12 || count % 100 > 14)) {
  ///       return PluralCase.few;
  ///     }
  ///     return PluralCase.many;
  ///   }
  ///   return count == 1 ? PluralCase.one : PluralCase.other;
  /// };
  /// ```
  PluralResolver? get pluralResolver => _intlHost.pluralResolver;

  set pluralResolver(PluralResolver? resolver) =>
      _intlHost.pluralResolver = resolver;

  Map<String, Map<String, String>> get translations => _intlHost.translations;

  void addTranslations(Map<String, Map<String, String>> tr) {
    translations.addAll(tr);
  }

  void clearTranslations() {
    translations.clear();
  }

  void appendTranslations(Map<String, Map<String, String>> tr) {
    tr.forEach((key, map) {
      if (translations.containsKey(key)) {
        translations[key]!.addAll(map);
      } else {
        translations[key] = map;
      }
    });
  }
}

extension Trans on String {
  // Builds the candidate translation keys for [locale], from the most
  // specific to the least specific:
  // language_script_country, language_script, language_country, language.
  static List<String> _candidateKeys(Locale locale) {
    final language = locale.languageCode;
    final script = locale.scriptCode;
    final country = locale.countryCode;
    return [
      if (script != null && country != null) "${language}_${script}_$country",
      if (script != null) "${language}_$script",
      if (country != null) "${language}_$country",
      language,
    ];
  }

  // Looks this key up for [locale], trying each candidate key in order of
  // specificity, then falling back to any other translation entry that
  // shares the same language code. Returns null when nothing matches.
  String? _resolveTranslationFor(Locale locale) {
    for (final key in _candidateKeys(locale)) {
      final translation = Get.translations[key];
      if (translation != null && translation.containsKey(this)) {
        return translation[this];
      }
    }
    // Similar-language fallback in the absence of a more specific match.
    final prefix = "${locale.languageCode}_";
    for (final entry in Get.translations.entries) {
      if (entry.key.startsWith(prefix) && entry.value.containsKey(this)) {
        return entry.value[this];
      }
    }
    return null;
  }

  String get tr {
    final locale = Get.locale;
    // Returns the key if locale is null.
    if (locale == null) return this;

    final translation = _resolveTranslationFor(locale);
    if (translation != null) return translation;

    final fallback = Get.fallbackLocale;
    if (fallback != null) {
      return _resolveTranslationFor(fallback) ?? this;
    }
    // If there is no corresponding language or corresponding key, return
    // the key.
    return this;
  }

  String trArgs([List<String> args = const []]) {
    var key = tr;
    if (args.isNotEmpty) {
      for (final arg in args) {
        key = key.replaceFirst(RegExp(r'%s'), arg.toString());
      }
    }
    return key;
  }

  String trPlural([String? pluralKey, int? i, List<String> args = const []]) {
    return i == 1 ? trArgs(args) : pluralKey!.trArgs(args);
  }

  /// Translates this key with [tr], then replaces every `@name` placeholder
  /// in the result with the value mapped to `name` in [params].
  ///
  /// Placeholders are matched by the string's *logical* character order: the
  /// `@` must come immediately before the parameter name (`'@correctAnswers'`),
  /// regardless of the script or text direction of the surrounding text.
  ///
  /// Note for right-to-left translations (Arabic, Hebrew, etc.): inside an
  /// RTL string, a correctly written `@name` placeholder is *displayed* with
  /// the `@` on the visual right of the name. Do not "fix" this by moving the
  /// `@` after the name (`'correctAnswers@'`) — that stores the `@` on the
  /// wrong logical side, so the placeholder will never be substituted.
  ///
  /// ```dart
  /// // en_US: 'You answered @correct of @total questions!'
  /// // he_IL: 'ענית נכון על @correct מתוך @total שאלות!'
  /// 'score'.trParams({'correct': '9', 'total': '10'});
  /// ```
  String trParams([Map<String, String> params = const {}]) {
    var trans = tr;
    if (params.isNotEmpty) {
      params.forEach((key, value) {
        trans = trans.replaceAll('@$key', value);
      });
    }
    return trans;
  }

  String trPluralParams([
    String? pluralKey,
    int? i,
    Map<String, String> params = const {},
  ]) {
    return i == 1 ? trParams(params) : pluralKey!.trParams(params);
  }

  // Resolves the plural category for [count]: the resolver installed via
  // Get.pluralResolver when present, otherwise the two-form English rule.
  static PluralCase _pluralCaseFor(int count) {
    final resolver = Get.pluralResolver;
    if (resolver != null) return resolver(count, Get.locale);
    return count == 1 ? PluralCase.one : PluralCase.other;
  }

  // Picks the translation key for [count] from [caseKeys], falling back to
  // [PluralCase.other] and finally to this key itself.
  String _pluralKeyFor(Map<PluralCase, String> caseKeys, int count) {
    return caseKeys[_pluralCaseFor(count)] ??
        caseKeys[PluralCase.other] ??
        this;
  }

  /// Translates the plural form of this key that matches [count], supporting
  /// every CLDR plural category — unlike [trPlural], which only distinguishes
  /// `count == 1` from everything else.
  ///
  /// [caseKeys] maps each [PluralCase] the current language distinguishes to
  /// the translation key holding that form. The category for [count] is
  /// resolved through [LocalesIntl.pluralResolver] (defaulting to the
  /// two-form English rule), then the matching key is translated with
  /// [trArgs] and [args]. When [caseKeys] has no entry for the resolved
  /// category, [PluralCase.other] is used; when that is also absent, this
  /// key itself is translated.
  ///
  /// ```dart
  /// 'songs'.trPluralCases({
  ///   PluralCase.one: 'songs_one',
  ///   PluralCase.few: 'songs_few',
  ///   PluralCase.other: 'songs_other',
  /// }, 3, ['3']);
  /// ```
  String trPluralCases(
    Map<PluralCase, String> caseKeys,
    int count, [
    List<String> args = const [],
  ]) {
    return _pluralKeyFor(caseKeys, count).trArgs(args);
  }

  /// Translates the plural form of this key that matches [count], like
  /// [trPluralCases], but substitutes named `@placeholder` parameters via
  /// [trParams] and [params] instead of positional `%s` arguments.
  String trPluralCasesParams(
    Map<PluralCase, String> caseKeys,
    int count, [
    Map<String, String> params = const {},
  ]) {
    return _pluralKeyFor(caseKeys, count).trParams(params);
  }
}
