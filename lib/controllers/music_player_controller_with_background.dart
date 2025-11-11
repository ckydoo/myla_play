import 'package:get/get.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart'; // Add this import for LoopMode
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/song.dart';
import '../database/database_helper.dart';
import '../services/audio_handler.dart';

class MusicPlayerController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late MyAudioHandler _audioHandler;
  bool _isInitialized = false;

  // Observables
  final RxList<Song> allSongs = <Song>[].obs;
  final RxList<Song> currentPlaylist = <Song>[].obs;
  final Rx<Song?> currentSong = Rx<Song?>(null);
  final RxInt currentIndex = 0.obs;

  final RxBool isPlaying = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isShuffleEnabled = false.obs;
  final Rx<LoopMode> loopMode = LoopMode.off.obs;

  final Rx<Duration> duration = Duration.zero.obs;
  final Rx<Duration> position = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeAudioService();
  }

  Future<void> _initializeAudioService() async {
    try {
      _audioHandler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.example.myla_play.audio',
          androidNotificationChannelName: 'MyLa Play',
          androidNotificationChannelDescription: 'Music playback controls',
          androidNotificationOngoing: true,
          androidNotificationIcon:
              'mipmap/ic_launcher', // Ensure this path matches your app's icon resource
          androidShowNotificationBadge: true,
          androidStopForegroundOnPause: false,
        ),
      );

      _isInitialized = true;
      _listenToAudioService();
    } catch (e) {
      print('Error initializing audio service: $e');
    }
  }

  void _listenToAudioService() {
    // Listen to playback state
    _audioHandler.playbackState.listen((state) {
      isPlaying.value = state.playing;
      position.value = state.updatePosition;

      // Update shuffle and repeat modes
      if (state.shuffleMode == AudioServiceShuffleMode.all) {
        isShuffleEnabled.value = true;
      } else {
        isShuffleEnabled.value = false;
      }
    });

    // Listen to current media item
    _audioHandler.mediaItem.listen((item) {
      if (item != null) {
        // Find the corresponding song
        final song = allSongs.firstWhereOrNull((s) => s.filePath == item.id);
        if (song != null) {
          currentSong.value = song;
          currentIndex.value = currentPlaylist.indexWhere(
            (s) => s.id == song.id,
          );
        }
      }
    });

    // Listen to queue
    _audioHandler.queue.listen((queue) {
      // Queue updated
    });

    // Listen to player to get duration
    _audioHandler.player.durationStream.listen((d) {
      duration.value = d ?? Duration.zero;
    });

    // Listen to position
    _audioHandler.player.positionStream.listen((p) {
      position.value = p;
    });
  }

  // Convert Song to MediaItem
  MediaItem _songToMediaItem(Song song) {
    return MediaItem(
      id: song.filePath, // Use file path as ID
      album: song.album ?? 'Unknown Album',
      title: song.title,
      artist: song.artist,
      duration:
          song.duration != null ? Duration(milliseconds: song.duration!) : null,
      artUri: song.albumArt != null ? Uri.parse(song.albumArt!) : null,
    );
  }

  // Scan device for audio files
  Future<void> scanDeviceForAudio() async {
    isLoading.value = true;

    try {
      bool permissionGranted = await _requestPermissions();

      if (!permissionGranted) {
        isLoading.value = false;
        return;
      }

      await _scanMusicDirectories();

      final removedCount = await _dbHelper.removeDuplicates();
      if (removedCount > 0) {
        print('Removed $removedCount duplicate songs');
      }

      if (allSongs.isNotEmpty) {
        Get.snackbar(
          'Scan Complete',
          '${allSongs.length} songs in library',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error scanning device: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _scanMusicDirectories() async {
    List<String> directories = await _getMusicDirectories();

    for (String directory in directories) {
      await _scanDirectory(directory);
    }

    await loadSongs();
  }

  Future<List<String>> _getMusicDirectories() async {
    List<String> directories = [];

    if (Platform.isAndroid) {
      directories.addAll([
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/sdcard/Music',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ]);
    }

    return directories;
  }

  Future<void> _scanDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);

      if (!await directory.exists()) {
        return;
      }

      final List<String> audioExtensions = [
        '.mp3',
        '.m4a',
        '.wav',
        '.flac',
        '.aac',
        '.ogg',
        '.opus',
        '.wma',
      ];

      await for (var entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          String path = entity.path;
          String extension =
              path.substring(path.lastIndexOf('.')).toLowerCase();

          if (audioExtensions.contains(extension)) {
            try {
              FileStat stats = await entity.stat();

              if (stats.size < 100000) continue;

              String fileName = path.substring(path.lastIndexOf('/') + 1);
              String title = fileName.substring(0, fileName.lastIndexOf('.'));

              List<String> pathParts = path.split('/');
              String artist =
                  pathParts.length > 2
                      ? pathParts[pathParts.length - 2]
                      : 'Unknown Artist';

              if (artist.toLowerCase().contains('music') ||
                  artist.toLowerCase().contains('download') ||
                  artist.toLowerCase().contains('storage')) {
                artist = 'Unknown Artist';
              }

              Song song = Song(
                title: title,
                artist: artist,
                filePath: path,
                duration: null,
              );

              await _dbHelper.insertSong(song);
            } catch (e) {
              print('Error processing file $path: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error scanning directory $directoryPath: $e');
    }
  }

  Future<void> pickFolderToScan() async {
    try {
      await _requestPermissions();

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        isLoading.value = true;
        await _scanDirectory(selectedDirectory);
        await _dbHelper.removeDuplicates();
        await loadSongs();

        Get.snackbar(
          'Scan Complete',
          '${allSongs.length} songs in library',
          snackPosition: SnackPosition.BOTTOM,
        );

        isLoading.value = false;
      }
    } catch (e) {
      isLoading.value = false;
      print('Error picking folder: $e');
      Get.snackbar(
        'Info',
        'Please try selecting your music folder again',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> pickAudioFiles() async {
    try {
      await _requestPermissions();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        isLoading.value = true;

        for (var file in result.files) {
          if (file.path != null) {
            String fileName = file.name;
            String title = fileName.substring(0, fileName.lastIndexOf('.'));

            Song song = Song(
              title: title,
              artist: 'Unknown Artist',
              filePath: file.path!,
              duration: null,
            );

            await _dbHelper.insertSong(song);
          }
        }

        await _dbHelper.removeDuplicates();
        await loadSongs();

        Get.snackbar(
          'Success',
          '${allSongs.length} songs in library',
          snackPosition: SnackPosition.BOTTOM,
        );

        isLoading.value = false;
      }
    } catch (e) {
      isLoading.value = false;
      print('Error picking files: $e');
      Get.snackbar(
        'Info',
        'Please try selecting audio files again',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.audio.isDenied) {
          final status = await Permission.audio.request();
          if (status.isGranted) {
            return true;
          }
        }

        if (await Permission.storage.isDenied) {
          final status = await Permission.storage.request();
          return status.isGranted;
        }

        final audioGranted = await Permission.audio.isGranted;
        final storageGranted = await Permission.storage.isGranted;

        return audioGranted || storageGranted;
      }

      return true;
    } catch (e) {
      print('Permission request error: $e');
      Get.snackbar(
        'Permission Info',
        'Please grant storage permission in Settings → Apps → MyLa Play → Permissions',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    }
  }

  Future<void> loadSongs() async {
    isLoading.value = true;
    try {
      allSongs.value = await _dbHelper.getAllSongs();
      if (currentPlaylist.isEmpty && allSongs.isNotEmpty) {
        currentPlaylist.value = List.from(allSongs);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load songs: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rescanDevice() async {
    await scanDeviceForAudio();
  }

  Future<void> cleanDuplicates() async {
    isLoading.value = true;
    try {
      final removedCount = await _dbHelper.removeDuplicates();
      await loadSongs();

      Get.snackbar(
        'Cleanup Complete',
        removedCount > 0
            ? 'Removed $removedCount duplicate songs'
            : 'No duplicates found',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to clean duplicates: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFavorite(Song song) async {
    if (song.id == null) return;

    try {
      final newFavoriteStatus = !song.isFavorite;
      await _dbHelper.toggleFavorite(song.id!, newFavoriteStatus);

      final index = allSongs.indexWhere((s) => s.id == song.id);
      if (index != -1) {
        allSongs[index] = song.copyWith(isFavorite: newFavoriteStatus);
      }

      final playlistIndex = currentPlaylist.indexWhere((s) => s.id == song.id);
      if (playlistIndex != -1) {
        currentPlaylist[playlistIndex] = song.copyWith(
          isFavorite: newFavoriteStatus,
        );
      }

      if (currentSong.value?.id == song.id) {
        currentSong.value = song.copyWith(isFavorite: newFavoriteStatus);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update favorite: $e');
    }
  }

  // PLAYBACK CONTROLS using AudioService

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    if (!_isInitialized) return;

    try {
      if (playlist != null) {
        currentPlaylist.value = playlist;
      }

      currentSong.value = song;
      currentIndex.value = currentPlaylist.indexWhere((s) => s.id == song.id);

      // Convert songs to MediaItems
      final mediaItems = currentPlaylist.map(_songToMediaItem).toList();
      final currentMediaItem = _songToMediaItem(song);

      // Play through audio service
      await _audioHandler.addQueueItems(mediaItems);
      await _audioHandler.playMediaItem(currentMediaItem);
    } catch (e) {
      Get.snackbar('Error', 'Failed to play song: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (!_isInitialized) return;

    if (isPlaying.value) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }

  Future<void> play() async {
    if (!_isInitialized) return;
    await _audioHandler.play();
  }

  Future<void> pause() async {
    if (!_isInitialized) return;
    await _audioHandler.pause();
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    await _audioHandler.stop();
  }

  Future<void> playNext() async {
    if (!_isInitialized) return;
    await _audioHandler.skipToNext();
  }

  Future<void> playPrevious() async {
    if (!_isInitialized) return;
    await _audioHandler.skipToPrevious();
  }

  Future<void> seek(Duration position) async {
    if (!_isInitialized) return;
    await _audioHandler.seek(position);
  }

  Future<void> toggleShuffle() async {
    if (!_isInitialized) return;

    isShuffleEnabled.value = !isShuffleEnabled.value;

    if (isShuffleEnabled.value) {
      await _audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
      currentPlaylist.shuffle();
    } else {
      await _audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
      currentPlaylist.value = List.from(allSongs);
    }
  }

  Future<void> toggleLoopMode() async {
    if (!_isInitialized) return;

    AudioServiceRepeatMode repeatMode;

    switch (loopMode.value) {
      case LoopMode.off:
        loopMode.value = LoopMode.all;
        repeatMode = AudioServiceRepeatMode.all;
        break;
      case LoopMode.all:
        loopMode.value = LoopMode.one;
        repeatMode = AudioServiceRepeatMode.one;
        break;
      case LoopMode.one:
        loopMode.value = LoopMode.off;
        repeatMode = AudioServiceRepeatMode.none;
        break;
      default:
        repeatMode = AudioServiceRepeatMode.none; // Default assignment
        break;
    }

    await _audioHandler.setRepeatMode(repeatMode);
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  void onClose() {
    // Audio service will handle cleanup
    super.onClose();
  }
}
