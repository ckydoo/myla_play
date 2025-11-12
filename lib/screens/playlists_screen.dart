import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myla_play/models/playlist.dart';
import 'package:myla_play/screens/playlist_details_screen.dart';
import '../controllers/music_player_controller.dart';
import 'create_playlist_dialog.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlaylistDialog(context, controller),
            tooltip: 'Create Playlist',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final playlists = controller.playlists;

        if (playlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.queue_music, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No playlists yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Text(
                  'Create a playlist to organize your music',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed:
                      () => _showCreatePlaylistDialog(context, controller),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Playlist'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return _buildPlaylistTile(context, playlist, controller);
          },
        );
      }),
    );
  }

  Widget _buildPlaylistTile(
    BuildContext context,
    Playlist playlist,
    MusicPlayerController controller,
  ) {
    return Dismissible(
      key: Key('playlist_${playlist.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Delete Playlist'),
                    content: Text(
                      'Are you sure you want to delete "${playlist.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        controller.deletePlaylist(playlist);
        Get.snackbar(
          'Deleted',
          '"${playlist.name}" has been deleted',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      },
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              playlist.coverArt != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      playlist.coverArt!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              const Icon(Icons.queue_music, size: 28),
                    ),
                  )
                  : const Icon(Icons.queue_music, size: 28),
        ),
        title: Text(
          playlist.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${playlist.songIds.length} ${playlist.songIds.length == 1 ? 'song' : 'songs'}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (playlist.songIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () async {
                  final songs = await controller.getPlaylistSongs(playlist);
                  if (songs.isNotEmpty) {
                    controller.playSong(songs.first, playlist: songs);
                  }
                },
              ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  _showEditPlaylistDialog(context, controller, playlist);
                } else if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Delete Playlist'),
                          content: Text(
                            'Are you sure you want to delete "${playlist.name}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );
                  if (confirmed == true) {
                    controller.deletePlaylist(playlist);
                  }
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
        onTap: () {
          Get.to(() => PlaylistDetailScreen(playlist: playlist));
        },
      ),
    );
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    MusicPlayerController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CreatePlaylistDialog(
            onCreatePlaylist: (name, description) {
              controller.createPlaylist(name, description);
            },
          ),
    );
  }

  void _showEditPlaylistDialog(
    BuildContext context,
    MusicPlayerController controller,
    Playlist playlist,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CreatePlaylistDialog(
            initialName: playlist.name,
            initialDescription: playlist.description,
            isEditing: true,
            onCreatePlaylist: (name, description) {
              controller.updatePlaylist(
                playlist.copyWith(name: name, description: description),
              );
            },
          ),
    );
  }
}
