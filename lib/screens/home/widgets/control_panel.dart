import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../widgets/custom_dropdown.dart';

class ControlPanel extends StatelessWidget {
  final int selectedBitCount;
  final Function(int) onBitCountChanged;
  final VoidCallback onAddForm;
  final VoidCallback onReset;
  final bool isMobile;

  const ControlPanel({
    super.key,
    required this.selectedBitCount,
    required this.onBitCountChanged,
    required this.onAddForm,
    required this.onReset,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isMobile
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomDropdown<int>(
                          value: selectedBitCount,
                          items: AppConstants.availableBitCounts,
                          prefix: 'Total Bits:',
                          labelBuilder: (value) => '$value',
                          onChanged: (value) {
                            if (value != null) {
                              onBitCountChanged(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: onReset,
                        tooltip: 'Reset all forms',
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onAddForm,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add Form'),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  CustomDropdown<int>(
                    value: selectedBitCount,
                    items: AppConstants.availableBitCounts,
                    prefix: 'Total Bits:',
                    labelBuilder: (value) => '$value',
                    onChanged: (value) {
                      if (value != null) {
                        onBitCountChanged(value);
                      }
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onReset,
                    tooltip: 'Reset all forms',
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onAddForm,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Form'),
                  ),
                ],
              ),
      ),
    );
  }
} 