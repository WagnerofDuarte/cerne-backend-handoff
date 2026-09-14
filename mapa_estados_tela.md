<!-- GERADO por scripts/gen-handoff-docs.ts — não editar à mão. -->

# Mapa de estados de tela — exportação (RF05)

Fonte: `context/Contexto Geral.md` §11.7 (e equivalente no plano técnico) — tabela literal dos documentos-fonte, transcrita aqui, não gerada de código: a tela que ela descreve é do aplicativo, que não vive neste repositório.

`export_jobs` tem dois status **independentes** — o do job em si e o da narrativa gerada por IA (D11) — porque os dados brutos da exportação podem ficar prontos antes, depois ou independentemente da narrativa, e a UI nunca deve bloquear o download por causa de uma narrativa que falhou.

| O que a tela mostra | Status do job | Status da narrativa | Download disponível |
|---|---|---|---|
| Preparando exportação | pendente | pendente | não |
| Gerando resumo com IA | processando | processando | não |
| Dados prontos, resumo ainda gerando | dados_prontos | processando | sim (sem PDF) |
| Concluído, com resumo | concluído | concluída | sim (com PDF) |
| Concluído, resumo falhou/pulado | concluído | falhou ou pulada | sim (sem PDF) |
| Erro na exportação | erro | — | não |

Este é o **único** mapeamento tela↔status que os documentos-fonte definem em detalhe suficiente para reproduzir sem ambiguidade — cobre só a tela de exportação (RF05). Um mapa completo de todas as telas do protótipo (RF01–RF10) está em `ux/Requisitos_e_Fluxo_de_Telas_TCC.md` (recebido em 10/09/2026, ver `big-plan.md`, seção "Itens em aberto") — não transcrito aqui porque foge do escopo deste mapa (só RF05/export_jobs).
