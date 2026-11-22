import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/internationalization/internationalization.dart';

class _AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {'hello': 'Hello'},
    'es_ES': {'hello': 'Hola'},
  };
}

void main() {
  test(
    'internationalization module exports Translations and Trans extension',
    () {
      final translations = _AppTranslations();
      expect(translations.keys['en_US']?['hello'], 'Hello');
      expect('greeting'.tr, isA<String>());
    },
  );
}
