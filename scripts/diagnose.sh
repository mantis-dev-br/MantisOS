#!/usr/bin/env bash
set -u

echo "=== MODELO ==="
cat /proc/device-tree/model 2>/dev/null || true
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
if command -v iw >/dev/null 2>&1; then
    iw dev
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
