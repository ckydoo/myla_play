import 'package:get/get.dart';
import 'package:id3/id3.dart';
import 'dart:io';

class LyricsController extends GetxController {
  // Current lyrics
  final RxString lyrics = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLyrics = false.obs;

  // Extract lyrics from audio file
  Future<void> extractLyrics(String filePath) async {
    isLoading.value = true;
    hasLyrics.value = false;
    lyrics.value = '';

    try {
      final mp3 = MP3Instance(File(filePath).readAsBytesSync());

      if (mp3.parseTagsSync()) {
        // Try to get unsynchronized lyrics (USLT frame)
        final tags = mp3.getMetaTags();

        if (tags != null && tags.containsKey('USLT')) {
          lyrics.value = tags['USLT'] ?? '';
          hasLyrics.value = lyrics.value.isNotEmpty;
        }
        // Also check for synchronized lyrics (SYLT frame) - though less common
        else if (tags != null && tags.containsKey('SYLT')) {
          lyrics.value = tags['SYLT'] ?? '';
          hasLyrics.value = lyrics.value.isNotEmpty;
        }
        // Check for lyrics in comments
        else if (tags != null && tags.containsKey('COMM')) {
          final comment = tags['COMM'] ?? '';
          // Sometimes lyrics are stored in comments
          if (comment.contains('\n') && comment.length > 50) {
            lyrics.value = comment;
            hasLyrics.value = true;
          }
        }
      }

      if (!hasLyrics.value) {
        lyrics.value =
            'No lyrics found in this audio file.\n\n'
            'Lyrics can be embedded in MP3 files using ID3 tags (USLT frame).';
      }
    } catch (e) {
      print('Error extracting lyrics: $e');
      lyrics.value = 'Error loading lyrics: ${e.toString()}';
      hasLyrics.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // Clear current lyrics
  void clearLyrics() {
    lyrics.value = '';
    hasLyrics.value = false;
  }

  // Search for lyrics online (placeholder for future implementation)
  Future<void> searchLyricsOnline(String title, String artist) async {
    // This would require an API integration (e.g., Genius, Musixmatch)
    // For now, just show a message
    Get.snackbar(
      'Coming Soon',
      'Online lyrics search will be available in a future update',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
