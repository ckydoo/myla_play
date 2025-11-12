import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myla_play/models/library.dart';
import '../controllers/music_player_controller.dart';
import 'artist_detail_screen.dart';

class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Artists')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final artists = controller.artists;

        if (artists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No artists found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return _buildArtistTile(context, artist, controller);
          },
        );
      }),
    );
  }

  Widget _buildArtistTile(
    BuildContext context,
    Artist artist,
    MusicPlayerController controller,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child:
            artist.artistArt != null
                ? ClipOval(
                  child: Image.network(
                    artist.artistArt!,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person),
                  ),
                )
                : const Icon(Icons.person),
      ),
      title: Text(
        artist.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${artist.albumCount} ${artist.albumCount == 1 ? 'album' : 'albums'} • '
        '${artist.songCount} ${artist.songCount == 1 ? 'song' : 'songs'}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: () async {
          final songs = await controller.getSongsByArtist(artist.name);
          if (songs.isNotEmpty) {
            controller.playSong(songs.first, playlist: songs);
          }
        },
      ),
      onTap: () {
        Get.to(() => ArtistDetailScreen(artist: artist));
      },
    );
  }
}
