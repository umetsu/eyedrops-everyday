# キーストア設定手順

## 1. キーストアファイルの作成

```bash
# android/keystoreディレクトリでキーストアを作成
cd android/keystore
keytool -genkey -v -keystore release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
```

作成時に以下の情報を入力してください：
- キーストアパスワード（安全に保管）
- キーパスワード（安全に保管）
- 組織情報（適宜入力）

## 2. GitHub Secretsの設定

リポジトリの Settings > Secrets and variables > Actions で以下のSecretsを追加：

- `KEYSTORE_BASE64`: キーストアファイルをBase64エンコードした文字列
  ```bash
  base64 -i android/keystore/release.keystore | tr -d '\n'
  ```
- `KEYSTORE_PASSWORD`: キーストアのパスワード
- `KEY_ALIAS`: キーのエイリアス（通常は "release"）
- `KEY_PASSWORD`: キーのパスワード

## 3. ローカルビルド用設定

`android/key.properties`ファイルを作成（.gitignoreに含まれているため安全）：

```
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=release
storeFile=../keystore/release.keystore
```

## 4. ビルドコマンド

```bash
# 開発版（デバッグ署名）
flutter build apk --release --flavor dev

# 本番版（リリース署名）
flutter build apk --release --flavor prod
```

## 5. アプリケーションID

各フレーバーで以下のアプリケーションIDが生成されます：

- 開発版: `jp.umeg.eyedrops_everyday.dev`
- 本番版: `jp.umeg.eyedrops_everyday`

## 6. 注意事項

- **キーストアファイルは絶対に紛失しないよう安全に保管してください**
- **GitHub Secretsの設定が完了するまでCI/CDは失敗します**
- **既存ユーザーは一度アプリをアンインストールしてから新しいバージョンをインストールする必要があります**

## 7. トラブルシューティング

### ビルドエラーが発生する場合

1. `flutter clean` を実行
2. `flutter pub get` を実行
3. キーストアファイルのパスと権限を確認
4. `key.properties`ファイルの内容を確認

### CI/CDでエラーが発生する場合

1. GitHub Secretsの設定を確認
2. Base64エンコードが正しく行われているか確認
3. キーストアファイルが破損していないか確認
