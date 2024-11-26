import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';  // kIsWeb 용

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  Widget _buildHelpSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 2,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D63EA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'Help & Tutorial',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHelpSection(
                      'Input Types',
                      [
                        'bitmap: Enter hexadecimal value (e.g., 0xf)',
                        'n-bit: Enter single bit position (e.g., 5)',
                        'n-bit list: Enter multiple bit positions (e.g., 1, 3, 5)',
                      ],
                    ),
                    _buildHelpSection(
                      'Bit Toggle Grid',
                      [
                        'Click on bits to toggle them on/off',
                        'Red highlight indicates overlapping bits',
                        'Bits are grouped by 4 for better readability',
                        'Numbers above bits show their positions',
                      ],
                    ),
                    _buildHelpSection(
                      'Features',
                      [
                        'Add multiple input forms using "Add Form"',
                        'Copy values using the copy button',
                        'Reset all forms using the reset button',
                        'Change total bits (32/64/128) as needed',
                        'Forms are automatically saved',
                      ],
                    ),
                    _buildHelpSection(
                      'Result',
                      [
                        'Shows combined result of all forms using OR operation',
                        'Displays total number of set bits',
                        'Result is shown in hexadecimal format',
                      ],
                    ),
                    if (kIsWeb) _buildHelpSection(
                      'Keyboard Shortcuts',
                      [
                        'Ctrl/Cmd + /: Open/close this help dialog',
                        'Esc: Close dialog',
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 