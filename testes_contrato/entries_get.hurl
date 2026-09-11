# T-039 — GET /entries/:id: caminho feliz + sem token + recurso de outro
# usuário -> 404 NOT_FOUND (nunca 403, D7). Critério de conclusão
# explícito do T-039.

POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token_a: jsonpath "$.data.session.accessToken"

POST {{base_url}}/auth-login
{
  "email": "cenario-uma@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token_b: jsonpath "$.data.session.accessToken"

# sem token -> AUTH_EXPIRED
GET {{base_url}}/entries-get/a0000000-0000-0000-0004-000000000008
HTTP 401
[Asserts]
jsonpath "$.code" == "AUTH_EXPIRED"

# a própria dona lê a entrada -> 200
GET {{base_url}}/entries-get/a0000000-0000-0000-0004-000000000008
Authorization: Bearer {{access_token_a}}
HTTP 200
[Asserts]
jsonpath "$.data.id" == "a0000000-0000-0000-0004-000000000008"

# conta B tenta ler uma entrada da conta A -> 404 NOT_FOUND, nunca 403 (D7)
GET {{base_url}}/entries-get/a0000000-0000-0000-0004-000000000008
Authorization: Bearer {{access_token_b}}
HTTP 404
[Asserts]
jsonpath "$.code" == "NOT_FOUND"

# uuid bem formado mas inexistente -> 404 NOT_FOUND
GET {{base_url}}/entries-get/99999999-9999-9999-9999-999999999999
Authorization: Bearer {{access_token_a}}
HTTP 404
[Asserts]
jsonpath "$.code" == "NOT_FOUND"

# id que não é sequer um uuid -> 404 (nunca erro de sintaxe do banco)
GET {{base_url}}/entries-get/nao-e-um-uuid
Authorization: Bearer {{access_token_a}}
HTTP 404
[Asserts]
jsonpath "$.code" == "NOT_FOUND"
