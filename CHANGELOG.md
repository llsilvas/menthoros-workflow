# Changelog

Todas as mudanças relevantes do `menthoros-workflow`. Formato: [Keep a Changelog](https://keepachangelog.com/),
versionamento [SemVer](https://semver.org/).

## [1.8.0] — 2026-06-18
### Changed
- **Renomeados para nomes mais intuitivos:** `/ship` → **`/pr`** (deixa claro que abre um Pull Request, não faz deploy) e `/land` → **`/done`** (finaliza pós-merge). `/change`, `/implement` e `/qa` mantidos.

## [1.7.0] — 2026-06-13
### Changed
- **Fluxo PR-first:** `/ship` agora **abre um Pull Request** (`gh pr create`) em vez de mergear localmente —
  `develop` é integrada só no remote (CI verde + branch protection).
- `git-guard` passou a **bloquear merge local** na `develop`/`main` (integração só via PR).
- `/implement init` ganhou um **passo de plano**: refina o `tasks.md` contra o código real, com `verify:` por task.
### Added
- Comando `/land`: pós-merge — arquiva a change, atualiza o `SPRINTS.md` e limpa a branch.

## [1.6.0] — 2026-06-13
### Added
- Subagent `spec-reviewer`: **Definition-of-Ready** gate no `/implement init` (Full track) — barra spec
  sem critério de aceite testável, métrica, dependências resolvidas, impacto de dados/contrato ou rollback.
- **Varredura de premissas** no `/change` (Full): passo `common-ground` que expõe e valida suposições;
  seção **Open Questions & Assumptions** obrigatória no proposal.
- Regras de spec no `openspec/config.yaml`: critérios de aceite (Given/When/Then), Open Questions, métrica de sucesso.

## [1.5.0] — 2026-06-13
### Added
- Subagent `product-reviewer`: lente de produto **centrada no treinador** (otimizar a rotina do coach +
  coach-in-the-loop), rodado no `/change` em Full track ao lado do `the-fool`. Avalia valor antes de
  implementar; verdict Go/Refine/Reconsider.

## [1.4.0] — 2026-06-13
### Added
- Hook `migration-guard` (PreToolUse/Edit·Write·MultiEdit): bloqueia migration Flyway com DDL
  destrutivo (`DROP TABLE` / `TRUNCATE` / `DROP COLUMN`); override explícito via
  `MENTHOROS_ALLOW_DESTRUCTIVE_MIGRATION=1`. Cobre a última confirmation gate do CLAUDE.md.
- 7 testes do `migration-guard` na suíte (`tests/run.sh`) — 26 testes no total.
### Project
- `LICENSE` (MIT), este `CHANGELOG.md` e CI (GitHub Actions) validando os manifests e rodando
  `tests/run.sh` a cada push/PR.

## [1.3.1] — 2026-06-13
### Added
- Suíte de testes dos hooks sem dependências (`tests/run.sh`): matriz do `git-guard` e lógica de
  decisão do `qa-gate` (com stubs de `mvnw`/`npm`).

## [1.3.0] — 2026-06-13
### Added
- Comando `/change`: início do funil — classifica Tamanho·Trilha e cria a change OpenSpec
  (proposal + tasks; `design.md` + pre-mortem `the-fool` no Full track).

## [1.2.0] — 2026-06-13
### Added
- `/implement run <id> --step`: autopilot supervisionado (pausa por seção). Dica de trilha:
  Full → `--step`, Fast → `run` puro.

## [1.1.0] — 2026-06-13
### Added
- `/implement run <id>`: modo autônomo que empilha e executa as tasks da change em sequência,
  com freios (para em teste vermelho, pausa em decisão humana, para antes do `/ship`).

## [1.0.0] — 2026-06-13
### Added
- Comandos `/implement` (init + task única em TDD), `/qa`, `/ship` — context-aware (Spring/Vite).
- Subagents `code-reviewer`, `security-reviewer`, `frontend-reviewer`, `clean-code-reviewer`.
- Hooks `git-guard` (PreToolUse/Bash) e `qa-gate` (Stop).
- Tooling em inglês com deferência ao `CLAUDE.md` de cada repo para o idioma da saída (PT-BR).
