# T-040 — GET /entries/search: busca por "ansiedade" retorna a entrada
# plantada do par 1. Critério de conclusão explícito do T-040 (Seção 6.4
# do plano técnico, prova original em T-024/scripts/prove-rf06.ts — aqui é
# o mesmo par, mas pelo endpoint real, não pela conexão direta ao banco).
#
# Faz uma chamada real à Voyage (embedding da query "ansiedade", sem cache
# de replay ainda — T-060 é Fase 6).
#
# Pré-requisito: as entradas da conta A precisam ter embedding_status=
# 'ready' de verdade — rodar `deno run --allow-net --allow-env
# scripts/backfill-seed-embeddings.ts` (com VOYAGE_API_KEY no ambiente)
# depois de qualquer `supabase db reset`, senão a busca semântica não
# encontra nada (RPC filtra por embedding_status='ready', T-040).

POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

GET {{base_url}}/entries-search?q=ansiedade&limit=5
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.meta.mode" == "semantic"
jsonpath "$.data[?(@.id=='a0000000-0000-0000-0004-000000000003')]" exists
jsonpath "$.data[0].similarity" exists
jsonpath "$.data[0].id" exists
