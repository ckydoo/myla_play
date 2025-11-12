import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myla_play/models/library.dart';
import 'package:myla_play/screens/artist_detail_screen.dart';
import '../controllers/music_player_controller.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Albums')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final albums = controller.albums;

        if (albums.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.album, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No albums found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return _buildAlbumCard(context, album, controller);
          },
        );
      }),
    );
  }

  Widget _buildAlbumCard(
    BuildContext context,
    Album album,
    MusicPlayerController controller,
  ) {
    return InkWell(
      onTap: () {
        Get.to(() => AlbumDetailScreen(album: album));
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[800],
                child:
                    album.albumArt != null
                        ? Image.network(
                          album.albumArt!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultArt(),
                        )
                        : _buildDefaultArt(),
              ),
            ),
            // Album info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    album.artist,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${album.songCount} ${album.songCount == 1 ? 'song' : 'songs'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultArt() {
    return const Center(
      child: Icon(Icons.album, size: 60, color: Colors.white54),
    );
  }
}
