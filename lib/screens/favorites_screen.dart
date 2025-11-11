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

        return ListView.builder(
          itemCount: favoriteSongs.length,
          itemBuilder: (context, index) {
            final song = favoriteSongs[index];
            return _buildSongTile(context, song, controller);
          },
        );
      }),
    );
  }

  Widget _buildSongTile(BuildContext context, Song song, MusicPlayerController controller) {
    return Obx(() {
      final isCurrentSong = controller.currentSong.value?.id == song.id;

      return ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: song.albumArt != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    song.albumArt!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.music_note),
                  ),
                )
              : const Icon(Icons.music_note, color: Colors.blue),
        ),
        title: Text(
          song.title,
          style: TextStyle(
            fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
            color: isCurrentSong ? Colors.blue : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentSong && controller.isPlaying.value)
              const Icon(Icons.equalizer, color: Colors.blue),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => controller.toggleFavorite(song),
            ),
          ],
        ),
        onTap: () {
          final favoriteSongs = controller.allSongs.where((s) => s.isFavorite).toList();
          controller.playSong(song, playlist: favoriteSongs);
        },
      );
    });
  }
}
