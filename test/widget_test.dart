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
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:eyedrops_everyday/main.dart';
import 'package:eyedrops_everyday/features/home/providers/home_provider.dart';
import 'package:eyedrops_everyday/features/home/screens/home_screen.dart';
import 'package:eyedrops_everyday/features/home/widgets/quick_action_button.dart';
import 'package:eyedrops_everyday/shared/themes/app_theme.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('毎日目薬アプリの基本表示テスト', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('点眼履歴'), findsOneWidget);
  });

  testWidgets('画面内のUI要素が正しく表示されるテスト', (WidgetTester tester) async {
    final provider = HomeProvider();
    provider.setTestMode();
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
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
          home: const HomeScreen(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();

    expect(find.text('点眼履歴'), findsOneWidget);
    expect(find.text('点眼カレンダー'), findsOneWidget);

    expect(find.text('今日の点眼状況'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);

    expect(find.byType(QuickActionButton), findsOneWidget);

    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });

  testWidgets('点眼状態の切り替え機能テスト', (WidgetTester tester) async {
    final provider = HomeProvider();
    provider.setTestMode();
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
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
          home: const HomeScreen(),
        ),
      ),
    );
    
    await tester.pump();

    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(find.text('未実施'), findsOneWidget);

    final actionButton = find.byType(QuickActionButton);
    expect(actionButton, findsOneWidget);
    
    await tester.tap(actionButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(find.text('点眼を取り消す'), findsOneWidget);

    await tester.tap(actionButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(find.text('未実施'), findsOneWidget);
  });

  testWidgets('カレンダーの日付選択機能テスト', (WidgetTester tester) async {
    final provider = HomeProvider();
    provider.setTestMode();
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
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
          home: const HomeScreen(),
        ),
      ),
    );
    
    await tester.pump();

    expect(find.byType(TableCalendar), findsOneWidget);
    expect(find.text('今日の点眼状況'), findsOneWidget);
  });
}
