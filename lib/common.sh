#!/bin/bash

show_status() {
    echo "=== MantisOS ==="
MODEL="desconhecido"
if [ -r /proc/device-tree/model ]; then
    MODEL="$(tr -d '\000' < /proc/device-tree/model)"
fi
echo "Modelo: ${MODEL:-desconhecido}"
    echo "Kernel: $(uname -r)"
    echo "Arquitetura: $(uname -m)"
    echo
    echo "=== MEMORIA ==="
    free -h
    echo
    echo "=== ARMAZENAMENTO ==="
    df -h /
}

show_network() {
    echo "=== INTERFACES ==="
    ip -br link
    echo
    echo "=== ENDERECOS ==="
    ip -br addr
    echo
    echo "=== ROTAS ==="
    ip route
    echo
    echo "=== NETWORKMANAGER ==="
    nmcli general status
    nmcli device status
}

show_services() {
    echo "=== SERVICOS DO MANTISOS ==="
    systemctl --no-pager --type=service --state=running
}
