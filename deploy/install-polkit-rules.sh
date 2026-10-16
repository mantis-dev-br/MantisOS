#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

SOURCE="$ROOT/deploy/polkit/49-mantis-wifi-scan.rules"
DEST="/etc/polkit-1/rules.d/49-mantis-wifi-scan.rules"

if [[ "$EUID" -ne 0 ]]; then
    echo "Execute com privilégios administrativos: sudo $0" >&2
    exit 1
fi

if ! id orangepi >/dev/null 2>&1; then
    echo "Erro: o usuário orangepi não existe neste sistema." >&2
    exit 1
fi

if [[ ! -f "$SOURCE" ]]; then
    echo "Erro: arquivo de regra não encontrado: $SOURCE" >&2
    exit 1
fi

install -o root -g root -m 0644 "$SOURCE" "$DEST"

echo "Regra do Polkit instalada em: $DEST"
