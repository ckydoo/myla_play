import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/music_player_controller.dart';
import '../models/audio_settings.dart';

class AudioSettingsScreen extends StatefulWidget {
  const AudioSettingsScreen({super.key});

  @override
  State<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends State<AudioSettingsScreen> {
  final controller = Get.find<MusicPlayerController>();
  late AudioSettings settings;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    settings = await AudioSettings.load();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await settings.save();

    // Update audio handler
    await controller.audioHandler.customAction('updateAudioSettings', {
      'gaplessPlayback': settings.gaplessPlayback,
      'crossfadeEnabled': settings.crossfadeEnabled,
      'crossfadeDuration': settings.crossfadeDuration,
      'replayGainEnabled': settings.replayGainEnabled,
      'replayGainMode': settings.replayGainMode,
      'replayGainPreAmp': settings.replayGainPreAmp,
      'replayGainPreventClipping': settings.replayGainPreventClipping,
    });

    Get.snackbar(
      'Success',
      'Audio settings saved',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Audio Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: ListView(
        children: [
          // Gapless Playback Section
          _buildSectionHeader('Gapless Playback'),
          SwitchListTile(
            title: const Text('Enable Gapless Playback'),
            subtitle: const Text(
              'Seamless transitions between tracks with no silence',
            ),
            value: settings.gaplessPlayback,
            onChanged: (value) {
              setState(() {
                settings = settings.copyWith(gaplessPlayback: value);
              });
            },
          ),
          const Divider(),

          // Crossfade Section
          _buildSectionHeader('Crossfade'),
          SwitchListTile(
            title: const Text('Enable Crossfade'),
            subtitle: const Text('Smooth fade between songs'),
            value: settings.crossfadeEnabled,
            onChanged: (value) {
              setState(() {
                settings = settings.copyWith(crossfadeEnabled: value);
              });
            },
          ),
          if (settings.crossfadeEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Crossfade Duration'),
                      Text(
                        '${(settings.crossfadeDuration / 1000).toStringAsFixed(1)}s',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.crossfadeDuration.toDouble(),
                    min: 1000,
                    max: 12000,
                    divisions: 11,
                    label:
                        '${(settings.crossfadeDuration / 1000).toStringAsFixed(1)}s',
                    onChanged: (value) {
                      setState(() {
                        settings = settings.copyWith(
                          crossfadeDuration: value.toInt(),
                        );
                      });
                    },
                  ),
                  Text(
                    'Adjust how long the transition between songs lasts',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
          const Divider(),

          // ReplayGain Section
          _buildSectionHeader('ReplayGain (Volume Normalization)'),
          SwitchListTile(
            title: const Text('Enable ReplayGain'),
            subtitle: const Text('Normalize volume across different songs'),
            value: settings.replayGainEnabled,
            onChanged: (value) {
              setState(() {
                settings = settings.copyWith(replayGainEnabled: value);
              });
            },
          ),

          if (settings.replayGainEnabled) ...[
            ListTile(
              title: const Text('ReplayGain Mode'),
              subtitle: Text(_getReplayGainModeDescription()),
            ),
            RadioListTile<ReplayGainMode>(
              title: const Text('Track Gain'),
              subtitle: const Text('Normalize each song individually'),
              value: ReplayGainMode.track,
              groupValue: settings.replayGainMode,
              onChanged: (value) {
                setState(() {
                  settings = settings.copyWith(replayGainMode: value);
                });
              },
            ),
            RadioListTile<ReplayGainMode>(
              title: const Text('Album Gain'),
              subtitle: const Text('Preserve album dynamics'),
              value: ReplayGainMode.album,
              groupValue: settings.replayGainMode,
              onChanged: (value) {
                setState(() {
                  settings = settings.copyWith(replayGainMode: value);
                });
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pre-Amplification'),
                      Text(
                        '${settings.replayGainPreAmp >= 0 ? "+" : ""}${settings.replayGainPreAmp.toStringAsFixed(1)} dB',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.replayGainPreAmp,
                    min: -15,
                    max: 15,
                    divisions: 60,
                    label:
                        '${settings.replayGainPreAmp >= 0 ? "+" : ""}${settings.replayGainPreAmp.toStringAsFixed(1)} dB',
                    onChanged: (value) {
                      setState(() {
                        settings = settings.copyWith(replayGainPreAmp: value);
                      });
                    },
                  ),
                  Text(
                    'Additional volume adjustment applied to all tracks',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            SwitchListTile(
              title: const Text('Prevent Clipping'),
              subtitle: const Text('Limit volume to prevent audio distortion'),
              value: settings.replayGainPreventClipping,
              onChanged: (value) {
                setState(() {
                  settings = settings.copyWith(
                    replayGainPreventClipping: value,
                  );
                });
              },
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'About ReplayGain',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ReplayGain analyzes audio files and stores volume adjustment values in metadata. '
                        'This ensures consistent playback volume across your music library. '
                        'Songs without ReplayGain tags will play at normal volume.',
                        style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  String _getReplayGainModeDescription() {
    switch (settings.replayGainMode) {
      case ReplayGainMode.track:
        return 'Each track plays at the same perceived loudness';
      case ReplayGainMode.album:
        return 'Preserves volume relationships within albums';
      case ReplayGainMode.off:
        return 'ReplayGain disabled';
    }
  }
}
