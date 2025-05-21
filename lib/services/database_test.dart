import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseTest {
  // Make sure SQLite is properly initialized
  static void _ensureSqfliteInitialized() {
    if (!kIsWeb) {
      try {
        // Initialize FFI if not already done
        sqfliteFfiInit();
        // Set global factory
        databaseFactory = databaseFactoryFfi;
        print('DatabaseTest: Initialized sqflite_ffi');
      } catch (e) {
        print('DatabaseTest: Error initializing SQLite: $e');
      }
    }
  }
  
  static Future<String> testDatabaseConnection() async {
    try {
      // Ensure SQLite is initialized
      _ensureSqfliteInitialized();
      
      if (kIsWeb) {
        return 'Running on web platform - database testing limited';
      }
      
      // Get database path
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'test_db.db');
      
      // Delete existing test database if it exists
      if (await databaseExists(path)) {
        await deleteDatabase(path);
      }
      
      // Create test database
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)');
        },
      );
      
      // Check if database is open
      if (db.isOpen) {
        await db.close();
        return 'Database connection test successful. Path: $path';
      } else {
        return 'Database failed to open';
      }
    } catch (e) {
      return 'Database connection test failed: $e';
    }
  }
  
  static Future<String> testInsertAndRetrieve() async {
    try {
      // Ensure SQLite is initialized
      _ensureSqfliteInitialized();
      
      if (kIsWeb) {
        return 'Running on web platform - database testing limited';
      }
      
      // Get database path
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'test_db.db');
      
      // Open database
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)');
        },
      );
      
      // Insert test data
      await db.insert('test', {'name': 'Test Item'});
      
      // Query test data
      final List<Map<String, dynamic>> result = await db.query('test');
      
      // Close database
      await db.close();
      
      if (result.isNotEmpty) {
        return 'Insert and retrieve test successful. Found ${result.length} records.';
      } else {
        return 'Insert and retrieve test failed. No records found.';
      }
    } catch (e) {
      return 'Insert and retrieve test failed: $e';
    }
  }
  
  static Future<String> checkDatabasePermissions() async {
    try {
      // Ensure SQLite is initialized
      _ensureSqfliteInitialized();
      
      if (kIsWeb) {
        return 'Running on web platform - permission testing not applicable';
      }
      
      // Get database path
      final databasesPath = await getDatabasesPath();
      
      // Check if directory exists
      if (!await Directory(databasesPath).exists()) {
        return 'Database directory does not exist: $databasesPath';
      }
      
      // Try to create a file in the directory
      final testFile = File(join(databasesPath, 'permission_test.txt'));
      await testFile.writeAsString('Test write permission');
      
      // Check if file was created
      if (await testFile.exists()) {
        // Clean up
        await testFile.delete();
        return 'Write permission test successful. Path: $databasesPath';
      } else {
        return 'Failed to write test file. Possible permission issue.';
      }
    } catch (e) {
      return 'Permission test failed: $e';
    }
  }
} 