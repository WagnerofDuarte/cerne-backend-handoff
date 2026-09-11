# T-050 — POST /chat/sessions/:id/insight (RF08). Critério de conclusão:
# "Dois POST com o mesmo triggerKey → mesmo id" — a UNIQUE
# (session_id, trigger_type, trigger_key), migração 0006, garante o
# disparo único pelo banco, não pelo código (mesmo espírito de D4/RF10).

POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

POST {{base_url}}/chat-sessions-create
Authorization: Bearer {{access_token}}
{}
HTTP 200
[Captures]
session_id: jsonpath "$.data.id"

# 1º POST — cria o insight de verdade (chama a Haiku).
POST {{base_url}}/chat-insight-create/{{session_id}}
Authorization: Bearer {{access_token}}
{
  "triggerType": "message_count",
  "triggerKey": "1"
}
HTTP 200
[Captures]
insight_id: jsonpath "$.data.id"
[Asserts]
jsonpath "$.data.triggerType" == "message_count"
jsonpath "$.data.triggerKey" == "1"

# 2º POST — mesmo triggerType/triggerKey -> conflito na UNIQUE -> devolve
# o MESMO insight (mesmo id), sem chamar a Haiku de novo.
POST {{base_url}}/chat-insight-create/{{session_id}}
Authorization: Bearer {{access_token}}
{
  "triggerType": "message_count",
  "triggerKey": "1"
}
HTTP 200
[Asserts]
jsonpath "$.data.id" == "{{insight_id}}"

# triggerKey diferente -> insight DIFERENTE (a UNIQUE é por chave, não por sessão)
POST {{base_url}}/chat-insight-create/{{session_id}}
Authorization: Bearer {{access_token}}
{
  "triggerType": "message_count",
  "triggerKey": "2"
}
HTTP 200
[Asserts]
jsonpath "$.data.id" != "{{insight_id}}"
