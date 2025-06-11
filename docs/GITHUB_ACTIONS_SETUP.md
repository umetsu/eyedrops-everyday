# GitHub Actions & Firebase App Distribution 設定手順

## 概要
このドキュメントでは、GitHub ActionsからFirebase App Distributionへの自動デプロイを設定する手順を説明します。

## 前提条件
- Firebase App Distributionが有効化済み
- `google-services.json`ファイルをダウンロード済み
- Firebase Service Account Keyを作成済み

## GitHub Secrets設定

以下のSecretsをGitHubリポジトリに設定する必要があります：

### 1. GOOGLE_SERVICES_JSON
ダウンロードした`google-services.json`ファイルの内容全体を文字列として設定します。

**設定手順：**
1. `google-services.json`ファイルをテキストエディタで開く
2. ファイル内容全体をコピー
3. GitHub → Settings → Secrets and variables → Actions
4. 「New repository secret」をクリック
5. Name: `GOOGLE_SERVICES_JSON`
6. Secret: コピーしたJSON内容を貼り付け

### 2. FIREBASE_APP_ID
Firebase ConsoleのプロジェクトSettings → General → Your appsから取得できるApp IDです。

**取得手順：**
1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. プロジェクトを選択
3. プロジェクト設定（歯車アイコン）→ 全般
4. 「マイアプリ」セクションでAndroidアプリを選択
5. アプリIDをコピー（`1:`で始まる文字列）

**設定手順：**
- Name: `FIREBASE_APP_ID`
- Secret: コピーしたアプリID

### 3. FIREBASE_SERVICE_ACCOUNT_KEY
Firebase Service Account Keyの内容（JSON形式）です。

**作成・取得手順：**
1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. プロジェクト設定 → サービスアカウント
3. 「新しい秘密鍵の生成」をクリック
4. ダウンロードしたJSONファイルをテキストエディタで開く
5. ファイル内容全体をコピー

**設定手順：**
- Name: `FIREBASE_SERVICE_ACCOUNT_KEY`
- Secret: コピーしたJSON内容

## ワークフロー動作

### トリガー条件
- `main`ブランチへのpush
- `main`ブランチへのPull Request

### 実行内容
1. コードのチェックアウト
2. Java 17のセットアップ
3. Flutterのセットアップ
4. 依存関係のキャッシュ
5. `google-services.json`の復元
6. Flutter依存関係の取得
7. テストの実行
8. APKのビルド
9. Firebase App Distributionへの配布

### 配布先
- テスターグループ: `testers`
- Firebase App Distributionで事前にテスターグループを作成してください

## トラブルシューティング

### よくある問題

#### 1. `google-services.json`が見つからない
- `GOOGLE_SERVICES_JSON` Secretが正しく設定されているか確認
- JSON形式が正しいか確認

#### 2. Firebase App IDが無効
- `FIREBASE_APP_ID` Secretが正しいアプリIDか確認
- Firebase Consoleでアプリが正しく設定されているか確認

#### 3. Service Account権限エラー
- Firebase Service Account KeyにApp Distribution権限があるか確認
- Service Account KeyのJSON形式が正しいか確認

#### 4. テスターグループが見つからない
- Firebase App Distributionで`testers`グループを作成
- または、ワークフローファイルの`groups`を既存のグループ名に変更

## セキュリティ注意事項

- `google-services.json`ファイルは`.gitignore`に追加済みです
- 実際のファイルをリポジトリにコミットしないでください
- GitHub Secretsは暗号化されて保存されます
- Service Account Keyは最小限の権限で作成してください

## 参考リンク

- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Flutter CI/CD](https://docs.flutter.dev/deployment/cd)
