# T-050 — POST /chat/sessions/:id/insight (RF08). Critério de conclusão:
# "Com ai_timeout → HTTP 200, status='failed'" — nunca um erro HTTP, "o
# chat não pode quebrar" (§8.3, literal).
#
# 1ª suíte desta fase (e do projeto) a usar X-Test-Fault — nenhum arquivo
# anterior precisou (as suítes de falha de T-034–T-048 testam o caminho
# real de erro, não a injeção). Requer `X-Test-Key` == `TEST_FAULT_KEY`
# do ambiente (Seção 10.1) — passado aqui como `{{test_fault_key}}`.

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

# ai_timeout força a "chamada de IA" a falhar, sem esperar nem custar nada
# — "o resto do endpoint funciona" (§10.2): grava o insight (status
# inicial 'generating' vira 'failed'), responde 200 normalmente.
POST {{base_url}}/chat-insight-create/{{session_id}}
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: ai_timeout
{
  "triggerType": "inactivity",
  "triggerKey": "algum-id-de-mensagem"
}
HTTP 200
[Asserts]
jsonpath "$.data.status" == "failed"
jsonpath "$.data.errorCode" == "AI_GENERATION_TIMEOUT"
jsonpath "$.data.content" == null
