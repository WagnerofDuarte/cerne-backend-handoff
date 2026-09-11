# T-056 — GET /dashboard/aggregate: sempre 200, nos três cenários de
# volume do RF09 (0/1/>30 entradas — as 3 contas do seed).

# sem token -> AUTH_EXPIRED
GET {{base_url}}/dashboard-aggregate-get?period=all
HTTP 401
[Asserts]
jsonpath "$.code" == "AUTH_EXPIRED"

# conta C (cenario-vazio): zero entradas -> 200, buckets: []
POST {{base_url}}/auth-login
{
  "email": "cenario-vazio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
vazio_token: jsonpath "$.data.session.accessToken"

GET {{base_url}}/dashboard-aggregate-get?period=all
Authorization: Bearer {{vazio_token}}
HTTP 200
[Asserts]
jsonpath "$.data.buckets" count == 0
jsonpath "$.data.totals.count" == 0
header "X-Data-Version" exists

# conta B (cenario-uma): 1 entrada -> 200, totals.count == 1
POST {{base_url}}/auth-login
{
  "email": "cenario-uma@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
uma_token: jsonpath "$.data.session.accessToken"

GET {{base_url}}/dashboard-aggregate-get?period=all
Authorization: Bearer {{uma_token}}
HTTP 200
[Asserts]
jsonpath "$.data.totals.count" == 1

# conta A (cenario-cheio): 34 entradas (>30) -> 200, totals.count == 34
POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
cheio_token: jsonpath "$.data.session.accessToken"

GET {{base_url}}/dashboard-aggregate-get?period=all
Authorization: Bearer {{cheio_token}}
HTTP 200
[Asserts]
jsonpath "$.data.totals.count" == 34
jsonpath "$.data.totals.sources.manual" == 14
jsonpath "$.data.totals.sources.audio" == 8
jsonpath "$.data.totals.sources.photo" == 6
jsonpath "$.data.totals.sources.chat" == 6

# period=7d com o relógio fixado na âncora do seed (supabase/seed/ancora.md)
# — a conta A distribui as 34 entradas em 10 dias, então uma janela de 7
# dias tem que excluir pelo menos parte delas (< 34, nunca == , nunca erro).
GET {{base_url}}/dashboard-aggregate-get?period=7d
Authorization: Bearer {{cheio_token}}
X-Test-Key: {{test_fault_key}}
X-Test-Now: 2026-09-23T09:41:00Z
HTTP 200
[Asserts]
jsonpath "$.data.totals.count" < 34
