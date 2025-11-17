import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_service/audio_service.dart';
import 'package:myla_play/controllers/equalizer_controller.dart';
import 'package:myla_play/controllers/gapless_playback_controller.dart';
import 'package:myla_play/controllers/music_player_controller.dart';
import 'package:myla_play/controllers/replay_gain_controller.dart';
import 'package:myla_play/controllers/settings_controller.dart';
import 'package:myla_play/controllers/sleep_timer_controller.dart';
import 'package:myla_play/screens/home_screen.dart';
import 'package:myla_play/services/audio_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MyLa Play',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize the MusicPlayerController
    Get.put(GaplessPlaybackController());
    Get.put(ReplayGainController());
    print("gapless playback controller initialized");
    Get.put(MusicPlayerController());
    Get.put(SleepTimerController());

    // Load existing songs from database (no permission needed)
    final controller = Get.find<MusicPlayerController>();
    Get.put(SettingsController());
    // Initialize Equalizer
    Get.put(EqualizerController());
    await controller.loadSongs();

    // NEW: Load library views (Albums, Artists, Genres, Playlists)
    await controller.loadLibraryViews();

    // Small delay to ensure Activity is ready
    await Future.delayed(const Duration(milliseconds: 500));

    // Try to auto-scan only if no songs exist
    if (controller.allSongs.isEmpty) {
      await controller.scanDeviceForAudio();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

// You'll need to create this AudioPlayerHandler class
class AudioPlayerHandler extends BaseAudioHandler {
  // Implement the required methods for audio_service
  // This is a basic implementation - you'll need to expand it based on your needs

  AudioPlayerHandler() {
    // Initialize your audio player here
  }

  @override
  Future<void> play() async {
    // Implement play functionality
  }

  @override
  Future<void> pause() async {
    // Implement pause functionality
  }

  @override
  Future<void> stop() async {
    // Implement stop functionality
  }
}
