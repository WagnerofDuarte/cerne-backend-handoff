# T-058 — PATCH /account/settings: caminho feliz + sem token + corpo
# inválido. Usa a conta B do seed (cenario-uma) para não sujar a conta A,
# compartilhada por quase toda a suíte.

PATCH {{base_url}}/account-settings-update
{
  "displayName": "Nome Sem Token"
}
HTTP 401
[Asserts]
jsonpath "$.code" == "AUTH_EXPIRED"

POST {{base_url}}/auth-login
{
  "email": "cenario-uma@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

# displayName vazio (min 1) -> VALIDATION_ERROR
PATCH {{base_url}}/account-settings-update
Authorization: Bearer {{access_token}}
{
  "displayName": ""
}
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_ERROR"

# caminho feliz — displayName + persona + biometricEnabled
PATCH {{base_url}}/account-settings-update
Authorization: Bearer {{access_token}}
{
  "displayName": "Conta B (Hurl)",
  "persona": "socratico",
  "biometricEnabled": true
}
HTTP 200
[Asserts]
jsonpath "$.data.displayName" == "Conta B (Hurl)"
jsonpath "$.data.persona" == "socratico"
jsonpath "$.data.biometricEnabled" == true
jsonpath "$.data.email" == "cenario-uma@cerne.test"

# corpo vazio ({}) é válido — todos os campos são opcionais, nada muda
PATCH {{base_url}}/account-settings-update
Authorization: Bearer {{access_token}}
{}
HTTP 200
[Asserts]
jsonpath "$.data.displayName" == "Conta B (Hurl)"
