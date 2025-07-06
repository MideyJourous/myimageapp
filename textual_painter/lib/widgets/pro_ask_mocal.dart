import 'package:flutter/material.dart';
import '../screens/pro_screen.dart';

class ProAskModal extends StatelessWidget {
  final VoidCallback? onSubscribePressed;

  const ProAskModal({
    Key? key,
    this.onSubscribePressed,
  }) : super(key: key);

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const ProAskModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Text('Upgrade to Pro!'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscribe to Pro to unlock all features!',
            style: TextStyle(fontSize: 16),
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProScreen(),
              ),
            );
            onSubscribePressed?.call();
          },
          child: const Text('테스트 모드: Pro 활성화'),
        ),
      ],
    );
  }
}
