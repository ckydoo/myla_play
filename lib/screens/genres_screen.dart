import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myla_play/models/library.dart';
import 'package:myla_play/models/song.dart';
import '../controllers/music_player_controller.dart';

class GenresScreen extends StatelessWidget {
  const GenresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Genres')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final genres = controller.genres;

        if (genres.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No genres found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Text(
                  'Genres are detected from your music metadata',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: genres.length,
          itemBuilder: (context, index) {
            final genre = genres[index];
            return _buildGenreCard(context, genre, controller);
          },
        );
      }),
    );
  }

  Widget _buildGenreCard(
    BuildContext context,
    Genre genre,
    MusicPlayerController controller,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final songs = await controller.getSongsByGenre(genre.name);
          if (songs.isNotEmpty) {
            _showGenreSongsBottomSheet(context, genre, songs, controller);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getGenreColor(genre.name).withOpacity(0.7),
                _getGenreColor(genre.name),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_getGenreIcon(genre.name), size: 40, color: Colors.white),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      genre.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${genre.songCount} ${genre.songCount == 1 ? 'song' : 'songs'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getGenreColor(String genre) {
    // Assign colors based on genre
    final genreLower = genre.toLowerCase();
    if (genreLower.contains('rock')) return Colors.red;
    if (genreLower.contains('pop')) return Colors.pink;
    if (genreLower.contains('jazz')) return Colors.purple;
    if (genreLower.contains('classical')) return Colors.indigo;
    if (genreLower.contains('hip') || genreLower.contains('rap')) {
      return Colors.orange;
    }
    if (genreLower.contains('electronic') || genreLower.contains('edm')) {
      return Colors.cyan;
    }
    if (genreLower.contains('country')) return Colors.brown;
    if (genreLower.contains('metal')) return Colors.grey[800]!;
    if (genreLower.contains('blues')) return Colors.blue[800]!;
    if (genreLower.contains('r&b') || genreLower.contains('soul')) {
      return Colors.deepPurple;
    }
    return Colors.teal; // Default
  }

  IconData _getGenreIcon(String genre) {
    final genreLower = genre.toLowerCase();
    if (genreLower.contains('rock')) return Icons.music_note;
    if (genreLower.contains('pop')) return Icons.star;
    if (genreLower.contains('jazz')) return Icons.piano;
    if (genreLower.contains('classical')) return Icons.music_note;
    if (genreLower.contains('hip') || genreLower.contains('rap')) {
      return Icons.mic;
    }
    if (genreLower.contains('electronic') || genreLower.contains('edm')) {
      return Icons.settings_input_component;
    }
    if (genreLower.contains('country')) return Icons.landscape;
    if (genreLower.contains('metal')) return Icons.whatshot;
    return Icons.library_music;
  }

  void _showGenreSongsBottomSheet(
    BuildContext context,
    Genre genre,
    List<dynamic> songs,
    MusicPlayerController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getGenreColor(genre.name),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getGenreIcon(genre.name),
                                size: 32,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      genre.displayName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${genre.songCount} songs',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  controller.playSong(
                                    songs.first,
                                    playlist: songs.cast<Song>(),
                                  );
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Play All'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _getGenreColor(genre.name),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  controller.isShuffleEnabled.value = true;
                                  controller.playSong(
                                    songs.first,
                                    playlist: songs.cast<Song>(),
                                  );
                                  controller.toggleShuffle();
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.shuffle),
                                label: const Text('Shuffle'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Songs list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(song.title),
                          subtitle: Text(song.artist),
                          trailing: IconButton(
                            icon: Icon(
                              song.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: song.isFavorite ? Colors.red : null,
                            ),
                            onPressed: () => controller.toggleFavorite(song),
                          ),
                          onTap: () {
                            controller.playSong(
                              song,
                              playlist: songs.cast<Song>(),
                            );
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}
