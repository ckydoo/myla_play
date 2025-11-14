import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myla_play/controllers/music_player_controller.dart';
import 'package:myla_play/models/song.dart';
import 'package:myla_play/screens/artist_screen.dart';
import 'package:path/path.dart';
import 'player_screen.dart';
import 'favorites_screen.dart';
import 'albums_screen.dart';
import 'genres_screen.dart';
import 'playlists_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicPlayerController controller = Get.find();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MyLa Play'),
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite),
              tooltip: 'Favorites',
              onPressed: () => Get.to(() => const FavoritesScreen()),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'rescan') {
                  await controller.rescanDevice();
                } else if (value == 'pick_folder') {
                  await controller.pickFolderToScan();
                } else if (value == 'pick_files') {
                  await controller.pickAudioFiles();
                } else if (value == 'clean_duplicates') {
                  await controller.cleanDuplicates();
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'rescan',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 10),
                          Text('Rescan Folders'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'pick_folder',
                      child: Row(
                        children: [
                          Icon(Icons.folder_open),
                          SizedBox(width: 10),
                          Text('Pick Music Folder'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'pick_files',
                      child: Row(
                        children: [
                          Icon(Icons.library_music),
                          SizedBox(width: 10),
                          Text('Pick Audio Files'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clean_duplicates',
                      child: Row(
                        children: [
                          Icon(Icons.cleaning_services),
                          SizedBox(width: 10),
                          Text('Clean Duplicates'),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.music_note), text: 'Songs'),
              Tab(icon: Icon(Icons.album), text: 'Albums'),
              Tab(icon: Icon(Icons.person), text: 'Artists'),
              Tab(icon: Icon(Icons.style), text: 'Genres'),
              Tab(icon: Icon(Icons.queue_music), text: 'Playlists'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSongsTab(controller),
            const AlbumsScreen(),
            const ArtistsScreen(),
            const GenresScreen(),
            const PlaylistsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsTab(MusicPlayerController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading songs...'),
            ],
          ),
        );
      }

      if (controller.allSongs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_off, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                'No audio files found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Add music by picking a folder or selecting audio files',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => controller.pickFolderToScan(),
                icon: const Icon(Icons.folder_open),
                label: const Text('Pick Music Folder'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => controller.pickAudioFiles(),
                icon: const Icon(Icons.library_music),
                label: const Text('Pick Audio Files'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => controller.rescanDevice(),
                icon: const Icon(Icons.refresh),
                label: const Text('Auto-Scan Common Folders'),
              ),
            ],
          ),
        );
      }

      // Use Builder to get a proper BuildContext
      return Builder(
        builder:
            (context) => Column(
              children: [
                // Song count header
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  child: Row(
                    children: [
                      const Icon(Icons.library_music, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${controller.allSongs.length} Songs',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.shuffle),
                        onPressed: () {
                          if (controller.allSongs.isNotEmpty) {
                            controller.toggleShuffle();
                            controller.playSong(
                              controller.currentPlaylist.first,
                            );
                            Get.snackbar(
                              'Shuffle',
                              'Playing all songs in shuffle mode',
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 2),
                            );
                          }
                        },
                        tooltip: 'Shuffle all',
                      ),
                    ],
                  ),
                ),
                // Songs list
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.allSongs.length,
                    itemBuilder: (context, index) {
                      final song = controller.allSongs[index];
                      return _buildSongTile(context, song, controller, index);
                    },
                  ),
                ),
                // Mini Player
                Obx(() {
                  if (controller.currentSong.value == null) {
                    return const SizedBox.shrink();
                  }
                  // context is already BuildContext, no need to cast
                  return _buildMiniPlayer(context, controller);
                }),
              ],
            ),
      );
    });
  }

  Widget _buildSongTile(
    BuildContext context,
    Song song,
    MusicPlayerController controller,
    int index,
  ) {
    return Obx(() {
      final isCurrentSong = controller.currentSong.value?.id == song.id;

      return InkWell(
        onTap: () => controller.playSong(song),
        child: Container(
          decoration: BoxDecoration(
            color:
                isCurrentSong
                    ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child:
                  isCurrentSong && controller.isPlaying.value
                      ? const Icon(Icons.equalizer, color: Colors.white)
                      : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
            title: Text(
              song.title,
              style: TextStyle(
                fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                color:
                    isCurrentSong
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    song.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: song.isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => controller.toggleFavorite(song),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'play') {
                      controller.playSong(song);
                    } else if (value == 'add_to_playlist') {
                      _showAddToPlaylistDialog(context, song, controller);
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
                        const PopupMenuItem(
                          value: 'add_to_playlist',
                          child: Row(
                            children: [
                              Icon(Icons.playlist_add),
                              SizedBox(width: 10),
                              Text('Add to playlist'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMiniPlayer(
    BuildContext context,
    MusicPlayerController controller,
  ) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Get.to(() => const PlayerScreen()),
        child: Column(
          children: [
            // Progress bar
            Obx(
              () => LinearProgressIndicator(
                value:
                    controller.duration.value.inMilliseconds > 0
                        ? controller.position.value.inMilliseconds /
                            controller.duration.value.inMilliseconds
                        : 0,
                minHeight: 2,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.music_note),
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
                    Obx(
                      () => IconButton(
                        icon: Icon(
                          controller.isPlaying.value
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 40,
                        ),
                        onPressed: controller.togglePlayPause,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: controller.playNext,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(
    BuildContext context,
    Song song,
    MusicPlayerController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add to Playlist'),
            content: Obx(() {
              if (controller.playlists.isEmpty) {
                return const Text('No playlists available. Create one first!');
              }

              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = controller.playlists[index];
                    return ListTile(
                      leading: const Icon(Icons.queue_music),
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.songIds.length} songs'),
                      onTap: () {
                        controller.addSongToPlaylist(playlist, song);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              );
            }),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }
}
