import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app/app.dart';
import 'src/data/championship_repository.dart';
import 'src/data/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseService = DatabaseService();
  await databaseService.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ChampionshipRepository(databaseService)..bootstrap(),
      child: const ChampionshipManagerApp(),
    ),
  );
}
