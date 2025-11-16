import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sleep_timer_controller.dart';

class SleepTimerScreen extends StatelessWidget {
  const SleepTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SleepTimerController());

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Timer'), centerTitle: true),
      body: Obx(() {
        if (controller.isActive.value) {
          return _buildActiveTimer(context, controller);
        } else {
          return _buildTimerSetup(context, controller);
        }
      }),
    );
  }

  // Timer setup view
  Widget _buildTimerSetup(
    BuildContext context,
    SleepTimerController controller,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.bedtime,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Set Sleep Timer',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Music will automatically stop after the selected time',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Text(
            'Quick Presets',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildPresetGrid(controller),
          const SizedBox(height: 30),
          _buildCustomTimerButton(context, controller),
        ],
      ),
    );
  }

  // Preset duration grid
  Widget _buildPresetGrid(SleepTimerController controller) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2,
      ),
      itemCount: controller.presetMinutes.length,
      itemBuilder: (context, index) {
        final minutes = controller.presetMinutes[index];
        return _buildPresetButton(
          context,
          minutes,
          () => controller.startTimer(Duration(minutes: minutes)),
        );
      },
    );
  }

  // Individual preset button
  Widget _buildPresetButton(
    BuildContext context,
    int minutes,
    VoidCallback onTap,
  ) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final label = hours > 0 ? '${hours}h ${mins}m' : '${minutes}m';

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Custom timer button
  Widget _buildCustomTimerButton(
    BuildContext context,
    SleepTimerController controller,
  ) {
    return OutlinedButton.icon(
      onPressed: () => _showCustomTimerDialog(context, controller),
      icon: const Icon(Icons.timer),
      label: const Text('Set Custom Timer'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Active timer view
  Widget _buildActiveTimer(
    BuildContext context,
    SleepTimerController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular progress indicator
            Obx(
              () => SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: controller.progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bedtime,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          controller.formattedRemainingTime,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'remaining',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
            // Quick add time buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickAddButton(
                  context,
                  '+5m',
                  () => controller.addTime(const Duration(minutes: 5)),
                ),
                const SizedBox(width: 15),
                _buildQuickAddButton(
                  context,
                  '+10m',
                  () => controller.addTime(const Duration(minutes: 10)),
                ),
                const SizedBox(width: 15),
                _buildQuickAddButton(
                  context,
                  '+15m',
                  () => controller.addTime(const Duration(minutes: 15)),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.cancelTimer();
                  Get.back();
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Timer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quick add time button
  Widget _buildQuickAddButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  // Custom timer dialog
  void _showCustomTimerDialog(
    BuildContext context,
    SleepTimerController controller,
  ) {
    int hours = 0;
    int minutes = 30;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Custom Timer'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Hours picker
                          Column(
                            children: [
                              const Text('Hours'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed:
                                        hours > 0
                                            ? () => setState(() => hours--)
                                            : null,
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '$hours',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.headlineSmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed:
                                        hours < 12
                                            ? () => setState(() => hours++)
                                            : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Minutes picker
                          Column(
                            children: [
                              const Text('Minutes'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed:
                                        minutes > 0
                                            ? () => setState(() {
                                              minutes = (minutes - 5).clamp(
                                                0,
                                                59,
                                              );
                                            })
                                            : null,
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '$minutes',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.headlineSmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed:
                                        minutes < 59
                                            ? () => setState(() {
                                              minutes = (minutes + 5).clamp(
                                                0,
                                                59,
                                              );
                                            })
                                            : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final duration = Duration(
                          hours: hours,
                          minutes: minutes,
                        );
                        controller.startTimer(duration);
                        Navigator.pop(context);
                      },
                      child: const Text('Start'),
                    ),
                  ],
                ),
          ),
    );
  }
}
