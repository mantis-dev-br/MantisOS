#!/usr/bin/env bash
set -u

echo "=== MODELO ==="
if [ -r /proc/device-tree/model ]; then
    # O arquivo termina em NUL; removê-lo evita aviso e lixo na saída.
    tr -d '\000' < /proc/device-tree/model
    echo
else
    echo "desconhecido"
fi
echo

echo "=== SISTEMA ==="
cat /etc/os-release 2>/dev/null || true
uname -a
echo

echo "=== MEMORIA ==="
free -h
echo

echo "=== ARMAZENAMENTO ==="
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS,MODEL
echo

echo "=== INTERFACES ==="
ip -br link
echo

echo "=== ENDERECOS ==="
ip -br addr
echo

echo "=== WIFI ==="
# iw fica em /usr/sbin, fora do PATH de usuários comuns no Debian.
IW="$(PATH="$PATH:/usr/sbin:/sbin" command -v iw 2>/dev/null || true)"
if [ -n "$IW" ]; then
    "$IW" dev
else
    echo "Comando iw indisponivel."
fi
echo

echo "=== GERENCIAMENTO DE REDE ==="
systemctl is-active NetworkManager 2>/dev/null || true
systemctl is-active systemd-networkd 2>/dev/null || true
echo

echo "=== TEMPERATURA ==="
for zone in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$zone" ] || continue
    printf '%s: ' "$zone"
    cat "$zone"
done

echo
echo "Diagnostico concluido."
