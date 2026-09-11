# T-063 (Fase 6) — Os 15 cenários de injeção de falha (D6/§10.3, plano
# técnico): 5 endpoints de escrita × 3 tipos (`timeout`, `malformed`,
# `offline`), lista congelada — POST /entries, POST /chat/sessions/:id/
# messages, POST /media/ocr, POST /export/summary, POST /chat/sessions/:id/
# insight. Critério de conclusão: `experiment.fault_injection_log` com 15
# linhas distintas.
#
# Requer `X-Test-Key` == `TEST_FAULT_KEY` (§10.1) — mesmo padrão de
# `insight_falha.hurl` (Fase 4, 1ª suíte a usar `X-Test-Fault`).
#
# **Cobre só 10 dos 15 cenários** (`timeout`+`malformed` × 5 endpoints) —
# achado real deste sandbox, validado contra o binário `hurl` 6.1.1 de
# verdade (mesma versão do Wagner): o efeito de `offline`
# (`gateway.ts::simulateOffline`) é, por desenho, uma `Response` que nunca
# resolve — "não existe, no nível de uma Edge Function, um jeito de derrubar
# o socket TCP sem responder" (comentário do próprio módulo). O Hurl não tem
# um jeito de fazer uma requisição e *esperar* que ela nunca receba
# resposta: `--max-time`/`-m` (o único jeito de limitar isso) é
# explicitamente "cli-only" (não pode ir num bloco `[Options]` por
# entrada — confirmado no manual do binário instalado aqui), então um valor
# curto aplicaria a TODAS as entradas deste arquivo, derrubando as 5 de
# `timeout` (que legitimamente levam 35s) antes delas terminarem. Deixar o
# padrão (300s) para testar `offline` faria cada uma das 5 entradas
# pendurar até o teto externo do runtime de Edge Functions (150s local) —
# 12+ minutos só nisso, num arquivo que já leva ~3min pelas 5 entradas de
# `timeout`. Os 5 cenários de `offline` (e a contagem final das 15 linhas
# distintas) são verificados por `scripts/verify-fault-injection-log.ts`
# (T-063) — script dedicado, não Hurl, que faz a requisição com um timeout
# de cliente curto (confirma "sem resposta", não espera o teto do runtime) e
# confere a tabela direto no Postgres. Ver esse arquivo para o porquê de a
# verificação final também não caber só na Hurl (a tabela é `experiment.*`,
# sem rota HTTP — migração 0008/0010).
#
# **Custo de tempo esperado desta suíte: ~3 minutos** (5 × 35s de
# `timeout`, sequenciais — `--jobs 1` é obrigatório neste projeto, ver
# tests/hurl/README.md) — bem mais lento que qualquer outro arquivo desta
# suíte. Rodar isolado, não misturado no `--jobs 1 tests/hurl/*.hurl` do
# dia a dia, quando só se quer iterar rápido nos outros arquivos.

POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

POST {{base_url}}/chat-sessions-create
Authorization: Bearer {{access_token}}
{}
HTTP 200
[Captures]
session_id: jsonpath "$.data.id"

# =========================================================================
# 1/5 — POST /entries
# =========================================================================

POST {{base_url}}/entries-create
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: timeout
{
  "content": "conteúdo irrelevante — timeout curto-circuita antes da validação Zod (passo 4b vem antes do passo 6 no gateway)",
  "source": "manual"
}
HTTP 504
[Asserts]
jsonpath "$.code" == "NETWORK_TIMEOUT"
jsonpath "$.retryable" == true

POST {{base_url}}/entries-create
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: malformed
{
  "content": "idem — mesmo motivo",
  "source": "manual"
}
HTTP 200
[Asserts]
jsonpath "$.__injected_fault__" == "malformed"
jsonpath "$.data" not exists
jsonpath "$.code" not exists

# =========================================================================
# 2/5 — POST /chat/sessions/:id/messages
# =========================================================================

POST {{base_url}}/chat-messages-send/{{session_id}}
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: timeout
{
  "content": "mensagem irrelevante — mesmo motivo do bloco acima"
}
HTTP 504
[Asserts]
jsonpath "$.code" == "NETWORK_TIMEOUT"
jsonpath "$.retryable" == true

POST {{base_url}}/chat-messages-send/{{session_id}}
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: malformed
{
  "content": "idem"
}
HTTP 200
[Asserts]
jsonpath "$.__injected_fault__" == "malformed"

# =========================================================================
# 3/5 — POST /media/ocr
# =========================================================================

POST {{base_url}}/media-ocr
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: timeout
{
  "image": "aWdub3JhZG8=",
  "mimeType": "image/png"
}
HTTP 504
[Asserts]
jsonpath "$.code" == "NETWORK_TIMEOUT"
jsonpath "$.retryable" == true

POST {{base_url}}/media-ocr
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: malformed
{
  "image": "aWdub3JhZG8=",
  "mimeType": "image/png"
}
HTTP 200
[Asserts]
jsonpath "$.__injected_fault__" == "malformed"

# =========================================================================
# 4/5 — POST /export/summary
# =========================================================================

POST {{base_url}}/export-summary-create
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: timeout
{
  "periodStart": null,
  "periodEnd": null,
  "includeNarrative": false
}
HTTP 504
[Asserts]
jsonpath "$.code" == "NETWORK_TIMEOUT"
jsonpath "$.retryable" == true

POST {{base_url}}/export-summary-create
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: malformed
{
  "periodStart": null,
  "periodEnd": null,
  "includeNarrative": false
}
HTTP 200
[Asserts]
jsonpath "$.__injected_fault__" == "malformed"

# =========================================================================
# 5/5 — POST /chat/sessions/:id/insight
# =========================================================================

POST {{base_url}}/chat-insight-create/{{session_id}}
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: timeout
{
  "triggerType": "message_count",
  "triggerKey": "fault-timeout"
}
HTTP 504
[Asserts]
jsonpath "$.code" == "NETWORK_TIMEOUT"
jsonpath "$.retryable" == true

POST {{base_url}}/chat-insight-create/{{session_id}}
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: malformed
{
  "triggerType": "message_count",
  "triggerKey": "fault-malformed"
}
HTTP 200
[Asserts]
jsonpath "$.__injected_fault__" == "malformed"
