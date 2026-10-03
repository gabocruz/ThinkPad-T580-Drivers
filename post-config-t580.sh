#!/usr/bin/env bash

# ==============================================================================
# Script de Post-Configuración Integral para Lenovo ThinkPad T580 
# Sistema: Debian 13 (Trixie)
# ==============================================================================

# Validar ejecución como root
if [[ $EUID -ne 0 ]]; then
   echo "[-] Este script debe ejecutarse con privilegios de root (sudo)." 
   exit 1
fi

echo "[+] Iniciando configuración de repositorios y hardware para ThinkPad T580..."

# ------------------------------------------------------------------------------
# 1. Configuración Profesional de Repositorios (/etc/apt/sources.list)
# ------------------------------------------------------------------------------
echo "[*] Resguardando el sources.list original..."
cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%F_%T)

echo "[*] Escribiendo configuración optimizada para Debian 13 (Trixie)..."
cat << 'EOF' > /etc/apt/sources.list
# Debian 13 (Trixie) - Repositorios Oficiales Principales
deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware

# Actualizaciones de seguridad oficiales
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware

# Actualizaciones propuestas / mantenimiento (Trixie Updates)
deb http://deb.debian.org/debian/ trixie-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie-updates main contrib non-free non-free-firmware
EOF

# ------------------------------------------------------------------------------
# 2. Actualización de listas e instalación de paquetes esenciales
# ------------------------------------------------------------------------------
echo "[*] Actualizando índices de paquetes..."
apt update && apt upgrade -y

echo "[*] Instalando microcódigo, firmware, aceleración gráfica y utilidades..."
apt install -y \
    intel-microcode \
    firmware-iwlwifi \
    intel-media-va-driver \
    thermald \
    tlp \
    tlp-rdw \
    smartmontools \
    acpi-call-dkms

# ------------------------------------------------------------------------------
# 3. Configuración de Umbrales de Batería en TLP (Específico ThinkPad T580)
# ------------------------------------------------------------------------------
# La T580 maneja dos baterías: BAT0 (interna) y BAT1 (externa).
# Ajustamos los umbrales para que empiece a cargar al 75% y pare al 80% 
# (ideal si usas mucho la laptop conectada a corriente para cuidar la vida de las celdas).
echo "[*] Configurando políticas de energía y umbrales de batería en TLP..."

TLP_CONF="/etc/tlp.conf"
if [ -f "$TLP_CONF" ]; then
    # Descomentar o inyectar configuraciones recomendadas para ThinkPad
    sed -i 's/#START_CHARGE_THRESH_BAT0=60/START_CHARGE_THRESH_BAT0=75/' "$TLP_CONF"
    sed -i 's/#STOP_CHARGE_THRESH_BAT0=80/STOP_CHARGE_THRESH_BAT0=80/' "$TLP_CONF"
    sed -i 's/#START_CHARGE_THRESH_BAT1=60/START_CHARGE_THRESH_BAT1=75/' "$TLP_CONF"
    sed -i 's/#STOP_CHARGE_THRESH_BAT1=80/STOP_CHARGE_THRESH_BAT1=80/' "$TLP_CONF"
fi

# ------------------------------------------------------------------------------
# 4. Habilitación y Activación de Servicios del Sistema
# ------------------------------------------------------------------------------
echo "[*] Habilitando y arrancando servicios críticos..."

# Thermal Daemon (Evita Thermal Throttling en procesadores Intel)
systemctl enable --now thermald.service

# TLP (Gestión de energía)
systemctl enable --now tlp.service

# TRIM automático para el disco NVMe
systemctl enable --now fstrim.timer

echo "[+] ¡Post-configuración completada exitosamente!"
echo "[*] Se recomienda reiniciar el equipo para aplicar cambios de microcódigo y kernel."
