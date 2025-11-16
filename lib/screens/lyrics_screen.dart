import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lyrics_controller.dart';
import '../controllers/music_player_controller.dart';

class LyricsScreen extends StatelessWidget {
  const LyricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lyricsController = Get.put(LyricsController());
    final musicController = Get.find<MusicPlayerController>();

    // Load lyrics when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (musicController.currentSong.value != null) {
        lyricsController.extractLyrics(
          musicController.currentSong.value!.filePath,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyrics'),
        centerTitle: true,
        actions: [
          Obx(() {
            final song = musicController.currentSong.value;
            if (song != null && !lyricsController.hasLyrics.value) {
              return IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search Online',
                onPressed: () {
                  lyricsController.searchLyricsOnline(song.title, song.artist);
                },
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        // Show loading state
        if (lyricsController.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Loading lyrics...'),
              ],
            ),
          );
        }

        // Show lyrics or empty state
        return _buildLyricsContent(context, lyricsController, musicController);
      }),
    );
  }

  Widget _buildLyricsContent(
    BuildContext context,
    LyricsController lyricsController,
    MusicPlayerController musicController,
  ) {
    return Column(
      children: [
        // Song info header
        _buildSongHeader(context, musicController),

        const Divider(),

        // Lyrics content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              if (lyricsController.hasLyrics.value) {
                return _buildLyricsText(context, lyricsController.lyrics.value);
              } else {
                return _buildNoLyricsState(context, lyricsController);
              }
            }),
          ),
        ),
      ],
    );
  }

  // Song information header
  Widget _buildSongHeader(
    BuildContext context,
    MusicPlayerController musicController,
  ) {
    return Obx(() {
      final song = musicController.currentSong.value;
      if (song == null) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Album art placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.music_note,
                size: 60,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),

            // Song title
            Text(
              song.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Artist name
            Text(
              song.artist,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    });
  }

  // Lyrics text display
  Widget _buildLyricsText(BuildContext context, String lyrics) {
    return SelectableText(
      lyrics,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(height: 1.8, fontSize: 16),
      textAlign: TextAlign.center,
    );
  }

  // No lyrics state
  Widget _buildNoLyricsState(
    BuildContext context,
    LyricsController lyricsController,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            lyricsController.lyrics.value,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Tips card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'How to add lyrics',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    '• Use a tag editor like Mp3tag or MusicBrainz Picard\n'
                    '• Add lyrics to the USLT (Unsynchronized Lyrics) frame\n'
                    '• Lyrics will automatically display here',
                    style: TextStyle(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
