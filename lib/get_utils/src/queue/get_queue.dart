import 'dart:async';

class GetQueue {
  final List<_Item<dynamic>> _queue = [];
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
        item.completer.completeError('Canceled');
      }
    }
    _queue.clear();
  }

  void _check() async {
    if (_active) return;
    _active = true;
    while (_queue.isNotEmpty) {
      var item = _queue.removeAt(0);
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
