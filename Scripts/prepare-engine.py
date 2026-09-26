#!/usr/bin/env python3
"""获取固定版本的 llama.cpp，保留上游完整许可证。"""
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
config = json.loads((root / "Scripts/dependencies.json").read_text())["llama_cpp"]
target = root / "Vendor/llama.cpp"
if target.exists():
    if (target / ".git").exists():
        revision = subprocess.check_output(["git", "-C", str(target), "rev-parse", "HEAD"], text=True).strip()
    else:
        marker = target / ".pinned-revision"
        revision = marker.read_text().strip() if marker.exists() else ""
    if revision != config["commit"]:
        raise SystemExit("本地推理引擎版本不同，请保留现有修改后移开 Vendor/llama.cpp 再运行。")
else:
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "init", str(target)], check=True)
    subprocess.run(["git", "-C", str(target), "remote", "add", "origin", config["url"]], check=True)
    subprocess.run(["git", "-C", str(target), "fetch", "--depth", "1", "origin", config["commit"]], check=True)
    subprocess.run(["git", "-C", str(target), "checkout", "--detach", "FETCH_HEAD"], check=True)
print("推理引擎固定版本已就绪。")
