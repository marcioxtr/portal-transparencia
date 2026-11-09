# Fonte — Intertec GPMOD (Transparência 2023 → 2025)

> Fonte: **"Transparência a partir de 2023"**
> URL: `https://gpmodsaojoaodaboavista.intertecsolucoes.com.br/GPMODSJV/f?p=109:1:::::id_entidade:1`
> Tecnologia: Oracle APEX (padrão de URL `f?p=APP:PAGE:SESSION::...`).
> **Status em 2026-11-08: fora do ar — "Estamos em Manutenção. Desculpe pelo transtorno. Voltaremos em breve."**

## O que se sabe

- A prefeitura trocou de fornecedor em 2026 (Intertec → SmarAPD), e este portal ficou como histórico de 2023 a 2025.
- Não há snapshots no Wayback Machine (`archive.org/wayback/available` retorna vazio), então não foi possível mapear suas telas.
- Oracle APEX **não expõe API REST por padrão**; dados são renderizados via `wwv_flow.ajax` com sessão e checksums por página. Scraping é possível, mas frágil (precisa manter sessão APEX e tokens `p_instance`/`p_flow_step_id`).

## Estratégia recomendada

1. **Não bloquear o MVP nesta fonte.** O app lança com SmarAPD (2026+) e site da prefeitura (contratos, emendas, legado até 2022).
2. Monitorar o retorno do portal (issue aberta com label `fonte:intertec`). Quando voltar:
   - Capturar HAR da navegação completa.
   - Verificar se a Intertec publica *Interactive Reports* com link "Download CSV" — APEX gera URLs `f?p=…:CSV` que podem ser consumidas sem sessão interativa.
   - Verificar se há `ords/` (Oracle REST Data Services) habilitado no host: `https://gpmodsaojoaodaboavista.intertecsolucoes.com.br/ords/`.
3. **Alternativa oficial**: os dados 2023–2025 também existem em bases públicas padronizadas e com API, que o app pode consumir diretamente:
   - **TCE-SP — Portal de Transparência Municipal** (`https://transparencia.tce.sp.gov.br/`): despesas e receitas de todos os municípios paulistas, com download CSV por ano/município. Base oficial e estável.
   - **SICONFI/Tesouro** (`https://apidatalake.tesouro.gov.br/ords/siconfi/tt/`): RREO, RGF e DCA via API REST pública (ORDS). Útil para indicadores fiscais.
   - **Portal da Transparência federal** (`https://api.portaldatransparencia.gov.br/`): transferências da União ao município (precisa de chave gratuita).

Essas fontes cobrem o "buraco" 2023–2025 com dados **melhores que o portal original** (padronizados e com API), ao custo de não terem o mesmo detalhe de empenho/credor em alguns casos.

## Pendências

- [ ] Recheck semanal do host (automatizar via GitHub Action que abre issue quando voltar 200 com conteúdo ≠ "Manutenção").
- [ ] Avaliar TCE-SP como fonte primária para 2023–2025.
