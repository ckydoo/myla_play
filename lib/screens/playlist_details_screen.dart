import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myla_play/controllers/music_player_controller.dart';
import 'package:myla_play/models/playlist.dart';
import 'package:myla_play/models/song.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Playlist header
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                playlist.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child:
                    playlist.coverArt != null
                        ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              playlist.coverArt!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildDefaultArt(),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                        : _buildDefaultArt(),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditPlaylistDialog(context, controller);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, controller);
                  } else if (value == 'add_songs') {
                    _showAddSongsDialog(context, controller);
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'add_songs',
                        child: Row(
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 10),
                            Text('Add Songs'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 10),
                            Text('Edit Info'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 10),
                            Text(
                              'Delete Playlist',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
          // Playlist info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (playlist.description != null &&
                      playlist.description!.isNotEmpty) ...[
                    Text(
                      playlist.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Text(
                        '${playlist.songIds.length} ${playlist.songIds.length == 1 ? 'song' : 'songs'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• Created ${_formatDate(playlist.createdDate)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Play buttons
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final songs = await controller.getPlaylistSongs(
                            playlist,
                          );
                          if (songs.isNotEmpty) {
                            controller.playSong(songs.first, playlist: songs);
                          }
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final songs = await controller.getPlaylistSongs(
                            playlist,
                          );
                          if (songs.isNotEmpty) {
                            controller.isShuffleEnabled.value = true;
                            controller.playSong(songs.first, playlist: songs);
                            controller.toggleShuffle();
                          }
                        },
                        icon: const Icon(Icons.shuffle),
                        label: const Text('Shuffle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                ],
              ),
            ),
          ),
          // Songs list with reordering
          SliverToBoxAdapter(
            child: FutureBuilder<List<Song>>(
              future: controller.getPlaylistSongs(playlist),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.music_off,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No songs in this playlist',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the menu to add songs',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed:
                                () => _showAddSongsDialog(context, controller),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Songs'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final songs = snapshot.data!;
                return ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: songs.length,
                  onReorder: (oldIndex, newIndex) {
                    controller.reorderPlaylistSongs(
                      playlist,
                      oldIndex,
                      newIndex,
                    );
                  },
                  itemBuilder: (context, index) {
                    return _buildSongTile(
                      context,
                      songs[index],
                      songs,
                      controller,
                      index,
                      Key('song_${songs[index].id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(
    BuildContext context,
    Song song,
    List<Song> playlistSongs,
    MusicPlayerController controller,
    int index,
    Key key,
  ) {
    return Obx(() {
      final isCurrentSong = controller.currentSong.value?.id == song.id;

      return Dismissible(
        key: key,
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Remove Song'),
                      content: Text(
                        'Remove "${song.title}" from this playlist?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Remove',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              ) ??
              false;
        },
        onDismissed: (direction) {
          if (song.id != null) {
            controller.removeSongFromPlaylist(playlist, song.id!);
          }
        },
        child: ListTile(
          key: key,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              color:
                  isCurrentSong ? Theme.of(context).colorScheme.primary : null,
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
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'play') {
                controller.playSong(song, playlist: playlistSongs);
              } else if (value == 'remove') {
                if (song.id != null) {
                  controller.removeSongFromPlaylist(playlist, song.id!);
                }
              } else if (value == 'favorite') {
                controller.toggleFavorite(song);
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'play',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow),
                        SizedBox(width: 10),
                        Text('Play'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'favorite',
                    child: Row(
                      children: [
                        Icon(
                          song.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: song.isFavorite ? Colors.red : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          song.isFavorite
                              ? 'Remove from Favorites'
                              : 'Add to Favorites',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle_outline, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          'Remove from Playlist',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
          onTap: () => controller.playSong(song, playlist: playlistSongs),
        ),
      );
    });
  }

  Widget _buildDefaultArt() {
    return const Center(
      child: Icon(Icons.queue_music, size: 100, color: Colors.white54),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showEditPlaylistDialog(
    BuildContext context,
    MusicPlayerController controller,
  ) {
    final nameController = TextEditingController(text: playlist.name);
    final descController = TextEditingController(
      text: playlist.description ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Playlist'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Playlist Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final updatedPlaylist = playlist.copyWith(
                    name: nameController.text.trim(),
                    description:
                        descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                  );
                  controller.updatePlaylist(updatedPlaylist);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    MusicPlayerController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Playlist'),
            content: Text(
              'Are you sure you want to delete "${playlist.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  controller.deletePlaylist(playlist);
                  Navigator.pop(context); // Close dialog
                  Get.back(); // Go back to playlists screen
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showAddSongsDialog(
    BuildContext context,
    MusicPlayerController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Songs to Playlist'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Obx(() {
                // Filter out songs already in playlist
                final availableSongs =
                    controller.allSongs
                        .where(
                          (song) =>
                              song.id != null &&
                              !playlist.songIds.contains(song.id),
                        )
                        .toList();

                if (availableSongs.isEmpty) {
                  return const Center(
                    child: Text('All songs are already in this playlist'),
                  );
                }

                return ListView.builder(
                  itemCount: availableSongs.length,
                  itemBuilder: (context, index) {
                    final song = availableSongs[index];
                    return CheckboxListTile(
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: false,
                      onChanged: (value) {
                        if (value == true) {
                          controller.addSongToPlaylist(playlist, song);
                        }
                      },
                    );
                  },
                );
              }),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }
}
