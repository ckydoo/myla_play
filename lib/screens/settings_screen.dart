import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../controllers/gapless_playback_controller.dart';
import '../controllers/replay_gain_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final gaplessController = Get.put(GaplessPlaybackController());
    final replayGainController = Get.put(ReplayGainController());

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          // Audio Playback Section
          _buildSectionHeader(context, 'Audio Playback'),

          // Gapless Playback
          Obx(
            () => SwitchListTile(
              title: const Text('Gapless Playback'),
              subtitle: const Text('Seamless transitions between tracks'),
              value: gaplessController.isGaplessEnabled.value,
              onChanged: gaplessController.toggleGapless,
              secondary: const Icon(Icons.compare_arrows),
            ),
          ),

          // Crossfade
          Obx(
            () => SwitchListTile(
              title: const Text('Crossfade'),
              subtitle: Text(
                gaplessController.isCrossfadeEnabled.value
                    ? 'Fade duration: ${gaplessController.crossfadeDuration.value.toInt()}s'
                    : 'Smooth fade between tracks',
              ),
              value: gaplessController.isCrossfadeEnabled.value,
              onChanged: gaplessController.toggleCrossfade,
              secondary: const Icon(Icons.blur_on),
            ),
          ),

          // Crossfade duration slider
          Obx(() {
            if (!gaplessController.isCrossfadeEnabled.value) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crossfade Duration',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Slider(
                    value: gaplessController.crossfadeDuration.value,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label:
                        '${gaplessController.crossfadeDuration.value.toInt()}s',
                    onChanged: gaplessController.setCrossfadeDuration,
                  ),
                ],
              ),
            );
          }),

          const Divider(),

          // ReplayGain Section
          _buildSectionHeader(context, 'ReplayGain (Volume Normalization)'),

          Obx(
            () => SwitchListTile(
              title: const Text('Enable ReplayGain'),
              subtitle: const Text('Normalize volume across tracks'),
              value: replayGainController.isEnabled.value,
              onChanged: replayGainController.toggleReplayGain,
              secondary: const Icon(Icons.volume_up),
            ),
          ),

          // ReplayGain Mode
          Obx(() {
            if (!replayGainController.isEnabled.value) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Track Mode'),
                  subtitle: const Text('Normalize each track independently'),
                  value: 'track',
                  groupValue: replayGainController.mode.value,
                  onChanged: (value) => replayGainController.setMode(value!),
                ),
                RadioListTile<String>(
                  title: const Text('Album Mode'),
                  subtitle: const Text('Normalize based on album gain'),
                  value: 'album',
                  groupValue: replayGainController.mode.value,
                  onChanged: (value) => replayGainController.setMode(value!),
                ),
              ],
            );
          }),

          // Preamp Gain
          Obx(() {
            if (!replayGainController.isEnabled.value) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preamp Gain: ${replayGainController.preampGain.value.toStringAsFixed(1)} dB',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Slider(
                    value: replayGainController.preampGain.value,
                    min: -15.0,
                    max: 15.0,
                    divisions: 60,
                    label:
                        '${replayGainController.preampGain.value.toStringAsFixed(1)} dB',
                    onChanged: replayGainController.setPreampGain,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          }),

          // Prevent Clipping
          Obx(() {
            if (!replayGainController.isEnabled.value) {
              return const SizedBox.shrink();
            }

            return SwitchListTile(
              title: const Text('Prevent Clipping'),
              subtitle: const Text('Limit volume to avoid distortion'),
              value: replayGainController.preventClipping.value,
              onChanged: replayGainController.togglePreventClipping,
            );
          }),

          const Divider(),

          // Library Section
          _buildSectionHeader(context, 'Library'),

          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Music Folder'),
            subtitle: Obx(
              () => Text(
                settingsController.musicDirectory.value.isEmpty
                    ? 'Not set'
                    : settingsController.musicDirectory.value,
              ),
            ),
            onTap: () {
              // Open folder picker
              Get.snackbar(
                'Music Folder',
                'Feature coming soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Rescan Library'),
            subtitle: const Text('Update music collection'),
            onTap: () {
              Get.back();
              // Trigger rescan from music controller
              Get.snackbar(
                'Library Scan',
                'Scanning for new music...',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),

          const Divider(),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),

          Obx(
            () => SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: settingsController.isDarkMode.value,
              onChanged: settingsController.toggleDarkMode,
              secondary: const Icon(Icons.dark_mode),
            ),
          ),

          const Divider(),

          // About Section
          _buildSectionHeader(context, 'About'),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),

          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Open Source Licenses'),
            onTap: () {
              showLicensePage(context: context);
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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
}
