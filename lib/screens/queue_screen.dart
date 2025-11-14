import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myla_play/controllers/music_player_controller.dart';
import 'package:myla_play/models/song.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _clearQueue(controller);
              } else if (value == 'save') {
                _saveQueueAsPlaylist(context, controller);
              } else if (value == 'shuffle') {
                controller.toggleShuffle();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'save',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_add),
                        SizedBox(width: 10),
                        Text('Save as Playlist'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'shuffle',
                    child: Row(
                      children: [
                        Icon(Icons.shuffle),
                        SizedBox(width: 10),
                        Text('Shuffle Queue'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          'Clear Queue',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Obx(() {
        final queue = controller.currentPlaylist;
        final currentIndex = controller.currentIndex.value;

        if (queue.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.queue_music, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'Queue is empty',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Text(
                  'Play a song to start your queue',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Queue info
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.5),
              child: Row(
                children: [
                  const Icon(Icons.queue_music, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${queue.length} songs in queue',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),

            // Now Playing section
            if (controller.currentSong.value != null)
              Container(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'NOW PLAYING',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    _buildSongTile(
                      context,
                      controller.currentSong.value!,
                      controller,
                      currentIndex,
                      isCurrentSong: true,
                    ),
                  ],
                ),
              ),

            // Up Next section
            if (currentIndex < queue.length - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'UP NEXT (${queue.length - currentIndex - 1})',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),

            // Queue list
            Expanded(
              child: ReorderableListView.builder(
                itemCount: queue.length - currentIndex - 1,
                onReorder: (oldIndex, newIndex) {
                  // Adjust indices to account for current song
                  final actualOldIndex = currentIndex + 1 + oldIndex;
                  final actualNewIndex = currentIndex + 1 + newIndex;

                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }

                  final song = queue.removeAt(actualOldIndex);
                  queue.insert(actualNewIndex, song);
                },
                itemBuilder: (context, index) {
                  final actualIndex = currentIndex + 1 + index;
                  final song = queue[actualIndex];

                  return _buildSongTile(
                    context,
                    song,
                    controller,
                    actualIndex,
                    key: Key('queue_song_${song.id}_$actualIndex'),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSongTile(
    BuildContext context,
    Song song,
    MusicPlayerController controller,
    int index, {
    Key? key,
    bool isCurrentSong = false,
  }) {
    return Dismissible(
      key: key ?? Key('song_${song.id}_$index'),
      direction:
          isCurrentSong ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        controller.currentPlaylist.removeAt(index);
      },
      child: ListTile(
        key: key,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCurrentSong)
              const Icon(Icons.drag_handle, color: Colors.grey),
            const SizedBox(width: 8),
            Container(
              width: 40,
              alignment: Alignment.center,
              child:
                  isCurrentSong && controller.isPlaying.value
                      ? const Icon(Icons.equalizer, color: Colors.blue)
                      : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ],
        ),
        title: Text(
          song.title,
          style: TextStyle(
            fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
            color: isCurrentSong ? Theme.of(context).colorScheme.primary : null,
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
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing:
            !isCurrentSong
                ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.currentPlaylist.removeAt(index);
                  },
                )
                : null,
        onTap:
            isCurrentSong
                ? null
                : () {
                  controller.playSong(
                    song,
                    playlist: controller.currentPlaylist,
                  );
                },
      ),
    );
  }

  void _clearQueue(MusicPlayerController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Queue'),
        content: const Text('Are you sure you want to clear the entire queue?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.stop();
              controller.currentPlaylist.clear();
              Get.back();
              Get.back(); // Close the queue screen
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _saveQueueAsPlaylist(
    BuildContext context,
    MusicPlayerController controller,
  ) {
    final nameController = TextEditingController(
      text: 'Queue - ${DateTime.now().toString().split(' ')[0]}',
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Save Queue as Playlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Playlist Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await controller.createPlaylist(name, 'Created from queue');
                final newPlaylist = controller.playlists.last;

                // Add all queue songs to the playlist
                for (final song in controller.currentPlaylist) {
                  if (song.id != null) {
                    await controller.addSongToPlaylist(newPlaylist, song);
                  }
                }

                Get.back();
                Get.snackbar(
                  'Success',
                  'Queue saved as "$name"',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
