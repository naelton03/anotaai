import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  Database? _database;

  Future<void> init() async {
    if (_database != null) return;

    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      p.join(dbPath, 'anotaai_campeonatos.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE championships(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            format TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            theme TEXT NOT NULL,
            sponsor TEXT NOT NULL,
            privacy TEXT NOT NULL,
            banner_url TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE teams(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            championship_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            logo TEXT NOT NULL,
            status TEXT NOT NULL,
            group_name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE players(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            team_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            position TEXT NOT NULL,
            goals INTEGER NOT NULL DEFAULT 0,
            assists INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE stages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            championship_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            display_order INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE rounds(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            stage_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            display_order INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE matches(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            round_id INTEGER NOT NULL,
            home_team_id INTEGER NOT NULL,
            away_team_id INTEGER NOT NULL,
            home_score INTEGER NOT NULL DEFAULT 0,
            away_score INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL,
            scheduled_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Database get db {
    final database = _database;
    if (database == null) {
      throw StateError('Database not initialized');
    }
    return database;
  }
}
