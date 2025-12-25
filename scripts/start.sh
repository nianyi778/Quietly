#!/bin/bash
# 启动 Quietly (Debug 版本)

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$PROJECT_DIR/build/Build/Products/Debug/Quietly.app"
EXECUTABLE="$APP_PATH/Contents/MacOS/Quietly"

# 检查是否已编译
if [ ! -f "$EXECUTABLE" ]; then
    echo "❌ 未找到编译产物，请先运行 build.sh"
    exit 1
fi

# 关闭已运行的实例
pkill -x Quietly 2>/dev/null || true
sleep 0.3

# 启动应用
echo "🚀 启动 Quietly..."
"$EXECUTABLE" &

echo "✅ Quietly 已启动 (PID: $!)"
