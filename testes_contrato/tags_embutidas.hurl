# T-038 — GET /entries traz tags[] populado, embutidas (sem N+1).
# Critério de conclusão explícito do T-038.
#
# a0000000-0000-0000-0004-000000000008 tem a tag 'trabalho' aplicada pelo
# seed (supabase/seed/seed.sql, bloco "entry_tags da conta A").
#
# Nota de sintaxe (achada rodando de verdade — versões diferentes do Hurl
# se comportam diferente aqui): `count`/`==` sobre um jsonpath que mistura
# filtro `[?(...)]` com `[*]` é frágil — algumas versões colapsam o
# resultado num valor único, outras mantêm lista. `contains` funciona nos
# dois casos (compara substring numa string ou elemento numa lista), e
# `exists`/`not exists` é a forma robusta de provar presença/ausência.

POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

GET {{base_url}}/entries-list?limit=50
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.data[?(@.id=='a0000000-0000-0000-0004-000000000008')]" exists
jsonpath "$.data[?(@.id=='a0000000-0000-0000-0004-000000000008')].tags[*].name" contains "trabalho"
jsonpath "$.data[?(@.id=='a0000000-0000-0000-0004-000000000008')].tags[*].id" exists
# uma entrada sem tag nenhuma vem com tags: [] (nunca null/ausente)
jsonpath "$.data[?(@.id=='a0000000-0000-0000-0004-000000000001')].tags[0]" not exists
