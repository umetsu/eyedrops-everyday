import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_utils.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '通知設定',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('通知を有効にする'),
                        subtitle: const Text('点眼リマインダーと忘れ通知を受け取る'),
                        value: provider.notificationsEnabled,
                        onChanged: (value) {
                          provider.setNotificationsEnabled(value);
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '通知時刻',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.schedule, color: AppColors.primary),
                        title: const Text('定時通知'),
                        subtitle: const Text('毎日の点眼を促す通知'),
                        trailing: Text(
                          AppDateUtils.formatDisplayTime(provider.dailyReminderTime),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: provider.notificationsEnabled
                            ? () => _selectTime(context, provider, true)
                            : null,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.warning, color: AppColors.accent),
                        title: const Text('忘れ通知'),
                        subtitle: const Text('前日の点眼を忘れた場合の通知'),
                        trailing: Text(
                          AppDateUtils.formatDisplayTime(provider.missedReminderTime),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: provider.notificationsEnabled
                            ? () => _selectTime(context, provider, false)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '通知について',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• 定時通知：毎日指定した時刻に点眼を促す通知が届きます\n'
                        '• 忘れ通知：前日の点眼が記録されていない場合、朝の指定時刻に通知が届きます\n'
                        '• 通知を受け取るには、端末の通知設定で本アプリの通知を許可してください',
                        style: TextStyle(
                          color: AppColors.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, SettingsProvider provider, bool isDailyReminder) async {
    final currentTime = isDailyReminder ? provider.dailyReminderTime : provider.missedReminderTime;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newTime = DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day,
        picked.hour,
        picked.minute,
      );

      if (isDailyReminder) {
        await provider.setDailyReminderTime(newTime);
      } else {
        await provider.setMissedReminderTime(newTime);
      }
    }
  }
}
