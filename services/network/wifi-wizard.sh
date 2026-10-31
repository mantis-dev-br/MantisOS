#!/usr/bin/env bash

set -u
set -o pipefail

NM_CONN_DIR="/etc/NetworkManager/system-connections"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Erro: comando não encontrado: $1" >&2
        return 1
    fi
}

usage() {
    cat <<'HELP'
MantisOS - Assistente Wi-Fi

Uso:
  wifi-wizard.sh status
  wifi-wizard.sh scan
  wifi-wizard.sh configure
  wifi-wizard.sh help

Comandos:
  status      Mostra interfaces e conexões.
  scan        Lista redes Wi-Fi disponíveis.
  configure   Cadastra um perfil sem ativá-lo.
  help        Exibe esta ajuda.

A configuração não desconecta a rede atual.
Suporte inicial: redes pessoais WPA/WPA2-PSK.
HELP
}

as_root() {
    if [ "${EUID}" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
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
            echo "Aviso: não foi possível iniciar nova varredura." >&2
        fi

        sleep 2

        nmcli --colors no \
            -f IN-USE,SSID,CHAN,RATE,SIGNAL,SECURITY \
            device wifi list ifname "$iface" || return 1
    done < <(wifi_interfaces)

    if [ "$found" -eq 0 ]; then
        echo "Nenhuma interface Wi-Fi encontrada."
        return 1
    fi
}

# SSID: 1 a 32 bytes, sem caracteres de controle.
valid_ssid() {
    local ssid="$1"
    local LC_ALL=C

    [ "${#ssid}" -ge 1 ] && [ "${#ssid}" -le 32 ] || return 1
    [[ ! "$ssid" =~ [[:cntrl:]] ]]
}

# PSK WPA: 8 a 63 caracteres ASCII imprimíveis, ou 64 dígitos hexadecimais.
valid_psk() {
    local psk="$1"
    local LC_ALL=C
    local printable='^[ -~]+$'

    if [[ "$psk" =~ ^[[:xdigit:]]{64}$ ]]; then
        return 0
    fi

    [ "${#psk}" -ge 8 ] && [ "${#psk}" -le 63 ] || return 1
    [[ "$psk" =~ $printable ]]
}

# SSID como lista de bytes decimais (formato aceito pelo keyfile do
# NetworkManager). Evita qualquer escape de ';', '\' ou UTF-8.
ssid_to_bytes() {
    printf '%s' "$1" | od -An -tu1 -v | tr -s ' \n' ';;' | sed 's/^;//'
}

# Escape de valor GKeyFile feito só com builtins, para a PSK nunca
# aparecer nos argumentos de um processo externo.
keyfile_escape() {
    local v="$1"
    v="${v//\\/\\\\}"
    v="${v// /\\s}"
    printf '%s' "$v"
}

build_keyfile() {
    local id="$1" uuid="$2" iface="$3" ssid_bytes="$4" psk_escaped="$5"

    printf '[connection]\n'
    printf 'id=%s\n' "$(keyfile_escape "$id")"
    printf 'uuid=%s\n' "$uuid"
    printf 'type=wifi\n'
    printf 'interface-name=%s\n' "$iface"
    printf 'autoconnect=false\n'
    printf '\n[wifi]\n'
    printf 'mode=infrastructure\n'
    printf 'ssid=%s\n' "$ssid_bytes"
    printf '\n[wifi-security]\n'
    printf 'key-mgmt=wpa-psk\n'
    printf 'psk-flags=0\n'
    printf 'psk=%s\n' "$psk_escaped"
    printf '\n[ipv4]\nmethod=auto\n'
    printf '\n[ipv6]\naddr-gen-mode=default\nmethod=auto\n'
    printf '\n[proxy]\n'
}

# Grava em arquivo temporário no mesmo diretório (terminado em '~',
# ignorado pelo NetworkManager), com umask 077, e renomeia atomicamente.
install_keyfile() {
    local dest="$1"

    as_root sh -c '
        umask 077
        tmp="$(mktemp --suffix="~" "$1.XXXXXX")" || exit 1
        if cat > "$tmp" && chmod 0600 "$tmp" && mv -f "$tmp" "$1"; then
            exit 0
        fi
        rm -f "$tmp"
        exit 1
    ' sh "$dest"
}

profile_exists() {
    nmcli -g NAME connection show | grep -qxF -- "$1"
}

configure_profile() {
    local -a interfaces=()
    local iface choice ssid profile_name uuid dest
    local psk psk_confirm psk_escaped
    local autoconnect secret

    mapfile -t interfaces < <(wifi_interfaces)

    if [ "${#interfaces[@]}" -eq 0 ]; then
        echo "Erro: nenhuma interface Wi-Fi encontrada." >&2
        return 1
    fi

    echo "=== CONFIGURAÇÃO DE WI-FI ==="
    echo "Esta operação cria um perfil, sem ativá-lo."
    echo

    if [ "${#interfaces[@]}" -eq 1 ]; then
        iface="${interfaces[0]}"
        echo "Interface selecionada: $iface"
    else
        echo "Interfaces disponíveis:"
        local i
        for i in "${!interfaces[@]}"; do
            printf '  %d) %s\n' "$((i + 1))" "${interfaces[$i]}"
        done

        read -r -p "Número da interface: " choice || return 1

        if [[ ! "$choice" =~ ^[0-9]+$ ]] ||
           [ "$choice" -lt 1 ] ||
           [ "$choice" -gt "${#interfaces[@]}" ]; then
            echo "Seleção inválida." >&2
            return 1
        fi

        iface="${interfaces[$((choice - 1))]}"
    fi

    echo
    read -r -p "Nome da rede (SSID): " ssid || return 1

    if ! valid_ssid "$ssid"; then
        echo "Erro: SSID deve ter de 1 a 32 bytes, sem caracteres de controle." >&2
        return 1
    fi

    profile_name="MantisOS Wi-Fi - $ssid"

    if profile_exists "$profile_name"; then
        echo "Já existe um perfil com esse nome:"
        echo "$profile_name"
        echo "Nenhuma alteração foi feita."
        return 1
    fi

    read -r -s -p "Senha da rede: " psk || { echo; return 1; }
    echo
    read -r -s -p "Confirme a senha: " psk_confirm || { echo; unset psk; return 1; }
    echo

    if [ "$psk" != "$psk_confirm" ]; then
        unset psk psk_confirm
        echo "Erro: as senhas não conferem." >&2
        return 1
    fi
    unset psk_confirm

    if ! valid_psk "$psk"; then
        unset psk
        echo "Erro: senha WPA-PSK deve ter de 8 a 63 caracteres ASCII imprimíveis," >&2
        echo "      ou 64 dígitos hexadecimais." >&2
        return 1
    fi

    psk_escaped="$(keyfile_escape "$psk")"
    unset psk

    uuid="$(cat /proc/sys/kernel/random/uuid)" || {
        unset psk_escaped
        echo "Erro: não foi possível gerar UUID." >&2
        return 1
    }

    # Nome do arquivo pelo UUID: o SSID nunca entra no caminho.
    dest="$NM_CONN_DIR/mantisos-$uuid.nmconnection"

    echo
    echo "Será solicitada autorização administrativa, se necessário."

    if [ "${EUID}" -ne 0 ] && ! sudo -v; then
        unset psk_escaped
        echo "Erro: autorização administrativa negada." >&2
        return 1
    fi

    if ! build_keyfile "$profile_name" "$uuid" "$iface" \
            "$(ssid_to_bytes "$ssid")" "$psk_escaped" |
         install_keyfile "$dest"; then
        unset psk_escaped
        echo "Erro ao gravar o perfil." >&2
        return 1
    fi
    unset psk_escaped

    if ! as_root nmcli connection load "$dest" >/dev/null; then
        as_root rm -f "$dest"
        echo "Erro: o NetworkManager rejeitou o perfil. Nada foi mantido." >&2
        return 1
    fi

    autoconnect="$(nmcli -g connection.autoconnect connection show uuid "$uuid" 2>/dev/null)" || {
        echo "Erro: perfil gravado, mas não foi possível validá-lo." >&2
        return 1
    }

    if [ "$autoconnect" != "no" ]; then
        echo "Erro: autoconnect não está desativado. Não ative o perfil." >&2
        return 1
    fi

    secret="$(as_root nmcli --show-secrets -g 802-11-wireless-security.psk \
        connection show uuid "$uuid" 2>/dev/null)" || secret=""

    if [ -z "$secret" ] || [ "$secret" = "--" ]; then
        unset secret
        echo "Erro: perfil gravado sem PSK legível pelo NetworkManager." >&2
        return 1
    fi
    unset secret

    echo
    echo "=== PERFIL CADASTRADO ==="
    echo "Nome: $profile_name"
    echo "UUID: $uuid"
    echo "Interface: $iface"
    echo "Conexão automática: desativada"
    echo "Senha: gravada"
    echo
    echo "O perfil foi salvo, mas a conexão ainda NÃO foi testada."
    echo "A rede atual não foi alterada."
}

main() {
    require_command nmcli || return 1
    require_command ip || return 1
    require_command awk || return 1
    require_command od || return 1

    case "${1:-help}" in
        status)
            show_status
            ;;
        scan)
            scan_networks
            ;;
        configure)
            configure_profile
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
