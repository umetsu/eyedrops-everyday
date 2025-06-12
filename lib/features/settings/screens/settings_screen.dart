import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/notification_setting.dart';
import '../widgets/time_picker_tile.dart';

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
                      NotificationSetting(
                        title: '通知を有効にする',
                        value: provider.notificationEnabled,
                        onChanged: (value) {
                          provider.setNotificationEnabled(value);
                        },
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
                      TimePickerTile(
                        title: '定時通知',
                        subtitle: '毎日の点眼リマインダー',
                        time: provider.dailyReminderTime,
                        enabled: provider.notificationEnabled,
                        onTimeChanged: (time) {
                          provider.setDailyReminderTime(time);
                        },
                      ),
                      const Divider(),
                      TimePickerTile(
                        title: '点眼忘れ通知',
                        subtitle: '前日の点眼を忘れた場合の通知',
                        time: provider.forgetReminderTime,
                        enabled: provider.notificationEnabled,
                        onTimeChanged: (time) {
                          provider.setForgetReminderTime(time);
                        },
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
                      Text(
                        '• 定時通知：指定した時刻に毎日通知されます\n'
                        '• スヌーズ機能：30分、15分、10分、5分後に再通知\n'
                        '• 点眼忘れ通知：前日の点眼記録がない場合のみ通知',
                        style: Theme.of(context).textTheme.bodyMedium,
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
}
