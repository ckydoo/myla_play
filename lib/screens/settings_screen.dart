import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myla_play/controllers/settings_controller.dart';
import 'package:myla_play/controllers/music_player_controller.dart';
import 'package:myla_play/screens/equalizer_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.put(SettingsController());
    final musicController = Get.find<MusicPlayerController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Playback Section
          _buildSectionHeader('Playback', Icons.play_circle_outline),

          Obx(
            () => SwitchListTile(
              title: const Text('ReplayGain'),
              subtitle: const Text('Normalize volume across tracks'),
              value: settingsController.replayGainEnabled.value,
              onChanged: settingsController.setReplayGainEnabled,
            ),
          ),

          const Divider(),

          // Library Section
          _buildSectionHeader('Library', Icons.library_music),
          ListTile(
            title: const Text('Minimum Song Duration'),
            subtitle: Text(
              'Ignore songs shorter than ${settingsController.minSongDuration.value}s',
            ),
            trailing: Text('${settingsController.minSongDuration.value}s'),
            onTap: () => _showDurationPicker(context, settingsController),
          ),
          Obx(
            () => SwitchListTile(
              title: const Text('Auto-Scan on Startup'),
              subtitle: const Text('Automatically scan for new music'),
              value: settingsController.autoScanEnabled.value,
              onChanged: settingsController.setAutoScanEnabled,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Rescan Library'),
            subtitle: const Text('Scan for new music files'),
            onTap: () async {
              await musicController.rescanDevice();
            },
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Clean Duplicates'),
            subtitle: const Text('Remove duplicate songs'),
            onTap: () async {
              await musicController.cleanDuplicates();
            },
          ),

          const Divider(),

          // Appearance Section
          _buildSectionHeader('Appearance', Icons.palette),
          Obx(
            () => ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Theme'),
              subtitle: Text(
                _getThemeLabel(settingsController.themeMode.value),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemePicker(context, settingsController),
            ),
          ),

          const Divider(),

          // Audio Section
          _buildSectionHeader('Audio', Icons.equalizer),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Equalizer'),
            subtitle: const Text('Adjust sound frequencies'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Get.to(() => const EqualizerScreen());
            },
          ),

          const Divider(),

          // About Section
          _buildSectionHeader('About', Icons.info_outline),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text('Version ${snapshot.data!.version}');
                }
                return const Text('Loading...');
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Licenses'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'MyLa Play',
                applicationVersion: '1.0.0',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Reset Settings'),
            subtitle: const Text('Restore default settings'),
            onTap: () => _showResetDialog(context, settingsController),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
      default:
        return 'System Default';
    }
  }

  void _showThemePicker(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose Theme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('System Default'),
                  value: 'system',
                  groupValue: controller.themeMode.value,
                  onChanged: (value) {
                    controller.setThemeMode(value!);
                    Get.changeThemeMode(ThemeMode.system);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Light'),
                  value: 'light',
                  groupValue: controller.themeMode.value,
                  onChanged: (value) {
                    controller.setThemeMode(value!);
                    Get.changeThemeMode(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Dark'),
                  value: 'dark',
                  groupValue: controller.themeMode.value,
                  onChanged: (value) {
                    controller.setThemeMode(value!);
                    Get.changeThemeMode(ThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showDurationPicker(
    BuildContext context,
    SettingsController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Minimum Song Duration'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => Slider(
                    value: controller.minSongDuration.value.toDouble(),
                    min: 10,
                    max: 120,
                    divisions: 22,
                    label: '${controller.minSongDuration.value}s',
                    onChanged: (value) {
                      controller.setMinSongDuration(value.toInt());
                    },
                  ),
                ),
                Obx(() => Text('${controller.minSongDuration.value} seconds')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Settings'),
            content: const Text(
              'Are you sure you want to reset all settings to default?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }
}
