class Playlist {
  final int? id;
  final String name;
  final String? description;
  final DateTime createdDate;
  final DateTime lastModified;
  final List<int> songIds;
  final String? coverArt;
  final bool isSmartPlaylist; // For future auto-generated playlists

  Playlist({
    this.id,
    required this.name,
    this.description,
    DateTime? createdDate,
    DateTime? lastModified,
    List<int>? songIds,
    this.coverArt,
    this.isSmartPlaylist = false,
  }) : createdDate = createdDate ?? DateTime.now(),
       lastModified = lastModified ?? DateTime.now(),
       songIds = songIds ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdDate': createdDate.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'songIds': songIds.join(','),
      'coverArt': coverArt,
      'isSmartPlaylist': isSmartPlaylist ? 1 : 0,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdDate: DateTime.parse(map['createdDate']),
      lastModified: DateTime.parse(map['lastModified']),
      songIds:
          map['songIds'] != null && map['songIds'].isNotEmpty
              ? (map['songIds'] as String)
                  .split(',')
                  .map((e) => int.parse(e))
                  .toList()
              : [],
      coverArt: map['coverArt'],
      isSmartPlaylist: map['isSmartPlaylist'] == 1,
    );
  }

  Playlist copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdDate,
    DateTime? lastModified,
    List<int>? songIds,
    String? coverArt,
    bool? isSmartPlaylist,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
      songIds: songIds ?? this.songIds,
      coverArt: coverArt ?? this.coverArt,
      isSmartPlaylist: isSmartPlaylist ?? this.isSmartPlaylist,
    );
  }
}
