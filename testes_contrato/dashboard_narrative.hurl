# T-057 — GET /dashboard/narrative: caminho feliz + sem token. Faz uma
# chamada real à Anthropic (sem cache de replay ainda — T-060 é Fase 6).

GET {{base_url}}/dashboard-narrative-get?period=30d
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

GET {{base_url}}/dashboard-narrative-get?period=30d
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.data.text" exists
jsonpath "$.data.generatedAt" exists
