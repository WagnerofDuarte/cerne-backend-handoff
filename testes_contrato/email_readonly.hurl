# T-058 — Campo email é rejeitado (Contexto Geral.md, cenário nomeado
# explicitamente): PATCH /account/settings com email -> VALIDATION_ERROR
# (`.strict()` do Zod, contracts/zod/account.ts — email não faz parte do
# shape aceito).

POST {{base_url}}/auth-login
{
  "email": "cenario-uma@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

PATCH {{base_url}}/account-settings-update
Authorization: Bearer {{access_token}}
{
  "email": "novo-email-proibido@cerne.test"
}
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_ERROR"

# mesmo junto com um campo válido, a presença de email já derruba a requisição inteira
PATCH {{base_url}}/account-settings-update
Authorization: Bearer {{access_token}}
{
  "displayName": "Não deveria salvar",
  "email": "outro-email-proibido@cerne.test"
}
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_ERROR"

# confirma que o email da conta continua o mesmo de sempre
GET {{base_url}}/auth-session
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.data.user.email" == "cenario-uma@cerne.test"
