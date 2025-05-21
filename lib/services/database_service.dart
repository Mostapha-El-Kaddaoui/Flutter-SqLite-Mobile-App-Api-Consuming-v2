import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/book.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal() {
    // Ensure SQLite is initialized when this service is created
    _ensureSqfliteInitialized();
  }
  
  // Make sure SQLite is properly initialized
  void _ensureSqfliteInitialized() {
    if (!kIsWeb) {
      try {
        // Initialize FFI if not already done
        sqfliteFfiInit();
        // Set global factory
        databaseFactory = databaseFactoryFfi;
        print('DatabaseService: Initialized sqflite_ffi');
      } catch (e) {
        print('DatabaseService: Error initializing SQLite: $e');
      }
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      print('Error getting database: $e');
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      print('Database path: $databasesPath');
      final path = join(databasesPath, 'book_favorites.db');
      
      print('Opening database at: $path');
      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          print('Creating database tables');
          await db.execute('''
            CREATE TABLE favorites(
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              authors TEXT NOT NULL,
              description TEXT NOT NULL,
              thumbnailUrl TEXT NOT NULL,
              publishedDate TEXT NOT NULL,
              pageCount INTEGER
            )
          ''');
          print('Database tables created successfully');
        },
        onOpen: (db) {
          print('Database opened successfully');
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> insertFavorite(Book book) async {
    try {
      final db = await database;
      await db.insert(
        'favorites',
        {
          'id': book.id,
          'title': book.title,
          'authors': book.authors.join('|'),
          'description': book.description,
          'thumbnailUrl': book.thumbnailUrl,
          'publishedDate': book.publishedDate,
          'pageCount': book.pageCount,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Inserted favorite with ID: ${book.id}');
    } catch (e) {
      print('Error inserting favorite: $e');
      rethrow;
    }
  }

  Future<void> deleteFavorite(String id) async {
    try {
      final db = await database;
      await db.delete(
        'favorites',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Deleted favorite with ID: $id');
    } catch (e) {
      print('Error deleting favorite: $e');
      rethrow;
    }
  }

  Future<List<Book>> getFavorites() async {
    try {
      final db = await database;
      print('Querying favorites table');
      final List<Map<String, dynamic>> maps = await db.query('favorites');
      print('Found ${maps.length} favorites in database');
      
      return List.generate(maps.length, (i) {
        return Book(
          id: maps[i]['id'],
          title: maps[i]['title'],
          authors: (maps[i]['authors'] as String).split('|'),
          description: maps[i]['description'],
          thumbnailUrl: maps[i]['thumbnailUrl'],
          publishedDate: maps[i]['publishedDate'],
          pageCount: maps[i]['pageCount'],
          isFavorite: true,
        );
      });
    } catch (e) {
      print('Error getting favorites: $e');
      return []; // Return empty list on error
    }
  }

  Future<bool> isFavorite(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'favorites',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking if book is favorite: $e');
      return false; // Default to not favorite on error
    }
  }
  
  // Check if database is working properly
  Future<bool> isDatabaseWorking() async {
    try {
      final db = await database;
      // Try a simple query to verify database is working
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      print('Database is not working: $e');
      return false;
    }
  }
} 