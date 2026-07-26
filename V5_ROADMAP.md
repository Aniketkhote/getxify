# GetXify v5.0 Architectural Roadmap & Proposals

This document outlines the proposed architectural changes and modernizations for **GetXify v5.0**. The primary goal of v5.0 is to eliminate legacy workarounds originally built 4+ years ago for Dart 2.x and early Flutter versions, replacing them with modern **Dart 3** and **Flutter 3.44+** native primitives.

---

## Key Pillars of v5.0

### 1. Modern Native Routing (`Router` & `Uri`)
* **Current State (v4.x)**: Uses a custom regex route parser (`ParseRouteTree`, `RouteDecoder`, `PathDecoded`) and custom route-branch flattening algorithms.
* **v5.0 Proposal**:
  - Replace custom regex parsing with native Dart `Uri` pattern matching and standard Flutter `RouterDelegate` page stacks.
  - Simplify deep linking, query parameter extraction, and route transition handling by leveraging Flutter's native `Navigator.pages` API directly.

### 2. Context-Aware Navigation Extensions over Global `Get.key`
* **Current State (v4.x)**: Uses a global `GlobalKey<NavigatorState>` (`Get.key`) for contextless navigation (`Get.to()`, `Get.back()`).
* **v5.0 Proposal**:
  - Introduce ergonomic `BuildContext` extension methods (e.g. `context.pushNamed()`, `context.pop()`, `context.showSnackBar()`).
  - Eliminate global key state leakage across nested navigators, enabling multi-shell routing, nested themes, and hero transitions to work seamlessly.

### 3. Native Flutter `ListenableBuilder` Integration
* **Current State (v4.x)**: Uses custom `ListNotifier` and `ListNotifierSingleMixin` classes for simple state management in `GetBuilder`.
* **v5.0 Proposal**:
  - Adopt Flutter’s native `ListenableBuilder` and standard `ChangeNotifier` / `ValueNotifier` primitives.
  - Remove redundant custom listener mixins, reducing maintenance overhead and aligning directly with Flutter framework updates.

### 4. Element-Tree Lifecycle Management over `SmartManagement`
* **Current State (v4.x)**: Uses `SmartManagement` modes (`full`, `keepFactory`, `onlyBuilder`, `fenix`) and manual route-key tracking (`RouterReportManager`).
* **v5.0 Proposal**:
  - Tie controller dependency lifecycles directly to the Flutter widget element tree (using `InheritedWidget` / `State.dispose` scope nodes).
  - Eliminate manual string key maps (`_singletons`), `lateRemove` chains, and route dependency tracking.

### 5. Unified Reactive Primitives via Dart 3 Records & Sealed Types
* **Current State (v4.x)**: Maintains separate specialized wrapper classes for every primitive type (`RxInt`, `RxDouble`, `RxString`, `RxBool`, `RxnBool`).
* **v5.0 Proposal**:
  - Consolidate primitive wrappers using Dart 3 sealed types and records.
  - Retain `.obs` ergonomics while simplifying the underlying class hierarchy.

---

## Summary of Benefits

| Subsystem | v4.x Implementation | v5.0 Proposed Replacement | Primary Benefit |
| :--- | :--- | :--- | :--- |
| **Routing** | Custom `ParseRouteTree` regex matcher | Native `Uri` & Flutter `RouterDelegate` | Eliminates ~2,000 lines of custom route tree matching |
| **Navigation** | Global `Get.key` Navigator Key | `BuildContext` Extensions | Prevents theme & nested scope leakage |
| **State** | Custom `ListNotifier` mixin | Flutter native `ListenableBuilder` | Direct framework alignment & zero custom listener bloat |
| **Dependency Injection** | `SmartManagement` & `RouterReportManager` | Element-tree bound scope nodes | Eliminates manual route dependency tracking & memory leaks |
| **Reactive Types** | Primitive wrappers (`RxInt`, `RxBool`) | Dart 3 Sealed Types & Records | Cleaner class hierarchy and unified reactive engine |
