import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_utils.dart';

class DailyStatusCard extends StatelessWidget {
  final bool isCompleted;
  final DateTime date;
  final VoidCallback onTap;

  const DailyStatusCard({
    super.key,
    required this.isCompleted,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? AppColors.success : AppColors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppDateUtils.formatDisplayDate(date),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isCompleted ? '点眼済み' : '未実施',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isCompleted ? AppColors.success : AppColors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(height: 4),
                Text(
                  '今日の点眼は完了しています',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
