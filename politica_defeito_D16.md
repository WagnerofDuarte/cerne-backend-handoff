<!-- GERADO por scripts/gen-handoff-docs.ts — não editar à mão. -->

# Política de defeito pós-congelamento (D16)

Fonte: `context/Contexto Geral.md` §10. Nenhuma linha do backend muda enquanto os dois ciclos rodam, **exceto** por esta política.

| Gravidade | Definição | Ação |
|---|---|---|
| **Não bloqueante** | Existe contorno razoável; nenhum critério de aceite fica impossível | **Não corrigir.** Registrar em `bugs_conhecidos.md`, entregue igual aos dois ciclos. |
| **Bloqueante** | Algum critério de aceite se torna impossível | Corrigir nos 3 ambientes, reexecutar o roteiro, repopular o cache, registrar em "Ameaças à Validade". Se o ciclo A já terminou, registrar que ele não teve a correção. |
| **Bloqueante descoberto no ciclo B** | Pior caso | Corrigir, terminar o ciclo, e **declarar aquela métrica como não comparável**. Não maquiar. |

**Por que "corrigir uma vez" não resolve nos dois ciclos:** os ciclos são sequenciais (rodam contra versões diferentes do backend, antes/depois da correção); são três ambientes que exigem reconferência de estrutura; uma correção que toque montagem de prompt ou ordenação muda as impressões digitais do cache de replay; e as horas já gastas contornando o bug no ciclo A contam como métrica de processo e não são devolvidas.
