import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/get_utils/get_utils.dart';

class SampleModel with Equality {
  final int id;
  final String name;
  final List<int> tags;
  final Map<String, dynamic> metadata;

  SampleModel({
    required this.id,
    required this.name,
    required this.tags,
    required this.metadata,
  });

  @override
  List<Object?> get props => [id, name, tags, metadata];
}

void main() {
  group('Equality Mixin & DeepCollectionEquality Tests', () {
    test('Identical models return true and equal hash codes', () {
      final a = SampleModel(
        id: 1,
        name: 'Item',
        tags: [1, 2, 3],
        metadata: {'a': 1, 'b': 'two'},
      );
      final b = SampleModel(
        id: 1,
        name: 'Item',
        tags: [1, 2, 3],
        metadata: {'a': 1, 'b': 'two'},
      );

      expect(a == b, isTrue);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Models with different values return false', () {
      final a = SampleModel(
        id: 1,
        name: 'Item',
        tags: [1, 2, 3],
        metadata: {'a': 1},
      );
      final b = SampleModel(
        id: 1,
        name: 'Item',
        tags: [1, 2, 4], // different list item
        metadata: {'a': 1},
      );

      expect(a == b, isFalse);
    });

    test('MapEquality zero-allocation fast-path works correctly', () {
      const mapEq = MapEquality<String, dynamic>();

      final map1 = {'a': 100, 'b': 200, 'c': true};
      final map2 = {'a': 100, 'b': 200, 'c': true};
      final map3 = {'a': 100, 'b': 200, 'c': false};

      expect(mapEq.equals(map1, map2), isTrue);
      expect(mapEq.equals(map1, map3), isFalse);

      const deepMapEq = MapEquality<String, dynamic>(
        values: DeepCollectionEquality(),
      );
      final nested1 = {
        'a': 100,
        'b': [1, 2],
        'c': {'nested': true},
      };
      final nested2 = {
        'a': 100,
        'b': [1, 2],
        'c': {'nested': true},
      };
      final nested3 = {
        'a': 100,
        'b': [1, 2],
        'c': {'nested': false},
      };

      expect(deepMapEq.equals(nested1, nested2), isTrue);
      expect(deepMapEq.equals(nested1, nested3), isFalse);
    });

    test('DeepCollectionEquality identity fast-path works', () {
      const deepEq = DeepCollectionEquality();
      final list = [1, 2, 3];

      expect(deepEq.equals(list, list), isTrue);
      expect(deepEq.equals(null, null), isTrue);
    });

    test('SetEquality and UnorderedIterableEquality work', () {
      const setEq = SetEquality<int>();
      expect(setEq.equals({1, 2, 3}, {3, 2, 1}), isTrue);
      expect(setEq.equals({1, 2, 3}, {1, 2, 4}), isFalse);

      const unorderedEq = UnorderedIterableEquality<int>();
      expect(unorderedEq.equals([1, 2, 3], [3, 2, 1]), isTrue);
      expect(unorderedEq.equals([1, 2, 3], [1, 2]), isFalse);
    });
  });
}
