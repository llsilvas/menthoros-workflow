# menthoros-workflow

Plugin do Claude Code com o fluxo OpenSpec-first do Menthoros. **Context-aware**: os comandos e o
gate detectam se o cwd é backend (Spring, `pom.xml`) ou frontend (Vite, `package.json`).

## Conteúdo
- **Comandos:** `/implement` (init de branch + task em TDD), `/qa` (reviewers + validação), `/ship` (merge --no-ff + archive + SPRINTS).
- **Subagents:** `code-reviewer`, `security-reviewer` (backend), `frontend-reviewer`.
- **Hooks:** `git-guard` (PreToolUse — bloqueia commit em develop, force-push, reset --hard, --no-verify), `qa-gate` (Stop — roda os testes do stack quando `src/` muda).

## Instalação (Claude Code CLI)
```bash
# marketplace local (uso imediato)
/plugin marketplace add /caminho/para/menthoros-workflow
# ou via repo no GitHub:  /plugin marketplace add <owner>/menthoros-workflow
/plugin install menthoros-workflow
```

## Migração (importante)
Ao instalar o plugin, **remova os arquivos duplicados** de `.claude/` em cada repo para o hook não
rodar duas vezes: `commands/{implement,qa,ship}.md`, `agents/*`, `hooks/{git-guard,qa-gate}.sh` e o
bloco `"hooks"` de `.claude/settings.json` (preserve `enabledPlugins`, `mcpServers`, `permissions`).
# menthoros-workflow
