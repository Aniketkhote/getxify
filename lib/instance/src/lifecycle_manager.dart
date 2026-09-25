import 'package:flutter/widgets.dart';

import '../../core/core.dart';
import '../../state_manager/src/controllers/list_notifier.dart';
import 'extension_instance.dart';

/// Manages the lifecycle and disposal of dependencies bound to the UI.
class DependencyLifecycleManager {
  /// Schedules a dependency to be deleted when the route finishes disposing.
  /// 
  /// The registration might have been superseded by a new one during disposal.
  /// This method safely peels the stale factory out of the memory without
  /// affecting the active one.
  static void deleteRouteDependency(String key) {
    final dep = GetInstanceExt.factories[key];
    if (dep == null) {
      Get.log('Instance "$key" already removed.', isError: true);
      return;
    }

    final live = dep.dependency;
    final hasSubscribers =
        live is ListNotifierSingleMixin &&
        !live.isDisposed &&
        live.hasSubscribers;
    if (dep.lateRemove != null || !hasSubscribers) {
      Get.delete(key: key);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = GetInstanceExt.factories[key];
      if (current == null) return;
      if (!identical(current, dep)) {
        // The registration was superseded meanwhile
        var chain = current.lateRemove;
        while (chain != null) {
          if (identical(chain, dep)) {
            Get.delete(key: key);
            return;
          }
          chain = chain.lateRemove;
        }
        return;
      }
      if (!live.isDisposed && live.hasSubscribers) {
        dep.isDirty = false;
        Get.log(
          'Instance "$key" was kept alive on route disposal: '
          'widgets are still subscribed to it.',
        );
        return;
      }
      Get.delete(key: key);
    });
  }
}
