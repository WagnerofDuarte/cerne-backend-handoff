# T-053 — POST /export/summary: caminho feliz + validação + sem token.
# Ver tests/hurl/README.md.

# sem token -> AUTH_EXPIRED
POST {{base_url}}/export-summary-create
{
  "periodStart": null,
  "periodEnd": null,
  "includeNarrative": true
}
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

# corpo inválido (periodStart não é ISO 8601) -> VALIDATION_ERROR
POST {{base_url}}/export-summary-create
Authorization: Bearer {{access_token}}
{
  "periodStart": "nao-e-uma-data",
  "periodEnd": null,
  "includeNarrative": true
}
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_ERROR"

# caminho feliz — conta A do seed tem 34 entradas, sempre != 0
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
[Asserts]
jsonpath "$.data.status" == "pending"
jsonpath "$.data.jobId" exists
