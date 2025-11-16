import 'dart:io';
import 'package:id3/id3.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import 'package:path/path.dart' as path;

class MetadataExtractor {
  // Extract complete metadata from audio file
  static Future<SongMetadata> extractMetadata(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      // Use just_audio for reliable audio properties
      final audioPlayer = AudioPlayer();
      Duration? audioDuration;
      int? bitrate;
      int? sampleRate;
      int? channels;

      try {
        audioDuration = await audioPlayer.setFilePath(filePath);
        await audioPlayer.dispose();
      } catch (e) {
        print('Error getting audio properties with just_audio: $e');
      }

      // Use id3 for metadata tags
      Map<String, dynamic> tags = {};
      try {
        final bytes = await file.readAsBytes();
        final mp3 = MP3Instance(bytes);
        if (mp3.parseTagsSync()) {
          final id3Tags = mp3.getMetaTags();
          if (id3Tags != null) {
            tags = id3Tags;
          }
        }
      } catch (e) {
        print('Error reading ID3 tags: $e');
      }

      // Estimate bitrate if we have duration and file size
      if (audioDuration != null && audioDuration.inSeconds > 0) {
        final fileSize = await file.length();
        bitrate = (fileSize * 8 / audioDuration.inSeconds).round();
      }

      return SongMetadata(
        title:
            _extractTag(tags, ['TIT2', 'Title']) ??
            _getFilenameWithoutExtension(filePath),
        artist: _extractTag(tags, ['TPE1', 'Artist']) ?? 'Unknown Artist',
        album: _extractTag(tags, ['TALB', 'Album']) ?? 'Unknown Album',
        albumArtist: _extractTag(tags, ['TPE2', 'AlbumArtist']),
        genre: _extractTag(tags, ['TCON', 'Genre']),
        year: _extractYear(tags),
        trackNumber: _extractTrackNumber(tags),
        discNumber: _extractDiscNumber(tags),
        composer: _extractTag(tags, ['TCOM', 'Composer']),
        comment: _extractTag(tags, ['COMM', 'Comment']),
        lyrics: _extractTag(tags, ['USLT', 'Lyrics']),
        duration: audioDuration,
        bitrate: bitrate,
        sampleRate: sampleRate, // just_audio doesn't provide this directly
        channels: channels, // just_audio doesn't provide this directly
        filePath: filePath,
        fileSize: await file.length(),
        replayGainTrack: _extractReplayGain(tags, 'TRACK'),
        replayGainAlbum: _extractReplayGain(tags, 'ALBUM'),
      );
    } catch (e) {
      print('Error extracting metadata from $filePath: $e');
      return _createFallbackMetadata(filePath);
    }
  }

  // Extract multiple files
  static Future<List<SongMetadata>> extractMultipleMetadata(
    List<String> filePaths,
  ) async {
    final List<SongMetadata> results = [];

    for (final filePath in filePaths) {
      try {
        final metadata = await extractMetadata(filePath);
        results.add(metadata);
      } catch (e) {
        print('Failed to extract metadata for $filePath: $e');
        // Add fallback metadata for failed files
        results.add(_createFallbackMetadata(filePath));
      }
    }

    return results;
  }

  // Convert metadata to Song model
  static Song metadataToSong(SongMetadata metadata) {
    return Song(
      title: metadata.title,
      artist: metadata.artist,
      album: metadata.album,
      albumArtist: metadata.albumArtist,
      genre: metadata.genre,
      year: metadata.year,
      trackNumber: metadata.trackNumber,
      filePath: metadata.filePath,
      duration:
          metadata
              .duration
              ?.inMilliseconds, // Convert to milliseconds for Song model
    );
  }

  // Helper: Extract tag with fallback keys
  static String? _extractTag(Map<String, dynamic> tags, List<String> keys) {
    for (final key in keys) {
      if (tags.containsKey(key)) {
        final value = tags[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString().trim();
        }
      }
    }
    return null;
  }

  // Helper: Extract year
  static int? _extractYear(Map<String, dynamic> tags) {
    final yearStr = _extractTag(tags, ['TDRC', 'TYER', 'Year']);
    if (yearStr != null) {
      try {
        // Handle various year formats (2024, 2024-01-01, etc.)
        final match = RegExp(r'(\d{4})').firstMatch(yearStr);
        if (match != null) {
          return int.parse(match.group(1)!);
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper: Extract track number
  static int? _extractTrackNumber(Map<String, dynamic> tags) {
    final trackStr = _extractTag(tags, ['TRCK', 'Track']);
    if (trackStr != null) {
      try {
        // Handle formats like "5" or "5/12"
        final parts = trackStr.split('/');
        return int.parse(parts[0].trim());
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper: Extract disc number
  static int? _extractDiscNumber(Map<String, dynamic> tags) {
    final discStr = _extractTag(tags, ['TPOS', 'Disc']);
    if (discStr != null) {
      try {
        final parts = discStr.split('/');
        return int.parse(parts[0].trim());
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper: Extract ReplayGain
  static double? _extractReplayGain(Map<String, dynamic> tags, String type) {
    final key = 'REPLAYGAIN_${type}_GAIN';
    final value = _extractTag(tags, [key, 'TXXX:$key']);

    if (value != null) {
      try {
        final cleaned = value.replaceAll(RegExp(r'[^\d.+-]'), '').trim();
        return double.parse(cleaned);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper: Get filename without extension
  static String _getFilenameWithoutExtension(String filePath) {
    final fileName = path.basename(filePath);
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      return fileName.substring(0, lastDot);
    }
    return fileName;
  }

  // Create fallback metadata when extraction fails
  static SongMetadata _createFallbackMetadata(String filePath) {
    return SongMetadata(
      title: _getFilenameWithoutExtension(filePath),
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      filePath: filePath,
      fileSize: 0,
    );
  }

  // Validate audio file
  static Future<bool> isValidAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final extension = path.extension(filePath).toLowerCase();
      final supportedFormats = [
        '.mp3',
        '.m4a',
        '.aac',
        '.wav',
        '.flac',
        '.ogg',
      ];

      return supportedFormats.contains(extension);
    } catch (e) {
      return false;
    }
  }
}

// Complete metadata model
class SongMetadata {
  final String title;
  final String artist;
  final String album;
  final String? albumArtist;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final String? composer;
  final String? comment;
  final String? lyrics;
  final Duration? duration;
  final int? bitrate;
  final int? sampleRate;
  final int? channels;
  final String filePath;
  final int fileSize;
  final double? replayGainTrack;
  final double? replayGainAlbum;

  SongMetadata({
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist,
    this.genre,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.composer,
    this.comment,
    this.lyrics,
    this.duration,
    this.bitrate,
    this.sampleRate,
    this.channels,
    required this.filePath,
    required this.fileSize,
    this.replayGainTrack,
    this.replayGainAlbum,
  });

  // Format file size
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Format bitrate
  String? get formattedBitrate {
    if (bitrate == null) return null;
    return '${bitrate! ~/ 1000} kbps';
  }

  // Format sample rate
  String? get formattedSampleRate {
    if (sampleRate == null) return null;
    return '${(sampleRate! / 1000).toStringAsFixed(1)} kHz';
  }

  // Format duration
  String? get formattedDuration {
    if (duration == null) return null;

    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    final seconds = duration!.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  String toString() {
    return 'SongMetadata(title: $title, artist: $artist, album: $album, '
        'year: $year, track: $trackNumber, duration: $formattedDuration, '
        'bitrate: $formattedBitrate)';
  }
}
