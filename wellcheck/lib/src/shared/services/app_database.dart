import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _dbName = 'wellcheck.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final docs = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docs.path, _dbName);
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE members ADD COLUMN date_of_birth TEXT;');
          await db.execute(
            "ALTER TABLE members ADD COLUMN user_type TEXT NOT NULL DEFAULT 'Pensioner';",
          );
        }
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    // Members
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT,
        location TEXT,
        date_of_birth TEXT,
        user_type TEXT NOT NULL DEFAULT 'Pensioner',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    // Next of kin
    await db.execute('''
      CREATE TABLE next_of_kin (
        id TEXT PRIMARY KEY,
        member_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        relationship TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(member_id) REFERENCES members(id) ON DELETE CASCADE
      );
    ''');
    // Security companies
    await db.execute('''
      CREATE TABLE security_companies (
        id TEXT PRIMARY KEY,
        member_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        area TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(member_id) REFERENCES members(id) ON DELETE CASCADE
      );
    ''');
    // Doctors
    await db.execute('''
      CREATE TABLE doctors (
        id TEXT PRIMARY KEY,
        member_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        practice TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(member_id) REFERENCES members(id) ON DELETE CASCADE
      );
    ''');
    // Help requests with GPS location
    await db.execute('''
      CREATE TABLE help_requests (
        id TEXT PRIMARY KEY,
        member_id INTEGER NOT NULL,
        message TEXT,
        lat REAL,
        lng REAL,
        address TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(member_id) REFERENCES members(id) ON DELETE CASCADE
      );
    ''');
    // Indexes for scalability
    await db.execute('CREATE INDEX IF NOT EXISTS idx_help_requests_member ON help_requests(member_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_help_requests_created ON help_requests(created_at);');
  }

  Database get _requireDb => _db!;

  // Members
  Future<void> upsertMember({
    required int id,
    required String name,
    required String email,
    String? phone,
    String? location,
    DateTime? dateOfBirth,
    required String userType,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    await init();
    final db = _requireDb;
    await db.insert(
      'members',
      {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'user_type': userType,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Help requests
  Future<void> insertHelpRequest({
    required String id,
    required int memberId,
    String? message,
    double? lat,
    double? lng,
    String? address,
    DateTime? createdAt,
  }) async {
    await init();
    final db = _requireDb;
    await db.insert('help_requests', {
      'id': id,
      'member_id': memberId,
      'message': message,
      'lat': lat,
      'lng': lng,
      'address': address,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    });
  }
}
