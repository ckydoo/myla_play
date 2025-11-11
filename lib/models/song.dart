class Song {
  final int? id;
  final String title;
  final String artist;
  final String? album;
  final String filePath;
  final int? duration;
  final String? albumArt;
  final DateTime addedDate;
  bool isFavorite;

  Song({
    this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.filePath,
    this.duration,
    this.albumArt,
    DateTime? addedDate,
    this.isFavorite = false,
  }) : addedDate = addedDate ?? DateTime.now();

  // Convert Song to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'filePath': filePath,
      'duration': duration,
      'albumArt': albumArt,
      'addedDate': addedDate.toIso8601String(),
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
      filePath: map['filePath'],
      duration: map['duration'],
      albumArt: map['albumArt'],
      addedDate: DateTime.parse(map['addedDate']),
      isFavorite: map['isFavorite'] == 1,
    );
  }

  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    int? duration,
    String? albumArt,
    DateTime? addedDate,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      albumArt: albumArt ?? this.albumArt,
      addedDate: addedDate ?? this.addedDate,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
