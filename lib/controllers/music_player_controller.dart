import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myla_play/models/library.dart';
import 'package:myla_play/models/playlist.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/song.dart';
import '../database/database_helper.dart';

class MusicPlayerController extends GetxController {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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

  final RxList<Album> albums = <Album>[].obs;
  final RxList<Artist> artists = <Artist>[].obs;
  final RxList<Genre> genres = <Genre>[].obs;
  final RxList<Playlist> playlists = <Playlist>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializePlayer();
  }

  void _initializePlayer() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;

      // Auto play next song when current song ends
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((d) {
      duration.value = d ?? Duration.zero;
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((p) {
      position.value = p;
    });
  }

  Future<void> loadLibraryViews() async {
    try {
      isLoading.value = true;

      final results = await Future.wait([
        _dbHelper.getAllAlbums(),
        _dbHelper.getAllArtists(),
        _dbHelper.getAllGenres(),
        _dbHelper.getAllPlaylists(),
      ]);

      albums.value = results[0] as List<Album>;
      artists.value = results[1] as List<Artist>;
      genres.value = results[2] as List<Genre>;
      playlists.value = results[3] as List<Playlist>;

      print(
        '✅ Library loaded: ${albums.length} albums, ${artists.length} artists',
      );
    } catch (e) {
      print('❌ Error loading library views: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Scan device for audio files using directory scanning
  Future<void> scanDeviceForAudio() async {
    isLoading.value = true;

    try {
      // Request permissions
      bool permissionGranted = await _requestPermissions();

      if (!permissionGranted) {
        // Don't show error, just let user use manual options
        isLoading.value = false;
        return;
      }

      // Scan common music directories WITHOUT clearing existing songs
      await _scanMusicDirectories();

      // Remove any duplicates that may have been created
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
      // Don't show error snackbar, just log it
      // User can use manual pick options instead
    } finally {
      isLoading.value = false;
    }
  }

  // Scan common music directories
  Future<void> _scanMusicDirectories() async {
    List<String> directories = await _getMusicDirectories();

    // DON'T clear old data - just add new songs
    // await _dbHelper.clearAllSongs();

    for (String directory in directories) {
      await _scanDirectory(directory);
    }

    // Load songs from database
    await loadSongs();
  }

  // Get common music directory paths
  Future<List<String>> _getMusicDirectories() async {
    List<String> directories = [];

    if (Platform.isAndroid) {
      // Common Android music directories
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

  // Scan a directory for audio files
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
              // Get file stats
              FileStat stats = await entity.stat();

              // Skip very small files (likely corrupted or system sounds)
              if (stats.size < 100000) continue; // Skip files < 100KB

              String fileName = path.substring(path.lastIndexOf('/') + 1);
              String title = fileName.substring(0, fileName.lastIndexOf('.'));

              // Try to extract artist from folder name
              List<String> pathParts = path.split('/');
              String artist =
                  pathParts.length > 2
                      ? pathParts[pathParts.length - 2]
                      : 'Unknown Artist';

              // Clean up artist name if it looks like a system folder
              if (artist.toLowerCase().contains('music') ||
                  artist.toLowerCase().contains('download') ||
                  artist.toLowerCase().contains('storage')) {
                artist = 'Unknown Artist';
              }

              Song song = Song(
                title: title,
                artist: artist,
                filePath: path,
                duration: null, // Will be updated when played
              );

              // Insert song - will be ignored if already exists
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

  // Let user pick a folder to scan
  Future<void> pickFolderToScan() async {
    try {
      // Try to request permissions first
      await _requestPermissions();

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        isLoading.value = true;
        // Don't clear all songs, just scan the new folder
        await _scanDirectory(selectedDirectory);

        // Remove duplicates
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

  // Pick multiple audio files
  Future<void> pickAudioFiles() async {
    try {
      // Try to request permissions first
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

            // Insert song - will be ignored if already exists
            await _dbHelper.insertSong(song);
          }
        }

        // Remove duplicates
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

  // Request storage permissions
  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+)
        if (await Permission.audio.isDenied) {
          final status = await Permission.audio.request();
          if (status.isGranted) {
            return true;
          }
        }

        // For older Android versions
        if (await Permission.storage.isDenied) {
          final status = await Permission.storage.request();
          return status.isGranted;
        }

        // Check if already granted
        final audioGranted = await Permission.audio.isGranted;
        final storageGranted = await Permission.storage.isGranted;

        return audioGranted || storageGranted;
      }

      return true; // iOS handles differently
    } catch (e) {
      print('Permission request error: $e');
      // Return true to continue - user can grant manually in settings
      Get.snackbar(
        'Permission Info',
        'Please grant storage permission in Settings → Apps → MyLa Play → Permissions',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    }
  }

  // Load all songs from database
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

  // Rescan device for new audio files
  Future<void> rescanDevice() async {
    await scanDeviceForAudio();
  }

  // Remove duplicate songs manually
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

  // Toggle favorite
  Future<void> toggleFavorite(Song song) async {
    if (song.id == null) return;

    try {
      final newFavoriteStatus = !song.isFavorite;
      await _dbHelper.toggleFavorite(song.id!, newFavoriteStatus);

      // Update in all lists
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

  // Play song
  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    try {
      if (playlist != null) {
        currentPlaylist.value = playlist;
      }

      currentSong.value = song;
      currentIndex.value = currentPlaylist.indexWhere((s) => s.id == song.id);

      await _audioPlayer.setFilePath(song.filePath);
      await _audioPlayer.play();
    } catch (e) {
      Get.snackbar('Error', 'Failed to play song: $e');
    }
  }

  // Play/Pause toggle
  Future<void> togglePlayPause() async {
    if (isPlaying.value) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    position.value = Duration.zero;
  }

  // Play next song
  Future<void> playNext() async {
    if (currentPlaylist.isEmpty) return;

    int nextIndex = (currentIndex.value + 1) % currentPlaylist.length;
    await playSong(currentPlaylist[nextIndex]);
  }

  // Play previous song
  Future<void> playPrevious() async {
    if (currentPlaylist.isEmpty) return;

    if (position.value.inSeconds > 3) {
      // If more than 3 seconds played, restart current song
      await seek(Duration.zero);
      return;
    }

    int prevIndex =
        (currentIndex.value - 1 + currentPlaylist.length) %
        currentPlaylist.length;
    await playSong(currentPlaylist[prevIndex]);
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // Toggle shuffle
  void toggleShuffle() {
    isShuffleEnabled.value = !isShuffleEnabled.value;
    if (isShuffleEnabled.value) {
      currentPlaylist.shuffle();
    } else {
      currentPlaylist.value = List.from(allSongs);
    }
  }

  // Toggle repeat mode
  void toggleLoopMode() {
    switch (loopMode.value) {
      case LoopMode.off:
        loopMode.value = LoopMode.all;
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        loopMode.value = LoopMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        loopMode.value = LoopMode.off;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
  }

  // Format duration
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
    _audioPlayer.dispose();
    super.onClose();
  }

  // Albums
  Future<List<Song>> getSongsByAlbum(
    String albumName,
    String artistName,
  ) async {
    return await _dbHelper.getSongsByAlbum(albumName, artistName);
  }

  // Artists
  Future<List<Song>> getSongsByArtist(String artistName) async {
    return await _dbHelper.getSongsByArtist(artistName);
  }

  // Genres
  Future<List<Song>> getSongsByGenre(String genreName) async {
    return await _dbHelper.getSongsByGenre(genreName);
  }

  // Playlists
  Future<List<Song>> getPlaylistSongs(Playlist playlist) async {
    return await _dbHelper.getPlaylistSongs(playlist);
  }

  Future<void> createPlaylist(String name, String? description) async {
    final playlist = Playlist(name: name, description: description);
    final created = await _dbHelper.createPlaylist(playlist);
    playlists.add(created);

    Get.snackbar(
      'Success',
      'Playlist "${created.name}" created',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    await _dbHelper.updatePlaylist(playlist);
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      playlists[index] = playlist;
    }
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    if (playlist.id != null) {
      await _dbHelper.deletePlaylist(playlist.id!);
      playlists.remove(playlist);
    }
  }

  Future<void> addSongToPlaylist(Playlist playlist, Song song) async {
    if (song.id == null || playlist.songIds.contains(song.id)) return;

    final updatedPlaylist = playlist.copyWith(
      songIds: [...playlist.songIds, song.id!],
    );
    await updatePlaylist(updatedPlaylist);
  }

  Future<void> removeSongFromPlaylist(Playlist playlist, int songId) async {
    final updatedPlaylist = playlist.copyWith(
      songIds: playlist.songIds.where((id) => id != songId).toList(),
    );
    await updatePlaylist(updatedPlaylist);
  }

  /// Reorder songs in a playlist
  Future<void> reorderPlaylistSongs(
    Playlist playlist,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      final songIds = List<int>.from(playlist.songIds);

      // Adjust newIndex if necessary
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final item = songIds.removeAt(oldIndex);
      songIds.insert(newIndex, item);

      final updatedPlaylist = playlist.copyWith(songIds: songIds);
      await updatePlaylist(updatedPlaylist);
    } catch (e) {
      print('Error reordering playlist songs: $e');
      Get.snackbar('Error', 'Failed to reorder songs: $e');
    }
  }
}
