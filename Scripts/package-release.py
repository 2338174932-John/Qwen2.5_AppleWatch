#!/usr/bin/env python3
"""将已跟踪源码、固定模型及推理引擎打包为可直接打开的完整工程。"""
import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tarfile
import zipfile

root = Path(__file__).resolve().parents[1]
output = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else root.parent / "output/releases"
output.mkdir(parents=True, exist_ok=True)
model = json.loads((root / "Models/model-manifest.json").read_text())
engine = json.loads((root / "Scripts/dependencies.json").read_text())["llama_cpp"]
subprocess.run([sys.executable, str(root / "Scripts/prepare-model.py")], check=True)
vendor = root / "Vendor/llama.cpp"
revision = subprocess.check_output(["git", "-C", str(vendor), "rev-parse", "HEAD"], text=True).strip()
if revision != engine["commit"]:
    raise SystemExit("推理引擎版本不符，停止打包。")
source = subprocess.check_output(["git", "-C", str(root), "ls-files", "-z"]).decode().split("\0")
archive = output / "Qwen_AppleWatch_完整工程.zip"
prefix = "QwenWatch/"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as package:
    for name in filter(None, source):
        package.write(root / name, prefix + name)
    package.write(root / "Config/Local.xcconfig.example", prefix + "Config/Local.xcconfig")
    package.write(root / "Models" / model["file"], prefix + "Models/" + model["file"])
    package.write(root / "Lib/libOfflineInference.a", prefix + "Lib/libOfflineInference.a")
    upstream = subprocess.check_output(["git", "-C", str(vendor), "archive", engine["commit"]])
    with tarfile.open(fileobj=io.BytesIO(upstream)) as sources:
        for member in sources:
            if member.isfile():
                package.writestr(prefix + "Vendor/llama.cpp/" + member.name, sources.extractfile(member).read())
    package.writestr(prefix + "Vendor/llama.cpp/.pinned-revision", revision + "\n")
with archive.open("rb") as stream:
    digest = hashlib.file_digest(stream, "sha256").hexdigest()
(output / "SHA256SUMS.txt").write_text(digest + "  " + archive.name + "\n")
print(f"完整工程已生成：{archive}（{archive.stat().st_size} 字节）")
