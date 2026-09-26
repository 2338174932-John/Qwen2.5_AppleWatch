#!/bin/bash
# 从源码准备固定模型和推理库；完整发布包无需运行此脚本。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for tool in python3 git cmake xcodegen; do
  command -v "$tool" >/dev/null || { echo "缺少 $tool，请按照 README 安装构建依赖。"; exit 1; }
done
if [ ! -f "$ROOT/Config/Local.xcconfig" ]; then
  cp "$ROOT/Config/Local.xcconfig.example" "$ROOT/Config/Local.xcconfig"
fi
python3 "$ROOT/Scripts/prepare-model.py"
python3 "$ROOT/Scripts/prepare-engine.py"
bash "$ROOT/Scripts/build-engine.sh"
xcodegen generate --spec "$ROOT/project.yml"
echo "准备完成。打开 QwenWatch.xcodeproj，设置自己的签名账号后安装到手表。"
