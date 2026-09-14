# Roteiro de validação (T-060, Fase 6)

**Status: Aprovado por Wagner em 10/09/2026** (mesmo espírito do `GATE-09`
que já aprovou `fixtures/pares_semanticos.md`) — executado de verdade em
modo `record` na Fase 7 (`T-064` passo 6) contra `ciclo-a`; corrigido D-25
(`docs/backend/DIVERGENCIAS_E_INCONSISTENCIAS.md`), esta linha estava
desatualizada desde a aprovação.

## Por que este documento existe

O plano técnico (§14.3) é direto: "o cache só produz determinismo se os
dois ciclos gerarem o mesmo pacote de entrada... sem esse roteiro, o cache
é decorativo." Este documento é esse roteiro — a sequência **fixa, literal,
tela a tela** que:

1. O Wagner segue manualmente, uma vez, contra o ambiente com
   `REPLAY_MODE=record` (`T-060`/`GATE-10`) — populando o cache de replay
   com respostas de IA de verdade.
2. O CI reexecuta automaticamente, duas vezes, com `REPLAY_MODE=replay_strict`
   (`T-062`, job `determinism`) — provando que o backend é determinístico.
3. É repetido no `ciclo-a` (grava) e reaproveitado via cache importado no
   `ciclo-b` (nunca regravado — `T-061`, Fase 7 §12 passo 6).

A versão executável — a MESMA sequência, em chamadas HTTP — é
`tests/determinism/roteiro_validacao.hurl`. Este documento é a narrativa
"o que o usuário vê/faz em cada tela"; aquele arquivo é o "o que isso
significa em termos de API". Os dois precisam ficar em sincronia — qualquer
mudança num implica revisar o outro.

## Por que só 4 textos literais novos, não os "7" estimados em 01/09/2026

`big-plan.md` (Fase 1, `T-021`/`GATE-09`) estimava "os 7 textos literais do
roteiro" antes de o roteiro em si existir — um chute razoável sem
visibilidade do desenho final. Desenhando a sequência de ponta a ponta
agora, com o sistema inteiro já construído (Fases 1-5), a conta é
diferente: a maior parte da jornada reaproveita fixtures **já aprovadas**
(`fixtures/pares_semanticos.md` para RF06, `fixtures/trancricoes.md` para a
entrada de origem áudio, `fixtures/media/*.png` para OCR) ou não precisa de
texto literal nenhum (dados semeados, filtros, endpoints de leitura). Só 4
textos são genuinamente novos — ver `fixtures/textos.json`. Divergência
sinalizada, não escondida (mesmo padrão da seção "Itens em aberto" do
big-plan.md).

## Regra de ordenação — a parte que não é óbvia

Três das 7 operações atrás do cache de replay (`chat`, `insight`,
`narrative`/`dashboard`) embutem, na impressão digital que decide o
`cache_key`, um id gerado pelo Postgres (`retrievedEntryIds`, `sessionId`,
`entryIdsHash` — `_shared/replay.ts`). Um id desses só é o MESMO em duas
execuções independentes (dois `db reset`, ou `ciclo-a` vs. `ciclo-b`) se
vier do **seed** (`supabase/seed/seed.sql`, ids literais fixos tipo
`a0000000-...`) — nunca de algo que o próprio roteiro cria (`POST /entries`,
`POST /chat/sessions` sempre geram id novo via `gen_random_uuid()`).

Por isso a jornada abaixo tem uma ordem obrigatória: **tudo que é sensível
a id via cache (chat, insight, busca, dashboard, exportação) vem antes de
qualquer criação de entrada nova.** Depois que a 1ª entrada nova existe, a
conta passa a ter ids "contaminados" (mistura de seed + novos), e qualquer
chamada de IA que dependesse desse conjunto deixaria de ser reproduzível
entre execuções. `pii`/`embedding` são as únicas 2 das 7 operações que
**não** têm essa restrição — o envelope delas só carrega o texto literal,
nunca um id — por isso a criação de entradas novas (Bloco 7) pode vir por
último com segurança.

## O relógio de teste

Toda requisição do roteiro leva `X-Test-Now: 2026-09-23T09:41:00Z` (a
âncora do seed, `supabase/seed/ancora.md`) — assim `period=30d` do
dashboard/exportação sempre olha pra mesma janela relativa entre as duas
execuções, em vez de depender de quando de verdade o roteiro rodou.
Requer `X-Test-Key` == `TEST_FAULT_KEY` do ambiente (mesmo gate de
`clock.ts`/`faults.ts`, §10.1) — nenhuma falha é injetada aqui, só o
relógio é fixado.

---

## A jornada, tela a tela

Conta usada: **A (`cenario-cheio@cerne.test`)** — a única com volume
suficiente (34 entradas, 3 sessões de chat, 4 tags) para exercitar as 7
operações de IA com significado. As contas B/C (RF09 com 1/0 entradas) já
são cobertas por `dashboard_aggregate.hurl`, não precisam reentrar aqui.

### Bloco 1 — Login (Tela 1)
O usuário abre o app, entra com e-mail/senha da conta A.
→ `POST /auth/login`

### Bloco 2 — Chat + Insight, conversa retomada (Tela 4, RF04/RF08)
O usuário abre a conversa "Conversa sobre o dia no trabalho" (já tem 4
trocas sobre um prazo apertado no trabalho) e manda mais uma mensagem,
fechando o assunto — texto literal `sessao1_quinta_mensagem`
(`fixtures/textos.json`). Essa é a 5ª mensagem do usuário na sessão,
gatilho do RF08 por contagem — o app dispara a geração do insight.
→ `POST /chat/sessions/:id/messages` (sessão semeada #1) → `POST
/chat/sessions/:id/insight` (`triggerType=message_count`) → repetir o
mesmo insight (prova que reabrir a tela não duplica) → tocar em "regenerar"
na última resposta (D15) → `POST .../retry`.

### Bloco 3 — Chat + Insight, conversa nova mensagem (RF04/RF08, gatilho por inatividade)
O usuário abre "Conversa sobre o sono" (já tem uma troca sobre celular
atrapalhando o sono) e manda duas mensagens novas — textos
`sessao2_mensagem_1`/`sessao2_mensagem_2`. Depois de um tempo sem responder
(RF08, `triggerType=inactivity`), o app dispara o insight por inatividade.
→ 2× `POST /chat/sessions/:id/messages` (sessão semeada #2) → `POST
.../insight` (`triggerType=inactivity`).

### Bloco 4 — Busca (Tela de Busca, RF06)
O usuário digita, em sequência, os 3 termos aprovados no `GATE-09`
(`fixtures/pares_semanticos.md`) — nenhum deles é a raiz literal do texto
que deveria encontrar, prova de que a busca é por significado, não por
substring. Por fim, repete a 1ª busca acrescentando um filtro de fonte
("só entradas de texto") — prova do "E lógico" do RF06 (§8.2).
→ 4× `GET /entries/search`.

### Bloco 5 — Configurações → Resumos (Tela de Configurações, RF09)
O usuário abre a aba de resumos: o app busca o agregado (gráfico por
dia/origem) e a narrativa em texto corrido, cada um independente do outro.
→ `GET /dashboard/aggregate` → `GET /dashboard/narrative`.

### Bloco 6 — Exportar meus dados (RF05)
O usuário pede a exportação completa (todo o histórico, com narrativa),
espera o processamento e baixa o resultado.
→ `POST /export/summary` → `GET /export/:jobId/status` (repetido até sair
de `pending`) → `GET /export/:jobId/download`.

### Bloco 7 — Capturar novo conteúdo (Tela 2, Modal de Inserção — RF01/RF02/RF10)
*(a partir daqui a conta ganha entradas com id novo — ver "Regra de
ordenação" acima; nenhum passo restante volta a chamar `chat`/`insight`/
`narrative`/`dashboard`)*

- **Texto:** o usuário digita um registro livre — texto
  `entrada_manual_nova`. → `POST /entries` (`source=manual`).
- **Áudio:** o usuário grava um áudio; o app transcreve no próprio
  aparelho (RF02 — STT client-side, o backend nunca recebe o arquivo de
  áudio) e envia o texto já transcrito — `fixtures/trancricoes.md`,
  aprovado. → `POST /entries` (`source=audio`).
- **Foto:** o usuário fotografa uma anotação (`fixtures/media/ocr_fixture_01.png`);
  o app manda a imagem pro backend extrair o texto (RF02 — aqui sim é o
  servidor, via Anthropic — D17: a imagem em si nunca é persistida, só o
  SHA-256 entra no cache) e, depois de o usuário revisar, salva o texto
  extraído como entrada. → `POST /media/ocr` → `POST /entries`
  (`source=photo`, conteúdo = o texto devolvido pelo OCR).
- **Salvar do chat (RF10):** o usuário volta à mensagem enviada no Bloco 2
  e toca em "salvar como entrada" — depois toca de novo, sem querer, no
  mesmo botão (prova de idempotência: mesma entrada, sem duplicar).
  → 2× `POST /entries` (`source=chat`, mesmo `chatMessageId`).

### Bloco 8 — Timeline (Tela 3, RF07)
O usuário volta pra tela principal e rola a lista — confirma que a entrada
recém-salva do chat aparece.
→ `GET /entries` → `GET /entries/:id`.

### Bloco 9 — Perfil (RF03, só o campo não-biométrico)
O usuário abre o perfil e ajusta a persona do assistente e liga o cadeado
biométrico (a biometria em si — Face ID/Touch ID/PIN — é 100% client-side,
RF03; o backend só guarda a preferência).
→ `PATCH /account/settings`.

*(Deliberadamente fora do roteiro: `DELETE /account` — apagaria a própria
conta usada por toda a jornada. Já tem suíte própria,
`tests/hurl/account_delete.hurl`, rodando numa conta descartável.)*

---

## Validação feita nesta sessão

`tests/determinism/roteiro_validacao.hurl`: sintaxe conferida com
`hurlfmt --check` (binário 6.1.1, baixado do GitHub Releases neste
sandbox — mesma versão do Wagner) e semântica de ponta a ponta (26/26
requisições) contra um mock HTTP local descartado, reproduzindo os
formatos reais de resposta dos 15 endpoints envolvidos (envelope SSE com
`userMessageId`, `X-Replay-Status: hit` no retry, `meta.idempotentReplay`
no RF10, etc.).

**Não validado** (mesmo bloqueio de Docker/rede das fases anteriores):
execução de verdade contra `supabase functions serve` — inclusive se as
suposições sobre RAG/embedding realmente devolvem exatamente as entradas
plantadas nos termos exatos assumidos aqui. Isso só o `T-060` (Wagner, com
o Docker local) confirma.

## Achado real (Wagner, 1ª tentativa de `T-060`) — acento cru na URL

O Bloco 4 (busca por "cansaço"/"gratidão") falhava com `400` e corpo vazio
rodando contra o Supabase CLI de verdade — nunca apareceu no mock desta
sessão, que é tolerante demais para pegar isso. Causa raiz confirmada via
`hurl --verbose` isolando só essa chamada: a resposta vinha do **Kong**
(`Via: kong/2.8.1`, `Content-Length: 0`, respondida em 1ms — rápido demais
pra ter passado pela nossa Edge Function, que sempre devolve corpo JSON
mesmo em erro) — o proxy que o `supabase functions serve` local roda na
frente de toda função rejeita um caractere não-ASCII cru (`ç`/`ã`) na linha
da requisição HTTP. `hurl`/libcurl não codifica isso automaticamente por
conta própria (diferente de "ansiedade", sem acento, que sempre funcionou).

**Não é um bug do projeto** — um cliente HTTP de verdade (`Uri` do
Dart/Flutter, por exemplo) já resolve isso sozinho ao montar a URL; é só o
`.hurl`, escrito com o texto cru, que precisa ajudar. Corrigido em
`tests/determinism/roteiro_validacao.hurl` codificando os dois termos na
URL (`cansa%C3%A7o`, `gratid%C3%A3o`) — `entries-search` decodifica de
volta pra "cansaço"/"gratidão" normalmente (`URLSearchParams.get`), então
o texto que entra no cache/na Voyage continua o literal correto.
