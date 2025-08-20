#!/usr/bin/env bash
# DNS Godmode Pro - Interface Premium v2.0 (Clean)

# ==================================================
# DESIGN SYSTEM E CONFIGURAÇÕES
# ==================================================
BACKGROUND="#0F1B2A"
ACCENT="#0066FF"
SUCCESS="#00CC88"
WARNING="#FFAA00"
ERROR="#FF3366"
TEXT_WHITE="#FFFFFF"
TEXT_LIGHT="#CCD6F6"
CARD_BG="#172135"
CARD_BORDER="#2A3655"

# Aponta para o script de backend na mesma pasta
MAIN_SCRIPT="./backend.sh" 

# ==================================================
# FUNÇÕES DA INTERFACE (GUI)
# ==================================================

# --- Função para mostrar diálogos simples ---
function show_dialog() {
    local type="$1"
    local title="$2"
    local message="$3"
    yad --$type --title="$title" --width=400 --height=200 --center --borders=20 \
        --text="<span font='14' weight='bold'>$title</span>\n\n<span>$message</span>" \
        --button=OK:0
}

# --- Função para mostrar a tela de instalação com progresso real ---
function install_screen() {
    # Executa o backend.sh --install e envia a saída para a barra de progresso do YAD
    # O 'sudo' é necessário aqui para que o backend possa executar comandos de administrador
    (
      sudo bash "$MAIN_SCRIPT" --install
    ) | yad --progress --title="Instalação Premium" --text="Iniciando a instalação..." \
        --width=500 --height=150 --center --auto-close --auto-kill --button="Cancelar:1"

    # Verifica se a instalação foi bem-sucedida ou cancelada
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        show_dialog "info" "Instalação Concluída" "O sistema DNS Godmode Pro foi instalado com sucesso!"
    else
        show_dialog "warning" "Instalação Interrompida" "A instalação foi cancelada pelo usuário."
    fi
}

# --- Função principal que desenha o menu e controla as ações ---
function main_menu() {
    while true; do
        # 1. Pega o status atual do backend (precisa de sudo para verificar serviços)
        STATUS_JSON=$(sudo bash "$MAIN_SCRIPT" --get-status 2>/dev/null || echo "{}")
        UNBOUND_STATUS=$(echo "$STATUS_JSON" | jq -r '.unbound' 2>/dev/null || echo "Desconhecido")
        ADGUARD_STATUS=$(echo "$STATUS_JSON" | jq -r '.adguard' 2>/dev/null || echo "Desconhecido")

        # 2. Define as cores com base no status
        UNBOUND_COLOR=$([[ "$UNBOUND_STATUS" == "Online" ]] && echo "$SUCCESS" || echo "$ERROR")
        ADGUARD_COLOR=$([[ "$ADGUARD_STATUS" == "Online" ]] && echo "$SUCCESS" || echo "$ERROR")

        # 3. Exibe a janela principal do YAD
        yad --html --title="DNS Godmode Pro" --width=600 --height=400 --center --borders=0 \
            --button="Sair:1" --button="Instalar/Atualizar:2" \
            --text="
            <div style='background-color: $BACKGROUND; color: $TEXT_WHITE; font-family: sans-serif; height: 100%;'>
                <div style='padding: 20px; border-bottom: 1px solid $CARD_BORDER;'>
                    <h1 style='margin: 0; font-size: 20px;'>DNS Godmode Pro</h1>
                    <p style='margin: 0; font-size: 12px; color: $TEXT_LIGHT;'>Painel de Controle</p>
                </div>
                <div style='padding: 25px;'>
                    <div style='background-color: $CARD_BG; border: 1px solid $CARD_BORDER; border-radius: 8px; padding: 20px;'>
                        <h3 style='margin-top: 0;'>Status do Sistema</h3>
                        <p><span style='display: inline-block; width: 12px; height: 12px; border-radius: 50%; background-color: $UNBOUND_COLOR; margin-right: 10px;'></span>Unbound DNS: <b>$UNBOUND_STATUS</b></p>
                        <p style='margin-bottom: 0;'><span style='display: inline-block; width: 12px; height: 12px; border-radius: 50%; background-color: $ADGUARD_COLOR; margin-right: 10px;'></span>AdGuard Home: <b>$ADGUARD_STATUS</b></p>
                    </div>
                </div>
            </div>"

        # 4. Decide o que fazer com base no botão que o usuário clicou
        choice=$?
        case $choice in
            1|252) # Botão "Sair" ou fechou a janela
                exit 0
                ;;
            2) # Botão "Instalar/Atualizar"
                install_screen
                ;;
        esac
    done
}

# ==================================================
# EXECUÇÃO PRINCIPAL
# ==================================================
main_menu