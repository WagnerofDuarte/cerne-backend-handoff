# T-040 — GET /entries/search: sem token, modo filter_only sem `q`, sem
# throttle no servidor (dois pedidos seguidos não são bloqueados). Os dois
# modos em si (AND, semântica) têm suítes próprias: busca_and.hurl,
# busca_semantica.hurl.

# sem token -> AUTH_EXPIRED
GET {{base_url}}/entries-search
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

# q ausente -> filter_only, nenhum item vem com `similarity`
GET {{base_url}}/entries-search
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.meta.mode" == "filter_only"
jsonpath "$.data[0].similarity" not exists

# q vazio conta como ausente -> filter_only também
GET {{base_url}}/entries-search?q=
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.meta.mode" == "filter_only"

# sem throttle no servidor — dois pedidos seguidos, ambos 200 (o debounce
# de 300ms é responsabilidade do app, não do backend)
GET {{base_url}}/entries-search?q=trabalho
Authorization: Bearer {{access_token}}
HTTP 200

GET {{base_url}}/entries-search?q=trabalho
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.meta.mode" == "semantic"
