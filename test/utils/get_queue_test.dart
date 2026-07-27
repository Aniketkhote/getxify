import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/get_utils/get_utils.dart';

void main() {
  group('GetQueue Tests', () {
    late GetQueue queue;

    setUp(() {
      queue = GetQueue();
    });

    test('Executes jobs sequentially in FIFO order', () async {
      final executionOrder = <int>[];

      final future1 = queue.add(() async {
        await Future.delayed(const Duration(milliseconds: 20));
        executionOrder.add(1);
        return 'first';
      });

      final future2 = queue.add(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        executionOrder.add(2);
        return 'second';
      });

      final future3 = queue.add(() {
        executionOrder.add(3);
        return 'third';
      });

      final results = await Future.wait([future1, future2, future3]);

      expect(results, equals(['first', 'second', 'third']));
      expect(executionOrder, equals([1, 2, 3]));
    });

    test(
      'Handles errors gracefully without breaking subsequent jobs',
      () async {
        final future1 = queue.add<int>(() async {
          throw Exception('Job 1 failed');
        });

        final future2 = queue.add<int>(() async {
          return 42;
        });

        expect(future1, throwsA(isA<Exception>()));
        expect(await future2, equals(42));
      },
    );

    test('cancelAllJobs cancels queued jobs', () async {
      final executionOrder = <int>[];

      // Active job running
      final future1 = queue.add(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        executionOrder.add(1);
        return 1;
      });

      // Queued jobs
      final future2 = queue.add(() async {
        executionOrder.add(2);
        return 2;
      });

      final future3 = queue.add(() async {
        executionOrder.add(3);
        return 3;
      });

      expect(queue.isJobInProgress, isTrue);

      final future2Expect = expectLater(future2, throwsA(equals('Canceled')));
      final future3Expect = expectLater(future3, throwsA(equals('Canceled')));

      // Cancel queued jobs
      queue.cancelAllJobs();

      expect(await future1, equals(1));
      await future2Expect;
      await future3Expect;

      expect(executionOrder, equals([1]));
    });
  });
}
