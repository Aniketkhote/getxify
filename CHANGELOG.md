## 4.1.0

A single, narrow fix: an `RxList` built on a **fixed-length** list no longer throws when you change its length. Nothing that worked in 4.0.1 stops working, so this is a minor release.

### Bug Fixes

- **Fixed `Unsupported operation: Cannot add to a fixed-length list` on `RxList`** - the reported crash was `RxList<T> x = List<T>.empty().obs; x.insert(0, item);`, with a latent `x.clear()` (`Cannot clear a fixed-length list`) in the same app. `List.empty()` and `List.filled()` default to `growable: false`, so `List<T>.empty().obs` — a very common way to spell "an empty reactive list" — aliased a fixed-length backing that refused every length change. A fixed-length backing carries no *immutability intent*; the default is an accident of the `dart:core` API, not a decision the caller made. So the length-changing members now heal it: `add`, `addAll`, `insert`, `insertAll`, `remove`, `removeAt`, `removeLast`, `removeRange`, `removeWhere`, `retainWhere`, `replaceRange`, `clear`, `length=` and `operator +` transparently swap in a growable copy, apply the mutation there and notify listeners exactly once. This covers `List.empty()`, `List.filled()`, `List.of(..., growable: false)`, a `Uint8List` or any other typed-data list, and third-party fixed-length lists — the backing is classified by probing it, not by its type
- **Fixed `RxList.shuffle()` notifying `2 * (length - 1)` times** - it was inherited from `ListMixin`, which swaps elements through `[]=`; it now delegates to the backing list and notifies exactly once, like every other mutator

### Behavior Changes

- **A length change on a fixed-length backing permanently detaches the `RxList` from it** - element writes (`[]=`, `sort`, `shuffle`, `setAll`, `setRange`, `fillRange`, `first=`, `last=`) still go straight through a fixed-length backing such as a `Uint8List`, and keep doing so for as long as the length never changes. The first `add`/`insert`/`remove`/`clear` swaps in a growable copy, and writes after that no longer reach the caller's buffer — including a length change that changes nothing, such as a `removeWhere` matching no element. If you need writes to keep reaching a fixed-length buffer, hold your own reference to it and avoid the length-changing members. The full aliasing contract is tabulated on the `RxList` class documentation
- **A still-illegal length change on a fixed-length backing can report a different exception** - it now fails against the growable copy rather than against the backing, so `RxList<int>(List.filled(3, 0)).length = 5` throws `TypeError` (a non-nullable list cannot be padded with nulls) where it used to throw `UnsupportedError`. `catch`/`on UnsupportedError` sites around `RxList` length changes are worth a look
- **`RxList.shuffle()` on a list of 0 or 1 elements notifies once, where it previously did not notify at all** - the inherited version performed no swaps and so emitted nothing. It still performs no swaps, and still does not touch the backing (so it does not throw on an unmodifiable one), but it does emit this override's single notification

### Unchanged: unmodifiable collections are still unmodifiable

An **unmodifiable** backing is the opposite of a fixed-length one: it is an explicit opt-in to immutability, and silently healing it would delete a guard the caller deliberately put in place, with no compile error to warn them. Nothing here changed in 4.1.0, and it is worth stating explicitly because the two shapes are easy to conflate:

- `RxList.unmodifiable(...)`, `RxSet.unmodifiable(...)`, `RxMap.unmodifiable(...)`, `const [].obs`, `const <K, V>{}.obs`, `Map.unmodifiable({...}).obs`, `List.unmodifiable([...]).obs`, and an `UnmodifiableListView` or `UnmodifiableSetView` wrapped directly as a backing (`RxList(view)` / `RxSet(view)`) all still throw `UnsupportedError` from every mutator, keep their contents and notify nobody. The one collection that does *not* carry the opt-in over is `Set.obs`, which has always copied rather than aliased — see the note under Documentation
- `RxSet` and `RxMap` are untouched apart from documentation. `dart:core` has no fixed-length-but-writable `Set` or `Map`, so "unmodifiable" was their only failure mode — there is nothing for them to heal
- **The one documented exception is `assign` / `assignAll`**, on lists, sets and maps alike. They have replaced an unmodifiable backing with a fresh mutable collection since 4.0.0 and continue to. The resulting seam — `assignAll` succeeds on an unmodifiable backing where `add` throws — is intended, not an oversight: `assign`/`assignAll` *replace the contents wholesale*, so which collection object happened to be holding the old contents is an implementation detail with nothing left to protect, whereas `add`/`insert`/`clear` mutate a collection the caller declared unmodifiable
- **Known limit of probing an *empty* backing.** With no element to attempt a write against, two empty shapes cannot be told apart from an empty fixed-length list, and both heal rather than throwing: a hand-rolled `ListBase` subclass that rejects mutation only through `length=`/`[]=`, and an unmodifiable typed-data view over a zero-length buffer (`Uint8List(0).asUnmodifiableView()`). Neither can hold data, so nothing is at risk of being overwritten. Every `dart:core` unmodifiable list is classified correctly whether empty or not, as is an unmodifiable typed-data view over a buffer with at least one byte in it

### Internal Improvements

- **Added `GetListenable.forceValue`** - a `@protected` counterpart to the `value` setter that skips its `==` short-circuit and then notifies exactly once, overridden in `RxObjectMixin` so it keeps the setter's disposal guard and stream bookkeeping. `RxList` uses it to publish the growable copy when it heals a fixed-length backing: the early return is right when an assignment replaces a *value*, but wrong when it replaces the *container*, because a `List` subclass with a content-insensitive `==` would make the setter silently drop the swap — and with it the mutation just applied to the copy — while still looking like it succeeded

### Documentation

- **Documented the three-way backing contract** - the `RxList` class documentation now tabulates growable / fixed-length / unmodifiable against element writes and length changes, spells out when the `RxList` detaches from the caller's list, and records the empty-backing limit above. `RxList.filled`/`empty`/`unmodifiable`, `RxSet.assign`/`assignAll` and `RxMap.assign` gained matching notes, including the copy fidelity `assign` offers (`toSet()` preserves the runtime element type and a `SplayTreeSet`'s comparator; `Map` has no `toMap()`, so an `RxMap` copy loses a `SplayTreeMap` comparator and `Map.identity()` semantics)
- **Documented that `Set.obs` copies where `List.obs` and `Map.obs` alias** - long-standing behaviour, but it means `Set.unmodifiable({...}).obs` yields a fully mutable `RxSet` while the list and map equivalents keep rejecting mutation

### Testing

- **Added coverage for the narrow contract** - the reported crash, every `RxList` mutator over growable, fixed-length and unmodifiable backings, the notification counts on both the in-place and the heal path, the aliasing contract, state preservation when the action throws, the capability probes themselves (including backings that answer them with something other than `UnsupportedError`, and one whose `==` claims equality with any list), and equivalence against a plain `List`/`Set`/`Map` for the same call sequences. `flutter test` now runs 1272 tests

---

## 4.0.1

### Bug Fixes

- **Fixed null safety issues in GetModalBottomSheetRoute** - Added null checks for `widget.route` which was declared as nullable but accessed with `!` operator throughout, preventing potential runtime crashes
- **Fixed transitionDuration inconsistency** - Changed hardcoded 700ms to use `enterBottomSheetDuration` for consistency with actual animation duration
- **Added public getter for animationController** - Exposed private `_animationController` field through public getter to avoid accessing private members from another class
- **Added fallback builder for null route builder** - Prevents crashes when `widget.route?.builder` is null by providing empty SizedBox fallback
- **Added fallback animation for null route animation** - Uses `AlwaysStoppedAnimation(0.0)` when route animation is null
- **Fixed null safety issues in GetMaterialApp and GetCupertinoApp** - Fixed `builder!` operator usage by using local variable to prevent null check errors
- **Fixed unsafe cast in GetRootState** - Made `rootDelegate` nullable and added null checks for `navigatorKey` access
- **Fixed GlobalKey creation in build method** - Added static fallback scaffold messenger key to avoid creating new GlobalKeys during build
- **Made private field `_keys` in GetRootState** - Changed public mutable `keys` field to private `_keys` for better encapsulation
- **Removed Material-specific properties from GetCupertinoApp** - Removed `highContrastTheme`, `highContrastDarkTheme`, and `actions` which are Material-specific
- **Removed commented code** - Cleaned up unused commented code in get_root.dart

---

## 4.0.0

This release is a massive contribution by [@Baghdady92](https://github.com/Baghdady92), who single-handedly resolved **111 issues** from the upstream GetX tracker, fixed long-standing bugs across routing, state management, dependency injection, and reactive types, and grew the test suite from 144 to 494 tests. Huge thanks for the extraordinary effort that made this release possible.

This release resolves **111 issues reported on the upstream GetX issue tracker** ([jonataslaw/getx](https://github.com/jonataslaw/getx)) that were verified against this codebase. Every fix ships with regression tests; the test suite grew from 144 to 494 tests.

### Behavior Changes

- **`Get.back` returns `bool`** - so callers can detect when the back navigation was ignored because there was no route to go back to; source-compatible for callers ignoring the result (getx#2474)
- **The iOS back-swipe starts only near the leading edge by default** - matching native iOS, so it no longer hijacks horizontal gestures like sliders and carousels; `popGesture: true` keeps the historical full-screen area and `gestureWidth: (_) => double.infinity` restores it explicitly (getx#3209)
- **Middleware lifecycle callbacks run once, on the declaring page's route** - (`onPageBuilt`, `onPageDispose`, ...) instead of once per page in the nested stack; navigation guards (`redirect`/`redirectDelegate`/`onPageCalled`) remain inherited by child pages, and nested flattening no longer registers duplicate routes (getx#3170)
- **`Get.reloadAll()` calls `onDelete`/`onClose` before clearing instances** - and skips `GetxService`s unless `force: true`, matching `Get.reload<S>()` (getx#2397)
- **Inherited bindings execute parents-first** - and a parent `GetPage`'s `binding` now runs when the initial route is one of its child pages (getx#2085)

### System Back & Pop Behavior

- **System back / predictive back respects `PopScope`, `WillPopScope` and `GetPage.canPop`** - `GetDelegate.popRoute` consults the route's pop disposition like `NavigatorState.maybePop`, and a blocked pop reports `onPopInvoked` with `didPop: false` (getx#3216, getx#2996, getx#2704, getx#2869, getx#2434, getx#2188)
- **Browser back on Flutter Web respects pop vetoes** - single-page back navigations consult `PopScope`/`WillPopScope`/`canPop` before popping, and the target entry is re-located by identity after the async veto check so a `willPop` callback that navigates cannot make the wrong pages pop (getx#3121)
- **Browser back with an open dialog/bottom sheet closes the overlay** - instead of popping the underlying page (getx#3322)
- **`Get.back()`/`Get.close()` close open Scaffold drawers** - and other local-history entries such as persistent bottom sheets, without popping the page (getx#3227, getx#2717)
- **Back navigation over imperatively pushed routes works** - `Get.back()`, the system back button/gesture, and the iOS edge-swipe pop pageless routes (e.g. `OpenContainer`, raw `Navigator.push`) through the Navigator instead of removing the underlying page from the router delegate's history, which previously tore down two screens at once (getx#3436)
- **Pops through the router delegate play the pop animation** - when a pop surfaces to a navigator as a page replacement (the norm inside `GetRouterOutlet`), the new pop-aware `GetTransitionDelegate` (default for the root and outlet navigators; a user-supplied `transitionDelegate` still wins) animates the leaving route in reverse on top of the revealed page; a `PopMode.page` pop of the only history entry now replaces it with the parent branch instead of pushing the parent on top of the leaf (getx#1883)

### Navigation & Routing

- **Fixed `preventDuplicates` being ignored in Navigator 2.0** - `GetPage.copyWith` no longer drops `preventDuplicateHandlingMode`, `preventDuplicates: false` on `Get.to`/`Get.toNamed`/`GetPage` pushes duplicates again, and `popUntilOriginalRoute` pops back to (not past) the original route (getx#3261, getx#3251, getx#2975, getx#3054)
- **`Get.arguments`/`Get.parameters` are scoped to the building page** - pages pushed in the same action no longer see each other's arguments (getx#2286)
- **Fixed `Get.to` with different closures returning the same widget type** - navigation no longer silently re-shows the old page (getx#2161)
- **Fixed tear-off route names** - `Get.to(MyPage.new)` no longer generates names polluted with the parameter list (getx#2245)
- **`initialRoute` is honored when a `/` page is registered** - the app starts on `initialRoute` and `/` stays reachable (getx#3196)
- **A stopped initial route no longer leaves a blank screen** - the delegate falls back to the not-found page when middleware nullifies the first navigation or a deep link (getx#2949)
- **Fixed `unknownRoute` never being shown when a root `/` page is registered** - `ParseRouteTree.matchRoute` no longer treats a partial ancestor match as a full match (getx#3352)
- **Fixed null-check crash in `PageRedirect.getPageToRoute`** - navigating to an unmatched route with no `unknownRoute` configured degrades gracefully to the delegate's not-found page (getx#3367)
- **Fixed `offAllNamed` to the surviving bottom route keeping stale content** - the page is rebuilt and its bindings/controllers recreated (getx#2899)
- **Fixed routing-state corruption** - `GetObserver.didPop` no longer sets `Routing.previous` equal to `Routing.current` (which also broke the `preventDuplicates` check in `Get.off`), dismissing stacked dialogs/sheets no longer leaves synthetic `DIALOG/BOTTOMSHEET <hash>` names in `Get.currentRoute`/`Get.previousRoute`, and `Get.rawRoute` no longer becomes null after `Get.offAllNamed` (getx#3394, getx#2597, getx#2334, getx#1237)
- **Fixed `Get.key` throwing "GetRoot is not part of the tree" before the app mounts** - `GetMaterialApp(navigatorKey: Get.key)` works (getx#3323)
- **Fixed theme changes being ignored when `GetMaterialApp` is rebuilt by a parent** - `GetRootState` reconciles updated `ConfigData` (theme, darkTheme, themeMode, locale, ...) in `didUpdateWidget`, so wrapping `GetMaterialApp` in `Obx` works (getx#3371)
- **`GetMaterialApp` renders its initial route on the first pump in widget tests** - no extra `pumpAndSettle` needed (getx#3244)
- **`shortcuts` parameter type matches `MaterialApp`** - now `Map<ShortcutActivator, Intent>?`, accepting `SingleActivator`/`CharacterActivator` (getx#2615)
- **Added `restorationScopeId` to `GetMaterialApp`/`GetCupertinoApp`** - including the `.router` constructors, enabling app-level state restoration (getx#2144)
- **Descriptive `GetPage` name assert** - states the offending name and the leading-slash requirement (getx#2564)

### Flutter Web

- **Replace-style navigations are reported as history replacements** - `Get.off`/`Get.offAll`/`Get.offAllNamed` use the new default `GetRouteInformationProvider`, and browser back/forward to a route already on the stack pops back to it instead of resurrecting removed pages; duplicate same-name entries and same-frame replace-then-push sequences are reported correctly (getx#3372)
- **Fixed the initial URL report pushing an extra history entry** - which activated the browser back button on a plain page load (getx#3266)
- **The URL strategy is applied once per process** - no more "Cannot set URL strategy a second time" crashes (getx#3224)

### Middleware

- **v4-style `GetMiddleware.redirect()` is honored again** - in all named navigation, with forwarded arguments; replace-style navigations (`off`/`offAll`/`offAllNamed`) run middleware, so `redirectDelegate` returning null stops them too (getx#2779, getx#2713, getx#2579, getx#2231)
- **Middlewares run in `priority` order and stop at the first redirect** (getx#1298)
- **`Get.parameters` reflects the in-flight route while middlewares run** - including parameters added by a redirect, hardened against overlapping navigations; redirect cycles settle on the not-found page instead of hanging navigation (getx#3139)
- **`onPageCalled` returning null cancels the page gracefully** - instead of a null-check crash (getx#2909)
- **Middleware redirects can forward navigation arguments** - `RouteDecoder.fromRoute` accepts an optional `arguments` parameter so `redirectDelegate` targets can access the original `Get.arguments` (getx#3408)
- **`GetRouterOutlet.initialRoute` runs the middleware pipeline** - synchronous results are honored during build, and asynchronous `redirectDelegate` results are resolved post-frame with change detection so stable decisions cannot rebuild in a loop (getx#1978)

### Nested Navigation & GetRouterOutlet

- **iOS swipe-back works between sibling routes inside `GetRouterOutlet`** - outlets stack the sibling pages of every history entry sharing their anchor (previous siblings stay mounted, retaining state), and imperative pops on the outlet navigator (back-swipe gesture, `Navigator.pop`, AppBar back) are reflected into the navigation history (getx#2107)
- **Nested shells stay mounted when unrelated root routes sit on top** - `participatesInRootNavigator` shells (with their navigators and controllers) survive sibling navigation, and pops restore the previously selected nested child (getx#3336, getx#2011)
- **Doubly nested `GetRouterOutlet`s work** - deeper outlets' pages no longer leak into the outer navigator, and outlets no longer fail the Navigator pages-API assertion (getx#3347, getx#2638)
- **Pages marked `participatesInRootNavigator` are no longer mounted twice** (getx#3111)
- **Fixed "Multiple widgets used the same GlobalKey" outlet crashes** - anchorless outlets no longer reuse the root navigator's key, and with duplicate same-anchor outlets the shared nested-delegate key attaches only to the most recently mounted one (getx#2742)
- **Hero animations fly exactly once** - removed `GetNavigator`'s duplicate `HeroController` (the framework scope owns it), gave nested outlets their own persistent `HeroControllerScope`, and back-gesture detectors disposed mid-drag no longer leave the navigator stuck in `userGestureInProgress` (getx#3350, getx#2931)
- **Deep links no longer take ownership of ancestor pages' controllers** - dependencies registered by bindings inherited from ancestor pages are linked to the declaring ancestor's route, so leaving a deep-linked leaf no longer disposes controllers the still-visible parent view depends on (getx#2183)

### Transitions & Gestures

- **Fixed frozen previous-page animation during route transitions** - `GetPageRouteTransitionMixin.canTransitionTo` accepts `MaterialRouteTransitionMixin` routes (mirroring Flutter's own implementation), so the outgoing page animates when a plain `MaterialPageRoute` is pushed over a `GetPageRoute` (getx#3452)
- **`Transition.native` honors the theme's `pageTransitionsTheme`** - e.g. `PredictiveBackPageTransitionsBuilder` (getx#2340)
- **`Get.defaultTransition` is no longer force-initialized from the fallback theme** - routes without an explicit transition follow the app theme on all platforms (getx#3274)
- **`gestureWidth` takes effect** - when set, the back-swipe only starts within that width from the leading edge (getx#3373)
- **Back-swipe direction fixed for `Transition.leftToRight`/`leftToRightWithFade`** - the page follows the finger toward the edge it entered from (getx#2193)
- **`Transition.downToUp` no longer reveals a black background** - the outgoing page stays in place, modal-style (getx#1560)
- **`Transition.circularReveal` radius is computed from the screen size** - fixing clipped corners on large screens such as iPad Pro 12.9 (getx#3130)
- **Added `Transition.predictiveBack`** - per-route Android predictive back without configuring `pageTransitionsTheme` (getx#3109)
- **Added `customTransition` to `Get.to`/`Get.off`/`Get.offAll`** - imperative navigation can use `CustomTransition` animations, previously only available via `GetPage` (getx#2475)
- **Added `GetPage.allowSnapshotting`** - disable route-transition snapshotting per page (getx#3282)
- **`transitionDuration` on `GetMaterialApp`/`GetCupertinoApp` is honored** - previously dead config (getx#2503)

### Dialogs, Bottom Sheets & Snackbars

- **Fixed `Get.close()` dropping its `result` and `id` arguments** - awaited `Get.bottomSheet`/`Get.dialog` futures complete with the provided result (getx#3319, getx#3387)
- **`Get.close`, `Get.closeDialog` and `Get.closeBottomSheet` close native overlays** - dialogs and sheets opened with Flutter's own `showDialog`/`showModalBottomSheet` are recognized by inspecting the navigator's top route (getx#3342)
- **Fixed `Get.closeOverlay()` popping page routes like `Get.back()`** - it closes the actual overlay when called right after an awaited navigation, and the router history no longer removes the wrong route (getx#3316)
- **Overlay status getters no longer throw before routing is initialized** - `Get.isOverlaysOpen`, `Get.isDialogOpen`, `Get.isBottomSheetOpen` and `Get.isSnackbarOpen` return `false`/`null` instead of throwing (getx#3370)
- **Overlays own their arguments and dependencies correctly** - `Get.arguments` returns the overlay's arguments while it is topmost (getx#2122), `Get.bottomSheet` gains `arguments`/`name` (getx#2005), and controllers `Get.put` while an overlay is open belong to the page beneath and survive the overlay's dismissal (getx#1969)
- **`Get.defaultDialog` renders its custom action** - `custom`, `textCustom` and `onCustom` were previously silently ignored (getx#1716, getx#3042, getx#1381)
- **Added `scrollable` and `canPop` parameters to `Get.defaultDialog`** - forward `AlertDialog.scrollable` for tall content, and block back-gesture dismissal (getx#3330, getx#3184)
- **Added `transitionBuilder` to `Get.dialog`** - custom dialog animations without dropping to `Get.generalDialog` (getx#3127)
- **`Get.showOverlay` always cleans up on error** - including non-`Exception` throws like Strings and Errors (getx#2827)
- **`Get.bottomSheet` works inside `GetCupertinoApp`** - falls back to `DefaultMaterialLocalizations` when no material delegates are installed (getx#2337)
- **Made `SnackbarController.close()` idempotent** - closing an already-dismissed snackbar no longer asserts, and `close(withAnimations: false)` cancels the pending duration timer (getx#3343)
- **Snackbar queue robustness** - closing a still-queued snackbar no longer crashes (getx#2761) or mounts broken overlay state later (getx#2257); `closeCurrentSnackbar`/`cancelAllSnackbars` (and the `Get.` wrappers) gain `withAnimations` (getx#2400)
- **Snackbar hit-testing and rendering** - the margin and the space beside width-constrained snackbars pass pointer events through while the bar stays tappable and swipe-dismissible (getx#3012, getx#2995), RTL icon paddings mirror correctly (getx#3069), and the left bar indicator respects `borderRadius` (getx#2747)

### Dependency Injection & Lifecycle

- **Fixed deferred route disposal destroying freshly created controllers** - when a route is popped and the same controller is re-registered before the old route finishes disposing (rapid back-and-forth navigation, re-push during exit transition, or `Get.offAllNamed` to a route reusing the same controller type), only the superseded instance is disposed and the live controller stays registered; superseded `GetxService`s in the pending chain are disposed instead of blocking deletion forever (getx#3446, getx#3315, getx#3351)
- **Fixed stale dirty flag on `fenix` registrations** - a `fenix` factory retained after deletion is no longer perpetually treated as stale, fixing missed `onClose` calls on resurrected controllers (getx#3292)
- **Fixed controllers being linked to the wrong route** - when multiple pages are pushed within the same frame, each route's bindings and lazily-created controllers link to their own route, so popping the top route no longer disposes them all (getx#3280)
- **Route disposal no longer deletes controllers a still-visible view depends on** - deletion of a route-linked instance that still has widget subscribers is deferred to end-of-frame; subscribers remaining after the disposed route's subtree unmounted keep the instance alive (getx#2404)
- **Controllers created inside native `showModalBottomSheet`/`showDialog` builders no longer leak** - they are released when the overlay is dismissed (getx#2439)
- **Restored `Get.putAsync` and added `Bind.putAsync`** - asynchronously-constructed dependencies register through `put()` with the full lifecycle (getx#3239)
- **`Get.replace`/`Get.lazyReplace` (and the `Bind` variants) really replace** - fenix registrations, `GetxService`s and pending disposal chains no longer resurrect the old builder (getx#2268)
- **Nullable generic registrations share the non-nullable registry key** - `Get.put<App?>(...)` is visible to `Get.find<App>()` (getx#2657)
- **`Get.reloadAll()` no longer throws `ConcurrentModificationError`** - when an instance's `onClose` mutates the registry

### State Management

- **`GetBuilder(global: false)` controllers receive `onClose` on unmount** - unless `autoRemove: false` (getx#2123)
- **Controllers survive tree-shape swaps** - a `LayoutBuilder` breakpoint change no longer deletes the controller the visible page is using; disposal defers to the last live subscriber (getx#2393)
- **`GetBuilder`/`Bind` rebinds when its `tag` changes on rebuild** - disposing an autoRemove controller created under the old tag instead of silently keeping the stale controller (getx#2232)
- **`GetBuilder`/`Bind` `initState` callbacks can access `state.controller`** - the callback runs after the controller is available (getx#2354)
- **Descriptive `BindError` on (type, tag) mismatch** - names the type and tag and how to fix it, instead of an opaque null-check crash (getx#2573)
- **Ticker providers follow `TickerMode`** - `GetSingleTickerProviderStateMixin`/`GetTickerProviderStateMixin` tickers are muted when the route is covered, unified behind a shared `GetTickerProvider` interface (getx#2426)

### Reactive Types

- **Fixed default-constructed `RxList`/`RxSet`/`RxMap` being unusable** - the default constructors previously backed the collection with an immutable `Never`-typed const literal, so the first `add()`/`[]=` threw a `TypeError`; they now create properly typed growable collections (getx#3411)
- **`assign`/`assignAll` no longer require a growable backing collection** - collections created from fixed-length or unmodifiable sources (e.g. `List.empty().obs`, `const [].obs`, `Set.unmodifiable(...).obs`) previously crashed with "Cannot clear a fixed-length list"; the backing is replaced with a fresh mutable copy preserving its runtime element type, and the collection is fully mutable afterwards
- **`assign`/`assignAll` notify exactly once** - `RxSet` and `RxMap` no longer emit an intermediate empty event or a redundant second notification (getx#2250)
- **`bindStream` no longer leaks subscriptions** - it returns its `StreamSubscription`, supports `cancelPrevious: true`, and cancels all bindings when the Rx closes (getx#3000)

### Internationalization & Platform

- **Fixed translation lookup ignoring `Locale.scriptCode`** - `tr` resolves keys in specificity order (`lang_script_country` > `lang_script` > `lang_country` > `lang` > similar-language) for both `Get.locale` and `Get.fallbackLocale`, so `Locale('zh', scriptCode: 'Hant')` no longer resolves to `zh_CN` (getx#3380)
- **Fixed device-locale changes overriding an explicitly set app locale** - the device locale is only followed when the app never set one via `GetMaterialApp(locale:)` or `Get.updateLocale`, which now records explicit intent (getx#3357)
- **CLDR plural-category support** - new `PluralCase` enum, pluggable `Get.pluralResolver`, and `trPluralCases`/`trPluralCasesParams` let apps supply correct plural forms for languages like Arabic and Russian; `trPlural`/`trPluralParams` behavior is unchanged (getx#1855)
- **Documented `trParams` placeholder ordering for RTL translations** - with regression tests (getx#3073)
- **`GetPlatform.isMacOS` works on Firefox for macOS** - and iPad/iPod `navigator.platform` values are detected correctly (getx#1936)

### Animations

- **`BlurAnimation` blurs its child, not the backdrop** - and `GetAnimatedBuilder` honors updated `duration`/`tween`/`curve` on rebuild, owning and disposing its `CurvedAnimation` across updates and unmount (getx#3233)
- **Added `autoPlayOnUpdate` to `GetAnimatedBuilder` and all animation extensions** - when enabled, the animation replays from the beginning whenever the widget is rebuilt with a different tween, enabling declarative replays driven by Obx state (getx#2760)

### Internal Improvements

- **Renamed `rx_ticket_provider_mixin.dart` to `rx_ticker_provider_mixin.dart`** - fixing the long-standing file name typo (getx#2801)
- **Refactors** - the bottom-sheet `MaterialLocalizations` fallback moved into `GetModalBottomSheetRoute.buildPage` (also fixing direct route users under Cupertino apps); overlay close loops resolve the navigator's top route once per iteration and `Get.close()` evaluates its predicates lazily; centralized routing-initialization guards; removed dead code

---

## 3.0.0

### Code Quality Improvements

- **Restructured navigation routes** - Reorganized the flat `lib/get_navigation/src/routes/` directory into three structured subdirectories (`transitions/`, `router/`, and `core/`) to improve codebase organization and readability.

- **Refactored naming conventions** - Renamed the legacy truncated private map `_singl` to `_singletons` and the `Inst` extension to `GetInstanceExt` in `extension_instance.dart`. Renamed the `RxTnew` extension to `RxTNew` in `rx_impl.dart` to adhere to Dart's UpperCamelCase style guidelines.

- **Fixed parameter naming in RxList** - Corrected parameter names in `fillRange` and `replaceRange` methods to match the overridden method signatures from Dart's List interface (changed `fillValue` to `fill` and `replacement` to `newContents`)

- **Enhanced RxSet factory constructors** - Added missing factory constructors (`from`, `of`, `unmodifiable`, `identity`) to match Dart's Set API and provide complete factory constructor coverage

- **Enhanced RxMap factory constructors** - Added missing factory constructors (`fromIterable`, `fromIterables`, `fromEntries`) to match Dart's Map API and provide complete factory constructor coverage

- **Fixed null safety in RxnString** - Removed `Comparable<String>` and `Pattern` interfaces from `RxnString` class as they don't make sense for nullable String types and were using forced null unwrap which could cause runtime exceptions

- **Maintained backward compatibility** - Kept both `.obs` extension methods (getter-style and method-style) to ensure compatibility with existing code while supporting Dart 3 features

- **Cleaned up navigation extensions** - Removed unrelated UI, layout, and media query properties (such as `pixelRatio`, `width`, `height`, `statusBarHeight`, `bottomBarHeight`, `textScaleFactor`, `textTheme`, `mediaQuery`, `isDarkMode`, `isPlatformDarkMode`, `iconColor`, `focusScope`) from `extension_navigation.dart` to keep the navigation module focused solely on routing and state features.

### Bug Fixes

- **Fixed parameter name mismatch warnings** - Resolved analyzer warnings about parameter names not matching overridden method signatures in RxList

- **Fixed overlay closure logic** - Fixed a logical bug in `closeAllDialogsAndBottomSheets` where it incorrectly required _both_ a dialog and a bottom sheet to be open simultaneously to close them (changed the condition check from `&&` to `||`).

---

## 2.0.2

### Refactoring & Code Quality

- **Cleaned up `get_rx` bloat** - Removed over 1,000 lines of redundant, unrelated proxy helper methods from `RxNum`, `RxInt`, `RxDouble`, and `RxString` extensions, aligning the reactive wrappers with the core project scope. Core basic mathematical, relational, and bitwise operators were retained.
- **Enhanced Documentation** - Added comprehensive Dart documentation comments and examples to public classes, extensions, methods, and callbacks across `get_instance`, `get_core`, `get_animations`, `get_common`, and `get_rx` modules.
- **Removed comment/code boilerplate** - Cleaned up commented-out methods, legacy variables, and dead code references across the entire codebase.

### Performance Optimizations

- **Optimized `RxList`, `RxMap`, and `RxSet`** - Overrode batch-mutating collection methods (such as `clear()`, `removeAt()`, `addAll()`, `removeWhere()`, etc.) to directly mutate the underlying standard Dart collections and trigger exactly one reactive refresh notification. This prevents multiple redundant widget rebuild cycles.

### Bug Fixes

- **Corrected doc comment typos** - Fixed possessive "it's" typos, brackets in generics `[find]<[S]>()`, and incorrect method references (`Get.[create]`) in documentation.

---

## 2.0.1

### Bug Fixes

- **Fixed RxnDouble subtraction operator** - The subtraction operator in `RxnDoubleExt` was incorrectly using addition instead of subtraction, now properly subtracts the given value.
- **Fixed ListExtension assign methods** - Added `clear()` call for non-RxList cases in both `assign()` and `assignAll()` methods to ensure proper list clearing before adding new items.
- **Fixed null safety in navigation extensions** - Replaced unsafe null assertion operators (`!`) with null-aware operators (`?? false`) for `isDialogOpen` and `isBottomSheetOpen` checks in `extension_navigation.dart` to prevent null pointer exceptions.
- **Fixed GetPage copyWith restorationId** - Fixed bug where `restorationId` parameter was being compared with itself instead of `this.restorationId` in the `copyWith` method.
- **Fixed ColorAnimation color filter** - Simplified ColorAnimation to use the animated value directly instead of incorrectly interpolating with Color.lerp, which was causing incorrect color filtering behavior.
- **Fixed dependency deletion logic** - Improved dependency cleanup in `extension_instance.dart` with recursive factory cleanup for `lateRemove` dependencies and proper fenix mode handling.
- **Fixed isDesktop context extension** - Fixed `isDesktop` getter to correctly reference `isDesktopOrWider` instead of `isDesktopOrLess`, ensuring proper desktop breakpoint detection.

---

## 2.0.0

### Breaking Changes

- **Removed GetUtils class** - The `GetUtils` class with 722 lines of validation and string manipulation methods has been removed. This includes:
  - Validation methods: `isEmail`, `isURL`, `isPhoneNumber`, `isDateTime`, `isMD5`, `isSHA1`, `isSHA256`, `isSSN`, `isBinary`, `isIPv4`, `isIPv6`, `isHexadecimal`, `isPalindrome`, `isUsername`, `isCurrency`, `isPassport`, Brazilian `isCpf`/`isCnpj`
  - File type checks: `isVideo`, `isImage`, `isAudio`, `isPPT`, `isWord`, `isExcel`, `isAPK`, `isPDF`, `isTxt`, `isChm`, `isVector`, `isHTML`
  - String manipulation: `capitalize`, `capitalizeFirst`, `removeAllWhitespace`, `camelCase`, `snakeCase`, `paramCase`, `numericOnly`, `capitalizeAllWordsFirstLetter`
  - Length validation methods
  - Basic type checks: `isNull`, `isNullOrBlank`, `isBlank`, `isNum`, `isNumericOnly`, `isAlphabetOnly`, `hasCapitalLetter`, `isBool`

- **Removed string extensions** - All string extensions that wrapped GetUtils methods have been removed:
  - `isNum`, `isNumericOnly`, `isAlphabetOnly`, `isBool`
  - `isVectorFileName`, `isImageFileName`, `isAudioFileName`, `isVideoFileName`, `isTxtFileName`, `isDocumentFileName`, `isExcelFileName`, `isPPTFileName`, `isAPKFileName`, `isPDFFileName`, `isHTMLFileName`
  - `isURL`, `isEmail`, `isPhoneNumber`, `isDateTime`
  - `capitalize`, `capitalizeFirst`, `removeAllWhitespace`, `camelCase`, `paramCase`, `numericOnly`, `capitalizeAllWordsFirstLetter`

- **Removed unused extensions** - The following extension modules have been removed:
  - `double_extensions.dart`
  - `duration_extensions.dart`
  - `dynamic_extensions.dart`
  - `int_extensions.dart`
  - `num_extensions.dart`
  - `widget_extensions.dart`

- **Removed GetMicrotask class** - The `GetMicrotask` class has been removed as it was not used anywhere in the codebase.

- **Removed OptimizedListView widget** - The `OptimizedListView` widget has been removed as it was not used anywhere in the codebase.

### Migration Guide

If you were using any of the removed utilities, you should migrate to dedicated packages:

- **Validation**: Use the [`validator`](https://pub.dev/packages/validator) package or similar
- **String manipulation**: Use the [`recase`](https://pub.dev/packages/recase) package for case conversion
- **File operations**: Use the [`path`](https://pub.dev/packages/path) package
- **Equality**: Use the [`equatable`](https://pub.dev/packages/equatable) package if you need value-based equality in your own code

### Bug Fixes

- **Fixed controller disposal during rapid navigation** - Controllers are now properly disposed when quickly navigating back and forth using keyboard shortcuts or programmatic navigation. Added `reportRouteWillDispose` call in the `didPop` method of `GetObserver` to ensure dependencies are cleaned up correctly.
- **Fixed secondary animation issue** - Outgoing pages now animate correctly when using `Navigator.push` with `GetMaterialApp` or `GetCupertinoApp`. The apps now use regular `MaterialApp`/`CupertinoApp` when `getPages` is null and no router config is provided, allowing proper secondary animations for imperative navigation.
- **Fixed null routerDelegate handling** - `GetRoot` now properly handles cases where `routerDelegate` is null, preventing runtime errors when accessing navigation keys in non-router scenarios.

### Improvements

- **Reduced bundle size** - Removed ~1000+ lines of unnecessary utility code
- **Focused scope** - GetXify now focuses on its core purpose: state management, navigation, and dependency injection
- **Better separation of concerns** - General-purpose utilities should use dedicated packages, not a framework

### Kept Functionality

The following essential utilities remain:

- `Equality` mixin - Needed by `StateMixin` for value-based equality comparison
- `GetPlatform` - Platform detection (used in 3 places in core framework)
- `GetQueue` - Queue management (used by snackbar system)
- `IterableExtensions` - `mapMany`, `firstWhereOrNull` (used by router)
- `ContextExtensions` - `theme`, `mediaQuery`, `height`, `width` (used by responsive design and navigation)
- `InternationalizationExtensions` - `.tr` extension for translations
- `EventLoopExtensions` - `asap`, `toEnd` methods (used by core framework)
- `printInfo` method - Added to `GetInterface` for logging

### Testing

- All 144 tests passing

## 1.0.2

### Code Quality Improvements

- **Enhanced documentation** - Added comprehensive doc comments to get_state_manager module (list_notifier, rx_notifier, get_responsive, rx_getx_widget, mixin_builder, simple_builder)
- **Code cleanup** - Removed dead/commented code across get_state_manager files
- **Modernized patterns** - Updated constructor patterns to use `super.key` in doc examples
- **Removed outdated lint ignores** - Cleaned up unnecessary lint suppression comments
- **Fixed field overrides** - Properly fixed field override issue in \_FactoryBind using super parameters

### Testing

- All 222 tests passing

---

## 1.0.1

### Code Quality Improvements

- **Internal codebase improvements** - Enhanced code structure and organization
- **Removed dead code** - Cleaned up commented-out and unused code across multiple modules
- **Added safety checks** - Improved widget lifecycle checks to prevent errors
- **Enhanced API documentation** - Added comprehensive documentation comments for better developer experience

### Feature Updates

- **BottomSheet** - Added new parameters to align with latest Flutter API
- **Snackbar** - Added new parameters to align with latest Flutter API
- **Router configuration** - Improved initialization logic for better compatibility

### Testing

- **Expanded test coverage** - Added more tests to ensure stability
- All 222 tests passing

---

## 1.0.0

### Initial Release - GetXify

GetXify is an improved and enhanced version of GetX, compatible with the latest Dart and Flutter versions.

### Breaking Changes

- **Removed GetConnect module** - HTTP/WebSocket communication module has been removed
- **Removed mini stream** - Stream-related utilities have been removed
- **Removed all deprecated methods** - Cleaned up all deprecated APIs from the original GetX

### Improvements

- Updated to support Dart SDK ^3.12.2
- Updated to support Flutter >=3.44.2
- Code cleanup and modernization
- Removed legacy dependencies and unused code
- Improved performance and stability

### Migration from GetX

If you were using GetX and want to migrate to GetXify:

- Replace `import 'package:get/get.dart';` with `import 'package:getxify/getxify.dart';`
- Replace `get` dependency with `getxify` in pubspec.yaml
- If you were using GetConnect, you'll need to implement your own HTTP client using dio or http package
- If you were using mini stream utilities, migrate to standard Dart streams or RxDart
- All deprecated methods have been removed, so update your code to use the current APIs

### Features

GetXify maintains all the core features of GetX:

- State Management (Reactive and Simple)
- Route Management (Navigation without context)
- Dependency Management (Dependency injection)
- Internationalization (i18n)
- Theme Management
- Utils and Helpers
