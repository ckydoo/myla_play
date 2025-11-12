import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myla_play/models/library.dart';
import 'package:myla_play/models/song.dart';
import '../controllers/music_player_controller.dart';

class ArtistDetailScreen extends StatelessWidget {
  final Artist artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Artist header
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                artist.displayName,
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
                child: const Center(
                  child: Icon(Icons.person, size: 100, color: Colors.white54),
                ),
              ),
            ),
          ),
          // Artist info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${artist.albumCount} ${artist.albumCount == 1 ? 'album' : 'albums'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${artist.songCount} ${artist.songCount == 1 ? 'song' : 'songs'}',
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
                          final songs = await controller.getSongsByArtist(
                            artist.name,
                          );
                          if (songs.isNotEmpty) {
                            controller.playSong(songs.first, playlist: songs);
                          }
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play All'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final songs = await controller.getSongsByArtist(
                            artist.name,
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
          // Songs grouped by album
          SliverToBoxAdapter(
            child: FutureBuilder<List<Song>>(
              future: controller.getSongsByArtist(artist.name),
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
                final songsByAlbum = _groupSongsByAlbum(songs);

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: songsByAlbum.length,
                  itemBuilder: (context, index) {
                    final albumName = songsByAlbum.keys.elementAt(index);
                    final albumSongs = songsByAlbum[albumName]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            albumName.isEmpty ? 'Unknown Album' : albumName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...albumSongs.map((song) {
                          return _buildSongTile(
                            context,
                            song,
                            songs,
                            controller,
                          );
                        }),
                      ],
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

  Map<String, List<Song>> _groupSongsByAlbum(List<Song> songs) {
    final Map<String, List<Song>> grouped = {};
    for (var song in songs) {
      final albumName = song.album ?? '';
      grouped.putIfAbsent(albumName, () => []).add(song);
    }
    return grouped;
  }

  Widget _buildSongTile(
    BuildContext context,
    Song song,
    List<Song> allSongs,
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
        onTap: () => controller.playSong(song, playlist: allSongs),
      );
    });
  }
}
