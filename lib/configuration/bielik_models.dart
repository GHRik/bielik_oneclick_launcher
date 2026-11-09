import 'package:bielik_oneclick_launcher/src/domain/models/bielik_model.dart';
import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

const bielikModels = [
  BielikModel(
    name: 'Bielik 1.5B v3.0 · Q8',
    file: ModelFile(
      name: 'Bielik-1.5B-v3.0-Instruct.Q8_0.gguf',
      url: 'https://huggingface.co/speakleash/Bielik-1.5B-v3.0-Instruct-GGUF/resolve/bb7ba70f60f2eee48d46857966ba3cf91bccb260/Bielik-1.5B-v3.0-Instruct.Q8_0.gguf',
      sizeBytes: 1699568288,
      sha256:
          'e206ebbd9ee00cc8f14af5a096ad3f193a59608c63905316e8dc680c96655a60',
    ),
    diskSpace: 'około 1,7 GB',
    downloadSizeMb: 1700,
    ram: 'około 3–4 GB wolnego RAM; zalecany telefon z 6 GB RAM',
    requiredFreeRamGb: 4,
  ),
  BielikModel(
    name: 'Bielik 4.5B v3.0 · Q8',
    file: ModelFile(
      name: 'Bielik-4.5B-v3.0-Instruct.Q8_0.gguf',
      url: 'https://huggingface.co/speakleash/Bielik-4.5B-v3.0-Instruct-GGUF/resolve/c80ffe0e154fab9f7af170993a16d6f8acc83903/Bielik-4.5B-v3.0-Instruct.Q8_0.gguf',
      sizeBytes: 5061215424,
      sha256:
          '562f2291de257890adf2b4a914da8b194affe6a7a838a6b7ef3d342f306c1b7f',
    ),
    diskSpace: 'około 5,06 GB',
    downloadSizeMb: 5060,
    ram: 'około 6–8 GB wolnego RAM; zalecany telefon z 12 GB RAM',
    requiredFreeRamGb: 8,
  ),
];
