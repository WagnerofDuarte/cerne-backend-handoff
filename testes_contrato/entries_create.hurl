# T-035/036/037 — POST /entries: caminho feliz + validação + sem token.
# Ver tests/hurl/README.md. Faz uma chamada real à Anthropic (PII) e à
# Voyage (embedding) — sem cache de replay ainda (T-060 é Fase 6).

POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

# sem token -> AUTH_EXPIRED
POST {{base_url}}/entries-create
{
  "content": "entrada de teste sem token",
  "source": "manual"
}
HTTP 401
[Asserts]
jsonpath "$.code" == "AUTH_EXPIRED"

# corpo inválido (content vazio) -> VALIDATION_ERROR
POST {{base_url}}/entries-create
Authorization: Bearer {{access_token}}
{
  "content": "",
  "source": "manual"
}
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_ERROR"

# refinamento Zod: source='chat' exige chatMessageId -> VALIDATION_ERROR
POST {{base_url}}/entries-create
Authorization: Bearer {{access_token}}
{
  "content": "mensagem de chat sem id",
  "source": "chat"
}
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_ERROR"

# caminho feliz
POST {{base_url}}/entries-create
Authorization: Bearer {{access_token}}
{
  "content": "Registro de teste do Hurl — dia tranquilo, sem novidades.",
  "source": "manual"
}
HTTP 200
[Asserts]
jsonpath "$.data.id" exists
jsonpath "$.data.content" == "Registro de teste do Hurl — dia tranquilo, sem novidades."
jsonpath "$.data.source" == "manual"
jsonpath "$.data.piiStatus" matches "^(clean|flagged)$"
jsonpath "$.data.embeddingStatus" matches "^(ready|failed)$"
jsonpath "$.data.tags" count == 0
jsonpath "$.data.serverRevision" >= 0
jsonpath "$.meta.idempotentReplay" not exists
