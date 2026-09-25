/// Pure user-agent string heuristics backing the web implementation of
/// `GeneralPlatform`.
///
/// The matching logic lives here, decoupled from `package:web`, so it can be
/// unit tested on the Dart VM where browser bindings are unavailable.
// ignore: avoid_classes_with_only_static_members
abstract class WebPlatformDetect {
  static final RegExp _iosPlatformPattern = RegExp(r'iPad|iPhone|iPod');

  /// Whether the given navigator values identify a macOS browser.
  ///
  /// Chrome and Safari report an `appVersion` containing `Mac OS`
  /// (e.g. `5.0 (Macintosh; Intel Mac OS X 10_15_7) ...`), while Firefox
  /// reports only `5.0 (Macintosh)`, so both tokens are checked, with a
  /// `Mac`-prefixed [platform] (such as `MacIntel`) as a fallback. iPads
  /// masquerading as macOS are excluded through [isIOS].
  static bool isMacOS(String appVersion, String platform, int maxTouchPoints) {
    return (appVersion.contains('Mac OS') ||
            appVersion.contains('Macintosh') ||
            platform.contains('Mac')) &&
        !isIOS(platform, maxTouchPoints);
  }

  /// Whether the given navigator values identify an iOS browser.
  ///
  /// [maxTouchPoints] is needed to separate iPadOS 13+ (which reports the
  /// desktop `MacIntel` platform) from real macOS.
  static bool isIOS(String platform, int maxTouchPoints) {
    return _iosPlatformPattern.hasMatch(platform) ||
        (platform == 'MacIntel' && maxTouchPoints > 1);
  }
}
