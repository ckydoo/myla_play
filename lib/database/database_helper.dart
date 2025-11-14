import 'package:myla_play/models/library.dart';
import 'package:myla_play/models/playlist.dart';
import 'package:myla_play/models/song.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('music_player_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to songs table
      await db.execute('ALTER TABLE songs ADD COLUMN genre TEXT');
      await db.execute('ALTER TABLE songs ADD COLUMN trackNumber INTEGER');
      await db.execute('ALTER TABLE songs ADD COLUMN year INTEGER');
      await db.execute('ALTER TABLE songs ADD COLUMN albumArtist TEXT');

      // Add new columns to playlists table
      await db.execute('ALTER TABLE playlists ADD COLUMN lastModified TEXT');
      await db.execute('ALTER TABLE playlists ADD COLUMN coverArt TEXT');
      await db.execute(
        'ALTER TABLE playlists ADD COLUMN isSmartPlaylist INTEGER DEFAULT 0',
      );

      // Create equalizer presets table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS equalizer_presets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          bandValues TEXT NOT NULL,
          isCustom INTEGER DEFAULT 0
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER';

    //  Songs table
    await db.execute('''
      CREATE TABLE songs (
        id $idType,
        title $textType,
        artist $textType,
        album TEXT,
        genre TEXT,
        filePath $textType UNIQUE,
        duration $intType,
        albumArt TEXT,
        addedDate $textType,
        trackNumber $intType,
        year $intType,
        albumArtist TEXT,
        isFavorite $intType DEFAULT 0
      )
    ''');

    // Enhanced Playlists table
    await db.execute('''
      CREATE TABLE playlists (
        id $idType,
        name $textType,
        description TEXT,
        createdDate $textType,
        lastModified $textType,
        songIds TEXT,
        coverArt TEXT,
        isSmartPlaylist $intType DEFAULT 0
      )
    ''');

    // Equalizer presets table
    await db.execute('''
      CREATE TABLE equalizer_presets (
        id $idType,
        name $textType,
        bandValues $textType,
        isCustom $intType DEFAULT 0
      )
    ''');
    await db.execute('''
  CREATE TABLE IF NOT EXISTS recent_searches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT NOT NULL UNIQUE,
    searchDate TEXT NOT NULL
  )
''');
    // Insert default EQ presets
    for (var preset in EqualizerPreset.standardPresets) {
      await db.insert('equalizer_presets', preset.toMap());
    }
  }

  // ========== SONG OPERATIONS ==========

  Future<Song> insertSong(Song song) async {
    final db = await database;
    try {
      final existing = await db.query(
        'songs',
        where: 'filePath = ?',
        whereArgs: [song.filePath],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return Song.fromMap(existing.first);
      }

      final id = await db.insert(
        'songs',
        song.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      if (id == 0) {
        final result = await db.query(
          'songs',
          where: 'filePath = ?',
          whereArgs: [song.filePath],
          limit: 1,
        );
        return Song.fromMap(result.first);
      }

      return song.copyWith(id: id);
    } catch (e) {
      print('Error inserting song: $e');
      rethrow;
    }
  }

  Future<List<Song>> getAllSongs() async {
    final db = await database;
    const orderBy = 'title COLLATE NOCASE ASC';
    final result = await db.query('songs', orderBy: orderBy);
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<Song?> getSong(int id) async {
    final db = await database;
    final maps = await db.query('songs', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Song.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Song>> getFavoriteSongs() async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'title COLLATE NOCASE ASC',
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
    return await db.delete('songs', where: 'id = ?', whereArgs: [id]);
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

  Future<void> clearAllSongs() async {
    final db = await database;
    await db.delete('songs');
  }

  Future<int> removeDuplicates() async {
    final db = await database;
    final duplicates = await db.rawQuery('''
      SELECT filePath, MIN(id) as keepId
      FROM songs
      GROUP BY filePath
      HAVING COUNT(*) > 1
    ''');

    int removedCount = 0;
    for (var dup in duplicates) {
      final filePath = dup['filePath'] as String;
      final keepId = dup['keepId'] as int;
      final deleted = await db.delete(
        'songs',
        where: 'filePath = ? AND id != ?',
        whereArgs: [filePath, keepId],
      );
      removedCount += deleted;
    }
    return removedCount;
  }

  // ========== LIBRARY VIEWS ==========

  Future<List<Album>> getAllAlbums() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        album,
        COALESCE(albumArtist, artist) as artist,
        COUNT(*) as songCount,
        MIN(year) as year,
        MIN(albumArt) as albumArt,
        SUM(duration) as totalDuration,
        GROUP_CONCAT(id) as songIds
      FROM songs
      WHERE album IS NOT NULL AND album != ''
      GROUP BY album, COALESCE(albumArtist, artist)
      ORDER BY album COLLATE NOCASE ASC
    ''');

    return result.map((map) {
      return Album(
        name: map['album'] as String,
        artist: map['artist'] as String,
        songCount: map['songCount'] as int,
        year: map['year'] as int?,
        albumArt: map['albumArt'] as String?,
        totalDuration: map['totalDuration'] as int?,
        songIds:
            (map['songIds'] as String)
                .split(',')
                .map((e) => int.parse(e))
                .toList(),
      );
    }).toList();
  }

  Future<List<Song>> getSongsByAlbum(
    String albumName,
    String artistName,
  ) async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'album = ? AND (albumArtist = ? OR artist = ?)',
      whereArgs: [albumName, artistName, artistName],
      orderBy: 'trackNumber ASC, title ASC',
    );
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<List<Artist>> getAllArtists() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(albumArtist, artist) as name,
        COUNT(*) as songCount,
        COUNT(DISTINCT album) as albumCount,
        GROUP_CONCAT(id) as songIds,
        GROUP_CONCAT(DISTINCT album) as albums
      FROM songs
      GROUP BY COALESCE(albumArtist, artist)
      ORDER BY name COLLATE NOCASE ASC
    ''');

    return result.map((map) {
      return Artist(
        name: map['name'] as String,
        songCount: map['songCount'] as int,
        albumCount: map['albumCount'] as int,
        songIds:
            (map['songIds'] as String)
                .split(',')
                .map((e) => int.parse(e))
                .toList(),
        albums: (map['albums'] as String).split(','),
      );
    }).toList();
  }

  Future<List<Song>> getSongsByArtist(String artistName) async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'albumArtist = ? OR artist = ?',
      whereArgs: [artistName, artistName],
      orderBy: 'album ASC, trackNumber ASC, title ASC',
    );
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<List<Genre>> getAllGenres() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(genre, 'Unknown') as name,
        COUNT(*) as songCount,
        GROUP_CONCAT(id) as songIds
      FROM songs
      GROUP BY COALESCE(genre, 'Unknown')
      ORDER BY name COLLATE NOCASE ASC
    ''');

    return result.map((map) {
      return Genre(
        name: map['name'] as String,
        songCount: map['songCount'] as int,
        songIds:
            (map['songIds'] as String)
                .split(',')
                .map((e) => int.parse(e))
                .toList(),
      );
    }).toList();
  }

  Future<List<Song>> getSongsByGenre(String genreName) async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'genre = ?',
      whereArgs: [genreName],
      orderBy: 'artist ASC, album ASC, title ASC',
    );
    return result.map((json) => Song.fromMap(json)).toList();
  }

  // ========== PLAYLIST OPERATIONS ==========

  Future<Playlist> createPlaylist(Playlist playlist) async {
    final db = await database;
    final id = await db.insert('playlists', playlist.toMap());
    return playlist.copyWith(id: id);
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final result = await db.query(
      'playlists',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return result.map((json) => Playlist.fromMap(json)).toList();
  }

  Future<Playlist?> getPlaylist(int id) async {
    final db = await database;
    final maps = await db.query('playlists', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Playlist.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePlaylist(Playlist playlist) async {
    final db = await database;
    final updatedPlaylist = playlist.copyWith(lastModified: DateTime.now());
    return db.update(
      'playlists',
      updatedPlaylist.toMap(),
      where: 'id = ?',
      whereArgs: [playlist.id],
    );
  }

  Future<int> deletePlaylist(int id) async {
    final db = await database;
    return await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Song>> getPlaylistSongs(Playlist playlist) async {
    if (playlist.songIds.isEmpty) return [];

    final db = await database;
    final placeholders = List.filled(playlist.songIds.length, '?').join(',');
    final result = await db.query(
      'songs',
      where: 'id IN ($placeholders)',
      whereArgs: playlist.songIds,
    );

    // Preserve playlist order
    final songMap = {
      for (var song in result) song['id'] as int: Song.fromMap(song),
    };
    return playlist.songIds
        .where((id) => songMap.containsKey(id))
        .map((id) => songMap[id]!)
        .toList();
  }

  // ========== EQUALIZER PRESETS ==========

  Future<List<EqualizerPreset>> getAllEqPresets() async {
    final db = await database;
    final result = await db.query(
      'equalizer_presets',
      orderBy: 'isCustom ASC, name ASC',
    );
    return result.map((json) => EqualizerPreset.fromMap(json)).toList();
  }

  Future<int> saveEqPreset(EqualizerPreset preset) async {
    final db = await database;
    return await db.insert('equalizer_presets', preset.toMap());
  }

  Future<int> deleteEqPreset(String name) async {
    final db = await database;
    return await db.delete(
      'equalizer_presets',
      where: 'name = ? AND isCustom = 1',
      whereArgs: [name],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Methods
  Future<void> addRecentSearch(String query) async {
    final db = await database;
    await db.insert('recent_searches', {
      'query': query,
      'searchDate': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<String>> getRecentSearches({int limit = 10}) async {
    final db = await database;
    final result = await db.query(
      'recent_searches',
      orderBy: 'searchDate DESC',
      limit: limit,
    );
    return result.map((row) => row['query'] as String).toList();
  }

  Future<void> clearRecentSearches() async {
    final db = await database;
    await db.delete('recent_searches');
  }
}
