import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

import '../navigation/utils/wrapper.dart';

// trPlural only supports the two-form (one/other) rule, which is wrong for
// Arabic, Russian, Polish, etc. trPluralCases exposes every CLDR plural
// category through a pluggable Get.pluralResolver.

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home'));
  }
}

void main() {
  testWidgets("translates keys and updates locale dynamically", (tester) async {
    await tester.pumpWidget(Wrapper(child: Container()));

    await tester.pumpAndSettle();

    expect('covid'.tr, 'Corona Virus');
    expect('total_confirmed'.tr, 'Total Confirmed');
    expect('total_deaths'.tr, 'Total Deaths');

    Get.updateLocale(const Locale('pt', 'BR'));

    await tester.pumpAndSettle();

    expect('covid'.tr, 'Corona Vírus');
    expect('total_confirmed'.tr, 'Total confirmado');
    expect('total_deaths'.tr, 'Total de mortes');

    Get.updateLocale(const Locale('en', 'EN'));

    await tester.pumpAndSettle();

    expect('covid'.tr, 'Corona Virus');
    expect('total_confirmed'.tr, 'Total Confirmed');
    expect('total_deaths'.tr, 'Total Deaths');
  });

  group('Script and locale resolution fallbacks', () {
    PluralCase russianRule(int count, Locale? locale) {
      if (count % 10 == 1 && count % 100 != 11) return PluralCase.one;
      if (count % 10 >= 2 &&
          count % 10 <= 4 &&
          (count % 100 < 12 || count % 100 > 14)) {
        return PluralCase.few;
      }
      return PluralCase.many;
    }

    PluralCase arabicRule(int count, Locale? locale) {
      if (count == 0) return PluralCase.zero;
      if (count == 1) return PluralCase.one;
      if (count == 2) return PluralCase.two;
      if (count % 100 >= 3 && count % 100 <= 10) return PluralCase.few;
      if (count % 100 >= 11) return PluralCase.many;
      return PluralCase.other;
    }

    setUp(() {
      Get.clearTranslations();
      Get.addTranslations({
        'en_US': {
          'songs_one': '%s song',
          'songs_other': '%s songs',
          'apples_one': 'You have @count apple',
          'apples_other': 'You have @count apples',
        },
        'ru_RU': {
          'songs_one': '%s песня',
          'songs_few': '%s песни',
          'songs_many': '%s песен',
          'apples_one': 'У вас @count яблоко',
          'apples_few': 'У вас @count яблока',
          'apples_many': 'У вас @count яблок',
        },
        'ar_SA': {
          'songs_zero': 'لا أغاني',
          'songs_one': 'أغنية واحدة',
          'songs_two': 'أغنيتان',
          'songs_few': '%s أغانٍ',
          'songs_many': '%s أغنية',
        },
      });
      Get.locale = const Locale('en', 'US');
      Get.fallbackLocale = null;
      Get.pluralResolver = null;
    });

    tearDown(() {
      Get.pluralResolver = null;
      Get.clearTranslations();
    });

    const songCases = {
      PluralCase.zero: 'songs_zero',
      PluralCase.one: 'songs_one',
      PluralCase.two: 'songs_two',
      PluralCase.few: 'songs_few',
      PluralCase.many: 'songs_many',
      PluralCase.other: 'songs_other',
    };

    const appleCases = {
      PluralCase.one: 'apples_one',
      PluralCase.few: 'apples_few',
      PluralCase.many: 'apples_many',
      PluralCase.other: 'apples_other',
    };

    test('default resolver applies the two-form English rule', () {
      expect('songs'.trPluralCases(songCases, 1, ['1']), '1 song');
      expect('songs'.trPluralCases(songCases, 0, ['0']), '0 songs');
      expect('songs'.trPluralCases(songCases, 5, ['5']), '5 songs');
    });

    test('unmatched category falls back to other, then to the key itself', () {
      expect(
        'songs'.trPluralCases({PluralCase.one: 'songs_one'}, 1, ['1']),
        '1 song',
      );
      // No entry for the resolved category and no "other": the key itself.
      expect('songs'.trPluralCases({PluralCase.one: 'songs_one'}, 7), 'songs');
      // Resolved category missing, "other" present.
      expect(
        'songs'.trPluralCases({PluralCase.other: 'songs_other'}, 1, ['1']),
        '1 songs',
      );
    });

    test('custom resolver enables Russian plural rules', () {
      Get.locale = const Locale('ru', 'RU');
      Get.pluralResolver = russianRule;

      expect('songs'.trPluralCases(songCases, 1, ['1']), '1 песня');
      expect('songs'.trPluralCases(songCases, 21, ['21']), '21 песня');
      expect('songs'.trPluralCases(songCases, 3, ['3']), '3 песни');
      expect('songs'.trPluralCases(songCases, 24, ['24']), '24 песни');
      expect('songs'.trPluralCases(songCases, 5, ['5']), '5 песен');
      expect('songs'.trPluralCases(songCases, 12, ['12']), '12 песен');
      expect('songs'.trPluralCases(songCases, 111, ['111']), '111 песен');
    });

    test(
      'custom resolver enables Arabic plural rules including zero and two',
      () {
        Get.locale = const Locale('ar', 'SA');
        Get.pluralResolver = arabicRule;

        expect('songs'.trPluralCases(songCases, 0), 'لا أغاني');
        expect('songs'.trPluralCases(songCases, 1), 'أغنية واحدة');
        expect('songs'.trPluralCases(songCases, 2), 'أغنيتان');
        expect('songs'.trPluralCases(songCases, 3, ['3']), '3 أغانٍ');
        expect('songs'.trPluralCases(songCases, 11, ['11']), '11 أغنية');
      },
    );

    test('resolver receives the count and the active locale', () {
      int? seenCount;
      Locale? seenLocale;
      Get.pluralResolver = (count, locale) {
        seenCount = count;
        seenLocale = locale;
        return PluralCase.other;
      };

      'songs'.trPluralCases(songCases, 42, ['42']);
      expect(seenCount, 42);
      expect(seenLocale, const Locale('en', 'US'));
    });

    test('trPluralCasesParams substitutes named parameters', () {
      expect(
        'apples'.trPluralCasesParams(appleCases, 1, {'count': '1'}),
        'You have 1 apple',
      );
      expect(
        'apples'.trPluralCasesParams(appleCases, 4, {'count': '4'}),
        'You have 4 apples',
      );

      Get.locale = const Locale('ru', 'RU');
      Get.pluralResolver = russianRule;
      expect(
        'apples'.trPluralCasesParams(appleCases, 2, {'count': '2'}),
        'У вас 2 яблока',
      );
      expect(
        'apples'.trPluralCasesParams(appleCases, 5, {'count': '5'}),
        'У вас 5 яблок',
      );
    });

    test('trPlural and trPluralParams keep their original behavior', () {
      expect('songs_one'.trPlural('songs_other', 1, ['1']), '1 song');
      expect('songs_one'.trPlural('songs_other', 2, ['2']), '2 songs');
      expect(
        'apples_one'.trPluralParams('apples_other', 1, {'count': '1'}),
        'You have 1 apple',
      );
      expect(
        'apples_one'.trPluralParams('apples_other', 3, {'count': '3'}),
        'You have 3 apples',
      );

      // Installing a resolver must not change trPlural's two-form contract.
      Get.pluralResolver = (count, locale) => PluralCase.many;
      expect('songs_one'.trPlural('songs_other', 1, ['1']), '1 song');
    });
  });

  group('trParams placeholder substitution in LTR and RTL strings', () {
    setUp(() {
      Get.clearTranslations();
      Get.addTranslations({
        'en_US': {
          'correct_answer_message':
              'You answered correctly on @correctAnswers of @questionsPerGame '
              'questions!',
        },
        'he_IL': {
          'correct_answer_message':
              'ענית נכון על @correctAnswers מתוך @questionsPerGame שאלות !',
          'malformed_message': 'ענית נכון על correctAnswers@ שאלות',
        },
      });
    });

    tearDown(() {
      Get.clearTranslations();
      Get.locale = null;
      Get.fallbackLocale = null;
    });

    test('trParams substitutes @ placeholders in an LTR (English) string', () {
      Get.locale = const Locale('en', 'US');
      expect(
        'correct_answer_message'.trParams({
          'correctAnswers': '9',
          'questionsPerGame': '10',
        }),
        'You answered correctly on 9 of 10 questions!',
      );
    });

    test('trParams substitutes @ placeholders in an RTL (Hebrew) string', () {
      Get.locale = const Locale('he', 'IL');
      expect(
        'correct_answer_message'.trParams({
          'correctAnswers': '9',
          'questionsPerGame': '10',
        }),
        'ענית נכון על 9 מתוך 10 שאלות !',
      );
    });

    test('trParams handles multi-codepoint values inside RTL text', () {
      Get.locale = const Locale('he', 'IL');
      expect(
        'correct_answer_message'.trParams({
          'correctAnswers': '11',
          'questionsPerGame': '22',
        }),
        'ענית נכון על 11 מתוך 22 שאלות !',
      );
    });

    test(
      'trParams does not substitute a logically reversed key@ placeholder',
      () {
        Get.locale = const Locale('he', 'IL');
        // 'correctAnswers@' has the '@' logically after the name (a common
        // RTL-editor authoring mistake); it must be left untouched.
        expect(
          'malformed_message'.trParams({'correctAnswers': '9'}),
          'ענית נכון על correctAnswers@ שאלות',
        );
      },
    );
  });

  group('Device locale adoption and override behavior', () {
    setUp(() {
      Get.locale = null;
    });

    tearDown(() {
      Get.locale = null;
      Get.reset();
    });

    Future<void> setDeviceLocale(WidgetTester tester, Locale locale) async {
      tester.platformDispatcher.localeTestValue = locale;
      tester.platformDispatcher.localesTestValue = [locale];
      await tester.pumpAndSettle();
    }

    Future<void> resetDeviceLocale(WidgetTester tester) async {
      tester.platformDispatcher.clearLocaleTestValue();
      tester.platformDispatcher.clearLocalesTestValue();
      await tester.pumpAndSettle();
    }

    testWidgets(
      'system locale change does not override locale set via GetMaterialApp',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            locale: const Locale('en', 'US'),
            getPages: [GetPage(name: '/', page: () => const Home())],
          ),
        );
        await tester.pumpAndSettle();

        expect(Get.locale, const Locale('en', 'US'));

        await setDeviceLocale(tester, const Locale('fr', 'FR'));

        expect(Get.locale, const Locale('en', 'US'));

        await resetDeviceLocale(tester);
      },
    );

    testWidgets(
      'system locale change does not override locale set via Get.updateLocale',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            getPages: [GetPage(name: '/', page: () => const Home())],
          ),
        );
        await tester.pumpAndSettle();

        Get.updateLocale(const Locale('ar', 'EG'));
        await tester.pumpAndSettle();
        expect(Get.locale, const Locale('ar', 'EG'));

        await setDeviceLocale(tester, const Locale('fr', 'FR'));

        expect(Get.locale, const Locale('ar', 'EG'));

        await resetDeviceLocale(tester);
      },
    );

    testWidgets(
      'device locale change is still adopted when the app never set a locale',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            getPages: [GetPage(name: '/', page: () => const Home())],
          ),
        );
        await tester.pumpAndSettle();

        await setDeviceLocale(tester, const Locale('pt', 'BR'));

        expect(Get.locale, const Locale('pt', 'BR'));

        await setDeviceLocale(tester, const Locale('fr', 'FR'));

        expect(Get.locale, const Locale('fr', 'FR'));

        await resetDeviceLocale(tester);
      },
    );
  });

  group('Custom plural rules and plural case parameter substitution', () {
    setUp(() {
      Get.clearTranslations();
      Get.addTranslations({
        'zh_Hant': {'hello': '你好（繁體）'},
        'zh_Hant_TW': {'hello': '你好（台灣繁體）'},
        'zh_CN': {'hello': '你好（简体）'},
        'en_US': {'hello': 'Hello', 'only_english': 'English only'},
      });
      Get.fallbackLocale = const Locale('en', 'US');
    });

    tearDown(() {
      Get.clearTranslations();
      Get.locale = null;
      Get.fallbackLocale = null;
    });

    test('scriptCode-only locale prefers language_script key', () {
      Get.locale = const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
      );
      expect('hello'.tr, '你好（繁體）');
    });

    test('script + country locale prefers language_script_country key', () {
      Get.locale = const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      );
      expect('hello'.tr, '你好（台灣繁體）');
    });

    test(
      'script + country falls back to language_script before language_country',
      () {
        Get.locale = const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'HK',
        );
        expect('hello'.tr, '你好（繁體）');
      },
    );

    test('locale without script still resolves language_country key', () {
      Get.locale = const Locale('zh', 'CN');
      expect('hello'.tr, '你好（简体）');
    });

    test('similar-language fallback still works for unknown country', () {
      Get.locale = const Locale('en', 'EN');
      expect('hello'.tr, 'Hello');
    });

    test(
      'missing key falls back to fallbackLocale, then to the key itself',
      () {
        Get.locale = const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
        );
        expect('only_english'.tr, 'English only');
        expect('missing_key'.tr, 'missing_key');
      },
    );

    test('fallbackLocale with scriptCode resolves script-specific keys', () {
      Get.locale = const Locale('fr', 'FR');
      Get.fallbackLocale = const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      );
      expect('hello'.tr, '你好（台灣繁體）');
    });
  });
}
