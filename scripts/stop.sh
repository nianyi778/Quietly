#!/bin/bash
# 关闭 Quietly

if pgrep -x Quietly > /dev/null; then
    pkill -x Quietly
    echo "✅ Quietly 已关闭"
else
    echo "ℹ️  Quietly 未在运行"
fi
