import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
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
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('点眼リマインダー'),
                        subtitle: const Text('指定した時刻に通知を受け取る'),
                        value: provider.notificationEnabled,
                        onChanged: (value) {
                          provider.setNotificationEnabled(value);
                        },
                        activeColor: AppColors.primary,
                      ),
                      if (provider.notificationEnabled) ...[
                        const Divider(),
                        ListTile(
                          title: const Text('通知時刻'),
                          subtitle: Text(provider.getFormattedNotificationTime()),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _showTimePicker(context, provider),
                        ),
                      ],
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
                        'スヌーズ機能について',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '通知後、以下の間隔で再通知されます：',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('• 30分後'),
                      const Text('• 15分後'),
                      const Text('• 10分後'),
                      const Text('• 5分後'),
                      const SizedBox(height: 8),
                      Text(
                        '点眼を完了すると再通知は停止されます。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey,
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

  Future<void> _showTimePicker(BuildContext context, SettingsProvider provider) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: provider.notificationTime,
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

    if (picked != null && picked != provider.notificationTime) {
      await provider.setNotificationTime(picked);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('通知時刻を${provider.getFormattedNotificationTime()}に設定しました'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
}
