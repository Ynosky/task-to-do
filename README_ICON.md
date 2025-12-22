# アプリアイコン自動生成スクリプト

## 概要
`generate_icon.py` は、Task Consumerアプリ用のアプリアイコンを自動生成するPythonスクリプトです。

## 必要な環境
- Python 3.6以上
- Pillow (PIL) ライブラリ

## セットアップ

### 1. Pillowのインストール
```bash
pip3 install Pillow
```

または、権限の問題がある場合：
```bash
pip3 install --user Pillow
```

## 実行方法

プロジェクトのルートディレクトリで実行：
```bash
python3 generate_icon.py
```

または実行権限を付与して：
```bash
chmod +x generate_icon.py
./generate_icon.py
```

## 生成されるアイコン

### iOS
- `AppIcon-1024.png` (1024x1024) - ライトモード
- `AppIcon-1024-dark.png` (1024x1024) - ダークモード
- `AppIcon-1024-tinted.png` (1024x1024) - ティントモード

### macOS
- `AppIcon-16.png` (16x16) - 1x
- `AppIcon-16@2x.png` (32x32) - 2x
- `AppIcon-32.png` (32x32) - 1x
- `AppIcon-32@2x.png` (64x64) - 2x
- `AppIcon-128.png` (128x128) - 1x
- `AppIcon-128@2x.png` (256x256) - 2x
- `AppIcon-256.png` (256x256) - 1x
- `AppIcon-256@2x.png` (512x512) - 2x
- `AppIcon-512.png` (512x512) - 1x
- `AppIcon-512@2x.png` (1024x1024) - 2x

## デザイン
- **背景色**: Teal (#008080)
- **アイコン**: 白色の時計アイコン
- **スタイル**: モダンでフラットなデザイン

## 出力先
生成されたアイコンは以下のディレクトリに保存されます：
```
Task Consumer/Assets.xcassets/AppIcon.appiconset/
```

`Contents.json` も自動的に更新されます。

## 次のステップ
1. Xcodeでプロジェクトを開く
2. `Assets.xcassets` > `AppIcon` を確認
3. 必要に応じてアイコンを調整

