# T-055 — GET /export/:jobId/status: sem token, jobId inexistente/alheio,
# e o estado imediatamente após criar (antes do worker rodar).

# sem token -> AUTH_EXPIRED
GET {{base_url}}/export-status-get/11111111-1111-1111-1111-111111111111
HTTP 401
[Asserts]
jsonpath "$.code" == "AUTH_EXPIRED"

POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

# jobId que não existe -> NOT_FOUND (D7, nunca 403)
GET {{base_url}}/export-status-get/11111111-1111-1111-1111-111111111111
Authorization: Bearer {{access_token}}
HTTP 404
[Asserts]
jsonpath "$.code" == "NOT_FOUND"

# cria um job e confere o estado imediatamente — ainda não deu tempo do
# worker (pg_cron a cada 15s, migração 0014) rodar.
POST {{base_url}}/export-summary-create
Authorization: Bearer {{access_token}}
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
HTTP 200
[Asserts]
jsonpath "$.data.jobId" == "{{job_id}}"
jsonpath "$.data.status" matches "^(pending|processing|data_ready|done)$"
jsonpath "$.data.downloadAvailable" isBoolean

# conta B (cenario-uma) não vê o job da conta A -> NOT_FOUND, nunca 403
POST {{base_url}}/auth-login
{
  "email": "cenario-uma@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
other_access_token: jsonpath "$.data.session.accessToken"

GET {{base_url}}/export-status-get/{{job_id}}
Authorization: Bearer {{other_access_token}}
HTTP 404
[Asserts]
jsonpath "$.code" == "NOT_FOUND"
