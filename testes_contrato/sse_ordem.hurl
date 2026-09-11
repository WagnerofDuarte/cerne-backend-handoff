# T-044/T-046 — POST /chat/sessions/:id/messages: a resposta SSE emite os
# eventos sempre na ordem fixa da D12 (message_created -> context ->
# token* -> done). Critério de conclusão do T-044.
#
# Nota (mesmo espírito das notas de tests/hurl/README.md): esta é a
# primeira suíte da Fase 4 a exercitar uma resposta em streaming
# (`text/event-stream`) via Hurl — nenhuma fase anterior precisou disso.
# O Hurl não tem um modo dedicado de "ler SSE evento a evento"; a
# abordagem aqui é deixar a conexão fechar (o servidor fecha o stream
# sozinho depois do `done`) e checar a ORDEM dos marcadores no corpo
# inteiro via uma regex com `(?s)` (o `.` passa a casar quebra de linha
# também). Se isso se provar frágil rodando de verdade, é esperado — como
# toda 1ª execução real de uma peça nova deste projeto, documentar o que
# for encontrado aqui.
#
# Custo: esta requisição chama a Anthropic de verdade (Sonnet 5) se o
# cache de replay ainda não tiver essa conversa gravada — mesmo padrão já
# aceito em entries_create.hurl/busca_semantica.hurl (Fase 3).

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

POST {{base_url}}/chat-messages-send/{{session_id}}
Authorization: Bearer {{access_token}}
{
  "content": "Estou me sentindo um pouco ansioso hoje, alguma sugestão?"
}
HTTP 200
[Asserts]
header "Content-Type" == "text/event-stream; charset=utf-8"
header "X-Replay-Status" matches "^(hit|miss|off)$"
body matches "(?s)event: message_created.*event: context.*event: token.*event: done"
body not contains "event: error"

# a sessão ganhou título (truncamento determinístico da 1ª mensagem, sem IA)
GET {{base_url}}/chat-sessions-list
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.data[?(@.id=='{{session_id}}')].title" != ""

# as duas mensagens (usuário + assistente) foram persistidas, seq 1 e 2
GET {{base_url}}/chat-messages-list/{{session_id}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.data" count == 2
jsonpath "$.data[0].role" == "user"
jsonpath "$.data[0].seq" == 1
jsonpath "$.data[1].role" == "assistant"
jsonpath "$.data[1].seq" == 2
jsonpath "$.data[1].status" == "complete"
