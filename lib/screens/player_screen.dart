import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/music_player_controller.dart';
import 'package:just_audio/just_audio.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicPlayerController controller = Get.find();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final song = controller.currentSong.value;
        if (song == null) {
          return const Center(
            child: Text(
              'No song playing',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Album Art
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildDefaultArt(),
                ),
              ),

              // Song Info
              Column(
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.artist,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (song.album != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      song.album!,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),

              // Progress Bar
              Column(
                children: [
                  Obx(() => Slider(
                        value: controller.position.value.inSeconds.toDouble(),
                        max: controller.duration.value.inSeconds.toDouble() > 0
                            ? controller.duration.value.inSeconds.toDouble()
                            : 1.0,
                        onChanged: (value) {
                          controller.seek(Duration(seconds: value.toInt()));
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveColor: Colors.grey[700],
                      )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() => Text(
                              controller.formatDuration(controller.position.value),
                              style: TextStyle(color: Colors.grey[400]),
                            )),
                        Obx(() => Text(
                              controller.formatDuration(controller.duration.value),
                              style: TextStyle(color: Colors.grey[400]),
                            )),
                      ],
                    ),
                  ),
                ],
              ),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle
                  Obx(() => IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: controller.isShuffleEnabled.value
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[400],
                        ),
                        iconSize: 28,
                        onPressed: controller.toggleShuffle,
                      )),

                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    iconSize: 40,
                    onPressed: controller.playPrevious,
                  ),

                  // Play/Pause
                  Obx(() => Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            controller.isPlaying.value
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          iconSize: 40,
                          onPressed: controller.togglePlayPause,
                        ),
                      )),

                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    iconSize: 40,
                    onPressed: controller.playNext,
                  ),

                  // Repeat
                  Obx(() {
                    Color color = Colors.grey[400]!;
                    IconData icon = Icons.repeat;

                    if (controller.loopMode.value == LoopMode.all) {
                      color = Theme.of(context).colorScheme.primary;
                    } else if (controller.loopMode.value == LoopMode.one) {
                      color = Theme.of(context).colorScheme.primary;
                      icon = Icons.repeat_one;
                    }

                    return IconButton(
                      icon: Icon(icon, color: color),
                      iconSize: 28,
                      onPressed: controller.toggleLoopMode,
                    );
                  }),
                ],
              ),

              // Additional Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      song.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: song.isFavorite ? Colors.red : Colors.grey[400],
                    ),
                    iconSize: 30,
                    onPressed: () => controller.toggleFavorite(song),
                  ),
                  IconButton(
                    icon: Icon(Icons.playlist_play, color: Colors.grey[400]),
                    iconSize: 30,
                    onPressed: () {
                      Get.back();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDefaultArt() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.music_note,
          size: 100,
          color: Colors.white54,
        ),
      ),
    );
  }
}
