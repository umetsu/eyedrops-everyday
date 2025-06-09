# eyedrops-everyday

緑内障患者向けの点眼管理アプリケーション

## 概要

eyedrops-everydayは、緑内障などにより毎日の点眼が必要な患者をサポートするFlutterアプリです。シンプルで使いやすいインターフェースで、点眼の記録管理、リマインダー機能、眼圧の履歴管理を提供します。

## 主な機能

- 📅 **点眼履歴カレンダー**: 月間カレンダーで点眼状況を視覚的に確認
- ⏰ **リマインダー通知**: 指定時刻での点眼通知
- 📊 **眼圧グラフ**: 眼圧の推移をグラフで表示
- 🎯 **シンプルUI**: 30代後半以降のユーザーに配慮した分かりやすいデザイン

## 技術スタック

- **フレームワーク**: Flutter
- **プラットフォーム**: Android (主要対象)
- **データベース**: SQLite (ローカル保存)
- **状態管理**: Provider
- **主要パッケージ**: 
  - sqflite (データベース)
  - flutter_local_notifications (通知)
  - table_calendar (カレンダーUI)
  - fl_chart (グラフ表示)

## デザインコンセプト

詳細なデザイン仕様については [SPECIFICATION.md](SPECIFICATION.md#デザイン仕様) を参照してください。

## ドキュメント

- [📋 仕様書](SPECIFICATION.md) - 詳細な機能仕様
- [🏗️ アーキテクチャ](ARCHITECTURE.md) - 技術設計とプロジェクト構造
- [📅 開発計画](DEVELOPMENT_PLAN.md) - 開発スケジュールとマイルストーン



## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照してください。
