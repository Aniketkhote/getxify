import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../get_core/get_core.dart';
import '../../../get_instance/src/extension_instance.dart';
import '../../../get_instance/src/lifecycle.dart';
import '../simple/list_notifier.dart';
import 'rx_ticker_provider_mixin.dart';

/// Builder function for GetX widgets.
typedef GetXControllerBuilder<T extends GetLifeCycleMixin> =
    Widget Function(T controller);

/// A StatefulWidget that provides reactive state management.
///
/// This widget automatically manages the lifecycle of a controller
/// and rebuilds when the controller's state changes. It supports
/// both global and local controller management.
class GetX<T extends GetLifeCycleMixin> extends StatefulWidget {
  /// Builder function that creates the widget tree.
  final GetXControllerBuilder<T> builder;

  /// Whether the controller is global (shared across the app).
  final bool global;

  /// Whether to automatically remove the controller when the widget is disposed.
  final bool autoRemove;

  /// Whether to assign a unique ID to this widget instance.
  final bool assignId;

  /// Callback called when the state is initialized.
  final void Function(GetXState<T> state)? initState,
      dispose,
      didChangeDependencies;

  /// Callback called when the widget updates.
  final void Function(GetX oldWidget, GetXState<T> state)? didUpdateWidget;

  /// The initial controller instance.
  final T? init;

  /// The tag to identify the controller in the dependency injection system.
  final String? tag;

  /// Creates a new GetX widget.
  const GetX({
    super.key,
    this.tag,
    required this.builder,
    this.global = true,
    this.autoRemove = true,
    this.initState,
    this.assignId = false,
    this.dispose,
    this.didChangeDependencies,
    this.didUpdateWidget,
    this.init,
  });

  @override
  StatefulElement createElement() => StatefulElement(this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('controller', init))
      ..add(DiagnosticsProperty<String>('tag', tag))
      ..add(
        ObjectFlagProperty<GetXControllerBuilder<T>>.has('builder', builder),
      );
  }

  @override
  GetXState<T> createState() => GetXState<T>();
}

/// The state for a [GetX] widget.
///
/// This state class manages the controller lifecycle and handles
/// dependency injection and disposal.
class GetXState<T extends GetLifeCycleMixin> extends State<GetX<T>> {
  /// The controller instance.
  T? controller;

  /// Whether this widget created the controller.
  bool? _isCreator = false;

  @override
  void initState() {
    final isRegistered = Get.isRegistered<T>(tag: widget.tag);

    if (widget.global) {
      if (isRegistered) {
        _isCreator = Get.isPrepared<T>(tag: widget.tag);
        controller = Get.find<T>(tag: widget.tag);
      } else {
        controller = widget.init;
        _isCreator = true;
        Get.put<T>(controller!, tag: widget.tag);
      }
    } else {
      controller = widget.init;
      _isCreator = true;
      controller?.onStart();
    }
    widget.initState?.call(this);

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Object? localController = controller;
    if (localController is GetTickerProvider) {
      localController.didChangeDependencies(context);
    }
    if (widget.didChangeDependencies != null) {
      widget.didChangeDependencies!(this);
    }
  }

  @override
  void didUpdateWidget(GetX oldWidget) {
    super.didUpdateWidget(oldWidget as GetX<T>);
    widget.didUpdateWidget?.call(oldWidget, this);
  }

  @override
  void dispose() {
    if (widget.dispose != null) widget.dispose!(this);
    if (_isCreator! || widget.assignId) {
      if (widget.autoRemove && Get.isRegistered<T>(tag: widget.tag)) {
        Get.delete<T>(tag: widget.tag);
      }
    }

    for (final disposer in disposers) {
      disposer();
    }

    disposers.clear();

    controller = null;
    _isCreator = null;
    super.dispose();
  }

  /// Updates the widget by calling setState.
  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  /// List of disposers for cleanup.
  final disposers = <Disposer>[];

  @override
  Widget build(BuildContext context) => Notifier.instance.append(
    NotifyData(disposers: disposers, updater: _update),
    () => widget.builder(controller!),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('controller', controller));
  }
}
