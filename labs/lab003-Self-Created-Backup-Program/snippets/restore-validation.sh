#!/usr/bin/env bash
# Portfolio excerpt — simplified restore-input validation.
snapshot="${1:-}"
item="${2:-}"
[[ "$snapshot" =~ ^backup-[0-9]{8}-[0-9]{6}$ ]] || exit 1
[[ -n "$item" ]] || exit 1
[[ "$item" != /* ]] || exit 1
[[ "$item" != *".."* ]] || exit 1
echo "Restore request passed portfolio-example validation."
