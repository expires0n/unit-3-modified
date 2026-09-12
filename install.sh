#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#   unit-3-modified installer — Hyprland + Quickshell rice (Pastel Dusk)
#   Kaynak: https://github.com/samyns/Unit-3 (fork: expires0n/unit-3-modified)
#   Kullanim: bash <(curl -fsSL https://raw.githubusercontent.com/expires0n/unit-3-modified/main/install.sh)
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

readonly REPO_URL="https://github.com/expires0n/unit-3-modified.git"
readonly REPO_BRANCH="${UNIT3_BRANCH:-main}"
readonly CLONE_DIR="${TMPDIR:-/tmp}/unit3mod-install-$$"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
readonly BACKUP_DIR
readonly CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Tekrar kurulumlarda EZILMEYECEK dosyalar ($CONFIG_HOME'a göre)
readonly PRESERVED_FILES=(
    "hypr/user.conf"
    "quickshell/settings/Settings.qml"
)

# Bu installer'in yönettiği klasörler ($CONFIG_HOME içinde)
readonly MANAGED_DIRS=(hypr quickshell waybar kitty fontconfig gtk-3.0 gtk-4.0)

PRESERVED_STASH=""

if [[ -t 1 ]]; then
    C_RED=$'\033[0;31m';   C_GREEN=$'\033[0;32m'
    C_YELLOW=$'\033[0;33m'; C_BLUE=$'\033[0;34m'
    C_BOLD=$'\033[1m';     C_RESET=$'\033[0m'
else
    C_RED='';C_GREEN='';C_YELLOW='';C_BLUE='';C_BOLD='';C_RESET=''
fi
log()   { printf "%s[*]%s %s\n" "$C_BLUE"   "$C_RESET" "$*"; }
ok()    { printf "%s[✓]%s %s\n" "$C_GREEN"  "$C_RESET" "$*"; }
warn()  { printf "%s[!]%s %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
err()   { printf "%s[✗]%s %s\n" "$C_RED"    "$C_RESET" "$*" >&2; }
fatal() { err "$*"; exit 1; }

ask_yn() {
    local prompt="$1" default="${2:-n}" reply hint="[y/N]"
    [[ "$default" == "y" ]] && hint="[Y/n]"
    while true; do
        read -rp "$(printf '%s[?]%s %s %s ' "$C_YELLOW" "$C_RESET" "$prompt" "$hint")" reply
        reply="${reply:-$default}"
        case "${reply,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *) warn "y ya da n yaz." ;;
        esac
    done
}

cleanup() {
    [[ -d "$CLONE_DIR" ]] && rm -rf "$CLONE_DIR"
    [[ -n "$PRESERVED_STASH" && -d "$PRESERVED_STASH" ]] && rm -rf "$PRESERVED_STASH"
}
trap cleanup EXIT

preflight() {
    log "Kontroller yapiliyor…"
    [[ $EUID -ne 0 ]] || fatal "Root olarak calistirma. Normal kullaniciyla calistir, sudo otomatik sorulur."
    command -v pacman >/dev/null || fatal "pacman yok — bu script Arch tabanli dagitimlar icin."
    command -v sudo   >/dev/null || fatal "sudo gerekli."
    command -v git    >/dev/null || sudo pacman -S --needed --noconfirm git
    sudo -v || fatal "sudo dogrulamasi basarisiz."
    while true; do sudo -n true; sleep 60; kill -0 $$ 2>/dev/null || exit; done 2>/dev/null &
    ping -c 1 -W 3 archlinux.org >/dev/null 2>&1 || fatal "Internet yok."
    ok "Tamam."
}

collect_choices() {
    echo
    BACKUP_OLD=true;          ask_yn "Eski configler $BACKUP_DIR altina yedeklensin mi?" y || BACKUP_OLD=false
    INSTALL_AUR=true;         ask_yn "AUR paketleri kurulsun mu? (quickshell-git, awww, fontlar… siddetle onerilir)" y || INSTALL_AUR=false
    INSTALL_WALLPAPERS=true;  ask_yn "Duvar kagitlari ~/Pictures/wallpapers icine kurulsun mu?" y || INSTALL_WALLPAPERS=false
    INSTALL_BASHRC=true;      ask_yn "Unit-3 .bashrc kurulsun mu?" y || INSTALL_BASHRC=false
    ENABLE_SERVICES=true;     ask_yn "Servisler acilsin mi? (NetworkManager, pipewire)" y || ENABLE_SERVICES=false
    echo
}

install_base() {
    log "base-devel + git kuruluyor…"
    sudo pacman -S --needed --noconfirm base-devel git
}

bootstrap_aur_helper() {
    if command -v yay  >/dev/null; then ok "yay zaten var."; return; fi
    if command -v paru >/dev/null; then ok "paru zaten var."; return; fi
    log "yay kuruluyor (AUR yardimcisi)…"
    local d; d=$(mktemp -d)
    git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$d/yay-bin"
    (cd "$d/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$d"
    ok "yay kuruldu."
}

clone_repo() {
    log "Repo klonlaniyor ($REPO_BRANCH)…"
    git clone --depth=1 --branch "$REPO_BRANCH" "$REPO_URL" "$CLONE_DIR"
}

install_packages() {
    local pacman_pkgs aur_pkgs
    mapfile -t pacman_pkgs < <(grep -vE '^\s*(#|$)' "$CLONE_DIR/packages/pacman.txt")
    if (( ${#pacman_pkgs[@]} > 0 )); then
        log "${#pacman_pkgs[@]} pacman paketi kuruluyor…"
        sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}"
    fi
    if $INSTALL_AUR; then
        mapfile -t aur_pkgs < <(grep -vE '^\s*(#|$)' "$CLONE_DIR/packages/aur.txt")
        if (( ${#aur_pkgs[@]} > 0 )); then
            log "${#aur_pkgs[@]} AUR paketi kuruluyor…"
            local helper; helper=$(command -v yay || command -v paru)
            "$helper" -S --needed --noconfirm "${aur_pkgs[@]}"
        fi
    fi
}

stash_preserved_files() {
    PRESERVED_STASH=$(mktemp -d)
    local count=0
    for rel in "${PRESERVED_FILES[@]}"; do
        local src="$CONFIG_HOME/$rel"
        if [[ -f "$src" ]]; then
            local stash="$PRESERVED_STASH/$rel"
            mkdir -p "$(dirname "$stash")"
            cp -a "$src" "$stash"
            count=$((count + 1))
        fi
    done
    (( count > 0 )) && ok "$count kisisel dosya korunacak."
}

restore_preserved_files() {
    [[ -z "$PRESERVED_STASH" || ! -d "$PRESERVED_STASH" ]] && return 0
    for rel in "${PRESERVED_FILES[@]}"; do
        local stash="$PRESERVED_STASH/$rel"
        local dest="$CONFIG_HOME/$rel"
        if [[ -f "$stash" ]]; then
            mkdir -p "$(dirname "$dest")"
            cp -a "$stash" "$dest"
            ok "Geri yuklendi: $rel"
        fi
    done
}

deploy_configs() {
    mkdir -p "$CONFIG_HOME"
    stash_preserved_files
    for name in "${MANAGED_DIRS[@]}"; do
        local src="$CLONE_DIR/config/$name"
        local dest="$CONFIG_HOME/$name"
        [[ -d "$src" ]] || { warn "$name repoda yok, atlaniyor."; continue; }
        if [[ -e "$dest" ]]; then
            if $BACKUP_OLD; then
                mkdir -p "$BACKUP_DIR"
                log "Yedek: $dest → $BACKUP_DIR/$name"
                mv "$dest" "$BACKUP_DIR/$name"
            else
                warn "Siliniyor (yedeksiz): $dest"
                rm -rf "$dest"
            fi
        fi
        log "Kuruluyor: $name"
        cp -r "$src" "$dest"
    done
    restore_preserved_files
    log "Scriptlere calisma izni veriliyor…"
    find "$CONFIG_HOME/hypr" "$CONFIG_HOME/quickshell" "$CONFIG_HOME/waybar" \
        -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true
}

deploy_system_files() {
    local pam_src="$CLONE_DIR/config/system/pam.d"
    [[ -d "$pam_src" ]] || { warn "Sistem dosyasi yok."; return; }
    log "PAM kurallari kuruluyor…"
    for f in "$pam_src"/*; do
        [[ -f "$f" ]] || continue
        sudo install -D -m 644 "$f" "/etc/pam.d/$(basename "$f")"
        ok "PAM: /etc/pam.d/$(basename "$f")"
    done
}

deploy_shell_config() {
    $INSTALL_BASHRC || { warn ".bashrc atlaniyor."; return; }
    local bashrc_src="$CLONE_DIR/config/bash/.bashrc"
    local bashrc_dest="$HOME/.bashrc"
    [[ -f "$bashrc_src" ]] || { warn "Repoda .bashrc yok."; return; }
    if [[ -f "$bashrc_dest" ]] && ! grep -q "Unit-3" "$bashrc_dest"; then
        if $BACKUP_OLD; then
            mkdir -p "$BACKUP_DIR"
            cp "$bashrc_dest" "$BACKUP_DIR/.bashrc"
            log "Eski ~/.bashrc yedeklendi."
        fi
    fi
    cp "$bashrc_src" "$bashrc_dest"
    [[ -f "$HOME/.bashrc.local" ]] || echo "# Kisisel bash ayarlarin (guncellemelerde ezilmez)." > "$HOME/.bashrc.local"
    ok ".bashrc kuruldu."
}

setup_user_dirs() {
    mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Screenshots"
    if $INSTALL_WALLPAPERS && [[ -d "$CLONE_DIR/assets/wallpapers" ]]; then
        log "Duvar kagitlari kuruluyor…"
        cp -n "$CLONE_DIR/assets/wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
    fi
    # Giriste acilacak duvar kagidi (SUPER+P secimi bunu ezer, kalici olur)
    if [[ ! -f "$CONFIG_HOME/hypr/current-wallpaper" ]]; then
        local first
        first="$(find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -n1)"
        [[ -n "$first" ]] && printf '%s' "$first" > "$CONFIG_HOME/hypr/current-wallpaper"
    fi
}

deploy_qshare_symlink() {
    local script="$CONFIG_HOME/quickshell/scripts/qshare.py"
    local link="$HOME/.local/bin/qshare"
    [[ -f "$script" ]] || { warn "qshare.py yok."; return; }
    mkdir -p "$HOME/.local/bin"
    rm -f "$link"
    ln -s "$script" "$link"
    ok "qshare baglantisi kuruldu."
}

enable_services() {
    $ENABLE_SERVICES || { warn "Servisler atlaniyor."; return; }
    sudo systemctl enable --now NetworkManager.service 2>/dev/null || warn "NetworkManager atlandi."
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || warn "pipewire atlandi."
}

finalize() {
    echo
    ok "${C_BOLD}Kurulum bitti!${C_RESET}"
    echo
    echo "  Sonraki adimlar (README'de detayli):"
    echo "    1. Cikis yapip Hyprland'a tekrar gir."
    echo "    2. Kisisel ayarlar: ~/.config/hypr/user.conf"
    echo "    3. Otomatik giris + kilit, SSD otomount, spicetify icin README'ye bak."
    [[ -d "$BACKUP_DIR" ]] && echo "  Yedek: $BACKUP_DIR"
    echo
}

main() {
    preflight
    collect_choices
    install_base
    $INSTALL_AUR && bootstrap_aur_helper
    clone_repo
    install_packages
    deploy_configs
    deploy_system_files
    deploy_shell_config
    setup_user_dirs
    deploy_qshare_symlink
    enable_services
    finalize
}

main "$@"
