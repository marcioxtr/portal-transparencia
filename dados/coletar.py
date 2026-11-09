#!/usr/bin/env python3
"""Roda todos os coletores e publica dados/*.json (+ cópia em apps/mobile/assets/dados).

Uso:  python3 -I dados/coletar.py            # todos
      python3 -I dados/coletar.py obras camara   # só alguns

Cada coletor é um módulo em dados/coletores/ com uma função `coletar()` que
devolve um dict; o orquestrador salva como dados/<nome>.json. Um coletor que
falhar não derruba os outros — o JSON anterior permanece válido.
"""
import importlib
import sys
import traceback
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from coletores import comum  # noqa: E402

COLETORES = [
    'obras',        # obras públicas georreferenciadas (site)
    'camara',       # vereadores, sessões, matérias, votos, leis (SAPL)
    'avisos',       # interdições, alterações de trânsito, coleta, eventos, agenda dos conselhos (site)
    'noticias',     # últimas notícias por departamento (RSS + site)
    'licitacoes',   # chamamentos públicos e inexigibilidades (site)
    'servicos',     # unidades de saúde, escolas, conselhos, carta de serviços, ouvidoria (site)
    'indicadores',  # mínimos constitucionais, LRF, comparativos entre anos e vizinhos (SICONFI + TCE)
]


def main():
    pedidos = sys.argv[1:] or COLETORES
    falhas = []
    for nome in pedidos:
        comum.log(f'\n== {nome} ==')
        try:
            mod = importlib.import_module(f'coletores.{nome}')
            dados = mod.coletar()
            if dados:
                comum.salvar(nome, dados)
        except Exception:  # noqa: BLE001
            falhas.append(nome)
            traceback.print_exc()
    if falhas:
        comum.log(f'\nFALHARAM: {falhas}')
        sys.exit(1)


if __name__ == '__main__':
    main()
