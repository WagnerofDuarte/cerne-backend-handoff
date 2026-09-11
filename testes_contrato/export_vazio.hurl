# T-053 — Período vazio (Contexto Geral.md, cenário nomeado explicitamente):
# EXPORT_EMPTY_PERIOD, zero linhas criadas em export_jobs. Usa a conta C do
# seed (cenario-vazio@cerne.test), que nunca tem nenhuma entrada.

POST {{base_url}}/auth-login
{
  "email": "cenario-vazio@cerne.test",
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
  "includeNarrative": true
}
HTTP 400
[Asserts]
jsonpath "$.code" == "EXPORT_EMPTY_PERIOD"
jsonpath "$.retryable" == false
