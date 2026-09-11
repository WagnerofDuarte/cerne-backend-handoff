# T-035 — Idempotência do RF10/D4 (critério de conclusão explícito do
# T-035): dois POST /entries com o mesmo chatMessageId produzem a MESMA
# entrada; a segunda resposta vem com meta.idempotentReplay=true. Sempre
# 200 — nunca 409 (D4, "garantido pelo banco, não pelo código").
#
# Reentrante de propósito: não assume que o chatMessageId está "fresco"
# (a primeira chamada pode, ela mesma, já ser um replay de uma execução
# anterior desta suíte) — só assevera a invariante real do RF10: as duas
# respostas trazem o mesmo id, e a segunda é sempre um replay.
#
# a0000000-0000-0000-0003-000000000001 é a 1ª mensagem (role='user') da
# sessão 1 da conta A no seed (supabase/seed/seed.sql) — não está entre as
# 3 mensagens da sessão 2 já promovidas a entries pelo próprio seed.

POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

POST {{base_url}}/entries-create
Authorization: Bearer {{access_token}}
{
  "content": "mensagem promovida a entrada via RF10 (suíte Hurl)",
  "source": "chat",
  "chatMessageId": "a0000000-0000-0000-0003-000000000001"
}
HTTP 200
[Captures]
first_id: jsonpath "$.data.id"
[Asserts]
jsonpath "$.data.chatMessageId" == "a0000000-0000-0000-0003-000000000001"
jsonpath "$.data.source" == "chat"

POST {{base_url}}/entries-create
Authorization: Bearer {{access_token}}
{
  "content": "mensagem promovida a entrada via RF10 (suíte Hurl)",
  "source": "chat",
  "chatMessageId": "a0000000-0000-0000-0003-000000000001"
}
HTTP 200
[Asserts]
jsonpath "$.data.id" == "{{first_id}}"
jsonpath "$.meta.idempotentReplay" == true

# GET /entries/:id confirma que só existe UMA linha com este chatMessageId
# — não duas (a idempotência é garantida pelo índice único, T-014).
GET {{base_url}}/entries-get/{{first_id}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.data.id" == "{{first_id}}"
jsonpath "$.data.chatMessageId" == "a0000000-0000-0000-0003-000000000001"
