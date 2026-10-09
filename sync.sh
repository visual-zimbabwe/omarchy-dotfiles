#!/usr/bin/env bash
# ==============================================================================
# sync.sh - Export current system state, dotfiles, packages & configs to repo
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${BOLD}${BLUE}==> Syncing current system state to repository...${RESET}"

# 1. Export Package Lists
echo -e "${GREEN}--> Exporting package manifests...${RESET}"
mkdir -p "$REPO_DIR/packages"

if command -v pacman &>/dev/null; then
  pacman -Qqen | sort -u > "$REPO_DIR/packages/pkglist-native.txt"
  pacman -Qqem | sort -u > "$REPO_DIR/packages/pkglist-aur.txt"
  echo "    Saved native packages: $(wc -l < "$REPO_DIR/packages/pkglist-native.txt")"
  echo "    Saved AUR packages:    $(wc -l < "$REPO_DIR/packages/pkglist-aur.txt")"
fi

if command -v code &>/dev/null; then
  code --list-extensions | sort -u > "$REPO_DIR/packages/vscode-extensions.txt"
  echo "    Saved VS Code extensions: $(wc -l < "$REPO_DIR/packages/vscode-extensions.txt")"
fi

cat << 'EXTS' > "$REPO_DIR/packages/npm-globals.txt"
mudslide
peerflix
webtorrent-cli
EXTS

# 2. Export Custom Binaries
echo -e "${GREEN}--> Exporting custom binaries from ~/.local/bin...${RESET}"
mkdir -p "$REPO_DIR/bin"
for bin in stream-torrent watchsports watchtv env env.fish; do
  if [[ -f "$HOME_DIR/.local/bin/$bin" ]]; then
    cp -f "$HOME_DIR/.local/bin/$bin" "$REPO_DIR/bin/$bin"
    chmod +x "$REPO_DIR/bin/$bin"
  fi
done

# 3. Export Home Dotfiles
echo -e "${GREEN}--> Exporting home dotfiles...${RESET}"
mkdir -p "$REPO_DIR/home"
for dot in .bashrc .zshrc .profile .bash_profile .XCompose; do
  if [[ -f "$HOME_DIR/$dot" ]]; then
    cp -f "$HOME_DIR/$dot" "$REPO_DIR/home/$dot"
  fi
done

# 4. Export ~/.config directories
echo -e "${GREEN}--> Exporting ~/.config configurations...${RESET}"
mkdir -p "$REPO_DIR/config"

# Helper function to copy and sanitize directories
copy_clean() {
  local src="$1"
  local dst="$2"
  if [[ -e "$src" ]]; then
    rm -rf "$dst"
    mkdir -p "$(dirname "$dst")"
    cp -rfL "$src" "$dst"
    # Remove backup, git, and cache artifacts
    find "$dst" -name ".git" -exec rm -rf {} + 2>/dev/null || true
    find "$dst" -name "*.bak*" -exec rm -rf {} + 2>/dev/null || true
    find "$dst" -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find "$dst" -name "*.sock*" -exec rm -rf {} + 2>/dev/null || true
    find "$dst" -name "*.log" -exec rm -rf {} + 2>/dev/null || true
  fi
}

# Standard config directories
for cfg in alacritty btop fcitx5 foot ghostty kitty lazygit mpv tmux; do
  copy_clean "$HOME_DIR/.config/$cfg" "$REPO_DIR/config/$cfg"
done

# Standalone config files
for file in starship.toml mimeapps.list chrome-flags.conf chromium-flags.conf; do
  [[ -f "$HOME_DIR/.config/$file" ]] && cp -f "$HOME_DIR/.config/$file" "$REPO_DIR/config/$file"
done

# CLI tools
copy_clean "$HOME_DIR/.config/cliamp" "$REPO_DIR/config/cliamp"
copy_clean "$HOME_DIR/.config/newsboat" "$REPO_DIR/config/newsboat"
copy_clean "$HOME_DIR/.config/mise" "$REPO_DIR/config/mise"
copy_clean "$HOME_DIR/.config/nvim" "$REPO_DIR/config/nvim"
copy_clean "$HOME_DIR/.config/hypr" "$REPO_DIR/config/hypr"
copy_clean "$HOME_DIR/.config/omarchy" "$REPO_DIR/config/omarchy"

# VS Code settings
mkdir -p "$REPO_DIR/config/Code/User"
[[ -f "$HOME_DIR/.config/Code/User/settings.json" ]] && cp -f "$HOME_DIR/.config/Code/User/settings.json" "$REPO_DIR/config/Code/User/settings.json"

# Git config (sanitize gh credential helper to be system-agnostic)
if [[ -f "$HOME_DIR/.config/git/config" ]]; then
  mkdir -p "$REPO_DIR/config/git"
  sed -E 's|helper = !/home/[^/]+/\.local/share/mise/installs/gh/[^/]+/gh_[^/]+/bin/gh auth git-credential|helper = !gh auth git-credential|g' \
    "$HOME_DIR/.config/git/config" > "$REPO_DIR/config/git/config"
fi

echo -e "\n${BOLD}${GREEN}✔ System state synced successfully!${RESET}"
echo -e "You can now commit and push the latest configuration:"
echo -e "  git add ."
echo -e "  git commit -m \"Update system dotfiles & package manifest\""
echo -e "  git push"
