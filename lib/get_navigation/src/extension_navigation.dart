import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:getxify/get_navigation/src/routes/core/test_kit.dart';

import '../../getxify.dart';
import 'dialog/dialog_route.dart';
import 'root/get_root.dart';

part 'extensions/bottomsheet.dart';
part 'extensions/dialog.dart';
part 'extensions/snackbar.dart';
part 'extensions/navigation.dart';
part 'extensions/overlay.dart';

class RouteNotFoundException implements Exception {
  final String message;
  RouteNotFoundException(this.message);

  @override
  String toString() => 'RouteNotFoundException: $message';
}

/// It replaces the Flutter Navigator, but needs no context.
/// You can to use navigator.push(YourRoute()) rather
/// Navigator.push(context, YourRoute());
NavigatorState? get navigator => GetNavigationExt(Get).key.currentState;

/// Whether [route] displays a dialog, either GetX's own [GetDialogRoute]
/// or one created by Flutter's native `showDialog`/`showGeneralDialog`.
bool _isDialogRoute(Route<dynamic>? route) =>
    route is GetDialogRoute || route is RawDialogRoute;

/// Whether [route] displays a bottom sheet, either GetX's own
/// [GetModalBottomSheetRoute] or one created by Flutter's native
/// `showModalBottomSheet`.
bool _isBottomSheetRoute(Route<dynamic>? route) =>
    route is GetModalBottomSheetRoute || route is ModalBottomSheetRoute;

/// Returns the topmost route of [navigatorState] without popping it.
Route<dynamic>? _topRouteOf(NavigatorState navigatorState) {
  Route<dynamic>? topRoute;
  navigatorState.popUntil((route) {
    topRoute = route;
    return true;
  });
  return topRoute;
}

/// Reassigns new dependency registrations to [route].
///
/// Transient overlays (dialogs and bottom sheets) must not own the
/// instances registered while they are open: a `Get.put` executed inside
/// an overlay's builder logically belongs to the page under the overlay
/// and has to survive the overlay's dismissal. Since pushing the overlay
/// synchronously reports it as the current dependency-link target, this
/// restores the target to the route that was topmost before the push.
void _relinkDependenciesTo(Route<dynamic>? route) {
  if (route == null) return;
}
