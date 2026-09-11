# T-038 — GET /entries: sem token, paginação por cursor, ordenação, header
# X-Data-Version. (Tags embutidas tem suíte própria: tags_embutidas.hurl.)

# sem token -> AUTH_EXPIRED
GET {{base_url}}/entries-list
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

# 1ª página: limit=5, ordenação occurred_at DESC (mais recente primeiro)
GET {{base_url}}/entries-list?limit=5
Authorization: Bearer {{access_token}}
HTTP 200
[Captures]
next_cursor: jsonpath "$.meta.nextCursor"
first_page_first_id: jsonpath "$.data[0].id"
[Asserts]
header "X-Data-Version" exists
jsonpath "$.data" count == 5
jsonpath "$.meta.nextCursor" exists
jsonpath "$.meta.total" >= 34

# 2ª página: nenhum item repete o da 1ª
GET {{base_url}}/entries-list?limit=5&cursor={{next_cursor}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.data[?(@.id=='{{first_page_first_id}}')]" not exists

# limit inválido (> 50) -> VALIDATION_ERROR
GET {{base_url}}/entries-list?limit=999
Authorization: Bearer {{access_token}}
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_ERROR"

# conta vazia (cenario-vazio) -> 200, data: [], nunca erro
POST {{base_url}}/auth-login
{
  "email": "cenario-vazio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token_vazio: jsonpath "$.data.session.accessToken"

GET {{base_url}}/entries-list
Authorization: Bearer {{access_token_vazio}}
HTTP 200
[Asserts]
jsonpath "$.data" count == 0
jsonpath "$.meta.nextCursor" == null
jsonpath "$.meta.total" == 0
