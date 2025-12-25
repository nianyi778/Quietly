#!/bin/bash
# 构建 Release 版本并可选复制到 /Applications

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "🔨 构建 Quietly (Release)..."

xcodebuild \
    -project Quietly.xcodeproj \
    -scheme Quietly \
    -configuration Release \
    -derivedDataPath ./build \
    build \
    | grep -E "^(Build|Compile|Link|Sign|error:|warning:|\*\*)" || true

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    echo "❌ 构建失败"
    exit 1
fi

APP_PATH="$PROJECT_DIR/build/Build/Products/Release/Quietly.app"

echo ""
echo "✅ Release 构建成功！"
echo "📦 产物路径: $APP_PATH"

# 询问是否安装到 /Applications
read -p "是否安装到 /Applications? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 关闭正在运行的实例
    pkill -x Quietly 2>/dev/null || true
    sleep 0.5
    
    # 删除旧版本并复制新版本
    rm -rf /Applications/Quietly.app
    cp -R "$APP_PATH" /Applications/
    
    echo "✅ 已安装到 /Applications/Quietly.app"
    
    read -p "是否立即启动? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open /Applications/Quietly.app
        echo "🚀 Quietly 已启动"
    fi
fi
