import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/configuration/bielik_models.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/device_resources.dart';
import 'package:bielik_oneclick_launcher/src/domain/repositories/device_resources_repository.dart';
import 'package:bielik_oneclick_launcher/src/domain/services/model_memory_guard.dart';

class _Resources implements DeviceResourcesRepository {
  int? availableBytes;

  @override
  Future<DeviceResources> read() async =>
      DeviceResources(availableRamBytes: availableBytes);
}

void main() {
  test(
    'Rejects loading when available RAM is below the model requirement',
    () async {
      final resources = _Resources()..availableBytes = 6000000000;
      final guard = ModelMemoryGuard(resources, bielikModels);

      await expectLater(
        guard.check(bielikModels.last.file!),
        throwsA(
          isA<InsufficientModelMemory>()
              .having((error) => error.requiredGb, 'required RAM', 8)
              .having((error) => error.availableGb, 'available RAM', 6),
        ),
      );
    },
  );

  test('Allows loading at the required RAM threshold', () async {
    final resources = _Resources()..availableBytes = 8000000000;
    final guard = ModelMemoryGuard(resources, bielikModels);

    await expectLater(guard.check(bielikModels.last.file!), completes);
  });

  test('Allows loading when the RAM reading is unavailable', () async {
    final guard = ModelMemoryGuard(_Resources(), bielikModels);

    await expectLater(guard.check(bielikModels.last.file!), completes);
  });

  test('Reads current RAM again before each load attempt', () async {
    final resources = _Resources()..availableBytes = 8000000000;
    final guard = ModelMemoryGuard(resources, bielikModels);
    await guard.check(bielikModels.last.file!);
    resources.availableBytes = 1000000000;

    await expectLater(
      guard.check(bielikModels.last.file!),
      throwsA(isA<InsufficientModelMemory>()),
    );
  });
}
