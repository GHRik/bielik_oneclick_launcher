import 'package:flutter_test/flutter_test.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/ut/test_github_app_update_repository.dart'
    as app_updates;
import 'package:bielik_oneclick_launcher/src/domain/models/ut/test_chat_text_action.dart'
    as text_actions;
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/ut/test_android_app_exit_repository.dart'
    as app_exit;

import 'package:bielik_oneclick_launcher/src/domain/models/ut/test_context_usage.dart'
    as suite18;
import 'package:bielik_oneclick_launcher/src/data/datasources/ut/test_txt_attachment_decoder.dart'
    as txt_decoder;
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/ut/test_local_attachment_repository.dart'
    as attachments;
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/ut/test_platform_incoming_text_repository.dart'
    as incoming_text_suite;
import 'package:bielik_oneclick_launcher/src/presentation/controllers/ut/test_speech_dictation_controller.dart'
    as dictation;

import 'package:bielik_oneclick_launcher/src/data/repositories_impl/ut/test_platform_speech_recognition_repository.dart'
    as speech_adapter;
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/ut/test_system_clipboard_repository.dart'
    as clipboard;

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
import 'package:bielik_oneclick_launcher/src/domain/models/ut/test_conversation.dart'
    as conversation;
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
import 'package:bielik_oneclick_launcher/src/presentation/controllers/ut/test_conversation_controller.dart'
    as conversation_controller;
import 'package:bielik_oneclick_launcher/src/presentation/controllers/ut/test_device_resources_controller.dart'
    as suite14;
import 'package:bielik_oneclick_launcher/src/presentation/controllers/ut/test_llm_settings_draft.dart'
    as suite15;
import 'package:bielik_oneclick_launcher/src/presentation/controllers/ut/test_model_download_controller.dart'
    as suite16;
import 'package:bielik_oneclick_launcher/src/presentation/formatters/ut/test_storage_size_formatter.dart'
    as suite17;

void main() {
  group(
    'src/data/repositories_impl/github_app_update_repository.dart',
    app_updates.main,
  );
  group('src/domain/models/chat_text_action.dart', text_actions.main);
  group(
    'src/data/repositories_impl/android_app_exit_repository.dart',
    app_exit.main,
  );
  group('src/domain/models/context_usage.dart', suite18.main);
  group('src/data/datasources/txt_attachment_decoder.dart', txt_decoder.main);
  group(
    'src/data/repositories_impl/local_attachment_repository.dart',
    attachments.main,
  );
  group(
    'src/data/repositories_impl/platform_incoming_text_repository.dart',
    incoming_text_suite.main,
  );
  group(
    'src/presentation/controllers/speech_dictation_controller.dart',
    dictation.main,
  );
  group(
    'src/data/repositories_impl/platform_speech_recognition_repository.dart',
    speech_adapter.main,
  );
  group(
    'src/data/repositories_impl/system_clipboard_repository.dart',
    clipboard.main,
  );
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
  group('src/domain/models/conversation.dart', conversation.main);
  group('src/domain/models/device_resources.dart', suite8.main);
  group('src/domain/models/llm_configuration.dart', suite9.main);
  group('src/domain/models/model_requirements.dart', suite10.main);
  group('src/domain/models/resource_requirement.dart', suite11.main);
  group('src/domain/services/chat_context_policy.dart', suite12.main);
  group('src/domain/services/chat_service.dart', suite13.main);
  group(
    'src/presentation/controllers/conversation_controller.dart',
    conversation_controller.main,
  );
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
