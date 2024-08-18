library dash;

import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart';
// ignore: unnecessary_import, depend_on_referenced_packages
import 'package:sqflite_common/sqlite_api.dart';
// ignore: unnecessary_import, depend_on_referenced_packages
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ignore: constant_identifier_names
const String TABLE_NAME = "cache";
// ignore: constant_identifier_names
const String SCHEMA =
    "CREATE TABLE IF NOT EXISTS $TABLE_NAME (id INTEGER PRIMARY KEY AUTOINCREMENT, key TEXT UNIQUE, value TEXT)";

class Dash {
  late final Database _db;
  late final String _path;

  Dash._(this._db, this._path);

  static Future<Dash> init() async {
    if (Platform.isLinux) return _initLinux();
    if (Platform.isAndroid) return _initAndroid();
    throw UnimplementedError(
      "Unimplemented platform: ${Platform.operatingSystem}",
    );
  }

  static Future<Dash> _initLinux() async {
    sqfliteFfiInit();

    final db = await databaseFactoryFfi.openDatabase("./local_cache.db");
    await db.execute(SCHEMA);
    final path = db.path;

    return Dash._(db, path);
  }

  static Future<Dash> _initAndroid() async {
    final databaseLocation = await getDatabasesPath();
    final path = p.join(databaseLocation, "local_cache.db");

    Database database = await openDatabase(
      path,
      version: 0,
      onCreate: (Database db, int version) async {
        await db.execute(SCHEMA);
      },
    );

    return Dash._(database, path);
  }

  Future<String?> get(String key) async {
    List<Map> query = await _db.rawQuery(
      'SELECT value FROM $TABLE_NAME WHERE key = ?',
      [key],
    );
    if (query.isEmpty) return null;
    return query[0]["value"];
  }

  void put<T>(String key, String value) async {
    await _db.transaction((transaction) async {
      await transaction.insert(
        TABLE_NAME,
        {"key": key, "value": value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  String path() {
    return _path;
  }

  void close() async {
    await _db.close();
  }

  void dropAll() async {
    await _db.delete(TABLE_NAME);
  }

  @visibleForTesting
  Future<int> version() {
    return _db.getVersion();
  }

  @visibleForTesting
  bool isOpen() {
    return _db.isOpen;
  }
}
