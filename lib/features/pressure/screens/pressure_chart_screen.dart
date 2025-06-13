import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/colors.dart';
import '../providers/pressure_provider.dart';

class PressureChartScreen extends StatefulWidget {
  const PressureChartScreen({super.key});

  @override
  State<PressureChartScreen> createState() => _PressureChartScreenState();
}

class _PressureChartScreenState extends State<PressureChartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PressureProvider>();
      provider.loadRecordsForPeriod(provider.selectedPeriod);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PressureProvider>(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '眼圧履歴',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  DropdownButton<String>(
                    value: provider.selectedPeriod,
                    items: provider.availablePeriods.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        provider.loadRecordsForPeriod(value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: _buildChart(provider),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('左目'),
                          const SizedBox(width: 24),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('右目'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (provider.records.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.visibility_off,
                            size: 64,
                            color: AppColors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '眼圧データがありません',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '下のボタンから眼圧を記録してください',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart(PressureProvider provider) {
    if (provider.records.isEmpty) {
      return Center(
        child: Text(
          'データがありません',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.grey,
          ),
        ),
      );
    }

    final leftRecords = provider.getRecordsForEye('left');
    final rightRecords = provider.getRecordsForEye('right');

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < provider.records.length) {
                  final record = provider.records[value.toInt()];
                  final date = DateTime.parse('${record.date}T00:00:00');
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.5)),
        ),
        minX: 0,
        maxX: provider.records.length.toDouble() - 1,
        minY: 0,
        maxY: 30,
        lineBarsData: [
          if (leftRecords.isNotEmpty)
            LineChartBarData(
              spots: _createSpots(leftRecords, provider.records),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          if (rightRecords.isNotEmpty)
            LineChartBarData(
              spots: _createSpots(rightRecords, provider.records),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
        ],
      ),
    );
  }

  List<FlSpot> _createSpots(List<dynamic> eyeRecords, List<dynamic> allRecords) {
    final spots = <FlSpot>[];
    final dateToIndex = <String, int>{};
    
    for (int i = 0; i < allRecords.length; i++) {
      dateToIndex[allRecords[i].date] = i;
    }

    for (final record in eyeRecords) {
      final index = dateToIndex[record.date];
      if (index != null) {
        spots.add(FlSpot(index.toDouble(), record.pressureValue));
      }
    }

    return spots;
  }
}
