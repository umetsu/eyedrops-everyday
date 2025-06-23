// 毎日目薬アプリのウィジェットテスト
//
// WidgetTesterを使用してウィジェットとのインタラクションをテストします。
// タップやスクロールジェスチャーを送信したり、ウィジェットツリー内の
// 子ウィジェットを見つけたり、テキストを読み取ったり、
// ウィジェットプロパティの値が正しいことを確認できます。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:eyedrops_everyday/main.dart';
import 'package:eyedrops_everyday/features/home/providers/home_provider.dart';
import 'package:eyedrops_everyday/features/pressure/providers/pressure_provider.dart';

import 'package:eyedrops_everyday/screens/main_screen.dart';
import 'package:eyedrops_everyday/shared/themes/app_theme.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // テスト間でデータベースをクリーンアップ
    sqfliteFfiInit();
  });

  testWidgets('毎日目薬アプリの基本表示テスト', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('点眼履歴'), findsAtLeastNWidgets(1));
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('画面内のUI要素が正しく表示されるテスト', (WidgetTester tester) async {
    final homeProvider = HomeProvider(testMode: true);
    final pressureProvider = PressureProvider(testMode: true);
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: homeProvider),
          ChangeNotifierProvider.value(value: pressureProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ja', 'JP'),
          ],
          theme: AppTheme.lightTheme,
          home: const MainScreen(),
        ),
      ),
    );
    
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('点眼履歴'), findsAtLeastNWidgets(1));
    expect(find.text('点眼カレンダー'), findsOneWidget);

    expect(find.text('今日の点眼状況'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });

  testWidgets('点眼状態の切り替え機能テスト', (WidgetTester tester) async {
    final homeProvider = HomeProvider(testMode: true);
    final pressureProvider = PressureProvider(testMode: true);
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: homeProvider),
          ChangeNotifierProvider.value(value: pressureProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ja', 'JP'),
          ],
          theme: AppTheme.lightTheme,
          home: const MainScreen(),
        ),
      ),
    );
    
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);

    final actionButton = find.byType(FloatingActionButton);
    expect(actionButton, findsOneWidget);
    
    await tester.tap(actionButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('カレンダーの日付選択機能テスト', (WidgetTester tester) async {
    final homeProvider = HomeProvider(testMode: true);
    final pressureProvider = PressureProvider(testMode: true);
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: homeProvider),
          ChangeNotifierProvider.value(value: pressureProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ja', 'JP'),
          ],
          theme: AppTheme.lightTheme,
          home: const MainScreen(),
        ),
      ),
    );
    
    await tester.pump();
    
    expect(find.text('点眼カレンダー'), findsOneWidget);
  });

  testWidgets('選択した日付に対する点眼状態切り替えテスト（デグレード防止）', (WidgetTester tester) async {
    final homeProvider = HomeProvider(testMode: true);
    final pressureProvider = PressureProvider(testMode: true);
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: homeProvider),
          ChangeNotifierProvider.value(value: pressureProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ja', 'JP'),
          ],
          theme: AppTheme.lightTheme,
          home: const MainScreen(),
        ),
      ),
    );
    
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // 昨日の日付を設定（今日以外の日付をテスト）
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    homeProvider.setSelectedDate(yesterday);
    await tester.pump();

    // 初期状態では昨日の点眼は未完了
    expect(homeProvider.isDateCompleted(yesterday), false);
    expect(homeProvider.isDateCompleted(DateTime.now()), false);

    // FloatingActionButtonをタップして点眼状態を切り替え
    final actionButton = find.byType(FloatingActionButton);
    expect(actionButton, findsOneWidget);
    
    await tester.tap(actionButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // データベース操作完了を待つ
    await tester.pumpAndSettle();

    // 昨日の日付の点眼状態が変更されていることを確認
    expect(homeProvider.isDateCompleted(yesterday), true);
    // 今日の日付は変更されていないことを確認（重要：デグレード防止）
    expect(homeProvider.isDateCompleted(DateTime.now()), false);
  });

  testWidgets('異なる日付選択時の点眼状態独立性テスト', (WidgetTester tester) async {
    final homeProvider = HomeProvider(testMode: true);
    final pressureProvider = PressureProvider(testMode: true);
    
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: homeProvider),
          ChangeNotifierProvider.value(value: pressureProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ja', 'JP'),
          ],
          theme: AppTheme.lightTheme,
          home: const MainScreen(),
        ),
      ),
    );
    
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // 昨日を選択して点眼状態を切り替え
    homeProvider.setSelectedDate(yesterday);
    await tester.pump();
    
    final actionButton = find.byType(FloatingActionButton);
    await tester.tap(actionButton);
    await tester.pump();
    await tester.pumpAndSettle();

    // 昨日のみ完了状態になっていることを確認
    expect(homeProvider.isDateCompleted(yesterday), true);
    expect(homeProvider.isDateCompleted(today), false);
    expect(homeProvider.isDateCompleted(twoDaysAgo), false);

    // 2日前を選択して点眼状態を切り替え
    homeProvider.setSelectedDate(twoDaysAgo);
    await tester.pump();
    
    await tester.tap(actionButton);
    await tester.pump();
    await tester.pumpAndSettle();

    // 昨日と2日前が完了状態、今日は未完了のまま
    expect(homeProvider.isDateCompleted(yesterday), true);
    expect(homeProvider.isDateCompleted(twoDaysAgo), true);
    expect(homeProvider.isDateCompleted(today), false);

    // 今日を選択して状態確認
    homeProvider.setSelectedDate(today);
    await tester.pump();
    
    // 今日は依然として未完了状態であることを確認
    expect(homeProvider.isDateCompleted(today), false);
  });

  testWidgets('notifyListeners呼び出し確認テスト', (WidgetTester tester) async {
    final homeProvider = HomeProvider(testMode: true);
    bool notified = false;
    
    homeProvider.addListener(() {
      notified = true;
    });
    
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: homeProvider,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer<HomeProvider>(
              builder: (context, provider, child) {
                return Text('Test');
              },
            ),
          ),
        ),
      ),
    );
    
    await tester.pump();
    
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    homeProvider.setSelectedDate(yesterday);
    
    expect(notified, true);
  });

  testWidgets('PressureProviderの基本機能テスト', (WidgetTester tester) async {
    final pressureProvider = PressureProvider(testMode: true);
    
    expect(pressureProvider.records, isEmpty);
    expect(pressureProvider.selectedPeriod, '1ヶ月');
    expect(pressureProvider.availablePeriods, contains('1ヶ月'));
    expect(pressureProvider.availablePeriods, contains('3ヶ月'));
    expect(pressureProvider.availablePeriods, contains('6ヶ月'));
    expect(pressureProvider.availablePeriods, contains('1年'));
  });

  testWidgets('PressureProviderの期間変更テスト', (WidgetTester tester) async {
    final pressureProvider = PressureProvider(testMode: true);
    bool notified = false;
    
    pressureProvider.addListener(() {
      notified = true;
    });
    
    await pressureProvider.loadRecordsForPeriod('3ヶ月');
    
    expect(pressureProvider.selectedPeriod, '3ヶ月');
    expect(notified, true);
  });

  testWidgets('データベースエラーハンドリングテスト', (WidgetTester tester) async {
    final homeProvider = HomeProvider(testMode: true);
    
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: homeProvider,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer<HomeProvider>(
              builder: (context, provider, child) {
                return Text('Test');
              },
            ),
          ),
        ),
      ),
    );
    
    await tester.pump();
    
    final invalidDate = '';
    await homeProvider.toggleEyedropStatus(invalidDate);
    
    expect(homeProvider.records, isNotNull);
  });
}
