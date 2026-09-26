from pathlib import Path
import hashlib, json
root = Path(__file__).resolve().parents[1]
m = json.loads((root/'Models/model-manifest.json').read_text())
model = root/'Models'/m['file']
assert model.stat().st_size == m['bytes']
assert hashlib.sha256(model.read_bytes()).hexdigest() == m['sha256']
source = '\n'.join(p.read_text() for p in (root/'App').glob('*') if p.suffix in ('.swift','.h','.cpp'))
for forbidden in ['URLSession', 'api.deepseek.com', 'KeyStore', 'WatchConnectivity']:
    assert forbidden not in source, forbidden
assert 'cp.n_ctx = 512' in source
assert 'n > 384' in source
assert 'cp.n_threads = 2' in source
assert 'wa_generate(path, prompt, 64' in source
assert 'Qwen' in (root/'project.yml').read_text()
assert (root/'Licenses/Qwen-Apache-2.0.txt').exists()
assert (root/'Lib/libOfflineInference.a').exists()
print('通过：模型校验、纯本地集成、上下文上限、许可证及原生库')
