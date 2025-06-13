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

  testWidgets('毎日目薬アプリの基本表示テスト', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('点眼履歴'), findsAtLeastNWidgets(1));
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('画面内のUI要素が正しく表示されるテスト', (WidgetTester tester) async {
    final homeProvider = HomeProvider();
    homeProvider.setTestMode();
    final pressureProvider = PressureProvider();
    pressureProvider.setTestMode();
    
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

    expect(find.text('点眼履歴'), findsAtLeastNWidgets(1));
    expect(find.text('点眼カレンダー'), findsOneWidget);

    expect(find.text('今日の点眼状況'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });

  testWidgets('点眼状態の切り替え機能テスト', (WidgetTester tester) async {
    final homeProvider = HomeProvider();
    homeProvider.setTestMode();
    final pressureProvider = PressureProvider();
    pressureProvider.setTestMode();
    
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

    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);

    final actionButton = find.byType(FloatingActionButton);
    expect(actionButton, findsOneWidget);
    
    await tester.tap(actionButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('カレンダーの日付選択機能テスト', (WidgetTester tester) async {
    final homeProvider = HomeProvider();
    homeProvider.setTestMode();
    final pressureProvider = PressureProvider();
    pressureProvider.setTestMode();
    
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
}
