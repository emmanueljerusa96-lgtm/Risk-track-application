import 'package:flutter/material.dart';

import '../utils/constants.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key, required this.icon, required this.title, required this.message,
    this.actionLabel, this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 36, backgroundColor: AppColors.mint,
                child: Icon(icon, color: AppColors.teal, size: 34)),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.ink,
                )),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.5)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ]),
        ),
      );
}
