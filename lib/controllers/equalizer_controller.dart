import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../controllers/music_player_controller.dart';
import '../database/database_helper.dart';
import '../models/library.dart';

class EqualizerController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Observables
  final RxBool isEnabled = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSupported = false.obs;

  // Equalizer data
  AndroidEqualizerParameters? _params;
  final RxList<EqualizerPreset> presets = <EqualizerPreset>[].obs;
  final Rx<EqualizerPreset?> currentPreset = Rx<EqualizerPreset?>(null);

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeEqualizer();
    await loadPresets();
  }

  Future<void> _initializeEqualizer() async {
    isLoading.value = true;
    try {
      final musicController = Get.find<MusicPlayerController>();

      // Get equalizer parameters from audio handler
      _params =
          await musicController.audioHandler.customAction('getEqParams')
              as AndroidEqualizerParameters?;

      if (_params != null && _params!.bands.isNotEmpty) {
        isSupported.value = true;
      }
    } catch (e) {
      print('Equalizer not supported: $e');
      isSupported.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // Load presets from database
  Future<void> loadPresets() async {
    try {
      final dbPresets = await _dbHelper.getAllEqPresets();
      presets.value = dbPresets;

      // Set Flat as default
      if (currentPreset.value == null && presets.isNotEmpty) {
        final flatPreset = presets.firstWhere(
          (p) => p.name == 'Flat',
          orElse: () => presets.first,
        );
        currentPreset.value = flatPreset;
      }
    } catch (e) {
      print('Error loading presets: $e');
    }
  }

  // Get current band values
  List<double> getBandValues() {
    if (_params == null) return List.filled(10, 0.0);
    return _params!.bands.map((band) => band.gain).toList();
  }

  // Get band count
  int getBandCount() {
    return _params?.bands.length ?? 0;
  }

  // Get min/max decibels
  double getMinDb() => _params?.minDecibels ?? -12.0;
  double getMaxDb() => _params?.maxDecibels ?? 12.0;

  // Get frequency label for band
  String getFrequencyLabel(int index) {
    if (_params == null || index >= _params!.bands.length) return '?';

    final freq = _params!.bands[index].centerFrequency;
    if (freq >= 1000) {
      return '${(freq / 1000).toStringAsFixed(freq % 1000 == 0 ? 0 : 1)}k';
    }
    return '${freq.toInt()}';
  }

  // Set band gain
  Future<void> setBandGain(int index, double gain) async {
    if (_params == null || index >= _params!.bands.length) return;

    try {
      final musicController = Get.find<MusicPlayerController>();
      await musicController.audioHandler.customAction('setBandGain', {
        'bandIndex': index,
        'gain': gain,
      });

      // Clear current preset
      currentPreset.value = null;
      update(); // Refresh UI
    } catch (e) {
      print('Error setting band gain: $e');
    }
  }

  // Toggle equalizer
  Future<void> toggleEnabled() async {
    try {
      final musicController = Get.find<MusicPlayerController>();
      isEnabled.value = !isEnabled.value;

      await musicController.audioHandler.customAction('setEqEnabled', {
        'enabled': isEnabled.value,
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to toggle equalizer');
      print('Error toggling equalizer: $e');
    }
  }

  // Apply preset
  Future<void> applyPreset(EqualizerPreset preset) async {
    if (_params == null) return;

    try {
      final musicController = Get.find<MusicPlayerController>();

      // Apply each band value
      for (
        int i = 0;
        i < preset.bandValues.length && i < _params!.bands.length;
        i++
      ) {
        await musicController.audioHandler.customAction('setBandGain', {
          'bandIndex': i,
          'gain': preset.bandValues[i],
        });
      }

      currentPreset.value = preset;
      update();

      Get.snackbar(
        'Equalizer',
        'Applied preset: ${preset.name}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to apply preset');
    }
  }

  // Reset all bands
  Future<void> resetBands() async {
    final flatPreset = presets.firstWhere(
      (p) => p.name == 'Flat',
      orElse: () => presets.first,
    );
    await applyPreset(flatPreset);
  }

  // Save custom preset
  Future<void> saveCustomPreset(String name) async {
    if (name.trim().isEmpty) {
      Get.snackbar('Error', 'Preset name cannot be empty');
      return;
    }

    if (presets.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      Get.snackbar('Error', 'A preset with this name already exists');
      return;
    }

    try {
      final bandValues = getBandValues();
      final preset = EqualizerPreset(
        name: name,
        bandValues: bandValues,
        isCustom: true,
      );

      await _dbHelper.saveEqPreset(preset);
      await loadPresets();

      final savedPreset = presets.firstWhere((p) => p.name == name);
      currentPreset.value = savedPreset;

      Get.back();
      Get.snackbar(
        'Success',
        'Custom preset "$name" saved',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to save preset');
    }
  }

  // Delete preset
  Future<void> deletePreset(EqualizerPreset preset) async {
    if (!preset.isCustom) {
      Get.snackbar('Error', 'Cannot delete standard presets');
      return;
    }

    try {
      await _dbHelper.deleteEqPreset(preset.name);
      presets.remove(preset);

      if (currentPreset.value?.name == preset.name) {
        await resetBands();
      }

      Get.snackbar(
        'Success',
        'Preset "${preset.name}" deleted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete preset');
    }
  }
}
