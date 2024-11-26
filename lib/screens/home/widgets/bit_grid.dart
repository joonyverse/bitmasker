import 'package:flutter/material.dart';
import '../../../models/bit_input_form.dart';

class BitGrid extends StatelessWidget {
  final BitInputForm form;
  final int formIndex;
  final Function(int) onToggle;
  final bool Function(int, int) isOverlapping;
  final bool isMobile;

  const BitGrid({
    super.key,
    required this.form,
    required this.formIndex,
    required this.onToggle,
    required this.isOverlapping,
    required this.isMobile,
  });

  int _calculateBitsPerRow(double width) {
    if (width < 300) return 4;
    if (width < 400) return 8;
    if (width < 600) return 12;
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bitsPerRow = _calculateBitsPerRow(constraints.maxWidth);
        final rows = (form.bitCount / bitsPerRow).ceil();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int row = 0; row < rows; row++) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isMobile ? 32 : 40,
                    padding: EdgeInsets.only(right: isMobile ? 2 : 4),
                    child: Text(
                      '[${form.bitCount - 1 - row * bitsPerRow}]',
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        color: Colors.grey.shade600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  ...List.generate(
                    bitsPerRow,
                    (col) {
                      if (col > 0 && col % 4 == 0) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: isMobile ? 4 : 8),
                            _buildBitToggle(row, col, bitsPerRow),
                          ],
                        );
                      }
                      return _buildBitToggle(row, col, bitsPerRow);
                    },
                  ),
                ],
              ),
              if (row < rows - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBitToggle(int row, int col, int bitsPerRow) {
    final bitIndex = form.bitCount - 1 - (row * bitsPerRow + col);
    if (bitIndex < 0) return const SizedBox.shrink();
    
    final isSelected = form.bits[bitIndex];
    final isOverlappingBit = isOverlapping(formIndex, bitIndex);

    return Column(
      children: [
        Text(
          '$bitIndex',
          style: TextStyle(
            fontSize: isMobile ? 9 : 10,
            color: Colors.grey.shade600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        GestureDetector(
          onTap: () => onToggle(bitIndex),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: isMobile ? const EdgeInsets.all(4) : EdgeInsets.zero,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(2),
              width: isMobile ? 32 : 28,
              height: isMobile ? 32 : 28,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? (isOverlappingBit
                          ? Colors.red.shade400
                          : const Color(0xFF2D63EA))
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? (isOverlappingBit
                        ? Colors.red.shade50
                        : const Color(0xFFEEF3FF))
                    : Colors.white,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: isOverlappingBit
                              ? Colors.red.withOpacity(0.1)
                              : const Color(0xFF2D63EA).withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  isSelected ? '1' : '0',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? (isOverlappingBit
                            ? Colors.red.shade700
                            : const Color(0xFF2D63EA))
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 