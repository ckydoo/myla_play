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
    _init();
  }

  Future<void> _init() async {
    // Step 1: Create equalizer FIRST
    _equalizer = AndroidEqualizer();
    await _equalizer.setEnabled(false);

    // Step 2: Create player with equalizer in pipeline
    _player = AudioPlayer(
      audioPipeline: AudioPipeline(androidAudioEffects: [_equalizer]),
    );

    // Step 3: Get equalizer parameters (after audio source is loaded)
    _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.ready && _eqParams == null) {
        _eqParams = await _equalizer.parameters;
      }

      // Auto-next
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });

    // Listen to player events
    _player.playbackEventStream.listen(_broadcastState);
    _player.positionStream.listen(
      (position) => _broadcastState(_player.playbackEvent),
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
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
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
