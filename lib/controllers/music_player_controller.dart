import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
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

  @override
  void onInit() {
    super.onInit();
    _initializePlayer();
    loadSongs();
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

  // Add song to database
  Future<void> addSong(Song song) async {
    try {
      final newSong = await _dbHelper.insertSong(song);
      allSongs.add(newSong);
      currentPlaylist.add(newSong);
      Get.snackbar('Success', 'Song added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add song: $e');
    }
  }

  // Delete song
  Future<void> deleteSong(Song song) async {
    if (song.id == null) return;
    
    try {
      await _dbHelper.deleteSong(song.id!);
      allSongs.remove(song);
      currentPlaylist.remove(song);
      
      if (currentSong.value?.id == song.id) {
        stop();
        currentSong.value = null;
      }
      
      Get.snackbar('Success', 'Song deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete song: $e');
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
        currentPlaylist[playlistIndex] = song.copyWith(isFavorite: newFavoriteStatus);
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
    
    int nextIndex;
    if (isShuffleEnabled.value) {
      nextIndex = (currentIndex.value + 1) % currentPlaylist.length;
    } else {
      nextIndex = (currentIndex.value + 1) % currentPlaylist.length;
    }
    
    await playSong(currentPlaylist[nextIndex]);
  }

  // Play previous song
  Future<void> playPrevious() async {
    if (currentPlaylist.isEmpty) return;
    
    int prevIndex;
    if (position.value.inSeconds > 3) {
      // If more than 3 seconds played, restart current song
      await seek(Duration.zero);
      return;
    }
    
    prevIndex = (currentIndex.value - 1 + currentPlaylist.length) % currentPlaylist.length;
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
}
