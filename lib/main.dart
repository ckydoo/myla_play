import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myla_play/controllers/music_player_controller.dart';
import 'package:myla_play/screens/home_screen.dart';

void main() {
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
    Get.put(MusicPlayerController());

    // Load existing songs from database (no permission needed)
    final controller = Get.find<MusicPlayerController>();
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
