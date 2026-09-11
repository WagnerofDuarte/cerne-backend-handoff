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

Este é o **único** mapeamento tela↔status que os documentos-fonte definem em detalhe suficiente para reproduzir sem ambiguidade — cobre só a tela de exportação (RF05). Um mapa completo de todas as telas do protótipo (RF01–RF10) depende de `Requisitos_e_Fluxo_de_Telas_TCC.md`, que não está neste repositório (ver `docs/bugs_conhecidos.md`/registro de pendências no `big-plan.md`, seção "Itens em aberto").
