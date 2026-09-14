<!-- GERADO por scripts/gen-handoff-docs.ts — não editar à mão. -->

# Pacote de handoff — backend Cerne

Entregue **igual** aos dois ciclos comparativos (Spec Kit e BMAD-METHOD), **sem o código-fonte do backend** — evita assimetria de informação entre os dois ciclos, que veriam a implementação de referência se o código vazasse.

## Caminho do contrato → função (D-01)

`contracts/openapi.yaml` não tem roteador: cada operação é servida por uma Edge Function própria, sob `{FUNCTIONS_BASE_URL}/<função>` (ver `servers` e `x-cerne-function` de cada operação no próprio YAML), **nunca** o caminho REST abaixo direto. Parâmetros de path entram como segmentos finais da URL, na mesma ordem em que aparecem no caminho; qualquer segmento literal depois do último parâmetro (ex.: o `/retry` de `chat.messages.retry`) não existe na URL real.

| Caminho do contrato | Função (`{FUNCTIONS_BASE_URL}/<função>`) |
|---|---|
| `POST /auth/signup` | `auth-signup` |
| `POST /auth/login` | `auth-login` |
| `POST /auth/refresh` | `auth-refresh` |
| `GET /auth/session` | `auth-session` |
| `POST /auth/logout` | `auth-logout` |
| `POST /entries` | `entries-create` |
| `GET /entries` | `entries-list` |
| `GET /entries/{id}` | `entries-get` |
| `GET /entries/search` | `entries-search` |
| `POST /media/ocr` | `media-ocr` |
| `POST /chat/sessions` | `chat-sessions-create` |
| `GET /chat/sessions` | `chat-sessions-list` |
| `GET /chat/sessions/{id}/messages` | `chat-messages-list` |
| `POST /chat/sessions/{id}/messages` | `chat-messages-send` |
| `POST /chat/sessions/{id}/messages/{userMessageId}/retry` | `chat-messages-retry` |
| `POST /chat/sessions/{id}/insight` | `chat-insight-create` |
| `POST /export/summary` | `export-summary-create` |
| `GET /export/{jobId}/status` | `export-status-get` |
| `GET /export/{jobId}/download` | `export-download-get` |
| `GET /dashboard/aggregate` | `dashboard-aggregate-get` |
| `GET /dashboard/narrative` | `dashboard-narrative-get` |
| `PATCH /account/settings` | `account-settings-update` |
| `DELETE /account` | `account-delete` |

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
