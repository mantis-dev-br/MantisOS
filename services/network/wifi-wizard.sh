
#!/usr/bin/env bash

set -u

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Erro: comando não encontrado: $1" >&2
        return 1
    fi
}

usage() {
    cat <<'HELP'
MantisOS - Assistente de rede Wi-Fi

Uso:
  wifi-wizard.sh status
  wifi-wizard.sh scan
  wifi-wizard.sh help

Comandos:
  status  Mostra o estado das interfaces e conexões.
  scan    Lista as redes Wi-Fi disponíveis.
  help    Exibe esta ajuda.

Esta versão não altera configurações de rede.
HELP
}

wifi_interfaces() {
    nmcli -t -f DEVICE,TYPE device status |
        awk -F: '$2 == "wifi" && $1 !~ /^p2p-/ {print $1}'
}

show_status() {
    echo "=== ESTADO DA REDE ==="
    nmcli general status
    echo
    nmcli device status
    echo
    echo "=== ROTA PADRAO ==="
    ip route show default
}

scan_networks() {
    local iface
    local found=0

    while IFS= read -r iface; do
        [ -n "$iface" ] || continue
        found=1

        echo
        echo "=== REDES WI-FI: $iface ==="

        if ! nmcli device wifi rescan ifname "$iface"; then
            echo "Aviso: não foi possível solicitar nova varredura."
        fi

        sleep 2

        nmcli --colors no \
            -f IN-USE,SSID,CHAN,RATE,SIGNAL,SECURITY \
            device wifi list ifname "$iface" || return 1
    done < <(wifi_interfaces)

    if [ "$found" -eq 0 ]; then
        echo "Nenhuma interface Wi-Fi encontrada pelo NetworkManager."
        return 1
    fi
}

main() {
    require_command nmcli || exit 1
    require_command ip || exit 1
    require_command awk || exit 1

    case "${1:-help}" in
        status)
            show_status
            ;;
        scan)
            scan_networks
            ;;
        help|-h|--help)
            usage
            ;;
        *)
            echo "Comando desconhecido: $1" >&2
            usage
            return 2
            ;;
    esac
}

main "$@"
