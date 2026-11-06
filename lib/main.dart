import 'package:material_ui/material_ui.dart';

import 'package:bielik_oneclick_launcher/src/app.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/app_database.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/model_file_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/local/sqlite_chat_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/datasources/model_download_datasource.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/local_model_files_repository.dart';
import 'package:bielik_oneclick_launcher/src/data/repositories_impl/sqlite_chat_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterModelDownloadDataSource.initialize();
  final database = AppDatabase();
  runApp(
    MyApp(
      chatRepository: SqliteChatRepository(SqliteChatDataSource(database)),
      modelFilesRepository: LocalModelFilesRepository(ModelFileDataSource()),
    ),
  );
}
