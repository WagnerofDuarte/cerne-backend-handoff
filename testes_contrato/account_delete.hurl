# T-059 — DELETE /account: cria uma conta descartável (nunca uma das 3
# contas do seed — apagar aquelas quebraria todo o resto da suíte),
# confirma o apagamento e que o login deixa de funcionar depois.
# `{{newUuid}}` garante um e-mail novo a cada execução (Hurl >= 4.x).

POST {{base_url}}/auth-signup
{
  "email": "hurl-descartavel-{{newUuid}}@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
disposable_token: jsonpath "$.data.session.accessToken"

# sem token -> AUTH_EXPIRED
DELETE {{base_url}}/account-delete
{
  "confirmation": "DELETE"
}
HTTP 401
[Asserts]
jsonpath "$.code" == "AUTH_EXPIRED"

# confirmação errada -> VALIDATION_ERROR, conta continua existindo
DELETE {{base_url}}/account-delete
Authorization: Bearer {{disposable_token}}
{
  "confirmation": "delete"
}
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_ERROR"

GET {{base_url}}/auth-session
Authorization: Bearer {{disposable_token}}
HTTP 200

# confirmação certa -> apaga de verdade
DELETE {{base_url}}/account-delete
Authorization: Bearer {{disposable_token}}
{
  "confirmation": "DELETE"
}
HTTP 200
[Asserts]
jsonpath "$.data.ok" == true

# a sessão antiga não serve mais para nada de útil (a conta não existe mais)
GET {{base_url}}/auth-session
Authorization: Bearer {{disposable_token}}
HTTP 401
