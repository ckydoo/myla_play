import 'package:shared_preferences/shared_preferences.dart';

/// Audio settings for the music player
class AudioSettings {
  // Gapless playback
  bool gaplessPlayback;

  // Crossfade
  bool crossfadeEnabled;
  int crossfadeDuration; // in milliseconds (0-12000)

  // ReplayGain
  bool replayGainEnabled;
  ReplayGainMode replayGainMode;
  double replayGainPreAmp; // Pre-amplification in dB (-15 to +15)
  bool replayGainPreventClipping;

  AudioSettings({
    this.gaplessPlayback = true,
    this.crossfadeEnabled = false,
    this.crossfadeDuration = 3000, // 3 seconds default
    this.replayGainEnabled = false,
    this.replayGainMode = ReplayGainMode.track,
    this.replayGainPreAmp = 0.0,
    this.replayGainPreventClipping = true,
  });

  // Save to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gaplessPlayback', gaplessPlayback);
    await prefs.setBool('crossfadeEnabled', crossfadeEnabled);
    await prefs.setInt('crossfadeDuration', crossfadeDuration);
    await prefs.setBool('replayGainEnabled', replayGainEnabled);
    await prefs.setString('replayGainMode', replayGainMode.toString());
    await prefs.setDouble('replayGainPreAmp', replayGainPreAmp);
    await prefs.setBool('replayGainPreventClipping', replayGainPreventClipping);
  }

  // Load from SharedPreferences
  static Future<AudioSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    return AudioSettings(
      gaplessPlayback: prefs.getBool('gaplessPlayback') ?? true,
      crossfadeEnabled: prefs.getBool('crossfadeEnabled') ?? false,
      crossfadeDuration: prefs.getInt('crossfadeDuration') ?? 3000,
      replayGainEnabled: prefs.getBool('replayGainEnabled') ?? false,
      replayGainMode: _parseReplayGainMode(
        prefs.getString('replayGainMode') ?? 'track',
      ),
      replayGainPreAmp: prefs.getDouble('replayGainPreAmp') ?? 0.0,
      replayGainPreventClipping:
          prefs.getBool('replayGainPreventClipping') ?? true,
    );
  }

  static ReplayGainMode _parseReplayGainMode(String value) {
    switch (value) {
      case 'ReplayGainMode.track':
        return ReplayGainMode.track;
      case 'ReplayGainMode.album':
        return ReplayGainMode.album;
      case 'ReplayGainMode.off':
        return ReplayGainMode.off;
      default:
        return ReplayGainMode.track;
    }
  }

  AudioSettings copyWith({
    bool? gaplessPlayback,
    bool? crossfadeEnabled,
    int? crossfadeDuration,
    bool? replayGainEnabled,
    ReplayGainMode? replayGainMode,
    double? replayGainPreAmp,
    bool? replayGainPreventClipping,
  }) {
    return AudioSettings(
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      crossfadeEnabled: crossfadeEnabled ?? this.crossfadeEnabled,
      crossfadeDuration: crossfadeDuration ?? this.crossfadeDuration,
      replayGainEnabled: replayGainEnabled ?? this.replayGainEnabled,
      replayGainMode: replayGainMode ?? this.replayGainMode,
      replayGainPreAmp: replayGainPreAmp ?? this.replayGainPreAmp,
      replayGainPreventClipping:
          replayGainPreventClipping ?? this.replayGainPreventClipping,
    );
  }
}

enum ReplayGainMode {
  off, // No ReplayGain
  track, // Per-track normalization
  album, // Per-album normalization
}
