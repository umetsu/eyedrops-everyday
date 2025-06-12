// 毎日目薬アプリのウィジェットテスト
//
// WidgetTesterを使用してウィジェットとのインタラクションをテストします。
// タップやスクロールジェスチャーを送信したり、ウィジェットツリー内の
// 子ウィジェットを見つけたり、テキストを読み取ったり、
// ウィジェットプロパティの値が正しいことを確認できます。

import 'package:flutter_test/flutter_test.dart';

import 'package:eyedrops_everyday/main.dart';

void main() {
  testWidgets('毎日目薬アプリの基本表示テスト', (WidgetTester tester) async {
    // アプリをビルドしてフレームをトリガー
    await tester.pumpWidget(const MyApp());

    // アプリタイトルが表示されることを確認
    expect(find.text('Eyedrops Everyday'), findsOneWidget);
    
    // ウェルカムメッセージが表示されることを確認
    expect(find.text('Welcome to Eyedrops Everyday!'), findsOneWidget);
    
    // 初期設定メッセージが表示されることを確認
    expect(find.text('This is a sample screen for Flutter initial setup.'), findsOneWidget);
    
    // 動作確認メッセージが表示されることを確認
    expect(find.text('Flutter project is working correctly!'), findsOneWidget);
  });
}
