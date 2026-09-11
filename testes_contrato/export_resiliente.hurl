# T-054 — Exportação resiliente (Contexto Geral.md, cenário nomeado
# explicitamente): com `ai_timeout`, a narrativa falha mas os dados brutos
# continuam disponíveis — narrativeStatus='failed' e downloadAvailable=true;
# download responde 302 mesmo assim (§8.4, literal: "falha de narrativa
# NUNCA produz 4xx/5xx aqui").
#
# Mesmo pré-requisito de `export_download.hurl` (worker_config configurado)
# — ver o comentário lá.

POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

# X-Test-Fault: ai_timeout na própria requisição síncrona — o handler grava
# a intenção junto do job (export_mark_fault, migração 0018); o worker lê
# isso antes de tentar a narrativa (export_get_fault) e força a falha sem
# bater na Anthropic.
POST {{base_url}}/export-summary-create
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: ai_timeout
{
  "periodStart": null,
  "periodEnd": null,
  "includeNarrative": true
}
HTTP 202
[Captures]
job_id: jsonpath "$.data.jobId"

GET {{base_url}}/export-status-get/{{job_id}}
Authorization: Bearer {{access_token}}
[Options]
retry: 20
retry-interval: 3000ms
HTTP 200
[Asserts]
jsonpath "$.data.status" == "data_ready"
jsonpath "$.data.narrativeStatus" == "failed"
jsonpath "$.data.narrativeErrorCode" == "AI_GENERATION_TIMEOUT"
jsonpath "$.data.downloadAvailable" == true

# download continua funcionando (só o bruto, sem PDF) — nunca 4xx/5xx por
# causa da narrativa ter falhado.
GET {{base_url}}/export-download-get/{{job_id}}
Authorization: Bearer {{access_token}}
HTTP 302
[Asserts]
header "Location" exists
