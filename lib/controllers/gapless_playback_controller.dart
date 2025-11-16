import 'package:just_audio/just_audio.dart';
import 'package:get/get.dart';

class GaplessPlaybackController extends GetxController {
  // Gapless playback settings
  final RxBool isGaplessEnabled = true.obs;
  final RxBool isCrossfadeEnabled = false.obs;
  final RxDouble crossfadeDuration = 3.0.obs; // seconds

  // Audio players for crossfade
  late AudioPlayer primaryPlayer;
  late AudioPlayer secondaryPlayer;
  bool usingPrimaryPlayer = true;

  @override
  void onInit() {
    super.onInit();
    _initializePlayers();
  }

  void _initializePlayers() {
    primaryPlayer = AudioPlayer();
    secondaryPlayer = AudioPlayer();

    // Enable gapless playback by default
    _configureGaplessPlayback();
  }

  // Configure gapless playback
  void _configureGaplessPlayback() {
    // just_audio handles gapless playback automatically when using playlists
    // No additional configuration needed for basic gapless playback
  }

  // Toggle gapless playback
  void toggleGapless(bool enabled) {
    isGaplessEnabled.value = enabled;

    Get.snackbar(
      'Gapless Playback',
      enabled ? 'Enabled' : 'Disabled',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  // Toggle crossfade
  void toggleCrossfade(bool enabled) {
    isCrossfadeEnabled.value = enabled;

    if (enabled) {
      Get.snackbar(
        'Crossfade',
        'Enabled (${crossfadeDuration.value.toInt()}s)',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    } else {
      Get.snackbar(
        'Crossfade',
        'Disabled',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    }
  }

  // Set crossfade duration
  void setCrossfadeDuration(double seconds) {
    crossfadeDuration.value = seconds.clamp(1.0, 10.0);
  }

  // Apply crossfade between tracks
  Future<void> applyCrossfade(
    AudioPlayer currentPlayer,
    AudioPlayer nextPlayer,
  ) async {
    if (!isCrossfadeEnabled.value) return;

    final fadeDuration = Duration(
      milliseconds: (crossfadeDuration.value * 1000).toInt(),
    );

    // Fade out current player
    final currentVolume = currentPlayer.volume;
    final fadeSteps = 20;
    final stepDuration = fadeDuration.inMilliseconds ~/ fadeSteps;

    for (int i = fadeSteps; i >= 0; i--) {
      final volume = currentVolume * (i / fadeSteps);
      await currentPlayer.setVolume(volume);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }

    // Fade in next player
    for (int i = 0; i <= fadeSteps; i++) {
      final volume = currentVolume * (i / fadeSteps);
      await nextPlayer.setVolume(volume);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }

    // Stop the faded-out player
    await currentPlayer.stop();
    await currentPlayer.setVolume(currentVolume); // Reset volume
  }

  // Create audio source with gapless configuration
  ConcatenatingAudioSource createGaplessPlaylist(List<String> filePaths) {
    return ConcatenatingAudioSource(
      useLazyPreparation: false, // Preload for gapless playback
      shuffleOrder: DefaultShuffleOrder(),
      children:
          filePaths.map((path) {
            return AudioSource.uri(Uri.file(path), tag: path);
          }).toList(),
    );
  }

  @override
  void onClose() {
    primaryPlayer.dispose();
    secondaryPlayer.dispose();
    super.onClose();
  }
}

// Extension for smooth volume transitions
extension VolumeTransition on AudioPlayer {
  Future<void> fadeVolume({
    required double targetVolume,
    required Duration duration,
  }) async {
    final currentVol = volume;
    final steps = 20;
    final stepDuration = duration.inMilliseconds ~/ steps;
    final volumeStep = (targetVolume - currentVol) / steps;

    for (int i = 0; i <= steps; i++) {
      await setVolume(currentVol + (volumeStep * i));
      await Future.delayed(Duration(milliseconds: stepDuration));
    }
  }
}
