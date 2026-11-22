import 'dart:async';
import 'dart:collection';

/// Exception thrown when a queued job is cancelled before execution.
class GetQueueCancelledException implements Exception {
  final String message;
  const GetQueueCancelledException([this.message = 'Canceled']);

  @override
  String toString() => 'GetQueueCancelledException: $message';
}

class GetQueue {
  final ListQueue<_Item<dynamic>> _queue = ListQueue<_Item<dynamic>>();
  bool _active = false;

  bool get isJobInProgress => _active || _queue.isNotEmpty;

  Future<T> add<T>(FutureOr<T> Function() job) {
    var completer = Completer<T>();
    _queue.add(_Item<T>(completer, job));
    _check();
    return completer.future;
  }

  void cancelAllJobs() {
    for (final item in _queue) {
      if (!item.completer.isCompleted) {
        item.completer.completeError(const GetQueueCancelledException());
      }
    }
    _queue.clear();
  }

  void _check() async {
    if (_active) return;
    _active = true;
    while (_queue.isNotEmpty) {
      var item = _queue.removeFirst();
      try {
        var result = await item.job();
        if (!item.completer.isCompleted) {
          item.completer.complete(result);
        }
      } catch (e, st) {
        if (!item.completer.isCompleted) {
          item.completer.completeError(e, st);
        }
      }
    }
    _active = false;
  }
}

class _Item<T> {
  final Completer<T> completer;
  final FutureOr<T> Function() job;

  _Item(this.completer, this.job);
}
