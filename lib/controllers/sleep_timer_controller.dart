import 'dart:async';
import 'package:get/get.dart';
import 'music_player_controller.dart';

class SleepTimerController extends GetxController {
  final MusicPlayerController _musicController = Get.find();

  // Timer state
  final RxBool isActive = false.obs;
  final Rx<Duration> remainingTime = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;

  Timer? _countdownTimer;

  // Preset durations (in minutes)
  final List<int> presetMinutes = [5, 10, 15, 20, 30, 45, 60, 90, 120];

  // Start sleep timer
  void startTimer(Duration duration) {
    // Cancel existing timer if any
    cancelTimer();

    totalDuration.value = duration;
    remainingTime.value = duration;
    isActive.value = true;

    // Start countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime.value.inSeconds <= 0) {
        _onTimerComplete();
      } else {
        remainingTime.value = Duration(
          seconds: remainingTime.value.inSeconds - 1,
        );
      }
    });

    Get.snackbar(
      'Sleep Timer Started',
      'Music will stop in ${_formatDuration(duration)}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  // Cancel timer
  void cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    isActive.value = false;
    remainingTime.value = Duration.zero;
    totalDuration.value = Duration.zero;
  }

  // Add time to existing timer
  void addTime(Duration duration) {
    if (isActive.value) {
      remainingTime.value = Duration(
        seconds: remainingTime.value.inSeconds + duration.inSeconds,
      );
      totalDuration.value = Duration(
        seconds: totalDuration.value.inSeconds + duration.inSeconds,
      );

      Get.snackbar(
        'Time Added',
        '+${_formatDuration(duration)}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    }
  }

  // Timer completion handler
  void _onTimerComplete() {
    cancelTimer();
    _musicController.pause();

    Get.snackbar(
      'Sleep Timer',
      'Music stopped - Sweet dreams! 😴',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  // Format duration for display
  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Get formatted remaining time
  String get formattedRemainingTime {
    return _formatDuration(remainingTime.value);
  }

  // Get progress (0.0 to 1.0)
  double get progress {
    if (totalDuration.value.inSeconds == 0) return 0.0;
    return 1.0 -
        (remainingTime.value.inSeconds / totalDuration.value.inSeconds);
  }

  @override
  void onClose() {
    cancelTimer();
    super.onClose();
  }
}
