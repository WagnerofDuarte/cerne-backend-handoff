<!-- GERADO por scripts/gen-handoff-docs.ts — não editar à mão. -->

# Pacote de handoff — backend Cerne

Entregue **igual** aos dois ciclos comparativos (Spec Kit e BMAD-METHOD), **sem o código-fonte do backend** — evita assimetria de informação entre os dois ciclos, que veriam a implementação de referência se o código vazasse.

## Conteúdo

Gerado por `scripts/gen-handoff-docs.ts` (este diretório, versionado em `cerne-backend`):
- `taxonomia_erros.md` — os 13 códigos de erro
- `mapa_estados_tela.md` — mapeamento tela↔status da exportação (RF05)
- `selo_sincronizacao.md` — semântica do selo de sincronização (D9)
- `politica_defeito_D16.md` — política de defeito pós-congelamento

Copiado/preenchido só na hora da publicação (`scripts/build-handoff-package.sh`, GATE-11) — não duplicado aqui de propósito, para não haver duas fontes do mesmo arquivo:
- `api/openapi.yaml` (cópia de `contracts/openapi.yaml`)
- `ux/` (cópia do protótipo congelado e do documento de requisitos — os dois times precisam saber o que construir, não só contra qual API)
- `roteiro_de_validacao.md` (cópia de `docs/roteiro_de_validacao.md`)
- `fixtures/` (cópia de `fixtures/` — textos, pares semânticos, mídia)
- `testes_contrato/` (cópia de `tests/hurl/*.hurl` + README)
- `bugs_conhecidos.md` (cópia de `docs/bugs_conhecidos.md`)
- `credenciais/` — **preenchido manualmente**, uma credencial por ciclo (`ciclo-a`/`ciclo-b`); nenhum script deste repositório gera, lê ou copia segredo nenhum.
