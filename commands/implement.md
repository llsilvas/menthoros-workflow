---
name: implement
description: "Inicia uma change (cria a branch) ou implementa UMA task em TDD — detecta backend (Spring) ou frontend (Vite)"
category: workflow
argument-hint: "init <change-id>  |  <change-id> <task-id>"
---

Detecte o stack pelo cwd: **backend** se houver `pom.xml`/`mvnw`; **frontend** se houver
`package.json` (Vite). Use o `CLAUDE.md` do repo como fonte canônica de regras. Dois modos:

## Modo A — `init <change-id>` (preparar a branch)

Não implemente nada. Siga as "Diretrizes de Git" do `CLAUDE.md` raiz (padrão `feature/<change-id>`):

1. Resolva o `<change-id>` (nome da spec): valide via `openspec show <change-id>` ou
   `menthoros-product/openspec/changes/<change-id>/`. Se omitido, liste as changes ativas e peça para escolher.
2. Árvore limpa: se houver mudanças não commitadas, PARE e avise.
3. `git checkout develop && git pull origin develop && git checkout -b feature/<change-id>`
   (se a branch já existir, faça `checkout`).
4. Reporte a branch e o commit base.

## Modo B — `<change-id> <task-id>` (implementar UMA task em TDD)

1. Leia o `CLAUDE.md` do repo e a change OpenSpec.
2. Uma task por vez, dentro do escopo.
3. **TDD red → green → refactor:**
   - **Backend:** teste primeiro (JUnit 5 / Mockito / AssertJ; skill `springboot-tdd`); valide `./mvnw clean test`.
   - **Frontend:** teste primeiro (Vitest + Testing Library); valide `npm run lint && npm run build && npm run test:run`.
   - Tasks sem comportamento testável podem pular o teste — justifique.
4. Marque a task em `tasks.md` como `[x]` e reporte arquivos/validação/follow-ups.

A branch deve já existir (Modo A). Nunca `--no-verify`/`@SuppressWarnings`/cast para burlar.
