#!/usr/bin/env bash

# ==============================================================================
# Script de Validación y Auditoría de Salud - Lenovo ThinkPad T580 (Debian 13)
# ==============================================================================

# Validar ejecución como root para poder leer todos los estados del sistema
if [[ $EUID -ne 0 ]]; then
   echo "[-] Este script debe ejecutarse con privilegios de root (sudo) para una auditoría completa." 
   exit 1
fi

ANOMALIAS=0

echo "=============================================================================="
echo " [i] INICIANDO AUDITORÍA DE SISTEMA PARA THINKPAD T580"
echo "=============================================================================="

# 1. Validación de Microcódigo Intel
echo -n "[*] Verificando microcódigo de CPU... "
MICROCODE_CHECK=$(dmesg | grep -i microcode)
if [[ -n "$MICROCODE_CHECK" ]]; then
    echo "OK"
else
    echo "[!] ADVERTENCIA: No se detectó la carga temprana de microcódigo."
    ((ANOMALIAS++))
fi

# 2. Validación de Thermal Daemon
echo -n "[*] Verificando servicio thermald (Protección térmica)... "
if systemctl is-active --quiet thermald.service; then
    echo "OK (Activo)"
else
    echo "[!] ANOMALÍA: El servicio 'thermald' no está activo."
    ((ANOMALIAS++))
fi

# 3. Validación de TLP (Gestión de energía y baterías)
echo -n "[*] Verificando servicio TLP... "
if systemctl is-active --quiet tlp.service; then
    echo "OK (Activo)"
else
    echo "[!] ANOMALÍA: El servicio 'tlp' no está activo."
    ((ANOMALIAS++))
fi

# 4. Validación de Estado de Baterías (TLP Stats resumido)
echo "------------------------------------------------------------------------------"
echo "[*] Estado de Baterías (ThinkPad Dual Battery):"
if command -v tlp-stat &>/dev/null; then
    tlp-stat -b | grep -E "(BAT0|BAT1| carico|charge|status)"
else
    echo "[!] ADVERTENCIA: 'tlp-stat' no está disponible."
    ((ANOMALIAS++))
fi
echo "------------------------------------------------------------------------------"

# 5. Validación de TRIM automático para NVMe
echo -n "[*] Verificando temporizador fstrim.timer (NVMe Trim)... "
if systemctl is-active --quiet fstrim.timer; then
    echo "OK (Programado)"
else
    echo "[!] ANOMALÍA: El temporizador de fstrim no está activo."
    ((ANOMALIAS++))
fi

# 6. Validación de Aceleración Gráfica VA-API
echo -n "[*] Verificando soporte de Aceleración por Hardware (VA-API)... "
if command -v vainfo &>/dev/null; then
    # Capturar salida de vainfo para ver si reporta un driver válido
    VA_OUTPUT=$(vainfo 2>&1)
    if echo "$VA_OUTPUT" | grep -q "Driver version"; then
        echo "OK"
    else
        echo "[!] ADVERTENCIA: 'vainfo' instalado pero puede que el driver iHD/i965 no esté respondiendo correctamente."
        ((ANOMALIAS++))
    fi
else
    echo "[!] ADVERTENCIA: El paquete 'vainfo' no está instalado para verificar la GPU."
    ((ANOMALIAS++))
fi

# ==============================================================================
# Resumen Final
# ==============================================================================
echo "=============================================================================="
if [[ $ANOMALIAS -eq 0 ]]; then
    echo " [+] ¡RESULTADO: Todo en orden! El sistema opera en óptimas condiciones."
else
    echo " [!] ¡ATENCIÓN: Se detectaron $ANOMALIAS anomalías o advertencias a revisar!"
fi
echo "=============================================================================="
