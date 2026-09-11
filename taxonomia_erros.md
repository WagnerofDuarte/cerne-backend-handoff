<!-- GERADO por scripts/gen-handoff-docs.ts — não editar à mão. -->

# Taxonomia de erro — 13 códigos

Fonte: `supabase/functions/_shared/errors.ts` (fonte única do projeto — todo handler lança erro só através de `throwError(code)`, nunca `throw` direto).

| Código | HTTP | Retryable |
|---|---|---|
| `AUTH_EXPIRED` | 401 | não |
| `AUTH_INVALID` | 401 | não |
| `NETWORK_TIMEOUT` | 504 | sim |
| `NETWORK_OFFLINE` | _(sem resposta HTTP — ver nota)_ | sim |
| `VALIDATION_ERROR` | 400 | não |
| `PII_CHECK_FAILED` | 502 | sim |
| `EMBEDDING_FAILED` | 502 | sim |
| `AI_GENERATION_TIMEOUT` | 504 | sim |
| `NOT_FOUND` | 404 | não |
| `RATE_LIMITED` | 429 | sim |
| `EXPORT_EMPTY_PERIOD` | 400 | não |
| `PAYLOAD_TOO_LARGE` | 413 | não |
| `OCR_NO_TEXT` | 400 | não |

**Duas armadilhas deliberadas, por desenho (nunca acontecem nesta API):**
- **Nunca `403`** — recurso de outro usuário sempre responde `404 NOT_FOUND` (evita vazar a existência do recurso).
- **Nunca `409`** — a idempotência do RF10 (reenvio da mesma mensagem de chat) sempre responde `200`; não existe código de "conflito" nesta taxonomia.

**`NETWORK_OFFLINE` não tem status HTTP:** é o único código que nunca vira uma resposta de verdade — a injeção de falha desse tipo encerra a conexão sem responder (usada só em teste, via `X-Test-Fault`).

Total: **13 códigos**, lista fechada — nenhum código novo pode ser adicionado depois do congelamento (contradiz o RNF09 do ciclo que já rodou).
