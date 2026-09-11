# T-055 — GET /export/:jobId/download: 302 para URL assinada, PDF com
# fallback para bruto, job de outro usuário -> NOT_FOUND.
#
# PRÉ-REQUISITO (só nesta suíte, ver big-plan.md Fase 5/T-051 e
# tests/hurl/README.md "Novidade da Fase 5"): o worker (`export-worker`)
# só roda de verdade se `experiment.worker_config` tiver uma linha (URL
# base das functions + um segredo compartilhado) — sem isso, o job fica
# preso em 'pending' para sempre e este arquivo nunca fecha (os
# `[Options] retry` abaixo esgotam e falham). Rodar uma vez, manualmente,
# antes desta suíte (depois de adicionar EXPORT_WORKER_SECRET=<qualquer
# string sua> ao .env.local — achado real, T-059v: NÃO use a
# SUPABASE_SERVICE_ROLE_KEY aqui, a CLI recusa carregá-la do .env.local):
#   insert into experiment.worker_config (functions_base_url, shared_secret)
#   values ('http://host.docker.internal:54321/functions/v1', '<o mesmo valor de EXPORT_WORKER_SECRET>');
#
# `includeNarrative: false` de propósito — mantém o job simples (sem
# depender de uma chamada real à Anthropic terminar a tempo do retry
# abaixo); a narrativa em si já é coberta por `export_resiliente.hurl`.

POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

POST {{base_url}}/export-summary-create
Authorization: Bearer {{access_token}}
{
  "periodStart": null,
  "periodEnd": null,
  "includeNarrative": false
}
HTTP 202
[Captures]
job_id: jsonpath "$.data.jobId"

# Espera o worker processar — pg_cron acorda a cada 15s (migração 0014).
# Até 20 tentativas de 3s (60s) cobre uma folga generosa sobre isso.
GET {{base_url}}/export-status-get/{{job_id}}
Authorization: Bearer {{access_token}}
[Options]
retry: 20
retry-interval: 3000ms
HTTP 200
[Asserts]
jsonpath "$.data.status" == "done"
jsonpath "$.data.narrativeStatus" == "skipped"
jsonpath "$.data.downloadAvailable" == true

# format=raw (só o que existe, já que includeNarrative=false) -> 302
GET {{base_url}}/export-download-get/{{job_id}}?format=raw
Authorization: Bearer {{access_token}}
HTTP 302
[Asserts]
header "Location" exists

# format=pdf (default) sem PDF gerado -> cai para o bruto mesmo assim (§8.4)
GET {{base_url}}/export-download-get/{{job_id}}
Authorization: Bearer {{access_token}}
HTTP 302
[Asserts]
header "Location" exists

# conta B não consegue baixar o job da conta A -> NOT_FOUND
POST {{base_url}}/auth-login
{
  "email": "cenario-uma@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
other_access_token: jsonpath "$.data.session.accessToken"

GET {{base_url}}/export-download-get/{{job_id}}
Authorization: Bearer {{other_access_token}}
HTTP 404
[Asserts]
jsonpath "$.code" == "NOT_FOUND"
