# Suíte Hurl — Fases 3 (`T-034`–`T-041`), 4 (`T-042`–`T-050`, chat) e 5 (`T-051`–`T-059`, exportação/dashboard/conta)

Contrato de endpoint (§11.2 do plano técnico): caminho feliz, corpo
inválido → `VALIDATION_ERROR`, sem token → `AUTH_EXPIRED`, recurso de
outro usuário → `NOT_FOUND` (nunca `403`, D7). Mais as suítes específicas
nomeadas no plano: `idempotencia_rf10.hurl`, `tags_embutidas.hurl`,
`busca_and.hurl`, `busca_semantica.hurl` (Fase 3); `chat_sessions.hurl`,
`sse_ordem.hurl`, `retry_chat.hurl`, `insight_unico.hurl`,
`insight_falha.hurl` (Fase 4).

**Novidade da Fase 4 — streaming SSE:** `chat-messages-send`/`.retry`
respondem `text/event-stream`, não JSON. O Hurl não tem um modo dedicado
de ler evento a evento; `sse_ordem.hurl` deixa a conexão fechar (o
servidor fecha sozinho após `done`/`error`) e verifica a ORDEM dos
marcadores no corpo inteiro via `body matches` com uma regex `(?s)`. É a
1ª vez que este projeto testa uma resposta em streaming via Hurl — se
isso se provar frágil rodando de verdade (buffering do runtime de Edge
Functions, timeout de leitura do Hurl em uma conexão que fica aberta por
alguns segundos), é esperado, e vale documentar aqui o que for encontrado
(mesmo espírito dos 5 achados reais da Fase 3 abaixo).

## Novidade da Fase 5 — exportação assíncrona

`export_download.hurl` e `export_resiliente.hurl` são os primeiros arquivos
deste projeto que esperam um **worker assíncrono** terminar (`export-worker`,
T-054, acordado pelo `pg_cron`/`pg_net` da migração 0014) — usam `[Options]
retry: 20` / `retry-interval: 3000` no `GET /export-status-get/...` para
tentar de novo até o job sair de `pending`, em vez de assumir que já está
pronto na primeira tentativa. Isso é novo para este projeto (todo endpoint
anterior resolve na própria requisição) — se `retry`/`retry-interval` não
existirem nessa forma na versão do Hurl instalada, é esperado que precise
de ajuste; reportar o que for encontrado, mesmo espírito dos achados reais
das fases anteriores.

**Pré-requisito só destas duas suítes:** o worker só desperta de verdade se
`experiment.worker_config` tiver uma linha (a fila/consumidor da migração
0014 lê essa tabela para saber para onde despachar) — rodar uma vez, à
mão, depois do `supabase db reset`:

```sql
insert into experiment.worker_config (functions_base_url, shared_secret)
values ('http://host.docker.internal:54321/functions/v1', '<o mesmo valor de EXPORT_WORKER_SECRET no .env.local>');
```

Sem `psql`/Studio à mão (achado real, Wagner, macOS — o Mac não vem com o
cliente `psql` instalado por padrão), o mesmo INSERT/UPDATE (idempotente)
via `deno`, sem precisar de nenhum binário extra:

```bash
EXPORT_WORKER_SECRET='<o mesmo valor do .env.local>' \
  deno run --allow-net --allow-env scripts/configure-worker.ts
```

`EXPORT_WORKER_SECRET` é uma variável nova (migração 0019) — precisa estar
em `supabase/.env.local` (qualquer string, escolhida por você; só precisa
ser a MESMA usada nesse INSERT) antes de rodar `supabase functions serve`.

**Achado real (Wagner, T-059v):** `127.0.0.1` aqui **não funciona** —
`pg_cron`/`pg_net` rodam dentro do container Docker do Postgres, e de lá
`127.0.0.1` aponta para o próprio container, não para a máquina onde
`supabase functions serve` está escutando. `host.docker.internal` é o
apelido que o Docker Desktop (Mac/Windows) usa para um container alcançar
a própria máquina — funciona sem configuração extra. Sintoma sem essa
correção: os jobs ficam presos em `pending` para sempre, e nenhuma linha
"serving the request with supabase/functions/export-worker" aparece no
log do `functions serve` (o worker nunca chega a ser chamado).

**2º achado real (Wagner, T-059v), mais sutil — coluna renomeada na
migração 0019:** mesmo com a URL corrigida (`net._http_response` mostrando
`status_code: 401`, não mais erro de conexão — prova de que a rede
funcionava), os jobs continuavam presos em `pending`. Causa: a coluna se
chamava `service_role_key` e a instrução original deste README pedia para
colar aqui a `SUPABASE_SERVICE_ROLE_KEY` do `.env.local` — mas `supabase
functions serve --env-file` **recusa carregar qualquer variável cujo nome
comece com `SUPABASE_`** do arquivo do desenvolvedor (imprime `Env name
cannot start with SUPABASE_, skipping: SUPABASE_SERVICE_ROLE_KEY` e injeta
sempre o valor interno da própria stack local no lugar). Ou seja: o valor
que você colava aqui nunca podia ser igual ao que a função `export-worker`
via de verdade em tempo de execução — a checagem de autorização
(`export-worker/index.ts`) rejeitava toda chamada com 401. Corrigido
trocando essa checagem por um segredo próprio, `EXPORT_WORKER_SECRET`, sem
o prefixo `SUPABASE_` (a CLI não mexe nele) — coluna renomeada para
`shared_secret` para não sugerir mais que precisa ser a service_role key
de verdade.

**3º achado real (Wagner, T-059v) — bug de código de verdade, corrigido
(migração 0020):** com a URL e o segredo já certos, o `export-worker`
finalmente era chamado (a linha "serving the request with
supabase/functions/export-worker" já aparecia no log) — mas o job
continuava preso em `pending`, nunca virava `error`. Antes disso não dava
pra saber o motivo: o `catch` do worker engolia o erro em silêncio (também
corrigido, ver mais abaixo). Com o log falando, apareceu o motivo real:
`permission denied for table export_jobs (42501)`. `service_role` tem
`BYPASSRLS` (ignora RLS), mas isso não dispensa o `GRANT` comum de tabela
— são dois mecanismos independentes do Postgres, e nenhuma migração
anterior tinha dado esse `GRANT` porque esta foi a 1ª vez que
`service_role` tocou uma tabela diretamente neste projeto (todo uso
anterior era `GRANT EXECUTE` numa RPC `SECURITY DEFINER`, que roda com o
privilégio do dono da função, não do chamador). Corrigido: `grant select,
update on public.export_jobs to service_role;` + `grant select on
public.entries to service_role;`.

**Achado de log, não de comportamento — 3 pontos que engoliam erro em
silêncio, corrigidos:** até aqui, um bug real de banco virava só "500
genérico" (`gateway.ts`) ou "job preso em pending" (`export-worker`) sem
NENHUMA pista no log do `functions serve` — foi assim que este achado (e o
`PGRST303` logo abaixo) só puderam ser confirmados, depois de adicionar
`console.error` em `gateway.ts` (`handleError`) e
`export-worker/{index,worker}.ts`. Nenhuma resposta ao cliente mudou — só
passou a aparecer no log.

**Achado de ambiente (não é bug de código) — `dashboard_aggregate.hurl`,
`PGRST303 "JWT issued at future"`:** o PostgREST rejeitou um token recém-
emitido pelo `auth-login` porque, do ponto de vista dele, foi "emitido no
futuro" — sintoma clássico de relógio do Docker Desktop dessincronizado do
relógio do Mac (comum depois que o Mac dorme/acorda com o Docker rodando).
Nada no código deste projeto define esse timestamp.

Simplesmente fechar/reabrir o Docker Desktop **nem sempre** resincroniza a
VM de verdade (achado real — persistiu mesmo depois disso, num teste com o
Wagner). Correção mais confiável, direto no relógio da VM:

```bash
docker run --rm --privileged --pid=host justincormack/nsenter1 date -u $(date -u +%m%d%H%M%Y.%S)
```

Isso força o relógio de dentro do Docker a bater com o do Mac agora mesmo
— comando só de leitura de data, não mexe em nenhum container/dado seu.
Se ainda assim persistir, o próximo passo é mais pesado: `supabase stop`,
fechar o Docker Desktop de verdade (não só a janela — sair do app pelo
menu), abrir de novo, `supabase start` (recria os containers do zero,
inclusive o de autenticação). **Confirmado (Wagner):** um reboot completo
do Mac também resolve, sem precisar de nenhum comando manual — resincroniza
tudo de uma vez.

**Lembrete de processo — não é bug, mas já causou 2 falsos alarmes:**
depois de QUALQUER `supabase db reset`, a tabela `experiment.worker_config`
volta vazia — o `INSERT` (acima) precisa ser refeito, com o MESMO valor
que está em `EXPORT_WORKER_SECRET` no `.env.local` naquele momento. Se os
dois ficarem diferentes (ex.: você trocou o `.env.local` depois de um
`db reset` anterior e esqueceu de atualizar a tabela), o sintoma é
exatamente o mesmo de antes — job preso em `pending` — só que agora o log
é claro sobre o motivo: `401 — bearer recebido não bate com
EXPORT_WORKER_SECRET`. Conferir os dois lados (`select shared_secret from
experiment.worker_config;` vs. `grep EXPORT_WORKER_SECRET
supabase/.env.local`) resolve na hora, com um simples `UPDATE` — não
precisa de outro `db reset`.

Sem `experiment.worker_config` configurado (de qualquer jeito, certa ou
errada), `export_dispatch_pending_jobs()` roda a cada 15s mas sai em
silêncio (nenhum erro, nenhum despacho) — os jobs ficam presos em
`pending` para sempre, e os dois arquivos acima estouram o `retry` e
falham. Se isso acontecer mesmo com a linha configurada (URL certa,
`shared_secret` igual ao `EXPORT_WORKER_SECRET`, migração 0020 aplicada),
é sinal de que o `pg_net`/`pgmq` reais (Nota de ambiente da migração 0014
— nenhum dos dois pôde ser exercitado no sandbox onde este código foi
escrito) não estão se
comportando como o esperado — reportar.

**Achado real de sintaxe, `hurlfmt --check` (versão 6.1.1, a mesma do
Wagner — baixada neste sandbox só para validar, não versionada):**
`retry-interval` não aceita um número puro, precisa da unidade explícita
(`3000ms`, não `3000`) — sem isso `hurlfmt` reformata silenciosamente na
primeira execução real, o que teria mascarado o erro em vez de apontá-lo
aqui. Corrigido nos dois arquivos antes de qualquer execução real.

`account_delete.hurl` usa `{{newUuid}}` (função embutida do Hurl, não uma
variável passada por `--variable`) para gerar um e-mail descartável
novo a cada execução — nunca uma das 3 contas do seed, cujo apagamento
quebraria o resto da suíte inteira.

## Convenção de URL — importante

Os arquivos chamam `{{base_url}}/<nome-da-função>`, **não** o caminho REST
"bonito" do OpenAPI (`/entries/:id`, `/auth/login`, ...). Cada endpoint é
uma Edge Function própria (Seção 2: "um diretório por endpoint"), com nome
= o `id` do `registry.ts` (T-026) trocando `.` por `-` — decisão registrada
em `big-plan.md`, Fase 3. Ex.: `entries.get` → função `entries-get`,
chamada em `{{base_url}}/entries-get/<id>` (o `:id` vira o último segmento
da URL, extraído pelo próprio `index.ts`).

## Como rodar

Pré-requisitos: `supabase start` + `supabase functions serve --env-file
supabase/.env.local` rodando localmente (GATE-01, Docker), banco com o
seed da Fase 1 carregado (`supabase db reset`).

**O `--env-file` não é opcional** — sem ele, nenhuma variável de ambiente
(`ANTHROPIC_API_KEY`, `VOYAGE_API_KEY`, `PROMPT_VERSION`, ...) chega até a
função, e `requireEnv` (`_shared/deps.ts`) lança um erro síncrono no
top-level do `index.ts`, fora de qualquer handler — isso derruba o worker
inteiro antes de processar a requisição, mesmo em endpoints/sub-passos
que não deveriam precisar de IA (ex.: a sub-requisição "sem token" do
`media_ocr.hurl`, que só checa auth). O sintoma na prática: a requisição
fica pendurada até o teto de wall-clock do runtime (150s local) e só
então volta um `504` — mesma aparência de trava que a nota abaixo
descreve, mas causa totalmente diferente (achado real, 04/09/2026).
`supabase/.env.local` está no `.gitignore` — nunca é versionado; precisa
de `ANTHROPIC_API_KEY`, `VOYAGE_API_KEY`, `PROMPT_VERSION`, `REPLAY_MODE`
(ver Seção 3.6 do plano técnico para a lista completa e onde conseguir
cada chave), mais `EXPORT_WORKER_SECRET` (Fase 5, T-054 — qualquer string
seguindo o achado real documentado na seção "Novidade da Fase 5" acima;
só usado por `export_download.hurl`/`export_resiliente.hurl`, indireta
via `experiment.worker_config.shared_secret`).

```bash
hurl --test --jobs 1 \
  --variable base_url=http://127.0.0.1:54321/functions/v1 \
  --variable test_account_password='Cerne-Teste-2026!' \
  --variable test_fault_key='<mesmo valor de TEST_FAULT_KEY no .env.local>' \
  tests/hurl/*.hurl
```

`test_fault_key` só é usado por `insight_falha.hurl` (1ª suíte deste
projeto a injetar falha via `X-Test-Fault` — Seção 10.1) — sem ele (ou
com um valor errado), o cabeçalho é "ignorado em silêncio" por design
(§10.1) e a chamada acaba indo para a Anthropic de verdade em vez de
simular `ai_timeout`.

**`--jobs 1` não é opcional quando se roda mais de um arquivo de uma vez**
— achado real, 07/09/2026: o `hurl --test` roda os arquivos em paralelo
por padrão (`--parallel: Run files in parallel (default in test mode)`,
confirmado no `hurl --help`, versão 6.1.1). Quase todo arquivo desta
suíte faz login na mesma conta seed (`cenario-cheio@cerne.test`) — em
paralelo, vários logins pra essa conta disparam quase simultaneamente, e
o `auth.hurl` chama `POST /auth/logout` nessa janela (escopo padrão do
GoTrue é `global`: revoga todas as sessões do usuário, não só a que
originou o logout). Isso colide com um bug aberto e conhecido do próprio
Supabase Auth com múltiplas sessões concorrentes por usuário
([supabase/auth#2036](https://github.com/supabase/auth/issues/2036)) —
um logout acaba invalidando sessões de outros logins concorrentes pela
mesma conta, não só a própria. Sintoma visto rodando de verdade: arquivos
que ainda tinham requisições pendentes com o token de `cenario-cheio`
(`media_ocr.hurl`, `idempotencia_rf10.hurl`) receberam `401` em vez do
status esperado, mesmo cada um tendo feito seu próprio login com sucesso
poucos milissegundos antes. `--jobs 1` força execução sequencial, arquivo
por arquivo — mais lento, mas sem essa colisão. Não é um bug do código
deste projeto (`gateway.ts`/`auth-logout` fazem exatamente o que o
contrato pede — "proxy fino do GoTrue", D1); é uma característica do
`hurl` moderno colidindo com uma conta compartilhada entre arquivos.

`media_ocr.hurl` precisa de três variáveis extras, geradas a partir das
fixtures da `T-020` (não versionadas em base64 dentro do `.hurl` — os
arquivos de imagem já existem em `fixtures/media/`). **Usar
`--variables-file`, não `--variable`** — confirmado neste sandbox: o
valor em base64 da imagem "grande demais" (>5MB decodificados) estoura o
`ARG_MAX` do shell (2MB neste sistema) quando passado como argumento de
linha de comando; um arquivo de propriedades não tem esse limite.

Dois detalhes de portabilidade do `base64` entre sistemas (achados rodando
de verdade num Mac — confirmar antes de assumir que "é só rodar"):

- **Passar o arquivo por entrada padrão (`<`), não como argumento** — a
  variante do macOS (BSD) não aceita `base64 arquivo`, só `base64 -i
  arquivo` ou `base64 < arquivo`; a do Linux (GNU) aceita as duas formas.
  `<` funciona nas duas.
- **`| tr -d '\n'` é obrigatório** — sem isso, o `base64` quebra a saída em
  linhas de ~76 caracteres por padrão; um valor de propriedade com quebra
  de linha no meio vira uma linha nova sem `chave=`, e o Hurl reconstrói a
  variável errada. Confirmado num teste real: sem o `tr`, a requisição
  trava por ~2min e volta com um erro de timeout do motor de Edge
  Functions em vez do 401 esperado, porque o corpo da requisição fica
  malformado.

**Atualização — a trava voltou mesmo com o `.properties` correto (sem
quebra de linha), e a causa era outra:** o log local mostrava "wall clock
duration warning" seguido de "early termination has been triggered" — não
é um limite de tamanho de corpo, é o teto externo do próprio motor de Edge
Functions (150s local/free, 400s pago) matando o isolate à força quando
algo dentro dele nunca retorna. Investigando o código (`ai/anthropic.ts`,
`ai/voyage.ts`, T-032): a chamada `fetch` para a Anthropic/Voyage não
tinha nenhum timeout próprio — se a rede travar (egress do Docker local,
DNS, etc.), a promise nunca resolve nem rejeita sozinha, e só o teto
externo do runtime interrompe, produzindo esse log em vez do erro normal
do envelope do projeto. Bate exatamente com o sintoma: as sub-requisições
de `media_ocr.hurl` que nunca chegam a chamar a Anthropic (401 sem token,
413 de imagem grande) respondiam na hora; só as duas que chamam
`performOcr` de verdade (imagem ilegível, caminho feliz) travavam.
Corrigido adicionando `signal: AbortSignal.timeout(30_000)` nos dois
clientes (`ANTHROPIC_REQUEST_TIMEOUT_MS`/`VOYAGE_REQUEST_TIMEOUT_MS`) —
uma chamada presa agora falha em 30s com um erro normal (`AI_GENERATION_
TIMEOUT` no OCR; cai no fallback `status: 'failed'` já existente no
embedding de `POST /entries`, D8) em vez de segurar o isolate até ele ser
morto de fora.

**Segunda atualização — a trava voltou de novo, agora na 1ª sub-requisição
do arquivo (a que testa "sem token" → 401), que nem chama a Anthropic:**
causa raiz diferente e mais fundamental, achada no `gateway.ts` (T-031),
não nos clientes de IA. Bug documentado do próprio Deno
([denoland/deno#10182](https://github.com/denoland/deno/issues/10182)):
devolver uma `Response` sem nunca ler o corpo da requisição trava a
conexão no `Deno.serve`/edge-runtime quando o payload é grande. O
`gateway.ts` autentica (passo 5) **antes** de validar o corpo com Zod
(passo 6) — então "sem token" lança `AUTH_EXPIRED` sem nunca tocar no
corpo, e a imagem real de ~2.2MB fica sem ser lida nem descartada.
Corrigido com um `finally` em `runGateway` que drena (`req.arrayBuffer()`)
qualquer corpo ainda não consumido antes de responder — cobre todo
caminho que rejeita antes do passo 6, não só este. Teste de regressão em
`gateway.test.ts` (`req.bodyUsed` vira `true` mesmo numa rejeição por
`AUTH_EXPIRED`).

**Confirmado pelo Wagner (07/09/2026), rodando de verdade contra o Docker
local:** `media_ocr.hurl` passa os 6 requests em ~9s depois desse fix. Uma
mensagem isolada de `early termination has been triggered` continuou
aparecendo no log entre requisições (isolate reciclado por estar ocioso,
sem trabalho pendente) — inofensiva quando não vem acompanhada de uma
requisição pendurada; era exatamente essa combinação (log + travamento)
que apontava pro bug real acima, não a mensagem em si.

```bash
{
  printf 'image_base64='; base64 < fixtures/media/ocr_fixture_01.png | tr -d '\n'; echo
  printf 'image_base64_illegible='; base64 < fixtures/media/ocr_fixture_ilegivel.png | tr -d '\n'; echo
  printf 'image_base64_oversized='; head -c 6000000 /dev/urandom | base64 | tr -d '\n'; echo
} > /tmp/hurl-ocr-vars.properties

hurl --test \
  --variable base_url=http://127.0.0.1:54321/functions/v1 \
  --variable test_account_password='Cerne-Teste-2026!' \
  --variables-file /tmp/hurl-ocr-vars.properties \
  tests/hurl/media_ocr.hurl
```

## Contas do seed usadas (Fase 1, `supabase/seed/seed.sql`)

| Conta | E-mail | `user_id` |
|---|---|---|
| A (`cenario-cheio`) | `cenario-cheio@cerne.test` | `a0000000-0000-0000-0000-000000000001` |
| B (`cenario-uma`) | `cenario-uma@cerne.test` | `b0000000-0000-0000-0000-000000000001` |
| C (`cenario-vazio`) | `cenario-vazio@cerne.test` | `c0000000-0000-0000-0000-000000000001` |

Senha única: `TEST_ACCOUNT_PASSWORD` (`Cerne-Teste-2026!`, documentado em
`supabase/seed/ancora.md`).

## Nota de ambiente

Escritos neste sandbox e validados em duas camadas, mas **nunca contra o
stack real do Supabase** (bloqueio de rede de Docker, mesma nota das
Fases 1/2/3):
1. Sintaxe: `hurlfmt --check` em todos os 10 arquivos.
2. Semântica das asserções: um mock HTTP local (Deno, descartado — não faz
   parte do repositório) imitando as respostas plausíveis dos 10
   endpoints, rodando a suíte inteira de ponta a ponta contra ele. Isso
   pegou dois erros reais de sintaxe jsonpath do Hurl que só apareceriam
   rodando de verdade — documentados como comentário em
   `tags_embutidas.hurl` (encadear `[0]` depois de um filtro `[?(...)]`
   não funciona como parece; a forma certa usa `[*]` + `count`/`contains`)
   — e a descoberta do `--variables-file` acima (`ARG_MAX` do shell).

Rodar contra o stack local de verdade (Docker, `supabase functions serve`)
é uma ação do Wagner. `entries_create.hurl`, `idempotencia_rf10.hurl`,
`busca_semantica.hurl` e `entries_search.hurl` fazem chamadas reais à
Anthropic/Voyage (nenhum cache de replay populado ainda — isso só
acontece no `T-060`, Fase 6) — custo pequeno, dentro do teto de gasto do
`GATE-04`/`GATE-05`.

**Fase 5, mesma nota de ambiente** (código escrito e testado neste
sandbox — `deno test`, tudo mockado; pgTAP das migrações 0013–0018
validado com Postgres 16 real via `apt`, mas `pgmq`/`pg_net`/`storage.*`
tiveram que ser simulados por um stub local, nunca a extensão/serviço de
verdade — ver os comentários nas próprias migrações). Os 11 arquivos novos
(`export_summary`, `export_vazio`, `export_status`, `export_download`,
`export_resiliente`, `dashboard_aggregate`, `dashboard_narrative`,
`dashboard_degradado`, `account_settings`, `email_readonly`,
`account_delete`) foram validados em sintaxe (`hurlfmt --check`, achado
real acima) e em semântica/fluxo — captures entre requisições, o
mecanismo de `retry` esperando o "worker" terminar, `{{newUuid}}` — contra
um mock HTTP local (Deno, descartado, não versionado, mesmo espírito do
mock da Fase 3): **11/11 arquivos, 55 requisições, 100%**. Nunca rodaram
contra o stack real do Supabase nem chamaram Anthropic de verdade nesta
validação. Ao rodar de verdade, `dashboard_narrative.hurl` (caminho feliz)
faz uma chamada real à Anthropic; `export_resiliente.hurl` dispara o
worker mas o `ai_timeout` marcado impede a chamada real de acontecer — só
o download/status são exercitados de ponta a ponta.
