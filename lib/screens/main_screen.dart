import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/providers/home_provider.dart';
import '../features/pressure/screens/pressure_chart_screen.dart';
import '../features/pressure/screens/pressure_input_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PressureChartScreen(),
  ];

  final List<String> _titles = [
    '点眼履歴',
    '眼圧',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '点眼履歴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.visibility),
            label: '眼圧履歴',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFloatingActionButton() {
    if (_currentIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          _toggleEyedropStatus();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.check),
      );
    } else {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PressureInputScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      );
    }
  }

  void _toggleEyedropStatus() {
    final homeProvider = context.read<HomeProvider>();
    final selectedDate = homeProvider.selectedDate;
    final dateString = selectedDate.toIso8601String().split('T')[0];
    
    final wasCompleted = homeProvider.isDateCompleted(selectedDate);
    
    if (homeProvider.isTestMode) {
      homeProvider.toggleEyedropStatusForTest(dateString);
    } else {
      homeProvider.toggleEyedropStatus(dateString);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(!wasCompleted ? '点眼を記録しました' : '点眼記録を取り消しました'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
