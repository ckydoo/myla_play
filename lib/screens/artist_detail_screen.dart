import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myla_play/models/library.dart';
import 'package:myla_play/models/song.dart';
import '../controllers/music_player_controller.dart';

class AlbumDetailScreen extends StatelessWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Album header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                album.displayName,
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
              background: Stack(
                fit: StackFit.expand,
                children: [
                  album.albumArt != null
                      ? Image.network(
                        album.albumArt!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultArt(),
                      )
                      : _buildDefaultArt(),
                  // Gradient overlay
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
              ),
            ),
          ),
          // Album info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.artist,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${album.songCount} ${album.songCount == 1 ? 'song' : 'songs'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (album.year != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${album.year}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                      if (album.totalDuration != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${controller.formatDuration(Duration(milliseconds: album.totalDuration!))}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Play buttons
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final songs = await controller.getSongsByAlbum(
                            album.name,
                            album.artist,
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
                          final songs = await controller.getSongsByAlbum(
                            album.name,
                            album.artist,
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
                ],
              ),
            ),
          ),
          // Song list
          SliverToBoxAdapter(
            child: FutureBuilder<List<Song>>(
              future: controller.getSongsByAlbum(album.name, album.artist),
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
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No songs found'),
                    ),
                  );
                }

                final songs = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    return _buildSongTile(
                      context,
                      songs[index],
                      songs,
                      controller,
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
    List<Song> albumSongs,
    MusicPlayerController controller,
  ) {
    return Obx(() {
      final isCurrentSong = controller.currentSong.value?.id == song.id;

      return ListTile(
        leading: Container(
          width: 40,
          alignment: Alignment.center,
          child:
              isCurrentSong && controller.isPlaying.value
                  ? const Icon(Icons.equalizer, color: Colors.blue)
                  : Text(
                    song.trackNumber?.toString() ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
        subtitle:
            song.duration != null
                ? Text(
                  controller.formatDuration(
                    Duration(milliseconds: song.duration!),
                  ),
                )
                : null,
        trailing: IconButton(
          icon: Icon(
            song.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: song.isFavorite ? Colors.red : Colors.grey,
          ),
          onPressed: () => controller.toggleFavorite(song),
        ),
        onTap: () => controller.playSong(song, playlist: albumSongs),
      );
    });
  }

  Widget _buildDefaultArt() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.album, size: 100, color: Colors.white54),
      ),
    );
  }
}
