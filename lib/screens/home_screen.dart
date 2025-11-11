import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/music_player_controller.dart';
import '../models/song.dart';
import '../utils/audio_file_helper.dart';
import 'player_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicPlayerController controller = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Get.to(() => const FavoritesScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.allSongs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No songs found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _showAddSongDialog(context, controller),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Songs'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: controller.allSongs.length,
                itemBuilder: (context, index) {
                  final song = controller.allSongs[index];
                  return _buildSongTile(context, song, controller);
                },
              ),
            ),
            // Mini Player
            Obx(() {
              if (controller.currentSong.value == null) {
                return const SizedBox.shrink();
              }
              return _buildMiniPlayer(context, controller);
            }),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSongDialog(context, controller),
        child: const Icon(Icons.add),
      ),
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
              icon: Icon(
                song.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: song.isFavorite ? Colors.red : null,
              ),
              onPressed: () => controller.toggleFavorite(song),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, song, controller),
            ),
          ],
        ),
        onTap: () => controller.playSong(song),
      );
    });
  }

  Widget _buildMiniPlayer(BuildContext context, MusicPlayerController controller) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note, color: Colors.blue),
        ),
        title: Text(
          controller.currentSong.value?.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          controller.currentSong.value?.artist ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: controller.playPrevious,
            ),
            Obx(() => IconButton(
                  icon: Icon(
                    controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: controller.togglePlayPause,
                )),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: controller.playNext,
            ),
          ],
        ),
        onTap: () => Get.to(() => const PlayerScreen()),
      ),
    );
  }

  void _showAddSongDialog(BuildContext context, MusicPlayerController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Add Songs'),
        content: const Text('Choose how you want to add songs:'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final songs = await AudioFileHelper.pickAudioFiles();
              if (songs != null && songs.isNotEmpty) {
                for (var song in songs) {
                  await controller.addSong(song);
                }
                Get.snackbar(
                  'Success',
                  '${songs.length} song(s) added successfully',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Pick from Device'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _showManualAddDialog(context, controller);
            },
            child: const Text('Add Manually'),
          ),
        ],
      ),
    );
  }

  void _showManualAddDialog(BuildContext context, MusicPlayerController controller) {
    final titleController = TextEditingController();
    final artistController = TextEditingController();
    final pathController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add Song Manually'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Song Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: artistController,
                decoration: const InputDecoration(
                  labelText: 'Artist',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pathController,
                decoration: const InputDecoration(
                  labelText: 'File Path',
                  border: OutlineInputBorder(),
                  hintText: '/path/to/song.mp3',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  artistController.text.isNotEmpty &&
                  pathController.text.isNotEmpty) {
                final song = Song(
                  title: titleController.text,
                  artist: artistController.text,
                  filePath: pathController.text,
                );
                controller.addSong(song);
                Get.back();
              } else {
                Get.snackbar('Error', 'Please fill all fields');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Song song, MusicPlayerController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Are you sure you want to delete "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteSong(song);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
