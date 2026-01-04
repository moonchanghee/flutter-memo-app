import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isPending,
    required this.timeText,
  });

  final String text;
  final bool isPending;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight, // 내가 쓴 메모니까 오른쪽
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(text),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPending)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Text('분류 중...', style: TextStyle(fontSize: 11)),
                  ),
                Text(timeText, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
