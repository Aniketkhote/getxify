import 'get_interface.dart';

/// The concrete implementation of [GetInterface].
///
/// This implementation allows extensions to add state management, navigation,
/// dependency injection, and internationalization APIs onto the global [Get] object.
class _GetImpl extends GetInterface {}

/// The global entrypoint for accessing GetX APIs.
///
/// Features are added to this instance via extensions (e.g., `GetInstanceExt` for dependency
/// management, `GetNavigation` for routing, etc.).
// ignore: non_constant_identifier_names
final Get = _GetImpl();
