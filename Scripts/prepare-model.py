#!/usr/bin/env python3
"""下载项目唯一支持的模型；校验固定版本的大小和 SHA-256。"""
import hashlib
import json
from pathlib import Path
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = json.loads((ROOT / "Models/model-manifest.json").read_text())
TARGET = ROOT / "Models" / MANIFEST["file"]


def valid(path):
    if not path.exists() or path.stat().st_size != MANIFEST["bytes"]:
        return False
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest() == MANIFEST["sha256"]


if valid(TARGET):
    print("固定模型已就绪，校验通过。")
else:
    url = ("https://huggingface.co/" + MANIFEST["quantization_repo"]
           + "/resolve/" + MANIFEST["revision"] + "/" + MANIFEST["file"])
    temporary = TARGET.with_suffix(".part")
    print("正在下载 Qwen2.5-0.5B（约 491 MB），请稍候……", flush=True)
    try:
        with urllib.request.urlopen(url, timeout=120) as response, temporary.open("wb") as stream:
            while chunk := response.read(1024 * 1024):
                stream.write(chunk)
        if not valid(temporary):
            raise RuntimeError("模型校验失败，请重新运行；原有模型未被覆盖。")
        temporary.replace(TARGET)
        print("模型下载完成，校验通过。")
    finally:
        temporary.unlink(missing_ok=True)
