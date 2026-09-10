import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_count_app/core/fake_backend/fake_backend.dart';

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend()..latency = Duration.zero;
  });

  group('FakeBackend.submitCount', () {
    test('accepts a submission when no product version has moved', () async {
      final result = await backend.submitCount(
        idempotencyKey: 'key-accept',
        storeId: 1,
        items: [
          {'productId': 101, 'countedQuantity': 20, 'expectedVersion': 5},
        ],
      );

      expect(result['status'], 'accepted');
      expect(result['sessionId'], isA<int>());
    });

    test(
      'replaying the same idempotency key returns the cached result '
      'instead of creating a second server session (duplicate-submission '
      'prevention)',
      () async {
        final payload = [
          {'productId': 101, 'countedQuantity': 18, 'expectedVersion': 5},
        ];

        final first = await backend.submitCount(
          idempotencyKey: 'key-retry',
          storeId: 1,
          items: payload,
        );
        final second = await backend.submitCount(
          idempotencyKey: 'key-retry',
          storeId: 1,
          items: payload,
        );

        expect(second, equals(first));
        expect(second['sessionId'], first['sessionId']);
      },
    );

    test('two different idempotency keys get two different server sessions', () async {
      final payload = [
        {'productId': 101, 'countedQuantity': 20, 'expectedVersion': 5},
      ];

      final first = await backend.submitCount(
        idempotencyKey: 'key-a',
        storeId: 1,
        items: payload,
      );
      final second = await backend.submitCount(
        idempotencyKey: 'key-b',
        storeId: 1,
        items: payload,
      );

      expect(second['sessionId'], isNot(first['sessionId']));
    });

    test(
      'detects a version conflict reproducing the assessment\'s documented '
      'example (client saw v5/qty20, a sale moves it to v6/qty19)',
      () async {
        backend.simulateConcurrentSale(
          storeId: 1,
          productId: 101,
          quantityDelta: -1,
        );

        final result = await backend.submitCount(
          idempotencyKey: 'key-conflict',
          storeId: 1,
          items: [
            {'productId': 101, 'countedQuantity': 18, 'expectedVersion': 5},
          ],
        );

        expect(result['status'], 'conflict');
        final conflicts = result['conflicts'] as List<dynamic>;
        expect(conflicts, hasLength(1));

        final conflict = conflicts.single as Map<String, dynamic>;
        expect(conflict['productId'], 101);
        expect(conflict['expectedVersion'], 5);
        expect(conflict['currentVersion'], 6);
        expect(conflict['originalSystemQuantity'], 20);
        expect(conflict['currentSystemQuantity'], 19);
        expect(conflict['countedQuantity'], 18);
      },
    );

    test('does not flag a conflict when expectedVersion matches current', () async {
      backend.simulateConcurrentSale(storeId: 1, productId: 101);
      // Re-download would give the client version 6 now.
      final result = await backend.submitCount(
        idempotencyKey: 'key-fresh',
        storeId: 1,
        items: [
          {'productId': 101, 'countedQuantity': 19, 'expectedVersion': 6},
        ],
      );

      expect(result['status'], 'accepted');
    });
  });
}
