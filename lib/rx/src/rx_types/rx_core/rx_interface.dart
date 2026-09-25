part of '../rx_types.dart';

/// This class is the foundation for all reactive (Rx) classes that make Get
/// so powerful.
///
/// This interface is the contract that `_RxImpl<T>` uses in all its
/// subclasses.
abstract class RxInterface<T> implements ValueListenable<T> {
  /// Closes the reactive variable and cleans up resources.
  void close();

  /// Listens to changes of the reactive variable.
  ///
  /// Calls [onData] with the current value whenever the value changes.
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  });
}
