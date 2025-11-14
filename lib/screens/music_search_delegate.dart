import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myla_play/controllers/music_player_controller.dart';
import 'package:myla_play/models/song.dart';

class MusicSearchDelegate extends SearchDelegate<Song?> {
  final MusicPlayerController controller;
  final List<String> recentSearches = [];

  MusicSearchDelegate(this.controller);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _searchSongs(query);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.music_note),
          ),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${song.artist}${song.album != null ? ' • ${song.album}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(
              song.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: song.isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: () => controller.toggleFavorite(song),
          ),
          onTap: () {
            _addToRecentSearches(query);
            controller.playSong(song, playlist: results);
            close(context, song);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      // Show recent searches
      return ListView.builder(
        itemCount: recentSearches.length,
        itemBuilder: (context, index) {
          final search = recentSearches[index];
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(search),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                recentSearches.removeAt(index);
              },
            ),
            onTap: () {
              query = search;
              showResults(context);
            },
          );
        },
      );
    }

    // Show suggestions based on current query
    final suggestions = _searchSongs(query).take(5).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final song = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.music_note),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            query = song.title;
            showResults(context);
          },
        );
      },
    );
  }

  List<Song> _searchSongs(String searchQuery) {
    if (searchQuery.isEmpty) return [];

    final lowerQuery = searchQuery.toLowerCase();

    return controller.allSongs.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery) ||
          (song.album?.toLowerCase().contains(lowerQuery) ?? false) ||
          (song.genre?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  void _addToRecentSearches(String search) {
    if (search.isEmpty) return;
    recentSearches.remove(search); // Remove if exists
    recentSearches.insert(0, search); // Add to beginning
    if (recentSearches.length > 10) {
      recentSearches.removeLast(); // Keep only 10 recent
    }
  }
}
