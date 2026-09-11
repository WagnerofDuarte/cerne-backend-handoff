# T-045 — POST /chat/sessions, GET /chat/sessions, GET
# /chat/sessions/:id/messages: caminho feliz + sem token + recurso de
# outro usuário -> 404 NOT_FOUND (nunca 403, D7).

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
POST {{base_url}}/chat-sessions-create
{}
HTTP 401
[Asserts]
jsonpath "$.code" == "AUTH_EXPIRED"

# sem title no corpo -> title='' e persona_snapshot igual à do perfil da conta A (empatico, seed)
POST {{base_url}}/chat-sessions-create
Authorization: Bearer {{access_token_a}}
{}
HTTP 200
[Captures]
session_id: jsonpath "$.data.id"
[Asserts]
jsonpath "$.data.title" == ""
jsonpath "$.data.userMessageCount" == 0

# com title explícito -> usa o título mandado, não fica vazio
POST {{base_url}}/chat-sessions-create
Authorization: Bearer {{access_token_a}}
{
  "title": "conversa de teste"
}
HTTP 200
[Asserts]
jsonpath "$.data.title" == "conversa de teste"

# listagem devolve pelo menos as sessões do seed da conta A (3, §6.5)
GET {{base_url}}/chat-sessions-list
Authorization: Bearer {{access_token_a}}
HTTP 200
[Asserts]
jsonpath "$.data" count >= 3

# mensagens de uma sessão inexistente -> 404 NOT_FOUND
GET {{base_url}}/chat-messages-list/99999999-9999-9999-9999-999999999999
Authorization: Bearer {{access_token_a}}
HTTP 404
[Asserts]
jsonpath "$.code" == "NOT_FOUND"

# conta B tenta ler mensagens de uma sessão da conta A -> 404, nunca 403 (D7)
GET {{base_url}}/chat-messages-list/{{session_id}}
Authorization: Bearer {{access_token_b}}
HTTP 404
[Asserts]
jsonpath "$.code" == "NOT_FOUND"

# a própria dona lê as mensagens -> 200 (sessão nova, ainda sem mensagens)
GET {{base_url}}/chat-messages-list/{{session_id}}
Authorization: Bearer {{access_token_a}}
HTTP 200
[Asserts]
jsonpath "$.data" count == 0
