import 'package:flutter/material.dart';

class ProAskModal extends StatelessWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  const ProAskModal({
    Key? key,
    required this.onUpgrade,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Upgrade to Pro',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'This feature is only available for Pro users. Upgrade now to unlock:',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildFeatureList(context),
          const SizedBox(height: 24),
          _buildButtons(context),
        ],
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final features = [
      'Generate up to 50 images per day',
      'Access to all premium themes',
      'Priority image generation',
      'Advanced customization options',
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onUpgrade,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Upgrade to Pro'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onDismiss,
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Maybe Later'),
        ),
      ],
    );
  }
}
