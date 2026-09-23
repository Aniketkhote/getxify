import 'dart:async';

import 'package:flutter/widgets.dart';

import 'list_notifier.dart';

/// Callback function to update the value in [ValueBuilder].
typedef ValueBuilderUpdateCallback<T> = void Function(T snapshot);

/// Builder function for [ValueBuilder].
typedef ValueBuilderBuilder<T> =
    Widget Function(T snapshot, ValueBuilderUpdateCallback<T> updater);

/// Manages a local state like ObxValue, but uses a callback instead of
/// a Rx value.
///
/// Example:
/// ```
///  ValueBuilder<bool>(
///    initialValue: false,
///    builder: (value, update) => Switch(
///    value: value,
///    onChanged: (flag) {
///       update( flag );
///    },),
///    onUpdate: (value) => print("Value updated: $value"),
///  ),
///  ```
/// Manages local state with a callback-based update mechanism.
///
/// This widget is similar to [ObxValue] but uses a callback instead of
/// a reactive Rx value. It's useful for managing simple local state.
class ValueBuilder<T> extends StatefulWidget {
  /// The initial value for the state.
  final T initialValue;

  /// Builder function that creates the widget tree.
  final ValueBuilderBuilder<T> builder;

  /// Callback called when the widget is disposed.
  final void Function()? onDispose;

  /// Callback called when the value is updated.
  final void Function(T)? onUpdate;

  /// Creates a new ValueBuilder widget.
  const ValueBuilder({
    super.key,
    required this.initialValue,
    this.onDispose,
    this.onUpdate,
    required this.builder,
  });

  @override
  ValueBuilderState<T> createState() => ValueBuilderState<T>();
}

/// The state for [ValueBuilder].
class ValueBuilderState<T> extends State<ValueBuilder<T>> {
  /// The current value.
  late T value;

  @override
  void initState() {
    value = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => widget.builder(value, updater);

  /// Updates the value and triggers a rebuild.
  void updater(T newValue) {
    if (widget.onUpdate != null) {
      widget.onUpdate!(newValue);
    }
    setState(() {
      value = newValue;
    });
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    if (value is ChangeNotifier) {
      (value as ChangeNotifier?)?.dispose();
    } else if (value is StreamController) {
      (value as StreamController?)?.close();
    }
    super.dispose();
  }
}

/// Element for Obx widgets that tracks reactive dependencies.
class ObxElement = StatelessElement with StatelessObserverComponent;

/// An experimental widget that observes reactive changes.
///
/// This widget automatically tracks reactive variables used in its
/// builder and rebuilds when they change.
class Observer extends ObxStatelessWidget {
  /// Builder function that creates the widget tree.
  final WidgetBuilder builder;

  const Observer({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context);
}

/// A StatelessWidget that can listen to reactive changes.
///
/// Subclasses of this widget will automatically track reactive
/// variables used in their build method and rebuild when they change.
abstract class ObxStatelessWidget extends StatelessWidget {
  /// Creates a new ObxStatelessWidget.
  const ObxStatelessWidget({super.key});

  @override
  StatelessElement createElement() => ObxElement(this);
}

/// Mixin that adds reactive tracking to StatelessElement.
///
/// This mixin automatically tracks reactive variables used during
/// the build process and sets up listeners to rebuild when they change.
mixin StatelessObserverComponent on StatelessElement {
  /// List of disposers for cleanup.
  List<Disposer>? disposers = <Disposer>[];

  /// Schedules a rebuild when reactive dependencies change.
  void getUpdate() {
    if (disposers != null) {
      scheduleMicrotask(() {
        if (mounted) {
          markNeedsBuild();
        }
      });
    }
  }

  @override
  Widget build() {
    return Notifier.instance.append(
      NotifyData(disposers: disposers!, updater: getUpdate),
      super.build,
    );
  }

  @override
  void unmount() {
    for (final disposer in disposers!) {
      disposer();
    }
    disposers!.clear();
    disposers = null;
    super.unmount();
  }
}
