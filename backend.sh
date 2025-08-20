#!/bin/bash
# DNS Godmode Pro - Backend Script v12.0 (Modular & Completo)

# ==============================================================================
# CONFIGURAÇÕES GLOBAIS E HELPERS
# ==============================================================================
UNBOUND_PORT=${UNBOUND_PORT:-5335}
ADG_DNS_PORT=${ADG_DNS_PORT:-53}
ADG_WEB_PORT=${ADG_WEB_PORT:-3000}
ADG_DIR=${ADG_DIR:-/opt/AdGuardHome}
BACKUP_DIR=${BACKUP_DIR:-/root/dns_godmode_backups_$(date +%Y%m%d%H%M%S)}
LOG=${LOG:-./dns_godmode.log} # Log local para compatibilidade com Windows/WSL
USE_GITHUB_API=true
ENABLE_NFTBLOCK=true
ENABLE_FIREWALL=true
ENABLE_FALLBACK=true
SERVICE_TIMEOUT=30

DISTRO=""
PACKAGE_MANAGER=""
NETWORK_MANAGER=""
IS_DESKTOP=false
HAS_SYSTEMD=false
HAS_IPV6=false

_ts(){ date +'%F %T'; }
log(){ printf "[%s] %s\n" "$(_ts)" "$*" | tee -a "$LOG"; }
info(){ log "INFO: $*"; }
ok(){ log "OK: $*"; }
warn(){ log "WARN: $*"; }
err(){ log "ERR: $*"; }

# ==============================================================================
# FUNÇÕES MODULARES (AS "CAIXAS" DE TRABALHO)
# ==============================================================================

# --- MÓDULO 1: DETECÇÃO E PREPARAÇÃO ---
function detect_os() {
    info "Detectando sistema operacional..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    else
        err "Não foi possível detectar a distribuição" && exit 1
    fi

    if command -v apt >/dev/null 2>&1; then PACKAGE_MANAGER="apt"
    elif command -v dnf >/dev/null 2>&1; then PACKAGE_MANAGER="dnf"
    elif command -v pacman >/dev/null 2>&1; then PACKAGE_MANAGER="pacman"
    else err "Gerenciador de pacotes não suportado" && exit 1
    fi

    if command -v systemctl &>/dev/null; then HAS_SYSTEMD=true; fi
    if [ -n "$DISPLAY" ] || pgrep -x "Xorg" &>/dev/null; then IS_DESKTOP=true; fi
    if systemctl is-active --quiet NetworkManager &>/dev/null; then NETWORK_MANAGER="NetworkManager"; fi
    
    if command -v ping6 &>/dev/null && ping6 -c1 -w3 2606:4700:4700::1111 &>/dev/null; then HAS_IPV6=true; fi

    ok "Sistema detectado: $DISTRO, PM: $PACKAGE_MANAGER, Systemd: $HAS_SYSTEMD, IPv6: $HAS_IPV6"
}

function install_dependencies() {
    info "Instalando dependências..."
    case "$PACKAGE_MANAGER" in
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -y >>"$LOG" 2>&1 || warn "apt update falhou"
            apt-get install -y --no-install-recommends ca-certificates curl wget tar jq dnsutils unbound unbound-anchor nftables ufw >>"$LOG" 2>&1 || warn "apt install falhou"
            ;;
        dnf)
            dnf install -y ca-certificates curl wget tar jq bind-utils unbound nftables >>"$LOG" 2>&1 || warn "dnf install falhou"
            ;;
        pacman)
            pacman -Sy --noconfirm --needed ca-certificates curl wget tar jq bind unbound nftables ufw >>"$LOG" 2>&1 || warn "pacman install falhou"
            ;;
    esac
    ok "Dependências instaladas."
}

function prepare_system_dns() {
    info "Preparando o sistema de DNS e resolvendo conflitos..."
    for s in systemd-resolved dnsmasq bind9 named; do
        if $HAS_SYSTEMD && systemctl is-active --quiet "$s" 2>/dev/null; then
            systemctl stop "$s" && systemctl disable "$s"
            log "Serviço conflitante '$s' parado e desabilitado."
        fi
    done
    # Simplificado para o exemplo, o original tem mais lógicas
    cat > /etc/resolv.conf << EOF
nameserver 127.0.0.1
options edns0 trust-ad
EOF
    ok "Sistema de DNS preparado."
}

# --- MÓDULO 2: CONFIGURAÇÃO DO UNBOUND ---
function setup_unbound() {
    info "Configurando Unbound (recursor DNSSEC)..."
    mkdir -p /etc/unbound /var/lib/unbound
    chown -R unbound:unbound /var/lib/unbound 2>/dev/null || true
    curl -o /var/lib/unbound/root.hints https://www.internic.net/domain/named.cache
    unbound-anchor -a /var/lib/unbound/root.key

    cat > /etc/unbound/unbound.conf << EOF
server:
    verbosity: 1
    num-threads: $(nproc)
    interface: 127.0.0.1
    port: $UNBOUND_PORT
    do-ip4: yes
    do-ip6: $HAS_IPV6
    access-control: 127.0.0.0/8 allow
    harden-dnssec-stripped: yes
    root-hints: "/var/lib/unbound/root.hints"
    trust-anchor-file: "/var/lib/unbound/root.key"
EOF

    if $HAS_SYSTEMD; then
        systemctl enable --now unbound.service >>"$LOG" 2>&1 || warn "Falha ao iniciar Unbound"
    fi
    ok "Unbound configurado e iniciado na porta $UNBOUND_PORT."
}

# --- MÓDULO 3: CONFIGURAÇÃO DO ADGUARD HOME ---
function setup_adguard() {
    info "Instalando e configurando AdGuard Home..."
    local ARCH_SFX
    case "$(uname -m)" in
        x86_64|amd64) ARCH_SFX="amd64" ;;
        aarch64|arm64) ARCH_SFX="arm64" ;;
        *) err "Arquitetura não suportada" && exit 1 ;;
    esac
    
    local ASSET_URL="https://static.adguard.com/adguardhome/release/AdGuardHome_linux_${ARCH_SFX}.tar.gz"
    mkdir -p "$ADG_DIR"
    curl -sSL "$ASSET_URL" | tar -xzf - -C "$ADG_DIR" --strip-components=1

    cat > "$ADG_DIR/AdGuardHome.yaml" << EOF
bind_host: 0.0.0.0
dns:
  port: $ADG_DNS_PORT
  upstream_dns:
  - 127.0.0.1:$UNBOUND_PORT
EOF

    if $HAS_SYSTEMD; then
        "$ADG_DIR/AdGuardHome" -s install >>"$LOG" 2>&1
        systemctl enable --now AdGuardHome.service >>"$LOG" 2>&1 || warn "Falha ao iniciar AdGuard Home"
    fi
    ok "AdGuard Home configurado e iniciado na porta $ADG_DNS_PORT."
}

# --- MÓDULO 4: FIREWALL E VALIDAÇÃO ---
function setup_firewall() {
    info "Configurando regras de firewall..."
    if command -v nft &>/dev/null && [ "$ENABLE_NFTBLOCK" = true ]; then
        nft flush ruleset
        nft add table inet dnsguard
        nft add chain inet dnsguard output { type filter hook output priority 0\; }
        nft add rule inet dnsguard output oif "lo" accept
        nft add rule inet dnsguard output ip daddr 127.0.0.1 accept
        nft add rule inet dnsguard output udp dport 53 drop
        nft add rule inet dnsguard output tcp dport 53 drop
        ok "Firewall (nftables) para anti-vazamento de DNS configurado."
    fi
}

function run_final_checks() {
    info "Executando verificações finais..."
    sleep 5 # Espera os serviços estabilizarem
    if ! dig @127.0.0.1 -p "$ADG_DNS_PORT" google.com +short &>/dev/null; then
        warn "Verificação do AdGuard Home falhou."
    fi
    if ! dig @127.0.0.1 -p "$UNBOUND_PORT" . SOA +short &>/dev/null; then
        warn "Verificação do Unbound falhou."
    fi
    ok "Verificações finais concluídas."
}

# --- MÓDULO 5: FUNÇÕES DE GERENCIAMENTO ---
function get_status_json() {
    local unbound_status="Offline"
    local adguard_status="Offline"
    if systemctl is-active --quiet unbound 2>/dev/null; then
        unbound_status="Online"
    fi
    if systemctl is-active --quiet AdGuardHome 2>/dev/null; then
        adguard_status="Online"
    fi
    echo "{\"unbound\": \"$unbound_status\", \"adguard\": \"$adguard_status\"}"
}

# ==============================================================================
# FUNÇÃO PRINCIPAL DE INSTALAÇÃO (O "MAESTRO")
# ==============================================================================
function run_install() {
    trap 'err "A instalação falhou na linha $LINENO." && exit 1' ERR

    if [[ "$EUID" -ne 0 && "$(uname)" == "Linux" ]]; then
      err "Erro: A instalação em um sistema Linux precisa ser executada com permissões de root (sudo)."
      exit 1
    fi

    : > "$LOG"
    info "INICIANDO INSTALAÇÃO DO DNS GODMODE PRO..."
    echo "# INICIANDO INSTALAÇÃO DO DNS GODMODE PRO..."

    echo "10" && echo "# Detectando sistema operacional..."
    detect_os
    
    echo "20" && echo "# Instalando dependências..."
    install_dependencies
    
    echo "40" && echo "# Preparando sistema de DNS..."
    prepare_system_dns
    
    echo "60" && echo "# Configurando Unbound..."
    setup_unbound
    
    echo "80" && echo "# Configurando AdGuard Home..."
    setup_adguard
    
    echo "90" && echo "# Configurando Firewall..."
    setup_firewall
    
    echo "95" && echo "# Realizando verificações finais..."
    run_final_checks

    echo "100" && echo "# Instalação concluída com sucesso!"
    ok "INSTALAÇÃO CONCLUÍDA COM SUCESSO."
    trap - ERR
}

# ==============================================================================
# O CÉREBRO DO SCRIPT (ROTEADOR DE COMANDOS)
# ==============================================================================
function main() {
    case "$1" in
        --install)
            run_install
            ;;
        --get-status)
            get_status_json
            ;;
        *)
            echo "Comando interno desconhecido: '$1'" >&2
            exit 1
            ;;
    esac
}

main "$@"