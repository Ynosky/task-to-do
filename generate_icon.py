#!/usr/bin/env python3
"""
アプリアイコン自動生成スクリプト
Teal色の背景に白い時計アイコンを描画して、必要なサイズのアイコンを生成します。
"""

import json
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# 設定
TEAL_COLOR = (0, 128, 128)  # Teal (#008080)
WHITE_COLOR = (255, 255, 255)
ICON_DIR = Path("Task Consumer/Assets.xcassets/AppIcon.appiconset")

# 必要なアイコンサイズの定義
ICON_SIZES = {
    # iOS (Universal)
    "ios-1024": {"size": 1024, "filename": "AppIcon-1024.png", "idiom": "universal", "platform": "ios"},
    "ios-1024-dark": {"size": 1024, "filename": "AppIcon-1024-dark.png", "idiom": "universal", "platform": "ios", "appearance": "dark"},
    "ios-1024-tinted": {"size": 1024, "filename": "AppIcon-1024-tinted.png", "idiom": "universal", "platform": "ios", "appearance": "tinted"},
    
    # macOS
    "mac-16-1x": {"size": 16, "filename": "AppIcon-16.png", "idiom": "mac", "scale": "1x"},
    "mac-16-2x": {"size": 32, "filename": "AppIcon-16@2x.png", "idiom": "mac", "scale": "2x"},
    "mac-32-1x": {"size": 32, "filename": "AppIcon-32.png", "idiom": "mac", "scale": "1x"},
    "mac-32-2x": {"size": 64, "filename": "AppIcon-32@2x.png", "idiom": "mac", "scale": "2x"},
    "mac-128-1x": {"size": 128, "filename": "AppIcon-128.png", "idiom": "mac", "scale": "1x"},
    "mac-128-2x": {"size": 256, "filename": "AppIcon-128@2x.png", "idiom": "mac", "scale": "2x"},
    "mac-256-1x": {"size": 256, "filename": "AppIcon-256.png", "idiom": "mac", "scale": "1x"},
    "mac-256-2x": {"size": 512, "filename": "AppIcon-256@2x.png", "idiom": "mac", "scale": "2x"},
    "mac-512-1x": {"size": 512, "filename": "AppIcon-512.png", "idiom": "mac", "scale": "1x"},
    "mac-512-2x": {"size": 1024, "filename": "AppIcon-512@2x.png", "idiom": "mac", "scale": "2x"},
}

def draw_clock_icon(draw, size, center_x, center_y, icon_size):
    """時計アイコンを描画"""
    # 時計の外側の円
    radius = icon_size * 0.4
    margin = size * 0.1
    
    # 外側の円
    draw.ellipse(
        [center_x - radius, center_y - radius, center_x + radius, center_y + radius],
        outline=WHITE_COLOR,
        width=max(2, int(size * 0.02))
    )
    
    # 時計の針（12時と3時の位置）
    line_width = max(2, int(size * 0.015))
    
    # 12時の位置（上）
    draw.line(
        [center_x, center_y - radius, center_x, center_y - radius * 0.7],
        fill=WHITE_COLOR,
        width=line_width
    )
    
    # 3時の位置（右）
    draw.line(
        [center_x + radius * 0.7, center_y, center_x + radius, center_y],
        fill=WHITE_COLOR,
        width=line_width
    )
    
    # 中心の点
    dot_size = max(2, int(size * 0.02))
    draw.ellipse(
        [center_x - dot_size, center_y - dot_size, center_x + dot_size, center_y + dot_size],
        fill=WHITE_COLOR
    )

def draw_checkmark_icon(draw, size, center_x, center_y, icon_size):
    """チェックマークアイコンを描画"""
    # チェックマークのサイズ
    check_size = icon_size * 0.5
    line_width = max(3, int(size * 0.03))
    
    # チェックマークのパス（V字型）
    # 左側の線（下向き）
    left_x = center_x - check_size * 0.3
    left_y = center_y - check_size * 0.1
    mid_x = center_x
    mid_y = center_y + check_size * 0.2
    
    # 右側の線（上向き）
    right_x = center_x + check_size * 0.3
    right_y = center_y - check_size * 0.1
    
    # チェックマークを描画
    draw.line([left_x, left_y, mid_x, mid_y], fill=WHITE_COLOR, width=line_width)
    draw.line([mid_x, mid_y, right_x, right_y], fill=WHITE_COLOR, width=line_width)

def generate_icon(size, filename, use_checkmark=False):
    """指定サイズのアイコンを生成"""
    # 画像を作成
    img = Image.new('RGB', (size, size), TEAL_COLOR)
    draw = ImageDraw.Draw(img)
    
    center_x = size // 2
    center_y = size // 2
    icon_size = size * 0.7  # アイコンは画像の70%のサイズ
    
    # アイコンを描画（時計またはチェックマーク）
    if use_checkmark:
        draw_checkmark_icon(draw, size, center_x, center_y, icon_size)
    else:
        draw_clock_icon(draw, size, center_x, center_y, icon_size)
    
    # 保存
    output_path = ICON_DIR / filename
    img.save(output_path, 'PNG')
    print(f"✓ Generated: {filename} ({size}x{size})")

def generate_contents_json():
    """Contents.jsonを生成"""
    images = []
    
    # iOS アイコン
    images.append({
        "idiom": "universal",
        "platform": "ios",
        "size": "1024x1024",
        "filename": "AppIcon-1024.png"
    })
    
    images.append({
        "appearances": [{"appearance": "luminosity", "value": "dark"}],
        "idiom": "universal",
        "platform": "ios",
        "size": "1024x1024",
        "filename": "AppIcon-1024-dark.png"
    })
    
    images.append({
        "appearances": [{"appearance": "luminosity", "value": "tinted"}],
        "idiom": "universal",
        "platform": "ios",
        "size": "1024x1024",
        "filename": "AppIcon-1024-tinted.png"
    })
    
    # macOS アイコン
    mac_sizes = [
        (16, "1x", "AppIcon-16.png"),
        (16, "2x", "AppIcon-16@2x.png"),
        (32, "1x", "AppIcon-32.png"),
        (32, "2x", "AppIcon-32@2x.png"),
        (128, "1x", "AppIcon-128.png"),
        (128, "2x", "AppIcon-128@2x.png"),
        (256, "1x", "AppIcon-256.png"),
        (256, "2x", "AppIcon-256@2x.png"),
        (512, "1x", "AppIcon-512.png"),
        (512, "2x", "AppIcon-512@2x.png"),
    ]
    
    for size, scale, filename in mac_sizes:
        images.append({
            "idiom": "mac",
            "scale": scale,
            "size": f"{size}x{size}",
            "filename": filename
        })
    
    contents = {
        "images": images,
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    # 保存
    contents_path = ICON_DIR / "Contents.json"
    with open(contents_path, 'w', encoding='utf-8') as f:
        json.dump(contents, f, indent=2, ensure_ascii=False)
    
    print(f"✓ Generated: Contents.json")

def main():
    """メイン処理"""
    print("🎨 アプリアイコン生成スクリプト")
    print("=" * 50)
    
    # ディレクトリの確認と作成
    if not ICON_DIR.exists():
        ICON_DIR.mkdir(parents=True, exist_ok=True)
        print(f"✓ Created directory: {ICON_DIR}")
    
    # アイコン生成（時計アイコンを使用）
    print("\n📱 iOS アイコン生成中...")
    generate_icon(1024, "AppIcon-1024.png", use_checkmark=False)
    generate_icon(1024, "AppIcon-1024-dark.png", use_checkmark=False)
    generate_icon(1024, "AppIcon-1024-tinted.png", use_checkmark=False)
    
    print("\n💻 macOS アイコン生成中...")
    generate_icon(16, "AppIcon-16.png")
    generate_icon(32, "AppIcon-16@2x.png")
    generate_icon(32, "AppIcon-32.png")
    generate_icon(64, "AppIcon-32@2x.png")
    generate_icon(128, "AppIcon-128.png")
    generate_icon(256, "AppIcon-128@2x.png")
    generate_icon(256, "AppIcon-256.png")
    generate_icon(512, "AppIcon-256@2x.png")
    generate_icon(512, "AppIcon-512.png")
    generate_icon(1024, "AppIcon-512@2x.png")
    
    # Contents.json生成
    print("\n📄 Contents.json生成中...")
    generate_contents_json()
    
    print("\n" + "=" * 50)
    print("✅ アプリアイコンの生成が完了しました！")
    print(f"📁 出力先: {ICON_DIR.absolute()}")
    print("\n💡 次のステップ:")
    print("   1. Xcodeでプロジェクトを開く")
    print("   2. Assets.xcassets > AppIcon を確認")
    print("   3. 必要に応じてアイコンを調整")

if __name__ == "__main__":
    main()

