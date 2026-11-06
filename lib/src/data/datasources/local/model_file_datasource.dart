import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:bielik_oneclick_launcher/src/domain/models/model_file.dart';

class ModelFileDataSource {
  ModelFileDataSource({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  Future<File> file(ModelFile model) async {
    if (path.basename(model.name) != model.name ||
        !model.name.endsWith('.gguf')) {
      throw const FormatException('Nieprawidłowa nazwa pliku modelu.');
    }
    final root = await _directory();
    final directory = Directory(path.join(root.path, 'models'));
    await directory.create(recursive: true);
    return File(path.join(directory.path, model.name));
  }
}
