// 毎日目薬アプリのウィジェットテスト
//
// WidgetTesterを使用してウィジェットとのインタラクションをテストします。
// タップやスクロールジェスチャーを送信したり、ウィジェットツリー内の
// 子ウィジェットを見つけたり、テキストを読み取ったり、
// ウィジェットプロパティの値が正しいことを確認できます。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:eyedrops_everyday/main.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('毎日目薬アプリの基本表示テスト', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Wait for initial frame without waiting for all animations to settle
    await tester.pump();
    
    // Wait a bit more for provider initialization
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('点眼履歴'), findsOneWidget);
  });
}
