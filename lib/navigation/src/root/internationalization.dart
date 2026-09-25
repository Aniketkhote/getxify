/// A predefined list of languages that are natively read Right-to-Left (RTL).
///
/// This is used internally by the GetXify entry points to automatically flip
/// text directionality when an RTL locale is detected.
const List<String> rtlLanguages = <String>[
  'ar', // Arabic
  'fa', // Farsi
  'he', // Hebrew
  'ps', // Pashto
  'ur', // Urdu
];

/// The base abstract class used for providing localized translations to the app.
///
/// Extend this class to define the key-value dictionary of strings per language.
/// Then pass the subclass instance to `translations` in `GetMaterialApp` or `GetCupertinoApp`.
///
/// Example:
/// ```dart
/// class MyTranslations extends Translations {
///   @override
///   Map<String, Map<String, String>> get keys => {
///     'en_US': {'hello': 'Hello World'},
///     'pt_BR': {'hello': 'Olá Mundo'}
///   };
/// }
/// ```
abstract class Translations {
  /// Defines the localization dictionary.
  ///
  /// The outer map key represents the Locale identifier (e.g. `en_US` or `pt_BR`),
  /// and the inner map represents the string keys and their translated values.
  Map<String, Map<String, String>> get keys;
}
