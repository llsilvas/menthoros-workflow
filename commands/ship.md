---
name: ship
description: "Fecha a change: valida, merge --no-ff em develop, arquiva OpenSpec e atualiza SPRINTS"
category: workflow
argument-hint: "<change-id>"
---

Finalize a change `$ARGUMENTS`. Detecte o stack pelo cwd para a validação.

**Pré-condições:** `tasks.md` com itens `[x]`; suíte verde (`./mvnw clean test` no backend;
`npm run lint && build && test:run` no front); `/qa` sem achado Crítico.

Siga as "Diretrizes de Git" do `CLAUDE.md` raiz. **Operações em `develop` exigem CONFIRMAÇÃO explícita:**

1. `git push -u origin feature/<change-id>` (se ainda não enviado)
2. `git checkout develop && git pull origin develop`
3. `git merge feature/<change-id> --no-ff -m "Merge branch 'feature/<change-id>'"`
4. `git push origin develop`
5. `git branch -d feature/<change-id>`

Feche o loop OpenSpec (em `menthoros-product`): atualize `tasks.md`, `openspec archive <change-id>`,
e atualize a linha no `openspec/SPRINTS.md`.

Nunca `--no-verify`, nunca `--force` em `develop`, nunca misture changes. Reporte merge/archive/SPRINTS.
