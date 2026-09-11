# Credenciais — `cerne-ciclo-b`

Preenchimento manual. Entregar **somente** ao ciclo comparativo que usa
este projeto — nunca ao outro ciclo, nunca a credencial de `dev`.

- **Project ref:** bpoutqdbpwccimridgdi
- **URL base das Edge Functions:** `https://bpoutqdbpwccimridgdi.supabase.co/functions/v1`
- **Anon key:** eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwb3V0cWRicHdjY2ltcmlkZ2RpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgyOTYzNDgsImV4cCI6MjEwMzg3MjM0OH0.LsbgL_-pH3hLWqXbG24jQNpVNtvb1eC1UonXG1PZdzo
- **Connection string (Session pooler)** — `postgresql://postgres.bpoutqdbpwccimridgdi:Y!ie8Av3ec%403SM7@aws-0-sa-east-1.pooler.supabase.com:5432/postgres`

  ⚠️ Não usar a "Direct connection" (`db.<ref>.supabase.co`) — o host só
  resolve por IPv6 em projetos novos (achado do Passo 0 do roteiro de
  congelamento) e, além disso, sua senha não pode ser colada aqui sem
  codificar o `@` como `%40` (senha tem um `@` literal); sem isso, o
  parser da connection string corta a senha no lugar errado e a
  autenticação falha silenciosamente com a senha errada, não com um erro
  óbvio de formato.


## Observações

- `REPLAY_MODE` deste projeto está configurado como `replay_strict` —
  nenhuma chamada real à Anthropic/Voyage AI deve ocorrer a partir daqui.
- Não compartilhar a senha do banco nem a `service_role key` fora deste
  arquivo.
- **Lembrete (`GATE-12`):** este projeto Supabase é gratuito e pausa por
  inatividade. Reativar no painel antes de liberar o Ciclo B, e
  reconferir o hash de schema como idêntico ao `dev`/`ciclo-a` naquele
  momento (ver `big-plan.md`, seção "Pós-congelamento").
