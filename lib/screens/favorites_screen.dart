import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/music_player_controller.dart';
import '../models/song.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicPlayerController controller = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: Obx(() {
        final favoriteSongs = controller.allSongs.where((song) => song.isFavorite).toList();

        if (favoriteSongs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No favorite songs yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap the heart icon to add songs to favorites',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    '${favoriteSongs.length} Favorite Songs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.shuffle),
                    onPressed: () {
                      if (favoriteSongs.isNotEmpty) {
                        controller.playSong(
                          favoriteSongs.first,
                          playlist: favoriteSongs,
                        );
                        controller.toggleShuffle();
                        Get.snackbar(
                          'Shuffle',
                          'Playing favorites in shuffle mode',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                        );
                      }
                    },
                    tooltip: 'Shuffle favorites',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: favoriteSongs.length,
                itemBuilder: (context, index) {
                  final song = favoriteSongs[index];
                  return _buildSongTile(context, song, controller, index);
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSongTile(BuildContext context, Song song, MusicPlayerController controller, int index) {
    return Obx(() {
      final isCurrentSong = controller.currentSong.value?.id == song.id;

      return InkWell(
        onTap: () {
          final favoriteSongs = controller.allSongs.where((s) => s.isFavorite).toList();
          controller.playSong(song, playlist: favoriteSongs);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isCurrentSong 
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                : null,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: isCurrentSong && controller.isPlaying.value
                  ? const Icon(Icons.equalizer, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            title: Text(
              song.title,
              style: TextStyle(
                fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                color: isCurrentSong 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (song.duration != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    controller.formatDuration(
                      Duration(milliseconds: song.duration!),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => controller.toggleFavorite(song),
            ),
          ),
        ),
      );
    });
  }
}
