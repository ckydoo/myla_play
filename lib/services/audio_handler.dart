import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Custom Audio Handler for background playback
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // Current playlist
  final List<MediaItem> _queue = [];
  int _currentIndex = 0;

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Listen to player state changes
    _player.playbackEventStream.listen(_broadcastState);

    // Listen to player state for auto-next
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      // Update playback state with current position
      _broadcastState(_player.playbackEvent);
    });
  }

  /// Broadcast current state to the system
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState:
            const {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ),
    );
  }

  // PLAYBACK CONTROLS

  @override
  Future<void> play() async {
    await _player.play();
    _broadcastState(_player.playbackEvent);
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastState(_player.playbackEvent);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.dispose();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await _loadAndPlay();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      // If more than 3 seconds played, restart current song
      await _player.seek(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      await _loadAndPlay();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      await _loadAndPlay();
    }
  }

  // QUEUE MANAGEMENT

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    _queue.add(mediaItem);
    queue.add(_queue);
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    _queue.addAll(mediaItems);
    queue.add(_queue);
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    _queue.remove(mediaItem);
    queue.add(_queue);
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    _queue.clear();
    _queue.addAll(newQueue);
    queue.add(_queue);
  }

  /// Custom method to load and play a specific item
  Future<void> playCustomMediaItem(
    MediaItem mediaItem,
    List<MediaItem> playlist,
  ) async {
    // Update queue
    await updateQueue(playlist);

    // Find index of the item
    _currentIndex = _queue.indexWhere((item) => item.id == mediaItem.id);
    if (_currentIndex == -1) _currentIndex = 0;

    // Load and play
    await _loadAndPlay();
  }

  /// Load current item and play
  Future<void> _loadAndPlay() async {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      final mediaItem = _queue[_currentIndex];

      // Update media item
      this.mediaItem.add(mediaItem);

      // Load audio source from file path
      try {
        // The id contains the file path
        await _player.setFilePath(mediaItem.id);
        await _player.play();
        _broadcastState(_player.playbackEvent);
      } catch (e) {
        print('Error loading media: $e');
      }
    }
  }

  // ADDITIONAL CONTROLS

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));

    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));

    if (shuffleMode == AudioServiceShuffleMode.all) {
      // Shuffle queue (keep current item at current position)
      final currentItem = _queue[_currentIndex];
      _queue.shuffle();
      final newIndex = _queue.indexOf(currentItem);
      if (newIndex != -1) {
        _currentIndex = newIndex;
      }
      queue.add(_queue);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    _broadcastState(_player.playbackEvent);
  }

  // Getters
  AudioPlayer get player => _player;
  List<MediaItem> get currentQueue => _queue;
  int get currentIndex => _currentIndex;
}
