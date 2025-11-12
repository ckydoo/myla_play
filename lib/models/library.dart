// Album grouping
class Album {
  final String name;
  final String artist;
  final int songCount;
  final int? year;
  final String? albumArt;
  final int? totalDuration;
  final List<int> songIds;

  Album({
    required this.name,
    required this.artist,
    required this.songCount,
    this.year,
    this.albumArt,
    this.totalDuration,
    required this.songIds,
  });

  String get displayName => name.isNotEmpty ? name : 'Unknown Album';
}

// Artist grouping
class Artist {
  final String name;
  final int songCount;
  final int albumCount;
  final String? artistArt;
  final List<int> songIds;
  final List<String> albums;

  Artist({
    required this.name,
    required this.songCount,
    required this.albumCount,
    this.artistArt,
    required this.songIds,
    required this.albums,
  });

  String get displayName => name.isNotEmpty ? name : 'Unknown Artist';
}

// Genre grouping
class Genre {
  final String name;
  final int songCount;
  final List<int> songIds;

  Genre({required this.name, required this.songCount, required this.songIds});

  String get displayName => name.isNotEmpty ? name : 'Unknown Genre';
}

// Equalizer preset
class EqualizerPreset {
  final String name;
  final List<double> bandValues; // Values between -12.0 and 12.0 dB
  final bool isCustom;

  EqualizerPreset({
    required this.name,
    required this.bandValues,
    this.isCustom = false,
  });

  // Standard presets
  static final List<EqualizerPreset> standardPresets = [
    EqualizerPreset(name: 'Flat', bandValues: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
    EqualizerPreset(
      name: 'Rock',
      bandValues: [5, 3, -3, -5, -2, 2, 5, 6, 6, 6],
    ),
    EqualizerPreset(
      name: 'Pop',
      bandValues: [-2, -1, 0, 2, 4, 4, 2, 0, -1, -2],
    ),
    EqualizerPreset(
      name: 'Classical',
      bandValues: [0, 0, 0, 0, 0, 0, -3, -3, -3, -5],
    ),
    EqualizerPreset(name: 'Jazz', bandValues: [4, 3, 1, 2, -2, -2, 0, 2, 3, 4]),
    EqualizerPreset(
      name: 'Bass Boost',
      bandValues: [7, 5, 4, 3, 1, 0, 0, 0, 0, 0],
    ),
    EqualizerPreset(
      name: 'Treble Boost',
      bandValues: [0, 0, 0, 0, 0, 2, 4, 5, 6, 7],
    ),
    EqualizerPreset(
      name: 'Vocal Boost',
      bandValues: [-2, -3, -2, 1, 3, 3, 2, 1, 0, -1],
    ),
  ];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bandValues': bandValues.join(','),
      'isCustom': isCustom ? 1 : 0,
    };
  }

  factory EqualizerPreset.fromMap(Map<String, dynamic> map) {
    return EqualizerPreset(
      name: map['name'],
      bandValues:
          (map['bandValues'] as String)
              .split(',')
              .map((e) => double.parse(e))
              .toList(),
      isCustom: map['isCustom'] == 1,
    );
  }
}
