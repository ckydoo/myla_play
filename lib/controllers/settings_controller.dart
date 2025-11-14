import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  late SharedPreferences _prefs;

  // Observables
  final RxBool gaplessPlayback = false.obs;
  final RxBool crossfadeEnabled = false.obs;
  final RxInt crossfadeDuration = 3.obs; // seconds
  final RxBool replayGainEnabled = false.obs;
  final RxBool showAlbumArt = true.obs;
  final RxString themeMode = 'system'.obs; // system, light, dark
  final RxInt minSongDuration = 30.obs; // seconds
  final RxBool autoScanEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    gaplessPlayback.value = _prefs.getBool('gaplessPlayback') ?? false;
    crossfadeEnabled.value = _prefs.getBool('crossfadeEnabled') ?? false;
    crossfadeDuration.value = _prefs.getInt('crossfadeDuration') ?? 3;
    replayGainEnabled.value = _prefs.getBool('replayGainEnabled') ?? false;
    showAlbumArt.value = _prefs.getBool('showAlbumArt') ?? true;
    themeMode.value = _prefs.getString('themeMode') ?? 'system';
    minSongDuration.value = _prefs.getInt('minSongDuration') ?? 30;
    autoScanEnabled.value = _prefs.getBool('autoScanEnabled') ?? true;
  }

  Future<void> setGaplessPlayback(bool value) async {
    gaplessPlayback.value = value;
    await _prefs.setBool('gaplessPlayback', value);
  }

  Future<void> setCrossfadeEnabled(bool value) async {
    crossfadeEnabled.value = value;
    await _prefs.setBool('crossfadeEnabled', value);
  }

  Future<void> setCrossfadeDuration(int value) async {
    crossfadeDuration.value = value;
    await _prefs.setInt('crossfadeDuration', value);
  }

  Future<void> setReplayGainEnabled(bool value) async {
    replayGainEnabled.value = value;
    await _prefs.setBool('replayGainEnabled', value);
  }

  Future<void> setShowAlbumArt(bool value) async {
    showAlbumArt.value = value;
    await _prefs.setBool('showAlbumArt', value);
  }

  Future<void> setThemeMode(String value) async {
    themeMode.value = value;
    await _prefs.setString('themeMode', value);
  }

  Future<void> setMinSongDuration(int value) async {
    minSongDuration.value = value;
    await _prefs.setInt('minSongDuration', value);
  }

  Future<void> setAutoScanEnabled(bool value) async {
    autoScanEnabled.value = value;
    await _prefs.setBool('autoScanEnabled', value);
  }

  Future<void> resetSettings() async {
    await _prefs.clear();
    await _loadSettings();
  }
}
