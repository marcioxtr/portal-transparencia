"""Espelha no repositório as fotos dos vereadores (o servidor do SAPL não envia o
certificado intermediário; o Android recusa a conexão). As imagens passam a ser
servidas por raw.githubusercontent.com e o JSON aponta para lá."""
import json
import urllib.request
from pathlib import Path

from . import comum

RAW = 'https://raw.githubusercontent.com/marcioxtr/portal-transparencia/main/dados/fotos/vereadores'
PASTA = comum.RAIZ / 'fotos' / 'vereadores'


def _reduzir(dados, lado=400):
    """Reduz para ~400 px (JPEG 80) se o Pillow estiver disponível; senão guarda como veio."""
    try:
        import io
        from PIL import Image
        im = Image.open(io.BytesIO(dados)).convert('RGB')
        im.thumbnail((lado, lado))
        saida = io.BytesIO()
        im.save(saida, 'JPEG', quality=80, optimize=True)
        return saida.getvalue()
    except Exception:  # noqa: BLE001
        return dados


def espelhar(camara):
    """Baixa fotos novas e reescreve `foto` nos vereadores. Devolve o dict alterado."""
    PASTA.mkdir(parents=True, exist_ok=True)
    for v in camara.get('vereadores', []):
        url = v.get('foto')
        if not url or 'raw.githubusercontent.com' in url:
            continue
        destino = PASTA / f"{v['id']}.jpg"
        if not destino.exists() or destino.stat().st_size < 1000:
            try:
                req = urllib.request.Request(url, headers={'User-Agent': comum.UA})
                with urllib.request.urlopen(req, timeout=60) as r:
                    dados = r.read()
                if len(dados) > 1000:
                    destino.write_bytes(_reduzir(dados))
            except Exception as e:  # noqa: BLE001
                comum.log(f'  foto {v["id"]} falhou: {e}')
                continue
        if destino.exists():
            v['fotoOriginal'] = url
            v['foto'] = f'{RAW}/{v["id"]}.jpg'
    return camara


def coletar():
    """Uso avulso: `python3 -I dados/coletar.py fotos` reescreve dados/camara.json."""
    p = comum.RAIZ / 'camara.json'
    camara = json.loads(p.read_text(encoding='utf-8'))
    camara = espelhar(camara)
    for destino in (p, comum.RAIZ.parent / 'apps' / 'mobile' / 'assets' / 'dados' / 'camara.json'):
        destino.write_text(json.dumps(camara, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    comum.log(f'fotos espelhadas: {len(list(PASTA.glob("*.jpg")))}')
    return None  # já gravou; nada a salvar em fotos.json
