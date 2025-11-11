class Playlist {
  final int? id;
  final String name;
  final String? description;
  final DateTime createdDate;
  final List<int> songIds;

  Playlist({
    this.id,
    required this.name,
    this.description,
    DateTime? createdDate,
    List<int>? songIds,
  })  : createdDate = createdDate ?? DateTime.now(),
        songIds = songIds ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdDate': createdDate.toIso8601String(),
      'songIds': songIds.join(','),
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdDate: DateTime.parse(map['createdDate']),
      songIds: map['songIds'] != null && map['songIds'].isNotEmpty
          ? (map['songIds'] as String).split(',').map((e) => int.parse(e)).toList()
          : [],
    );
  }
}
