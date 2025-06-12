import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/database/models/eyedrop_record.dart';
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
      final provider = context.read<HomeProvider>();
      if (provider.isLoading) {
        provider.loadRecords();
      }
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

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      locale: 'ja_JP',
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
                        weekendStyle: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                      ),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppDateUtils.isSameDay(_selectedDay, DateTime.now()) 
                              ? '今日の点眼状況' 
                              : '選択した日付',
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
                      ],
                    ),
                  ),
                ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: QuickActionButton(
                    isCompleted: provider.isDateCompleted(_selectedDay),
                    onPressed: () => _toggleSelectedDateStatus(context, provider),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleSelectedDateStatus(BuildContext context, HomeProvider provider) {
    final dateString = AppDateUtils.formatDate(_selectedDay);
    if (provider.records.isEmpty) {
      provider.toggleEyedropStatusForTest(dateString);
    } else {
      provider.toggleEyedropStatus(dateString);
    }
  }
}
