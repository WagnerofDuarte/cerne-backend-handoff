# T-034 — Autenticação: caminho feliz + validação + sem token.
# Ver tests/hurl/README.md para as variáveis e como rodar.

# corpo inválido -> VALIDATION_ERROR (não toca nenhuma conta real)
POST {{base_url}}/auth-signup
{
  "email": "nao-e-um-email",
  "password": "x"
}
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_ERROR"
jsonpath "$.requestId" exists
jsonpath "$.retryable" == false

# login: credenciais erradas -> AUTH_INVALID
POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "senha-errada-de-proposito"
}
HTTP 401
[Asserts]
jsonpath "$.code" == "AUTH_INVALID"

# login: caminho feliz (conta A do seed)
POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"
refresh_token: jsonpath "$.data.session.refreshToken"
[Asserts]
jsonpath "$.data.user.email" == "cenario-cheio@cerne.test"
jsonpath "$.data.session.tokenType" exists

# GET /auth/session: sem token -> AUTH_EXPIRED
GET {{base_url}}/auth-session
HTTP 401
[Asserts]
jsonpath "$.code" == "AUTH_EXPIRED"

# GET /auth/session: com token -> user + expiresAt + serverRevision (§8.1: único com lógica própria)
GET {{base_url}}/auth-session
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.data.user.email" == "cenario-cheio@cerne.test"
jsonpath "$.data.expiresAt" exists
jsonpath "$.data.serverRevision" >= 0

# refresh: caminho feliz
POST {{base_url}}/auth-refresh
{
  "refreshToken": "{{refresh_token}}"
}
HTTP 200
[Asserts]
jsonpath "$.data.session.accessToken" exists
jsonpath "$.data.user" not exists

# refresh: token inválido -> AUTH_EXPIRED
POST {{base_url}}/auth-refresh
{
  "refreshToken": "token-que-nao-existe-de-proposito"
}
HTTP 401
[Asserts]
jsonpath "$.code" == "AUTH_EXPIRED"

# logout
POST {{base_url}}/auth-logout
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.data.ok" == true
