#!/bin/bash
# DNS Godmode Pro - Backend Script

echo "Iniciando DNS Godmode Pro..."
echo "Este script configura Unbound + AdGuard Home automaticamente"

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    echo "Por favor, execute como root usando: sudo ./backend.sh"
    exit 1
fi

echo "Instalando dependências..."
# Adicione aqui os comandos de instalação
