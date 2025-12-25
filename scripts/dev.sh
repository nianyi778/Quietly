#!/bin/bash
# 开发模式：构建并启动 (Debug)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 关闭旧实例
"$SCRIPT_DIR/stop.sh"

# 构建
"$SCRIPT_DIR/build.sh" Debug

# 启动
"$SCRIPT_DIR/start.sh"
