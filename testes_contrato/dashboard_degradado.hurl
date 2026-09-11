# T-057 — Dashboard degradado (Contexto Geral.md, cenário nomeado
# explicitamente): com `ai_timeout` na narrativa, o agregado continua 200 —
# os dois endpoints são independentes (§8.5, literal).

POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

# narrativa falha via ai_timeout -> AI_GENERATION_TIMEOUT, nunca 200 com lixo
GET {{base_url}}/dashboard-narrative-get?period=30d
Authorization: Bearer {{access_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Fault: ai_timeout
HTTP 504
[Asserts]
jsonpath "$.code" == "AI_GENERATION_TIMEOUT"
jsonpath "$.retryable" == true

# o agregado nem percebe — endpoint totalmente independente, continua 200
GET {{base_url}}/dashboard-aggregate-get?period=30d
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.data.buckets" exists
