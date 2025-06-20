# eyedrops-everyday アーキテクチャ設計

## プロジェクト構造

```
lib/
├── main.dart                 # アプリケーションエントリーポイント
├── core/                     # コア機能
│   ├── constants/
│   │   └── colors.dart       # カラーパレット定義
│   ├── database/
│   │   ├── database_helper.dart  # SQLite操作
│   │   └── models/
│   │       ├── eyedrop_record.dart
│   │       └── pressure_record.dart
│   ├── services/
│   │   ├── notification_service.dart  # 通知管理
│   │   └── settings_service.dart      # 設定データ永続化
│   └── utils/
│       └── date_utils.dart    # 日付操作ユーティリティ
├── features/                 # 機能別モジュール
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   └── providers/
│   │       └── home_provider.dart
│   ├── pressure/
│   │   ├── screens/
│   │   │   ├── pressure_input_screen.dart
│   │   │   └── pressure_chart_screen.dart
│   │   └── providers/
│   │       └── pressure_provider.dart
│   └── settings/
│       ├── screens/
│       │   └── settings_screen.dart
│       └── providers/
│           └── settings_provider.dart
├── screens/                  # メイン画面
│   └── main_screen.dart      # ナビゲーション統合画面
└── shared/                   # 共通コンポーネント
    └── themes/
        └── app_theme.dart
```

## 実装済みコンポーネント

### データレイヤー
- **DatabaseHelper**: SQLite操作の中核クラス
- **EyedropRecord**: 点眼記録データモデル
- **PressureRecord**: 眼圧記録データモデル

### サービスレイヤー
- **NotificationService**: ローカル通知管理（定時・忘れ通知）
- **SettingsService**: SharedPreferencesによる設定永続化

### プロバイダー（状態管理）
- **HomeProvider**: 点眼記録とカレンダー状態管理
- **PressureProvider**: 眼圧データとグラフ状態管理
- **SettingsProvider**: 通知設定と時刻管理

### UI コンポーネント
- **MainScreen**: BottomNavigationBarによる画面切替
- **HomeScreen**: table_calendarによるカレンダー表示
- **PressureChartScreen**: fl_chartによるグラフ表示
- **PressureInputScreen**: 眼圧データ入力フォーム
- **SettingsScreen**: 通知設定画面

## アーキテクチャパターン

### Provider + MVVM パターン
- **Model**: データクラス（core/database/models/）
- **View**: 画面・ウィジェット（features/*/screens/, features/*/widgets/）
- **ViewModel**: Provider クラス（features/*/providers/）

### レイヤー構造
1. **Presentation Layer**: UI コンポーネント
2. **Business Logic Layer**: Provider クラス
3. **Data Layer**: データベース、ローカルストレージ

## データフロー

```
UI (Screen/Widget)
    ↓ ユーザーアクション
Provider (ViewModel)
    ↓ データ操作
Service Layer
    ↓ データ永続化
SQLite Database
```

## 状態管理

### Provider パターンの採用理由
- シンプルで学習コストが低い
- Flutterチームが推奨
- 小〜中規模アプリに適している
- テストしやすい

### 状態の種類
- **アプリケーション状態**: 設定情報、通知設定
- **画面状態**: 選択された日付、入力フォームの値
- **データ状態**: 点眼記録、眼圧記録

## データベース設計

### テーブル設計

#### eyedrop_records テーブル
```sql
CREATE TABLE eyedrop_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL UNIQUE,  -- YYYY-MM-DD形式
    completed BOOLEAN NOT NULL DEFAULT 0,
    completed_at TEXT,          -- ISO8601形式のタイムスタンプ
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
```

#### pressure_records テーブル
```sql
CREATE TABLE pressure_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,         -- YYYY-MM-DD形式
    pressure_value REAL NOT NULL,  -- mmHg単位
    eye_type TEXT NOT NULL,     -- 'left', 'right', 'both'
    measured_at TEXT NOT NULL,  -- ISO8601形式のタイムスタンプ
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
```

#### app_settings テーブル
```sql
CREATE TABLE app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
```

### インデックス設計
```sql
CREATE INDEX idx_eyedrop_records_date ON eyedrop_records(date);
CREATE INDEX idx_pressure_records_date ON pressure_records(date);
CREATE INDEX idx_pressure_records_measured_at ON pressure_records(measured_at);
```

## 通知システム

通知機能の詳細仕様については [SPECIFICATION.md](SPECIFICATION.md#3-リマインダー機能) を参照してください。

### アーキテクチャ上の考慮事項
- `NotificationService` クラスで通知管理を一元化
- `flutter_local_notifications` パッケージを使用
- 設定変更時の通知スケジュール更新

## セキュリティ考慮事項

### データ保護
- ローカルストレージのみ使用
- 外部通信なし
- 個人情報の最小化

### プライバシー
- ユーザー識別情報なし
- 位置情報使用なし
- カメラ・マイクアクセスなし

## パフォーマンス最適化

### データベース最適化
- 適切なインデックス設定
- クエリの最適化
- 不要なデータの定期削除

### UI最適化
- 画像の最適化
- 不要な再描画の防止
- メモリリークの防止

## テスト戦略

### テストの種類
1. **Unit Test**: ビジネスロジック、ユーティリティ関数
2. **Widget Test**: 個別ウィジェットの動作
3. **Integration Test**: 画面遷移、データフロー

### テスト対象
- Provider クラスのロジック
- データベース操作
- 日付計算ロジック
- バリデーション機能

## 依存関係管理

### 主要パッケージ
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5           # 状態管理
  sqflite: ^2.3.0           # ローカルデータベース
  flutter_local_notifications: ^19.2.1  # プッシュ通知
  table_calendar: ^3.0.9    # カレンダーUI
  fl_chart: ^0.66.0         # グラフ表示
  shared_preferences: ^2.2.2  # 設定保存
  intl: ^0.20.2             # 国際化・日付フォーマット
  timezone: ^0.10.1         # タイムゾーン管理
  path: ^1.8.3              # パス操作
  cupertino_icons: ^1.0.2   # iOS風アイコン
  flutter_localizations:    # ローカライゼーション
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  sqflite_common_ffi: ^2.3.0  # テスト用SQLite
  flutter_lints: ^6.0.0    # Lint ルール
```

## ビルド・デプロイ

### ビルド設定
- **Debug**: 開発用、デバッグ情報付き
- **Profile**: パフォーマンステスト用
- **Release**: 本番用、最適化済み

### APK署名
- リリース用キーストアの管理
- 署名設定の自動化

## 今後の技術的課題

### スケーラビリティ
- データ量増加への対応
- 機能追加時の設計拡張性

### メンテナンス性
- コードの可読性向上
- ドキュメント整備
- 自動テストの充実
