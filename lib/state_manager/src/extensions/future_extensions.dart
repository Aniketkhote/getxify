import '../../../../rx/src/rx_types/rx_types.dart';
import '../controllers/rx_notifier.dart';

/// Extension on [Future] providing reactive status binding.
extension FutureToRx<T> on Future<T> {
  /// Converts this [Future] into a reactive [Rx<GetStatus<T>>].
  ///
  /// The returned [Rx] starts with [GetStatus.loading()] (or [GetStatus.success(initialData)]
  /// if [initialData] is provided), and automatically updates to [GetStatus.success] or
  /// [GetStatus.error] upon future completion.
  Rx<GetStatus<T>> toRx([T? initialData]) {
    final rx = Rx<GetStatus<T>>(
      initialData != null
          ? GetStatus<T>.success(initialData)
          : GetStatus<T>.loading(),
    );
    then(
      (data) {
        if (!rx.isDisposed) {
          rx.value = GetStatus<T>.success(data);
        }
      },
      onError: (Object error, StackTrace? _) {
        if (!rx.isDisposed) {
          rx.value = GetStatus<T>.error(error);
        }
      },
    );
    return rx;
  }
}
