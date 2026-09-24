import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key, required this.label, required this.onPressed,
    this.icon, this.loading = false, this.outlined = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(height: 22, width: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(label),
          ]);
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(onPressed: loading ? null : onPressed, child: child)
          : FilledButton(onPressed: loading ? null : onPressed, child: child),
    );
  }
}
