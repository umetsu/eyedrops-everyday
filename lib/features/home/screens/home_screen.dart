import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_utils.dart';
import '../providers/home_provider.dart';
import '../widgets/daily_status_card.dart';
import '../widgets/quick_action_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('点眼履歴'),
        centerTitle: true,
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DailyStatusCard(
                  isCompleted: provider.isDateCompleted(DateTime.now()),
                  date: DateTime.now(),
                  onTap: () => _toggleTodayStatus(context, provider),
                ),
                const SizedBox(height: 16),
                QuickActionButton(
                  isCompleted: provider.isDateCompleted(DateTime.now()),
                  onPressed: () => _toggleTodayStatus(context, provider),
                ),
                const SizedBox(height: 24),
                Text(
                  '点眼カレンダー',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TableCalendar<EyedropRecord>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        todayDecoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 1,
                      ),
                      eventLoader: (day) {
                        if (provider.isDateCompleted(day)) {
                          return [EyedropRecord(
                            date: AppDateUtils.formatDate(day),
                            completed: true,
                            createdAt: '',
                            updatedAt: '',
                          )];
                        }
                        return [];
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        provider.setSelectedDate(selectedDay);
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                        provider.loadRecordsForMonth(focusedDay);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!AppDateUtils.isSameDay(_selectedDay, DateTime.now())) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '選択した日付',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                provider.isDateCompleted(_selectedDay)
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: provider.isDateCompleted(_selectedDay)
                                    ? AppColors.success
                                    : AppColors.grey,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppDateUtils.formatDisplayDate(_selectedDay),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.isDateCompleted(_selectedDay) ? '点眼済み' : '未実施',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: provider.isDateCompleted(_selectedDay)
                                  ? AppColors.success
                                  : AppColors.grey,
                            ),
                          ),
                          if (_selectedDay.isBefore(DateTime.now())) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _toggleDateStatus(context, provider, _selectedDay),
                                child: Text(
                                  provider.isDateCompleted(_selectedDay)
                                      ? '点眼を取り消す'
                                      : '点眼済みにする',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleTodayStatus(BuildContext context, HomeProvider provider) {
    final today = AppDateUtils.formatDate(DateTime.now());
    provider.toggleEyedropStatus(today);
  }

  void _toggleDateStatus(BuildContext context, HomeProvider provider, DateTime date) {
    final dateString = AppDateUtils.formatDate(date);
    provider.toggleEyedropStatus(dateString);
  }
}
