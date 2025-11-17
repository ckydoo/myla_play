import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  // Equalizer instance - MUST be created before AudioPlayer
  late final AndroidEqualizer _equalizer;
  late final AudioPlayer _player;
  AudioPlayer get player => _player;

  // Store equalizer parameters for UI access
  AndroidEqualizerParameters? _eqParams;

  // Current playlist
  final List<MediaItem> _queue = [];
  int _currentIndex = 0;

  MyAudioHandler() {
    // Initialize player
    _init();
  }

  Future<void> _init() async {
    try {
      // Setup player listeners
      _player.playbackEventStream.listen((event) {
        playbackState.add(
          playbackState.value.copyWith(
            playing: _player.playing,
            updatePosition: _player.position,
          ),
        );
      });
    } catch (e) {
      print('Error initializing audio handler: $e');
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  // Global initialization function
  late MyAudioHandler audioHandler;

  Future<void> initAudioService() async {
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.myla_play.audio',
        androidNotificationChannelName: 'MyLa Play',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }

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

  // ========== EQUALIZER CUSTOM ACTIONS ==========

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    switch (name) {
      case 'getEqParams':
        // Return the equalizer parameters object directly
        if (_eqParams == null) {
          _eqParams = await _equalizer.parameters;
        }
        return _eqParams;

      case 'setEqEnabled':
        final enabled = extras?['enabled'] as bool? ?? false;
        await _equalizer.setEnabled(enabled);
        return {'success': true};

      case 'setBandGain':
        final bandIdx = extras?['bandIndex'] as int? ?? 0;
        final gain = extras?['gain'] as double? ?? 0.0;

        if (_eqParams != null && bandIdx < _eqParams!.bands.length) {
          await _eqParams!.bands[bandIdx].setGain(gain);
        }
        return {'success': true};

      default:
        return super.customAction(name, extras);
    }
  }

  // ========== PLAYBACK CONTROLS ==========

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

  Future<void> _loadAndPlay() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;

    final item = _queue[_currentIndex];
    mediaItem.add(item);

    try {
      final uri = Uri.parse(item.id);
      await _player.setFilePath(uri.path);
      await _player.play();
    } catch (e) {
      print('Error loading audio: $e');
    }
  }

  // Queue management
  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    _queue.addAll(mediaItems);
    queue.add(_queue);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    _queue.removeAt(index);
    queue.add(_queue);
  }
}
