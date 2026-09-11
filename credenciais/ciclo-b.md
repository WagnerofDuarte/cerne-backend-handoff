# Credenciais — `cerne-ciclo-b`

Preenchimento manual. Entregar **somente** ao ciclo comparativo que usa
este projeto — nunca ao outro ciclo, nunca a credencial de `dev`.

- **Project ref:** bpoutqdbpwccimridgdi
- **URL base das Edge Functions:** `https://bpoutqdbpwccimridgdi.supabase.co/functions/v1`
- **Anon key:** eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwb3V0cWRicHdjY2ltcmlkZ2RpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgyOTYzNDgsImV4cCI6MjEwMzg3MjM0OH0.LsbgL_-pH3hLWqXbG24jQNpVNtvb1eC1UonXG1PZdzoeyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZnenFxa3d4d2Z4bHhiZGt0d3pvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgyOTI2OTAsImV4cCI6MjEwMzg2ODY5MH0.uWGUWukzmTY-p6kC202WXKFB-Ux2wmWCpreNUmSjN38
- **Connection string** — `postgresql://postgres:Y!ie8Av3ec@3SM7@db.bpoutqdbpwccimridgdi.supabase.co:5432/postgres`
- **Session pooler** — `postgresql://postgres.bpoutqdbpwccimridgdi:Y!ie8Av3ec%403SM7@aws-0-sa-east-1.pooler.supabase.com:5432/postgres`


## Observações

- `REPLAY_MODE` deste projeto está configurado como `replay_strict` —
  nenhuma chamada real à Anthropic/Voyage AI deve ocorrer a partir daqui.
- Não compartilhar a senha do banco nem a `service_role key` fora deste
  arquivo.
- **Lembrete (`GATE-12`):** este projeto Supabase é gratuito e pausa por
  inatividade. Reativar no painel antes de liberar o Ciclo B, e
  reconferir o hash de schema como idêntico ao `dev`/`ciclo-a` naquele
  momento (ver `big-plan.md`, seção "Pós-congelamento").
