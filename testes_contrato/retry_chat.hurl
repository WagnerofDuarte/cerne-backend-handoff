# T-048 — POST /chat/sessions/:id/messages/:userMessageId/retry (D15).
# Critério de conclusão: X-Replay-Status: hit e retry_count=1.
#
# IMPORTANTE: exige REPLAY_MODE=record ou REPLAY_MODE=replay no
# `.env.local` — em REPLAY_MODE=off o cache nunca é consultado nem
# gravado (peekChatCacheStatus sempre devolve 'off'), e o critério deste
# arquivo (X-Replay-Status: hit) nunca pode ser satisfeito. Isso é
# diferente das outras suítes que chamam IA (entries_create.hurl,
# busca_semantica.hurl, sse_ordem.hurl) — elas só verificam que a
# geração funciona, não que bate no cache.
#
# Mecanismo (D15): a 1ª chamada a chat-messages-send grava a resposta no
# cache (miss). O retry reconstrói o MESMO envelope — mesmo histórico
# (nada mudou), mesma pergunta (relida do banco, não reenviada), mesmo
# RAG (determinístico, T-043) — então a 2ª consulta ao cache acerta
# (hit), sem chamar a Anthropic de novo.

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

# 1ª tentativa — popula o cache (miss ou hit, se REPLAY_MODE=record já
# tiver essa exata pergunta gravada de uma execução anterior).
POST {{base_url}}/chat-messages-send/{{session_id}}
Authorization: Bearer {{access_token}}
{
  "content": "Me dê uma dica rápida para organizar o dia."
}
HTTP 200

GET {{base_url}}/chat-messages-list/{{session_id}}
Authorization: Bearer {{access_token}}
HTTP 200
[Captures]
user_message_id: jsonpath "$.data[0].id"

# retry — mesmo histórico/pergunta/RAG da 1ª tentativa -> acerta o cache.
POST {{base_url}}/chat-messages-retry/{{session_id}}/{{user_message_id}}
Authorization: Bearer {{access_token}}
{}
HTTP 200
[Asserts]
header "X-Replay-Status" == "hit"
body matches "(?s)event: message_created.*event: context.*event: done"
body not contains "event: error"

GET {{base_url}}/chat-messages-list/{{session_id}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.data[1].retryCount" == 1
jsonpath "$.data[1].status" == "complete"

# retry num userMessageId que não é a última mensagem do usuário -> VALIDATION_ERROR
POST {{base_url}}/chat-messages-send/{{session_id}}
Authorization: Bearer {{access_token}}
{
  "content": "segunda pergunta, depois da primeira"
}
HTTP 200

POST {{base_url}}/chat-messages-retry/{{session_id}}/{{user_message_id}}
Authorization: Bearer {{access_token}}
{}
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_ERROR"
