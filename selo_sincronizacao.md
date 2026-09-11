<!-- GERADO por scripts/gen-handoff-docs.ts — não editar à mão. -->

# Semântica do selo de sincronização (D9)

**Decisão de arquitetura D9:** não existe coluna `sync_status` no banco — a arquitetura é cloud-only, então "está no servidor" já significa "sincronizado", por definição. O servidor não guarda nem calcula um estado de sincronização; ele só expõe dois campos, e o **selo é derivado inteiramente no aplicativo** a partir deles:

| Campo | Onde aparece no contrato | O que significa |
|---|---|---|
| `updatedAt` | `Entry.updatedAt` (`contracts/zod/entries.ts`) | Timestamp da última escrita no servidor para aquela entrada. |
| `serverRevision` | `Entry.serverRevision`, e também no perfil (`contracts/zod/account.ts`/`auth.ts`) | Contador que sobe a cada escrita nas entradas do usuário — nunca reseta, nunca decresce. |

**Os 3 estados do selo, todos inferidos no cliente — nenhum vem pronto do servidor:**
1. **Sincronizando** — o app tem uma escrita local ainda não confirmada pelo servidor (ainda não recebeu a resposta com o `updatedAt`/`serverRevision` novos).
2. **Erro de sincronização** — a escrita foi tentada e falhou (rede, ou um dos 13 códigos de erro da taxonomia) e o app ainda não conseguiu reconciliar.
3. **Sincronizado** — a última escrita confirmada bateu; não há nada pendente do lado do cliente para aquela entrada.

**Por que isso importa para os dois ciclos comparativos:** nenhuma decisão de *quando* mostrar cada estado é do servidor — os dois ciclos implementam essa lógica de reconciliação de forma independente no cliente, usando exatamente os mesmos dois campos. Divergência de comportamento aqui é uma diferença legítima de metodologia, não um defeito do backend.
