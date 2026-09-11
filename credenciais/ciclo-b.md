# Credenciais — `cerne-ciclo-b`

Preenchimento manual. Entregar **somente** ao ciclo comparativo que usa
este projeto — nunca ao outro ciclo, nunca a credencial de `dev`.

- **Project ref:**
- **URL base das Edge Functions:** `https://<project-ref>.supabase.co/functions/v1`
- **Anon key:**
- **Connection string (Session pooler)** — necessária só se o ciclo for
  rodar migrações/scripts direto contra o banco; se o ciclo só consome a
  API, pode deixar em branco:
  `postgresql://postgres.<project-ref>:<senha>@aws-0-<região>.pooler.supabase.com:5432/postgres`

## Observações

- `REPLAY_MODE` deste projeto está configurado como `replay_strict` —
  nenhuma chamada real à Anthropic/Voyage AI deve ocorrer a partir daqui.
- Não compartilhar a senha do banco nem a `service_role key` fora deste
  arquivo.
- **Lembrete (`GATE-12`):** este projeto Supabase é gratuito e pausa por
  inatividade. Reativar no painel antes de liberar o Ciclo B, e
  reconferir o hash de schema como idêntico ao `dev`/`ciclo-a` naquele
  momento (ver `big-plan.md`, seção "Pós-congelamento").
