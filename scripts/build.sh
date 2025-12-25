#!/bin/bash
# 构建 Quietly

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# 默认 Debug，可通过参数指定 Release
CONFIG="${1:-Debug}"

echo "🔨 构建 Quietly ($CONFIG)..."

xcodebuild \
    -project Quietly.xcodeproj \
    -scheme Quietly \
    -configuration "$CONFIG" \
    -derivedDataPath ./build \
    build \
    | grep -E "^(Build|Compile|Link|Sign|error:|warning:|\*\*)" || true

if [ "${PIPESTATUS[0]}" -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo "📦 产物路径: $PROJECT_DIR/build/Build/Products/$CONFIG/Quietly.app"
else
    echo ""
    echo "❌ 构建失败"
    exit 1
fi
