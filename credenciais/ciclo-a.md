# Credenciais — `cerne-ciclo-a`

Preenchimento manual. Entregar **somente** ao ciclo comparativo que usa
este projeto — nunca ao outro ciclo, nunca a credencial de `dev`.

- **Project ref:** fgzqqkwxwfxlxbdktwzo
- **URL base das Edge Functions:** `https://fgzqqkwxwfxlxbdktwzo.supabase.co/functions/v1`
- **Anon key:** eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZnenFxa3d4d2Z4bHhiZGt0d3pvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgyOTI2OTAsImV4cCI6MjEwMzg2ODY5MH0.uWGUWukzmTY-p6kC202WXKFB-Ux2wmWCpreNUmSjN38
- **Connection string (Session pooler)** — `postgresql://postgres.fgzqqkwxwfxlxbdktwzo:Y!ie8Av3ec%403SM7@aws-0-sa-east-1.pooler.supabase.com:5432/postgres`

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
