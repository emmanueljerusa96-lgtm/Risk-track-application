import 'package:flutter/material.dart';

import '../utils/constants.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.message = 'Loading…'});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.teal),
            const SizedBox(height: 18),
            Text(message, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      );
}
