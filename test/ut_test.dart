import 'package:flutter_test/flutter_test.dart';

import 'package:bielik_oneclick_launcher/configuration/ut/test_llm_configuration.dart'
    as suite0;
import 'package:bielik_oneclick_launcher/src/data/datasources/ut/test_device_resources_datasource.dart'
    as suite1;
import 'package:bielik_oneclick_launcher/src/data/datasources/ut/test_gpu_inference_adapter.dart'
    as suite2;
import 'package:bielik_oneclick_launcher/src/data/datasources/ut/test_llm_runtime_adapter.dart'
    as suite3;
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/ut/test_compute_routing_llm_repository.dart'
    as suite4;
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/ut/test_configured_model_catalog_repository.dart'
    as suite5;
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/ut/test_local_device_resources_repository.dart'
    as suite6;
import 'package:bielik_oneclick_launcher/src/domain/models/ut/test_chat_message.dart'
    as suite7;
import 'package:bielik_oneclick_launcher/src/domain/models/ut/test_device_resources.dart'
    as suite8;
import 'package:bielik_oneclick_launcher/src/domain/models/ut/test_llm_configuration.dart'
    as suite9;
import 'package:bielik_oneclick_launcher/src/domain/models/ut/test_model_requirements.dart'
    as suite10;
import 'package:bielik_oneclick_launcher/src/domain/models/ut/test_resource_requirement.dart'
    as suite11;
import 'package:bielik_oneclick_launcher/src/domain/services/ut/test_chat_context_policy.dart'
    as suite12;
import 'package:bielik_oneclick_launcher/src/domain/services/ut/test_chat_service.dart'
    as suite13;
import 'package:bielik_oneclick_launcher/src/presentation/controllers/ut/test_device_resources_controller.dart'
    as suite14;
import 'package:bielik_oneclick_launcher/src/presentation/controllers/ut/test_llm_settings_draft.dart'
    as suite15;
import 'package:bielik_oneclick_launcher/src/presentation/controllers/ut/test_model_download_controller.dart'
    as suite16;
import 'package:bielik_oneclick_launcher/src/presentation/formatters/ut/test_storage_size_formatter.dart'
    as suite17;

void main() {
  group('configuration/llm_configuration.dart', suite0.main);
  group('src/data/datasources/device_resources_datasource.dart', suite1.main);
  group('src/data/datasources/gpu_inference_adapter.dart', suite2.main);
  group('src/data/datasources/llm_runtime_adapter.dart', suite3.main);
  group(
    'src/data/repositories_impl/compute_routing_llm_repository.dart',
    suite4.main,
  );
  group(
    'src/data/repositories_impl/configured_model_catalog_repository.dart',
    suite5.main,
  );
  group(
    'src/data/repositories_impl/local_device_resources_repository.dart',
    suite6.main,
  );
  group('src/domain/models/chat_message.dart', suite7.main);
  group('src/domain/models/device_resources.dart', suite8.main);
  group('src/domain/models/llm_configuration.dart', suite9.main);
  group('src/domain/models/model_requirements.dart', suite10.main);
  group('src/domain/models/resource_requirement.dart', suite11.main);
  group('src/domain/services/chat_context_policy.dart', suite12.main);
  group('src/domain/services/chat_service.dart', suite13.main);
  group(
    'src/presentation/controllers/device_resources_controller.dart',
    suite14.main,
  );
  group('src/presentation/controllers/llm_settings_draft.dart', suite15.main);
  group(
    'src/presentation/controllers/model_download_controller.dart',
    suite16.main,
  );
  group(
    'src/presentation/formatters/storage_size_formatter.dart',
    suite17.main,
  );
}
