class Song {
  final int? id;
  final String title;
  final String artist;
  final String? album;
  final String? genre;
  final String filePath;
  final int? duration;
  final String? albumArt;
  final DateTime addedDate;
  final int? trackNumber;
  final int? year;
  final String? albumArtist;
  bool isFavorite;

  Song({
    this.id,
    required this.title,
    required this.artist,
    this.album,
    this.genre,
    required this.filePath,
    this.duration,
    this.albumArt,
    DateTime? addedDate,
    this.trackNumber,
    this.year,
    this.albumArtist,
    this.isFavorite = false,
  }) : addedDate = addedDate ?? DateTime.now();

  // Convert Song to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'filePath': filePath,
      'duration': duration,
      'albumArt': albumArt,
      'addedDate': addedDate.toIso8601String(),
      'trackNumber': trackNumber,
      'year': year,
      'albumArtist': albumArtist,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  // Create Song from Map
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      album: map['album'],
      genre: map['genre'],
      filePath: map['filePath'],
      duration: map['duration'],
      albumArt: map['albumArt'],
      addedDate: DateTime.parse(map['addedDate']),
      trackNumber: map['trackNumber'],
      year: map['year'],
      albumArtist: map['albumArtist'],
      isFavorite: map['isFavorite'] == 1,
    );
  }

  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? filePath,
    int? duration,
    String? albumArt,
    DateTime? addedDate,
    int? trackNumber,
    int? year,
    String? albumArtist,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      albumArt: albumArt ?? this.albumArt,
      addedDate: addedDate ?? this.addedDate,
      trackNumber: trackNumber ?? this.trackNumber,
      year: year ?? this.year,
      albumArtist: albumArtist ?? this.albumArtist,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Helper to get display artist (prefers albumArtist for consistency)
  String get displayArtist => albumArtist ?? artist;
}
