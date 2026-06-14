---
name: qa
description: "Gate de qualidade: reviewers em paralelo + validação — detecta backend ou frontend"
category: workflow
---

Detecte o stack pelo cwd e rode o gate sobre o diff vs `develop`, em PARALELO:

- **Backend** (`pom.xml`): delegue aos subagents `code-reviewer` + `security-reviewer`; rode `./mvnw clean test`.
- **Frontend** (`package.json`): delegue ao subagent `frontend-reviewer`; rode `npm run lint && npm run build && npm run test:run`.

(Reforce com `/review` e `/security-review` nativos se instalados.)

Consolide um parecer priorizado (Crítico / Importante / Menor) com `arquivo:linha`. NÃO faça merge
(isso é `/ship`). Só aprove se: tudo verde e nenhum achado Crítico.
