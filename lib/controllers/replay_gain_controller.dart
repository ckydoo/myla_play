import 'package:get/get.dart';
import 'package:id3/id3.dart';
import 'dart:io';
import 'dart:math';

class ReplayGainController extends GetxController {
  // ReplayGain settings
  final RxBool isEnabled = false.obs;
  final RxString mode = 'track'.obs; // 'track' or 'album'
  final RxDouble preampGain = 0.0.obs; // dB
  final RxBool preventClipping = true.obs;

  // Default target loudness (per ReplayGain spec)
  static const double targetLoudness = 89.0; // dB SPL

  // Extract ReplayGain data from audio file
  Future<ReplayGainData?> extractReplayGain(String filePath) async {
    try {
      final mp3 = MP3Instance(File(filePath).readAsBytesSync());

      if (!mp3.parseTagsSync()) {
        return null;
      }

      final tags = mp3.getMetaTags();
      if (tags == null) return null;

      // Try to extract ReplayGain tags
      // Standard tags: REPLAYGAIN_TRACK_GAIN, REPLAYGAIN_ALBUM_GAIN
      // Also check for alternative formats

      double? trackGain;
      double? albumGain;
      double? trackPeak;
      double? albumPeak;

      // Parse track gain
      if (tags.containsKey('REPLAYGAIN_TRACK_GAIN')) {
        trackGain = _parseGainValue(tags['REPLAYGAIN_TRACK_GAIN']);
      } else if (tags.containsKey('TXXX:REPLAYGAIN_TRACK_GAIN')) {
        trackGain = _parseGainValue(tags['TXXX:REPLAYGAIN_TRACK_GAIN']);
      }

      // Parse album gain
      if (tags.containsKey('REPLAYGAIN_ALBUM_GAIN')) {
        albumGain = _parseGainValue(tags['REPLAYGAIN_ALBUM_GAIN']);
      } else if (tags.containsKey('TXXX:REPLAYGAIN_ALBUM_GAIN')) {
        albumGain = _parseGainValue(tags['TXXX:REPLAYGAIN_ALBUM_GAIN']);
      }

      // Parse track peak
      if (tags.containsKey('REPLAYGAIN_TRACK_PEAK')) {
        trackPeak = _parsePeakValue(tags['REPLAYGAIN_TRACK_PEAK']);
      } else if (tags.containsKey('TXXX:REPLAYGAIN_TRACK_PEAK')) {
        trackPeak = _parsePeakValue(tags['TXXX:REPLAYGAIN_TRACK_PEAK']);
      }

      // Parse album peak
      if (tags.containsKey('REPLAYGAIN_ALBUM_PEAK')) {
        albumPeak = _parsePeakValue(tags['REPLAYGAIN_ALBUM_PEAK']);
      } else if (tags.containsKey('TXXX:REPLAYGAIN_ALBUM_PEAK')) {
        albumPeak = _parsePeakValue(tags['TXXX:REPLAYGAIN_ALBUM_PEAK']);
      }

      if (trackGain != null || albumGain != null) {
        return ReplayGainData(
          trackGain: trackGain,
          albumGain: albumGain,
          trackPeak: trackPeak,
          albumPeak: albumPeak,
        );
      }

      return null;
    } catch (e) {
      print('Error extracting ReplayGain: $e');
      return null;
    }
  }

  // Calculate volume adjustment for a song
  Future<double> calculateVolumeAdjustment(String filePath) async {
    if (!isEnabled.value) {
      return 1.0; // No adjustment
    }

    final replayGain = await extractReplayGain(filePath);
    if (replayGain == null) {
      return 1.0; // No ReplayGain data available
    }

    // Choose gain based on mode
    double? gain;
    double? peak;

    if (mode.value == 'album' && replayGain.albumGain != null) {
      gain = replayGain.albumGain;
      peak = replayGain.albumPeak;
    } else if (replayGain.trackGain != null) {
      gain = replayGain.trackGain;
      peak = replayGain.trackPeak;
    }

    if (gain == null) {
      return 1.0; // No applicable gain data
    }

    // Apply preamp gain
    double totalGain = gain + preampGain.value;

    // Convert dB to linear scale
    double volumeMultiplier = pow(10, totalGain / 20).toDouble();

    // Prevent clipping if enabled
    if (preventClipping.value && peak != null) {
      double maxGain = 1.0 / peak;
      volumeMultiplier = min(volumeMultiplier, maxGain);
    }

    // Clamp to reasonable range (0.1 to 10.0)
    return volumeMultiplier.clamp(0.1, 10.0);
  }

  // Parse gain value from string (e.g., "+2.5 dB" or "-3.2")
  double? _parseGainValue(String? value) {
    if (value == null) return null;

    try {
      // Remove "dB" and whitespace, then parse
      final cleaned = value.replaceAll(RegExp(r'[^\d.+-]'), '').trim();
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  // Parse peak value from string (e.g., "0.987654")
  double? _parsePeakValue(String? value) {
    if (value == null) return null;

    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }

  // Toggle ReplayGain
  void toggleReplayGain(bool enabled) {
    isEnabled.value = enabled;

    Get.snackbar(
      'ReplayGain',
      enabled ? 'Enabled' : 'Disabled',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  // Set mode (track or album)
  void setMode(String newMode) {
    if (newMode == 'track' || newMode == 'album') {
      mode.value = newMode;

      Get.snackbar(
        'ReplayGain Mode',
        '${newMode.capitalize} mode selected',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    }
  }

  // Set preamp gain
  void setPreampGain(double gain) {
    preampGain.value = gain.clamp(-15.0, 15.0);
  }

  // Toggle prevent clipping
  void togglePreventClipping(bool enabled) {
    preventClipping.value = enabled;
  }
}

// Data class for ReplayGain information
class ReplayGainData {
  final double? trackGain; // dB
  final double? albumGain; // dB
  final double? trackPeak; // 0.0 to 1.0
  final double? albumPeak; // 0.0 to 1.0

  ReplayGainData({
    this.trackGain,
    this.albumGain,
    this.trackPeak,
    this.albumPeak,
  });

  bool get hasTrackGain => trackGain != null;
  bool get hasAlbumGain => albumGain != null;
  bool get hasAnyGain => hasTrackGain || hasAlbumGain;

  @override
  String toString() {
    return 'ReplayGain(track: $trackGain dB, album: $albumGain dB, '
        'trackPeak: $trackPeak, albumPeak: $albumPeak)';
  }
}
