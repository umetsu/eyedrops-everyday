# eyedrops-everyday 開発計画

## 開発アプローチ

### バーティカルスライス開発
機能を小さな単位に分割し、各機能について関連するUI、Provider、テストを同時に実装します。レイヤーごとではなく、機能ごとに完結させるアプローチを採用します。

### テスト駆動開発
各機能の開発時に自動テストを同時に作成し、可能な限りテスト駆動開発で進めます。

## 開発スケジュール

### Phase 1: プロジェクト基盤構築

#### 1.1 環境セットアップ
- [ ] Flutter プロジェクト初期化
- [ ] 依存関係パッケージの追加
- [ ] プロジェクト構造の作成
- [ ] Git設定とブランチ戦略の決定

#### 1.2 基本設計実装
- [ ] カラーパレット・テーマ設定
- [ ] 基本ウィジェット作成
- [ ] ナビゲーション構造の実装
- [ ] データベーススキーマの実装

#### 1.3 データレイヤー構築
- [ ] SQLite データベース初期化
- [ ] モデルクラス作成
- [ ] データベースヘルパー実装
- [ ] 基本的なCRUD操作実装
- [ ] データレイヤーのUnit テスト作成

### Phase 2: 点眼記録機能（バーティカルスライス）

#### 2.1 点眼記録の基本機能
- [ ] 点眼記録モデルの実装とテスト
- [ ] 記録作成・更新・削除機能とテスト
- [ ] 日付別記録取得機能とテスト
- [ ] HomeProvider作成とテスト
- [ ] 基本的なホーム画面UI実装
- [ ] Widget テスト作成

#### 2.2 点眼状態切替機能
- [ ] 状態切替ロジックの実装とテスト
- [ ] クイックアクションボタンUI
- [ ] 確認ダイアログ実装
- [ ] UI更新の自動化
- [ ] Integration テスト作成

### Phase 3: カレンダー履歴機能（バーティカルスライス）

#### 3.1 カレンダー表示機能
- [ ] table_calendar パッケージ統合
- [ ] カスタムカレンダーウィジェット作成とテスト
- [ ] 日付セル表示のカスタマイズ
- [ ] CalendarProvider作成とテスト
- [ ] Widget テスト作成

#### 3.2 履歴表示・編集機能
- [ ] 月間データ取得ロジックとテスト
- [ ] カレンダーへのデータ反映
- [ ] 日付選択時の詳細表示UI
- [ ] 過去データの編集機能とテスト
- [ ] Integration テスト作成

### Phase 4: 通知・リマインダー機能（バーティカルスライス）

#### 4.1 通知サービス機能
- [x] flutter_local_notifications 設定
- [x] 通知権限の取得
- [x] 定時通知の実装とテスト
- [x] 通知タップ時の処理とテスト
- [ ] NotificationService Unit テスト作成

#### 4.2 設定画面機能
- [x] 通知時刻設定UI実装
- [x] 通知ON/OFF切替機能とテスト
- [ ] スヌーズ設定（30分→15分→10分→5分）とテスト
- [x] 設定データの永続化とテスト
- [ ] Widget テスト作成
- [ ] Integration テスト作成

### Phase 5: 眼圧管理機能（バーティカルスライス）

#### 5.1 眼圧記録機能
- [ ] 眼圧記録モデル実装とテスト
- [ ] データ入力フォーム作成
- [ ] バリデーション機能とテスト
- [ ] データ保存・更新機能とテスト
- [ ] Widget テスト作成

#### 5.2 グラフ表示機能
- [ ] fl_chart パッケージ統合
- [ ] 折れ線グラフ実装とテスト
- [ ] 期間選択機能とテスト
- [ ] 統計情報表示とテスト
- [ ] PressureProvider実装とテスト
- [ ] Integration テスト作成

### Phase 6: 最終調整・統合テスト

#### 6.1 UI/UX改善
- [ ] デザインの統一性確認
- [ ] ユーザビリティテスト
- [ ] アクセシビリティ対応
- [ ] レスポンシブ対応

#### 6.2 パフォーマンス最適化
- [ ] データベースクエリ最適化
- [ ] 画面遷移の高速化
- [ ] メモリ使用量の最適化
- [ ] バッテリー消費の最適化

#### 6.3 統合テスト・品質確認
- [ ] 全機能の統合テスト
- [ ] エンドツーエンドテスト
- [ ] テストカバレッジ確認
- [ ] パフォーマンステスト

## 技術的マイルストーン

### マイルストーン 1: MVP完成
- 基本的な点眼記録機能
- シンプルなホーム画面
- データの永続化

### マイルストーン 2: カレンダー機能完成
- 月間履歴表示
- 視覚的な状況確認
- 過去データの編集

### マイルストーン 3: 通知機能完成
- 定時リマインダー
- 設定画面
- 通知管理

### マイルストーン 4: 眼圧管理完成
- 眼圧データ入力
- グラフ表示
- 統計情報

### マイルストーン 5: リリース準備完了
- 全機能統合
- テスト完了
- パフォーマンス最適化



## デプロイメント計画

### 開発環境
- **開発**: ローカル環境でのテスト
- **ステージング**: 実機でのテスト
- **本番**: Google Play Store リリース

### リリース戦略
1. **アルファ版**: 内部テスト用
2. **ベータ版**: 限定ユーザーテスト
3. **正式版**: 一般リリース
