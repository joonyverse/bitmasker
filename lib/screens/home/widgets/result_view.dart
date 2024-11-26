import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResultView extends StatelessWidget {
  final BigInt result;
  final int totalBits;

  const ResultView({
    super.key,
    required this.result,
    required this.totalBits,
  });

  @override
  Widget build(BuildContext context) {
    final resultHex = '0x${result.toRadixString(16).toUpperCase()}';
    
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D63EA), Color(0xFF4C8DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Result',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalBits bits',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    resultHex,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: resultHex));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('결과가 클립보드에 복사되었습니다'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 