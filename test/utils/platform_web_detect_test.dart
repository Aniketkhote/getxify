// macOS was not detected under Firefox on web: Firefox reports
// navigator.appVersion as '5.0 (Macintosh)' (no 'Mac OS' token), so the
// appVersion.contains('Mac OS') check silently failed.
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/get_utils/src/platform/platform_web_detect.dart';

void main() {
  const firefoxMacAppVersion = '5.0 (Macintosh)';
  const chromeMacAppVersion =
      '5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';
  const safariMacAppVersion =
      '5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
      '(KHTML, like Gecko) Version/17.4 Safari/605.1.15';
  const windowsAppVersion =
      '5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';

  group('macOS detection on web', () {
    test('detects macOS under Firefox (appVersion lacks "Mac OS")', () {
      expect(
        WebPlatformDetect.isMacOS(firefoxMacAppVersion, 'MacIntel', 0),
        isTrue,
      );
    });

    test('still detects macOS under Chrome', () {
      expect(
        WebPlatformDetect.isMacOS(chromeMacAppVersion, 'MacIntel', 0),
        isTrue,
      );
    });

    test('still detects macOS under Safari', () {
      expect(
        WebPlatformDetect.isMacOS(safariMacAppVersion, 'MacIntel', 0),
        isTrue,
      );
    });

    test('does not report macOS on Windows', () {
      expect(WebPlatformDetect.isMacOS(windowsAppVersion, 'Win32', 0), isFalse);
    });

    test('iPadOS 13+ masquerading as MacIntel is iOS, not macOS', () {
      const iPadAppVersion =
          '5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
          '(KHTML, like Gecko) Version/17.4 Safari/605.1.15';
      expect(WebPlatformDetect.isMacOS(iPadAppVersion, 'MacIntel', 5), isFalse);
      expect(WebPlatformDetect.isIOS('MacIntel', 5), isTrue);
    });
  });

  group('iOS platform pattern', () {
    test('matches iPhone, iPad and iPod platform values', () {
      expect(WebPlatformDetect.isIOS('iPhone', 0), isTrue);
      expect(WebPlatformDetect.isIOS('iPad', 0), isTrue);
      expect(WebPlatformDetect.isIOS('iPod touch', 0), isTrue);
    });

    test('does not match desktop platforms without touch', () {
      expect(WebPlatformDetect.isIOS('MacIntel', 0), isFalse);
      expect(WebPlatformDetect.isIOS('Win32', 0), isFalse);
      expect(WebPlatformDetect.isIOS('Linux x86_64', 0), isFalse);
    });
  });
}
