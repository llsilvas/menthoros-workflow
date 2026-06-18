#!/usr/bin/env bash
# Guardrail PreToolUse(Edit|Write|MultiEdit): bloqueia migration Flyway com DDL destrutivo.
exec python3 "$(cd "$(dirname "$0")" && pwd)/migration-guard.py"
