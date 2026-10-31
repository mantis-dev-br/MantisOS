#!/usr/bin/env bash
#
# Instala o link de gerência cabeado do MantisOS.
#
# A porta Ethernet recebe IP fixo numa sub-rede exclusiva, sem gateway e
# sem DNS, e nunca vira rota padrão. É o caminho de acesso administrativo
# e de recuperação quando o Wi-Fi está fora, em modo AP ou mal configurado.
#
# Idempotente: se o perfil já existir, é ajustado para os valores abaixo.
#
# Variáveis opcionais:
#   MANTIS_MGMT_IFACE    interface Ethernet        (padrão: end1)
#   MANTIS_MGMT_ADDRESS  endereço/prefixo da placa (padrão: 10.77.0.1/24)

set -euo pipefail

PROFILE="MantisOS Gerencia"
IFACE="${MANTIS_MGMT_IFACE:-end1}"
ADDRESS="${MANTIS_MGMT_ADDRESS:-10.77.0.1/24}"

die() {
    echo "Erro: $*" >&2
    exit 1
}

if [[ "$EUID" -ne 0 ]]; then
    die "execute com privilégios administrativos: sudo $0"
fi

command -v nmcli >/dev/null 2>&1 || die "nmcli não encontrado."

if [[ ! -d "/sys/class/net/$IFACE" ]]; then
    die "interface não encontrada: $IFACE"
fi

if [[ ! "$ADDRESS" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])$ ]]; then
    die "endereço inválido: $ADDRESS (formato esperado: A.B.C.D/prefixo)"
fi

settings=(
    connection.interface-name "$IFACE"
    connection.autoconnect yes
    connection.autoconnect-priority 100
    ipv4.method manual
    ipv4.addresses "$ADDRESS"
    ipv4.gateway ""
    ipv4.dns ""
    ipv4.never-default yes
    ipv6.method disabled
)

if nmcli -g NAME connection show | grep -qxF -- "$PROFILE"; then
    nmcli connection modify "$PROFILE" "${settings[@]}"
    echo "Perfil ajustado: $PROFILE"
else
    nmcli connection add type ethernet con-name "$PROFILE" "${settings[@]}" >/dev/null
    echo "Perfil criado: $PROFILE"
fi

# Outros perfis Ethernet com autoconnect na mesma interface disputariam a
# porta (tipicamente o perfil DHCP criado pela imagem). Só o autoconnect é
# desativado; nenhum perfil é apagado.
while IFS=: read -r uuid type autoconnect; do
    [[ "$type" == "802-3-ethernet" || "$type" == "ethernet" ]] || continue
    [[ "$autoconnect" == "yes" ]] || continue

    name="$(nmcli -g connection.id connection show uuid "$uuid")"
    [[ "$name" == "$PROFILE" ]] && continue

    # Perfil sem interface fixa também se aplicaria a esta porta.
    bound="$(nmcli -g connection.interface-name connection show uuid "$uuid")"
    [[ -z "$bound" || "$bound" == "$IFACE" ]] || continue

    nmcli connection modify uuid "$uuid" connection.autoconnect no
    echo "Autoconnect desativado em: $name"
done < <(nmcli -t -f UUID,TYPE,AUTOCONNECT connection show)

carrier="$(cat "/sys/class/net/$IFACE/carrier" 2>/dev/null || echo 0)"

active="$(nmcli -g GENERAL.CONNECTION device show "$IFACE" 2>/dev/null || true)"

if [[ "$carrier" != "1" ]]; then
    echo "Sem cabo em $IFACE. O perfil sobe sozinho quando o link aparecer."
elif [[ "$active" == "$PROFILE" ]]; then
    # Já ativo: aplica as mudanças sem derrubar o link (a sessão SSH pode
    # estar passando justamente por ele).
    nmcli device reapply "$IFACE" >/dev/null
    echo "Link ativo em $IFACE: $ADDRESS (configuração reaplicada)"
else
    nmcli connection up "$PROFILE" >/dev/null
    echo "Link ativo em $IFACE: $ADDRESS"
fi
