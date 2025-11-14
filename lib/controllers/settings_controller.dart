import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  // Audio Settings
  final RxBool gaplessPlaybackEnabled = false.obs;
  final RxInt crossfadeDuration = 0.obs;
  final RxBool replayGainEnabled = false.obs;

  // Library Settings
  final RxInt minSongDuration = 30.obs;
  final RxBool autoScanEnabled = false.obs;

  // Appearance Settings
  final RxString themeMode = 'system'.obs;
  final RxBool showMiniPlayer = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    gaplessPlaybackEnabled.value = prefs.getBool('gaplessPlayback') ?? false;
    crossfadeDuration.value = prefs.getInt('crossfadeDuration') ?? 0;
    replayGainEnabled.value = prefs.getBool('replayGain') ?? false;
    minSongDuration.value = prefs.getInt('minSongDuration') ?? 30;
    autoScanEnabled.value = prefs.getBool('autoScan') ?? false;
    themeMode.value = prefs.getString('themeMode') ?? 'system';
    showMiniPlayer.value = prefs.getBool('showMiniPlayer') ?? true;
  }

  Future<void> setGaplessPlayback(bool value) async {
    gaplessPlaybackEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gaplessPlayback', value);
  }

  Future<void> setCrossfadeDuration(int value) async {
    crossfadeDuration.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('crossfadeDuration', value);
  }

  Future<void> setReplayGainEnabled(bool value) async {
    replayGainEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('replayGain', value);
  }

  Future<void> setMinSongDuration(int value) async {
    minSongDuration.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('minSongDuration', value);
  }

  Future<void> setAutoScanEnabled(bool value) async {
    autoScanEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoScan', value);
  }

  Future<void> setThemeMode(String value) async {
    themeMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', value);
  }

  Future<void> setShowMiniPlayer(bool value) async {
    showMiniPlayer.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showMiniPlayer', value);
  }
}
