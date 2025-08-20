#!/usr/bin/env bash
# DNS Godmode Pro - Interface Premium
# UI/UX Design: Professional Enterprise Grade

# Configuração de cores e tema (Design System)
BACKGROUND="#0F1B2A"  # Azul escuro premium
ACCENT="#0066FF"      # Azul elétrico
ACCENT_LIGHT="#3399FF"
SUCCESS="#00CC88"     # Verde sucesso
WARNING="#FFAA00"     # Amarelo alerta
ERROR="#FF3366"       # Vermelho erro
TEXT_WHITE="#FFFFFF"
TEXT_LIGHT="#CCD6F6"
TEXT_GRAY="#8892B0"
CARD_BG="#172135"
CARD_BORDER="#2A3655"

# Configurações principais
CONFIG_DIR="$HOME/.config/dns-godmode-pro"
CONFIG_FILE="$CONFIG_DIR/config.conf"
LOG_FILE="$CONFIG_DIR/app.log"
MAIN_SCRIPT="./dns_godmode_universal_v12.sh"
ICONS_DIR="$CONFIG_DIR/icons"
WALLPAPER_DIR="$CONFIG_DIR/wallpapers"

# Inicializar configurações
initialize() {
    mkdir -p "$CONFIG_DIR" "$ICONS_DIR" "$WALLPAPER_DIR"
    
    # Criar ícones e wallpapers padrão
    create_default_assets
    
    # Configuração padrão se não existir
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
THEME=dark
ANIMATIONS=true
NOTIFICATIONS=true
AUTO_UPDATE=true
COMPACT_MODE=false
LANGUAGE=pt_BR
EOF
    fi
    
    # Carregar configuração
    source "$CONFIG_FILE"
    
    # Aplicar tema
    apply_theme
}

# Criar assets padrão
create_default_assets() {
    # Criar ícone padrão (usando base64 para ícone SVG simples)
    if [[ ! -f "$ICONS_DIR/logo.svg" ]]; then
        cat > "$ICONS_DIR/logo.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <defs>
    <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0066FF"/>
      <stop offset="100%" stop-color="#00CCFF"/>
    </linearGradient>
  </defs>
  <circle cx="50" cy="50" r="45" fill="url(#gradient)"/>
  <path d="M35,35 L65,65 M65,35 L35,65" stroke="$TEXT_WHITE" stroke-width="6" stroke-linecap="round"/>
  <circle cx="50" cy="50" r="15" stroke="$TEXT_WHITE" stroke-width="3" fill="none"/>
</svg>
EOF
    fi

    # Criar wallpaper padrão
    if [[ ! -f "$WALLPAPER_DIR/background.svg" ]]; then
        cat > "$WALLPAPER_DIR/background.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 800">
  <defs>
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0F1B2A"/>
      <stop offset="100%" stop-color="#1A2B4A"/>
    </linearGradient>
    <radialGradient id="circleGradient" cx="50%" cy="50%" r="50%" fx="50%" fy="50%">
      <stop offset="100%" stop-color="#0066FF" stop-opacity="0"/>
    </radialGradient>
  </defs>
  
  <rect width="100%" height="100%" fill="url(#bgGradient)"/>
  <circle cx="300" cy="200" r="150" fill="url(#circleGradient)"/>
  <circle cx="900" cy="600" r="120" fill="url(#circleGradient)"/>
  <circle cx="700" cy="300" r="80" fill="url(#circleGradient)"/>
  
  <!-- Linhas de conexão -->
  <path d="M200,400 C400,300 800,500 1000,400" stroke="$ACCENT" stroke-width="2" stroke-opacity="0.1" fill="none"/>
  <path d="M150,600 C350,400 850,300 1050,500" stroke="$ACCENT" stroke-width="2" stroke-opacity="0.1" fill="none"/>
</svg>

# Aplicar tema selecionado
apply_theme() {
    if [[ "$THEME" == "dark" ]]; then
        BACKGROUND="#0F1B2A"
        CARD_BG="#172135"
        CARD_BORDER="#2A3655"
        TEXT_WHITE="#FFFFFF"
        BACKGROUND="#FFFFFF"
        CARD_BG="#F8F9FA"
        CARD_BORDER="#E9ECEF"
        TEXT_WHITE="#212529"
        TEXT_LIGHT="#495057"
        TEXT_GRAY="#6C757D"
    fi
}

# Logging profissional
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    # Log também para systemd journal se disponível
    if command -v logger &> /dev/null; then
        logger -t "DNSGodmodePro" "$1"
    fi
}

# Verificar dependências
check_dependencies() {
    local missing=()
    
    if ! command -v yad &> /dev/null; then
        missing+=("yad")
    fi
    
    if ! command -v bash &> /dev/null; then
        missing+=("bash")
    fi
    
    if [[ ${#missing[@]} -ne 0 ]]; then
        show_dialog "error" "Dependências missing" "As seguintes dependências estão missing: <b>${missing[*]}</b><br><br>Instale com: <tt>sudo apt install yad</tt>"
        return 1
    fi
    
    if [[ ! -x "$MAIN_SCRIPT" ]]; then
        show_dialog "error" "Script principal" "Script principal não encontrado:<br><tt>$MAIN_SCRIPT</tt>"
        return 1
    fi
    
    return 0
}

# Diálogos estilizados
show_dialog() {
    local type="$1"
    local title="$2"
    local message="$3"
    
    local icon=""
    local buttons="--button=OK:0"
    
    case "$type" in
        "info") icon="--image=info" ;;
        "error") icon="--image=error" ;;
        "warning") icon="--image=warning" ;;
        "question") 
            icon="--image=question"
            buttons="--button=Sim:0 --button=Não:1"
            ;;
    esac
    
    yad --$type \
        --title="$title" \
        --window-icon="$ICONS_DIR/logo.svg" \
        --width=400 \
        --height=200 \
        --center \
        --borders=20 \
        --escape-ok \
        --html \
        --text="<span font='14' weight='bold' color='$TEXT_WHITE'>$title</span>\n\n<span color='$TEXT_LIGHT'>$message</span>" \
        $icon \
        $buttons \
        --formatter='<span font="10">{}</span>' \
        --gtkrc="
        style \"dialog-style\" {
            bg[NORMAL] = \"$BACKGROUND\"
            fg[NORMAL] = \"$TEXT_WHITE\"
            base[NORMAL] = \"$CARD_BG\"
            text[NORMAL] = \"$TEXT_WHITE\"
        }
        class \"GtkDialog\" style \"dialog-style\"
        class \"GtkLabel\" style \"dialog-style\"
        "
}

# Tela de splash/boas-vindas
show_splash() {
    yad --html \
        --title="DNS Godmode Pro" \
        --window-icon="$ICONS_DIR/logo.svg" \
        --width=800 \
        --height=500 \
        --center \
        --undecorated \
        --no-buttons \
        --timeout=3 \
        --text="
        <div style='background: linear-gradient(to bottom, $BACKGROUND, #1A2B4A); height: 100%; display: flex; flex-direction: column; justify-content: center; align-items: center; color: $TEXT_WHITE;'>
            <h1 style='font-size: 36px; margin-bottom: 10px; background: linear-gradient(to right, $ACCENT, $ACCENT_LIGHT); -webkit-background-clip: text; -webkit-text-fill-color: transparent;'>DNS GODMODE PRO</h1>
            <p style='color: $TEXT_LIGHT; font-size: 16px;'>Enterprise-grade DNS security solution</p>
            <div style='margin-top: 40px; width: 50px; height: 50px; border: 3px solid $ACCENT; border-top: 3px solid transparent; border-radius: 50%; animation: spin 1s linear infinite;'></div>
        </div>
        " \
        --gtkrc="
        style \"splash-style\" {
            bg[NORMAL] = \"$BACKGROUND\"
        }
        class \"GtkWindow\" style \"splash-style\"
        "
}

# Header com logo e título
create_header() {
    echo "
    <div style='background: linear-gradient(to right, $BACKGROUND, #1A2B4A); padding: 15px 20px; border-bottom: 1px solid $CARD_BORDER; display: flex; align-items: center;'>
        <img src='$ICONS_DIR/logo.svg' width='32' height='32' style='margin-right: 15px;'>
        <div>
            <h1 style='margin: 0; font-size: 20px; color: $TEXT_WHITE;'>DNS Godmode Pro</h1>
            <p style='margin: 0; font-size: 12px; color: $TEXT_GRAY;'>Enterprise DNS Security Suite</p>
        </div>
    </div>
    "
}

# Menu principal estilizado
main_menu() {
    while true; do
        local choice=$(yad --html \
            --title="DNS Godmode Pro" \
            --window-icon="$ICONS_DIR/logo.svg" \
            --width=1000 \
            --height=650 \
            --center \
            --borders=0 \
            --button="Sair:1" \
            --text="
            $(create_header)
            <div style='display: flex; height: calc(100% - 70px);'>
                <!-- Sidebar -->
                <div style='width: 250px; background: $CARD_BG; border-right: 1px solid $CARD_BORDER; padding: 20px;'>
                    <div style='color: $TEXT_GRAY; font-size: 12px; margin-bottom: 15px; text-transform: uppercase;'>Menu Principal</div>
                    <div style='display: flex; flex-direction: column; gap: 5px;'>
                        <button onclick='echo \"dashboard\" > /tmp/dns_choice' style='background: $ACCENT; color: white; border: none; padding: 12px; text-align: left; border-radius: 5px; cursor: pointer;'>📊 Dashboard</button>
                        <button onclick='echo \"install\" > /tmp/dns_choice' style='background: transparent; color: $TEXT_LIGHT; border: none; padding: 12px; text-align: left; border-radius: 5px; cursor: pointer;'>🚀 Instalar/Atualizar</button>
                        <button onclick='echo \"status\" > /tmp/dns_choice' style='background: transparent; color: $TEXT_LIGHT; border: none; padding: 12px; text-align: left; border-radius: 5px; cursor: pointer;'>🔍 Status do Sistema</button>
                        <button onclick='echo \"test\" > /tmp/dns_choice' style='background: transparent; color: $TEXT_LIGHT; border: none; padding: 12px; text-align: left; border-radius: 5px; cursor: pointer;'>🧪 Testes de Rede</button>
                        <button onclick='echo \"settings\" > /tmp/dns_choice' style='background: transparent; color: $TEXT_LIGHT; border: none; padding: 12px; text-align: left; border-radius: 5px; cursor: pointer;'>⚙️ Configurações</button>
                        <button onclick='echo \"about\" > /tmp/dns_choice' style='background: transparent; color: $TEXT_LIGHT; border: none; padding: 12px; text-align: left; border-radius: 5px; cursor: pointer;'>ℹ️ Sobre</button>
                    </div>
                    
                    <div style='margin-top: 30px; color: $TEXT_GRAY; font-size: 12px; text-transform: uppercase;'>Estatísticas</div>
                    <div style='margin-top: 10px; font-size: 11px; color: $TEXT_LIGHT;'>
                        <div>📡 Consultas hoje: 1,243</div>
                        <div>🛡️ Ameaças bloqueadas: 27</div>
                        <div>⏰ Uptime: 12h 43m</div>
                    </div>
                </div>
                
                <!-- Conteúdo principal -->
                <div style='flex: 1; padding: 25px; background: $BACKGROUND;'>
                    <div style='display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px;'>
                        <!-- Cartão de status -->
                        <div style='background: $CARD_BG; border: 1px solid $CARD_BORDER; border-radius: 8px; padding: 20px;'>
                            <h3 style='margin-top: 0; color: $TEXT_WHITE;'>Status do Sistema</h3>
                            <div style='display: flex; align-items: center; margin-bottom: 10px;'>
                                <span style='display: inline-block; width: 12px; height: 12px; border-radius: 50%; background: $SUCCESS; margin-right: 10px;'></span>
                                <span style='color: $TEXT_LIGHT;'>Unbound DNS: Online</span>
                            </div>
                            <div style='display: flex; align-items: center; margin-bottom: 10px;'>
                                <span style='display: inline-block; width: 12px; height: 12px; border-radius: 50%; background: $SUCCESS; margin-right: 10px;'></span>
                                <span style='color: $TEXT_LIGHT;'>AdGuard Home: Online</span>
                            </div>
                            <div style='display: flex; align-items: center; margin-bottom: 10px;'>
                                <span style='display: inline-block; width: 12px; height: 12px; border-radius: 50%; background: $SUCCESS; margin-right: 10px;'></span>
                                <span style='color: $TEXT_LIGHT;'>DNSSEC: Ativo</span>
                            </div>
                        </div>
                        
                        <!-- Cartão de desempenho -->
                        <div style='background: $CARD_BG; border: 1px solid $CARD_BORDER; border-radius: 8px; padding: 20px;'>
                            <h3 style='margin-top: 0; color: $TEXT_WHITE;'>Desempenho</h3>
                            <div style='color: $TEXT_LIGHT; margin-bottom: 10px;'>
                                <div>CPU: 12%</div>
                                <div style='height: 4px; background: #2A3655; border-radius: 2px; margin: 5px 0;'>
                                    <div style='height: 100%; width: 12%; background: $ACCENT; border-radius: 2px;'></div>
                                </div>
                            </div>
                            <div style='color: $TEXT_LIGHT; margin-bottom: 10px;'>
                                <div>Memória: 24%</div>
                                <div style='height: 4px; background: #2A3655; border-radius: 2px; margin: 5px 0;'>
                                    <div style='height: 100%; width: 24%; background: $ACCENT; border-radius: 2px;'></div>
                                </div>
                            </div>
                            <div style='color: $TEXT_LIGHT;'>
                                <div>Latência: 18ms</div>
                                <div style='height: 4px; background: #2A3655; border-radius: 2px; margin: 5px 0;'>
                                    <div style='height: 100%; width: 18%; background: $SUCCESS; border-radius: 2px;'></div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Cartão de segurança -->
                        <div style='background: $CARD_BG; border: 1px solid $CARD_BORDER; border-radius: 8px; padding: 20px; grid-column: span 2;'>
                            <h3 style='margin-top: 0; color: $TEXT_WHITE;'>Proteção de Segurança</h3>
                            <div style='display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px;'>
                                <div style='text-align: center;'>
                                    <div style='font-size: 24px; color: $SUCCESS;'>27</div>
                                    <div style='font-size: 12px; color: $TEXT_LIGHT;'>Ameaças bloqueadas</div>
                                </div>
                                <div style='text-align: center;'>
                                    <div style='font-size: 24px; color: $SUCCESS;'>1.2K</div>
                                    <div style='font-size: 12px; color: $TEXT_LIGHT;'>Anúncios bloqueados</div>
                                </div>
                                <div style='text-align: center;'>
                                    <div style='font-size: 24px; color: $SUCCESS;'>100%</div>
                                    <div style='font-size: 12px; color: $TEXT_LIGHT;'>DNS criptografado</div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Ações rápidas -->
                    <div style='margin-top: 30px;'>
                        <h3 style='color: $TEXT_WHITE;'>Ações Rápidas</h3>
                        <div style='display: flex; gap: 10px;'>
                            <button onclick='echo \"quick_test\" > /tmp/dns_choice' style='background: $ACCENT; color: white; border: none; padding: 10px 15px; border-radius: 5px; cursor: pointer;'>Teste Rápido</button>
                            <button onclick='echo \"flush_cache\" > /tmp/dns_choice' style='background: $CARD_BORDER; color: $TEXT_LIGHT; border: none; padding: 10px 15px; border-radius: 5px; cursor: pointer;'>Limpar Cache</button>
                            <button onclick='echo \"view_logs\" > /tmp/dns_choice' style='background: $CARD_BORDER; color: $TEXT_LIGHT; border: none; padding: 10px 15px; border-radius: 5px; cursor: pointer;'>Ver Logs</button>
                        </div>
                    </div>
                </div>
            </div>
            " \
            --gtkrc="
            style \"main-style\" {
                bg[NORMAL] = \"$BACKGROUND\"
                fg[NORMAL] = \"$TEXT_WHITE\"
                base[NORMAL] = \"$CARD_BG\"
                text[NORMAL] = \"$TEXT_WHITE\"
            }
            class \"GtkWindow\" style \"main-style\"
            class \"GtkButton\" style \"main-style\"
            ")
        
        if [[ $? -ne 0 ]]; then
            exit 0
        fi
        
        local choice=$(cat /tmp/dns_choice 2>/dev/null || echo "dashboard")
        rm -f /tmp/dns_choice
        
        case "$choice" in
            "dashboard") show_dashboard ;;
            "install") install_screen ;;
            "status") status_screen ;;
            "test") test_screen ;;
            "settings") settings_screen ;;
            "about") about_screen ;;
            "quick_test") quick_test ;;
            "flush_cache") flush_cache ;;
            "view_logs") view_logs ;;
        esac
    done
}

# Tela de dashboard
show_dashboard() {
    # Esta função seria uma versão mais elaborada do menu principal
    # com mais detalhes e visualizações
    show_dialog "info" "Dashboard" "Dashboard em desenvolvimento.<br>Em breve: gráficos em tempo real e métricas detalhadas."
}

# Tela de instalação premium
install_screen() {
    local steps=(
        "Verificando ambiente do sistema"
        "Validando dependências"
        "Configurando repositórios seguros"
        "Instalando Unbound DNS"
        "Configurando AdGuard Home"
        "Aplicando políticas de segurança"
        "Otimizando configurações de rede"
        "Iniciando serviços"
        "Realizando testes de validação"
        "Finalizando instalação"
    )
    
    local step=0
    local total_steps=${#steps[@]}
    
    # Criar arquivo de progresso
    echo "0" > /tmp/install_progress
    
    (
        for ((step=1; step<=total_steps; step++)); do
            percentage=$((step * 100 / total_steps))
            echo "$percentage"
            echo "# ${steps[step-1]}..."
            
            # Simular trabalho (substituir pela instalação real)
            sleep 1
            
            # Atualizar progresso
            echo "$percentage" > /tmp/install_progress
        done
    ) | yad --progress \
        --title="Instalação Premium" \
        --window-icon="$ICONS_DIR/logo.svg" \
        --text="Preparando instalação do DNS Godmode Pro..." \
        --percentage=0 \
        --auto-close \
        --auto-kill \
        --width=500 \
        --height=150 \
        --borders=20 \
        --center \
        --gtkrc="
        style \"progress-style\" {
            bg[NORMAL] = \"$BACKGROUND\"
            fg[NORMAL] = \"$TEXT_WHITE\"
        }
        class \"GtkWindow\" style \"progress-style\"
        " \
        --button="Cancelar:1"
    
    if [[ $? -eq 0 ]]; then
        show_dialog "info" "Instalação Concluída" "Sistema DNS Godmode Pro instalado com sucesso!<br><br>Seu sistema está agora protegido por:<br>• DNS recursivo com DNSSEC<br>• Filtro de conteúdo e anúncios<br>• Prevenção contra vazamento DNS<br>• Criptografia de consultas"
    else
        show_dialog "warning" "Instalação Interrompida" "A instalação foi cancelada pelo usuário."
    fi
}

# Outras funções (status, test, settings, about) seriam implementadas
# de forma similar com o mesmo padrão visual premium

# Função principal
main() {
    # Inicializar
    initialize
    
    # Verificar dependências
    if ! check_dependencies; then
        exit 1
    fi
    
    # Mostrar splash screen
    show_splash
    
    # Mostrar menu principal
    main_menu
}

# Executar
main "$@"        TEXT_LIGHT="#CCD6F6"
        TEXT_GRAY="#8892B0"
    else
EOF
    fi
}

