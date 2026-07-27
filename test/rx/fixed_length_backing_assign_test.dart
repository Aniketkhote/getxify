// modifiable backing collection, because their contract is to REPLACE the
// contents. Real-world trigger: `RxList<T> x = List<T>.empty().obs;` —
// List.empty() is fixed-length, and assignAll used to call clear() on it,
// throwing "Unsupported operation: Cannot clear a fixed-length list".
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/get_rx/get_rx.dart';

void main() {
  group('RxList with non-growable backing', () {
    test('assignAll replaces a fixed-length backing (List.empty)', () async {
      final RxList<int> list = List<int>.empty().obs;
      var notifications = 0;
      list.listen((_) => notifications++);

      list.assignAll([1, 2, 3]);
      await Future.delayed(Duration.zero);

      expect(list, [1, 2, 3]);
      expect(notifications, 1);
    });

    test('assignAll replaces a fixed-length backing (List.filled)', () {
      final RxList<int> list = List<int>.filled(3, 0).obs;

      list.assignAll([7, 8]);

      expect(list, [7, 8]);
    });

    test('assignAll replaces an unmodifiable backing (const [])', () {
      final RxList<int> list = RxList<int>(const []);

      list.assignAll([4, 5]);

      expect(list, [4, 5]);
    });

    test('assign replaces a fixed-length backing', () {
      final RxList<String> list = List<String>.empty().obs;

      list.assign('only');

      expect(list, ['only']);
    });

    test('the list is mutable after assignAll over a fixed backing', () {
      final RxList<int> list = List<int>.empty().obs;

      list.assignAll([1]);
      list.add(2);
      list.removeAt(0);

      expect(list, [2]);
    });

    test('assignAll keeps the runtime element type of the backing', () {
      final RxList<num> list = RxList<num>(List<int>.empty());

      // The replacement copy is built from the backing list, so it stays a
      // List<int> and rejects incompatible elements exactly like before.
      list.assignAll(<int>[1, 2]);
      expect(list, [1, 2]);
      expect(() => list.add(0.5), throwsA(isA<TypeError>()));
    });
  });

  group('RxSet with unmodifiable backing', () {
    test('assignAll replaces an unmodifiable backing', () async {
      final RxSet<int> set = Set<int>.unmodifiable({1, 2}).obs;
      var notifications = 0;
      set.listen((_) => notifications++);

      set.assignAll({3, 4});
      await Future.delayed(Duration.zero);

      expect(set, {3, 4});
      expect(notifications, 1);
    });

    test('assign replaces an unmodifiable backing (variant 1)', () {
      final RxSet<int> set = Set<int>.unmodifiable({1}).obs;

      set.assign(9);

      expect(set, {9});
    });
  });

  group('RxMap with unmodifiable backing', () {
    test('assign replaces an unmodifiable backing', () {
      final RxMap<String, int> map = Map<String, int>.unmodifiable({
        'a': 1,
      }).obs;

      map.assign('b', 2);

      expect(map, {'b': 2});
    });

    test('assignAll notifies exactly once', () async {
      final RxMap<String, int> map = <String, int>{'a': 1}.obs;
      var notifications = 0;
      map.listen((_) => notifications++);

      map.assignAll({'b': 2, 'c': 3});
      await Future.delayed(Duration.zero);

      expect(map, {'b': 2, 'c': 3});
      expect(notifications, 1);
    });
  });
}
