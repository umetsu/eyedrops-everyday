import 'package:flutter/material.dart';

class TimePickerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool enabled;
  final ValueChanged<String> onTimeChanged;

  const TimePickerTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.enabled,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: enabled ? null : Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.access_time,
            color: enabled ? null : Theme.of(context).disabledColor,
          ),
        ],
      ),
      enabled: enabled,
      onTap: enabled ? () => _showTimePicker(context) : null,
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final timeParts = time.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final formattedTime = 
          '${selectedTime.hour.toString().padLeft(2, '0')}:'
          '${selectedTime.minute.toString().padLeft(2, '0')}';
      onTimeChanged(formattedTime);
    }
  }
}
