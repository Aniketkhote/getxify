import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

void removeHash() {
  setUrlStrategy(PathUrlStrategy());
}

void removeHistory(String? url) {
  if (url != null && url.isNotEmpty) {
    web.window.history.replaceState(null, '', url);
  }
}
