import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import '../models/song.dart';

class AudioFileHelper {
  // Request storage permission
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }
      
      // For Android 13+ (API 33+)
      if (await Permission.audio.isDenied) {
        final audioStatus = await Permission.audio.request();
        return audioStatus.isGranted;
      }
      
      return status.isGranted;
    }
    return true; // iOS handles permissions differently
  }

  // Pick audio files using file picker
  static Future<List<Song>?> pickAudioFiles() async {
    try {
      // Request permission first
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        return null;
      }

      // Pick multiple audio files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        List<Song> songs = [];
        
        for (var file in result.files) {
          if (file.path != null) {
            // Extract file name without extension as title
            String fileName = file.name;
            String title = fileName.substring(0, fileName.lastIndexOf('.'));
            
            // Create song object
            Song song = Song(
              title: title,
              artist: 'Unknown Artist',
              filePath: file.path!,
              duration: null, // Will be updated when played
            );
            
            songs.add(song);
          }
        }
        
        return songs;
      }
    } catch (e) {
      print('Error picking audio files: $e');
    }
    
    return null;
  }

  // Pick a single audio file
  static Future<Song?> pickSingleAudioFile() async {
    try {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        return null;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        String fileName = result.files.single.name;
        String title = fileName.substring(0, fileName.lastIndexOf('.'));
        
        return Song(
          title: title,
          artist: 'Unknown Artist',
          filePath: result.files.single.path!,
        );
      }
    } catch (e) {
      print('Error picking audio file: $e');
    }
    
    return null;
  }

  // Get commonly used music directories
  static Future<List<String>> getMusicDirectories() async {
    List<String> directories = [];
    
    if (Platform.isAndroid) {
      // Common Android music directories
      directories.addAll([
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/sdcard/Music',
        '/sdcard/Download',
      ]);
      
      // Get external storage directory
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          directories.add(externalDir.path);
        }
      } catch (e) {
        print('Error getting external storage: $e');
      }
    } else if (Platform.isIOS) {
      // iOS documents directory
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        directories.add(documentsDir.path);
      } catch (e) {
        print('Error getting documents directory: $e');
      }
    }
    
    return directories;
  }

  // Scan directory for audio files
  static Future<List<Song>> scanDirectoryForAudio(String directoryPath) async {
    List<Song> songs = [];
    
    try {
      final directory = Directory(directoryPath);
      
      if (!await directory.exists()) {
        return songs;
      }

      final List<String> audioExtensions = [
        '.mp3', '.m4a', '.wav', '.flac', '.aac', '.ogg', '.opus'
      ];

      await for (var entity in directory.list(recursive: true)) {
        if (entity is File) {
          String path = entity.path;
          String extension = path.substring(path.lastIndexOf('.')).toLowerCase();
          
          if (audioExtensions.contains(extension)) {
            String fileName = path.substring(path.lastIndexOf('/') + 1);
            String title = fileName.substring(0, fileName.lastIndexOf('.'));
            
            songs.add(Song(
              title: title,
              artist: 'Unknown Artist',
              filePath: path,
            ));
          }
        }
      }
    } catch (e) {
      print('Error scanning directory: $e');
    }
    
    return songs;
  }

  // Check if file exists
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get file size in MB
  static Future<double> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.length();
        return bytes / (1024 * 1024); // Convert to MB
      }
    } catch (e) {
      print('Error getting file size: $e');
    }
    return 0;
  }
}
