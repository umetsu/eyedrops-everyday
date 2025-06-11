import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class QuickActionButton extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onPressed;
  final bool isLoading;

  const QuickActionButton({
    super.key,
    required this.isCompleted,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                isCompleted ? Icons.undo : Icons.check,
                size: 24,
              ),
        label: Text(
          isCompleted ? '点眼を取り消す' : '点眼完了',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? AppColors.grey : AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
