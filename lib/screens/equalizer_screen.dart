import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/equalizer_controller.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EqualizerController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        actions: [
          Obx(
            () => Switch(
              value: controller.isEnabled.value,
              onChanged:
                  controller.isSupported.value
                      ? (_) => controller.toggleEnabled()
                      : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!controller.isSupported.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Equalizer Not Supported',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Your device does not support audio equalizer',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Current Preset Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Preset',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      controller.currentPreset.value?.name ?? 'Custom',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildBandSliders(controller, theme),
                    const SizedBox(height: 24),
                    _buildControlButtons(controller),
                    const SizedBox(height: 24),
                    _buildPresetsSection(controller, theme),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBandSliders(EqualizerController controller, ThemeData theme) {
    final bandCount = controller.getBandCount();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // dB Scale
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '+${controller.getMaxDb().toInt()}dB',
                  style: theme.textTheme.labelSmall,
                ),
                Text('0dB', style: theme.textTheme.labelSmall),
                Text(
                  '${controller.getMinDb().toInt()}dB',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Band Sliders
            SizedBox(
              height: 300,
              child: GetBuilder<EqualizerController>(
                builder: (ctrl) {
                  final values = ctrl.getBandValues();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      bandCount,
                      (index) => Expanded(
                        child: _buildBandSlider(
                          controller,
                          index,
                          values[index],
                          theme,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBandSlider(
    EqualizerController controller,
    int index,
    double value,
    ThemeData theme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value >= 0
              ? '+${value.toStringAsFixed(1)}'
              : value.toStringAsFixed(1),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: value,
              min: controller.getMinDb(),
              max: controller.getMaxDb(),
              divisions: 48,
              onChanged:
                  controller.isEnabled.value
                      ? (newValue) => controller.setBandGain(index, newValue)
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          controller.getFrequencyLabel(index),
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildControlButtons(EqualizerController controller) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.tonalIcon(
          onPressed: () => controller.resetBands(),
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset'),
        ),
        FilledButton.icon(
          onPressed: () => _showSavePresetDialog(controller),
          icon: const Icon(Icons.save),
          label: const Text('Save Preset'),
        ),
      ],
    );
  }

  Widget _buildPresetsSection(EqualizerController controller, ThemeData theme) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Presets',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Standard Presets
          _buildPresetCategory(controller, 'Standard', false, theme),

          const SizedBox(height: 16),

          // Custom Presets
          if (controller.presets.any((p) => p.isCustom))
            _buildPresetCategory(controller, 'Custom', true, theme),
        ],
      );
    });
  }

  Widget _buildPresetCategory(
    EqualizerController controller,
    String title,
    bool isCustom,
    ThemeData theme,
  ) {
    final categoryPresets =
        controller.presets.where((p) => p.isCustom == isCustom).toList();

    if (categoryPresets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                categoryPresets.map((preset) {
                  final isActive =
                      controller.currentPreset.value?.name == preset.name;

                  return FilterChip(
                    label: Text(preset.name),
                    selected: isActive,
                    onSelected: (_) => controller.applyPreset(preset),
                    deleteIcon:
                        preset.isCustom
                            ? const Icon(Icons.close, size: 18)
                            : null,
                    onDeleted:
                        preset.isCustom
                            ? () => _confirmDelete(controller, preset)
                            : null,
                  );
                }).toList(),
          );
        }),
      ],
    );
  }

  void _showSavePresetDialog(EqualizerController controller) {
    final nameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Save Custom Preset'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Preset Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed:
                () => controller.saveCustomPreset(nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(EqualizerController controller, preset) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Preset'),
        content: Text('Delete "${preset.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              controller.deletePreset(preset);
              Get.back();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
