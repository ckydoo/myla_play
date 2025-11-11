import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('music_player.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER';

    // Songs table
    await db.execute('''
      CREATE TABLE songs (
        id $idType,
        title $textType,
        artist $textType,
        album TEXT,
        filePath $textType,
        duration $intType,
        albumArt TEXT,
        addedDate $textType,
        isFavorite $intType
      )
    ''');

    // Playlists table
    await db.execute('''
      CREATE TABLE playlists (
        id $idType,
        name $textType,
        description TEXT,
        createdDate $textType,
        songIds TEXT
      )
    ''');
  }

  // SONG OPERATIONS
  Future<Song> insertSong(Song song) async {
    final db = await database;
    final id = await db.insert('songs', song.toMap());
    return song.copyWith(id: id);
  }

  Future<List<Song>> getAllSongs() async {
    final db = await database;
    const orderBy = 'title ASC';
    final result = await db.query('songs', orderBy: orderBy);
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<Song?> getSong(int id) async {
    final db = await database;
    final maps = await db.query(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Song.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Song>> getFavoriteSongs() async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'title ASC',
    );
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<int> updateSong(Song song) async {
    final db = await database;
    return db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  Future<int> deleteSong(int id) async {
    final db = await database;
    return await db.delete(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'songs',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // PLAYLIST OPERATIONS
  Future<Playlist> createPlaylist(Playlist playlist) async {
    final db = await database;
    final id = await db.insert('playlists', playlist.toMap());
    return Playlist(
      id: id,
      name: playlist.name,
      description: playlist.description,
      createdDate: playlist.createdDate,
      songIds: playlist.songIds,
    );
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final result = await db.query('playlists', orderBy: 'name ASC');
    return result.map((json) => Playlist.fromMap(json)).toList();
  }

  Future<Playlist?> getPlaylist(int id) async {
    final db = await database;
    final maps = await db.query(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Playlist.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updatePlaylist(Playlist playlist) async {
    final db = await database;
    return db.update(
      'playlists',
      playlist.toMap(),
      where: 'id = ?',
      whereArgs: [playlist.id],
    );
  }

  Future<int> deletePlaylist(int id) async {
    final db = await database;
    return await db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
