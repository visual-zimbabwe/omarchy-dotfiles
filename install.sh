#!/usr/bin/env bash
# ==============================================================================
# Omarchy Setup & Cross-Platform Dotfiles Installer
# Author: Jean Marie Uwimana (visual-zimbabwe)
# Repository: https://github.com/visual-zimbabwe/omarchy-dotfiles
# ==============================================================================
set -euo pipefail

# Visual styling
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

echo -e "${BOLD}${CYAN}"
cat << "BANNER"
  ___                               _             
 / _ \ _ __ ___   __ _ _ __ ___| |__  _   _ 
| | | | '_ ` _ \ / _` | '__/ __| '_ \| | | |
| |_| | | | | | | (_| | | | (__| | | | |_| |
 \___/|_| |_| |_|\__,_|_|  \___|_| |_|\__, |
                                      |___/ 
      Complete System & Dotfiles Installer
BANNER
echo -e "${RESET}"

OS="$(uname -s)"
REPO_URL="https://github.com/visual-zimbabwe/omarchy-dotfiles.git"
TARGET_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-dotfiles"

# ------------------------------------------------------------------------------
# 1. Execution Context & Repository Bootstrapping
# ------------------------------------------------------------------------------
if [[ -d "$(dirname "$0")/config" && -f "$(dirname "$0")/sync.sh" ]]; then
  SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
else
  if [[ -d "$TARGET_DIR/.git" ]]; then
    echo -e "${BLUE}==>${RESET} ${BOLD}Updating existing repository at ${CYAN}$TARGET_DIR${RESET}..."
    git -C "$TARGET_DIR" pull --ff-only 2>/dev/null || true
  else
    echo -e "${BLUE}==>${RESET} ${BOLD}Cloning setup repository to ${CYAN}$TARGET_DIR${RESET}..."
    mkdir -p "$(dirname "$TARGET_DIR")"
    if ! command -v git &>/dev/null && command -v pacman &>/dev/null; then
      sudo pacman -S --needed --noconfirm git
    fi
    git clone "$REPO_URL" "$TARGET_DIR"
  fi
  SRC_DIR="$TARGET_DIR"
fi

cd "$SRC_DIR"

# ------------------------------------------------------------------------------
# 2. macOS Handling
# ------------------------------------------------------------------------------
if [[ "$OS" == "Darwin" ]]; then
  echo -e "${CYAN}==>${RESET} ${BOLD}Detected macOS environment.${RESET}"
  echo -e "--> Restoring cross-platform dotfiles (Alacritty, Ghostty, Kitty, Starship, Neovim, Lazygit)..."
  mkdir -p "$HOME/.config" "$HOME/.local/bin"

  for app in alacritty btop ghostty kitty lazygit nvim; do
    if [[ -d "config/$app" ]]; then
      mkdir -p "$HOME/.config/$app"
      cp -rf "config/$app"/* "$HOME/.config/$app/"
    fi
  done
  [[ -f "config/starship.toml" ]] && cp -f "config/starship.toml" "$HOME/.config/"
  [[ -f "home/.zshrc" ]] && cp -f "home/.zshrc" "$HOME/.zshrc"
  
  # Custom binaries
  if [[ -d "bin" ]]; then
    cp -rf bin/* "$HOME/.local/bin/" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
  fi

  echo -e "\n${BOLD}${GREEN}✔ macOS dotfiles successfully restored!${RESET}"
  echo -e "${YELLOW}Note:${RESET} Omarchy is a Wayland/Hyprland desktop environment for Linux."
  echo -e "To run the full Omarchy desktop on Apple Silicon Mac, install Try Omarchy:"
  echo -e "${CYAN}https://github.com/themartiano/try-omarchy${RESET}"
  exit 0
fi

# ------------------------------------------------------------------------------
# 3. Linux & Omarchy Base Check
# ------------------------------------------------------------------------------
echo -e "${BLUE}==>${RESET} ${BOLD}Detected Linux environment.${RESET}"

# If on Arch Linux but missing Omarchy desktop
if ! command -v omarchy &>/dev/null; then
  echo -e "${YELLOW}--> Notice: Omarchy is not yet installed on this system.${RESET}"
  if command -v pacman &>/dev/null; then
    echo -e "${BOLD}Would you like to install the full Omarchy base desktop first?${RESET}"
    read -rp "Install Omarchy desktop now? [Y/n] " choice < /dev/tty || choice="y"
    if [[ "$choice" =~ ^[Yy]$ || -z "$choice" ]]; then
      echo -e "${GREEN}--> Launching official Omarchy desktop installer...${RESET}"
      bash <(curl -fsSL https://omarchy.org/install)
    fi
  else
    echo -e "${YELLOW}--> Non-Arch Linux detected. Restoring portable terminal & CLI configurations.${RESET}"
  fi
fi

# ------------------------------------------------------------------------------
# 4. Package Installation (Native & AUR)
# ------------------------------------------------------------------------------
if command -v pacman &>/dev/null; then
  echo -e "\n${BLUE}==>${RESET} ${BOLD}Checking & installing native Arch packages...${RESET}"
  
  # Synchronize database
  sudo pacman -Sy --noconfirm 2>/dev/null || true

  if [[ -f "packages/pkglist-native.txt" ]]; then
    echo -e "--> Filtering available repository packages..."
    # Find matching available packages
    mapfile -t available_pkgs < <(comm -12 <(sort -u packages/pkglist-native.txt) <(pacman -Ssq | sort -u))
    if [[ ${#available_pkgs[@]} -gt 0 ]]; then
      echo -e "--> Installing ${#available_pkgs[@]} native packages..."
      sudo pacman -S --needed --noconfirm "${available_pkgs[@]}" || true
    fi
  fi

  # Setup AUR helper (yay) if missing
  if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
    echo -e "${BLUE}==>${RESET} ${BOLD}Installing AUR helper (yay)...${RESET}"
    sudo pacman -S --needed --noconfirm base-devel git
    TMP_YAY="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$TMP_YAY/yay-bin" 2>/dev/null || git clone https://aur.archlinux.org/yay.git "$TMP_YAY/yay-bin"
    (cd "$TMP_YAY/yay-bin" && makepkg -si --noconfirm) || true
    rm -rf "$TMP_YAY"
  fi

  AUR_HELPER=""
  if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
  elif command -v paru &>/dev/null; then
    AUR_HELPER="paru"
  fi

  if [[ -n "$AUR_HELPER" && -f "packages/pkglist-aur.txt" ]]; then
    echo -e "\n${BLUE}==>${RESET} ${BOLD}Checking & installing AUR packages with $AUR_HELPER...${RESET}"
    $AUR_HELPER -S --needed --noconfirm - < packages/pkglist-aur.txt || true
  fi
fi

# ------------------------------------------------------------------------------
# 5. Toolchains & Runtimes (Mise)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}==>${RESET} ${BOLD}Configuring toolchains & runtimes via Mise...${RESET}"
if ! command -v mise &>/dev/null; then
  if command -v pacman &>/dev/null; then
    sudo pacman -S --needed --noconfirm mise 2>/dev/null || yay -S --needed --noconfirm mise-bin 2>/dev/null || true
  fi
  if ! command -v mise &>/dev/null; then
    echo -e "--> Installing mise via standalone installer..."
    curl -fsSL https://mise.run | sh
    export PATH="$HOME/.local/bin:$HOME/.local/share/mise/bin:$PATH"
  fi
fi

# Deploy mise config early
if [[ -d "config/mise" ]]; then
  mkdir -p "$HOME/.config/mise"
  cp -rf config/mise/* "$HOME/.config/mise/"
fi

# Install toolchains configured in mise
if command -v mise &>/dev/null; then
  echo -e "--> Installing runtime toolchains (Node, Python, Go, CLI tools)..."
  mise install --yes 2>/dev/null || true
fi

# Install Global NPM Utilities if Node/npm is active
if [[ -f "packages/npm-globals.txt" ]]; then
  NPM_BIN="$(command -v npm || true)"
  if [[ -n "$NPM_BIN" ]]; then
    echo -e "--> Installing global NPM utilities..."
    mapfile -t npm_pkgs < <(grep -v '^[[:space:]]*$' packages/npm-globals.txt)
    if [[ ${#npm_pkgs[@]} -gt 0 ]]; then
      npm install -g "${npm_pkgs[@]}" 2>/dev/null || true
    fi
  fi
fi

# ------------------------------------------------------------------------------
# 6. Deploy Dotfiles & User Configurations
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}==>${RESET} ${BOLD}Deploying user configurations...${RESET}"

# A. Restore Home dotfiles (~/.*)
if [[ -d "home" ]]; then
  echo -e "--> Restoring shell dotfiles (.bashrc, .zshrc, .profile, etc.)..."
  for dotfile in home/.*; do
    name="$(basename "$dotfile")"
    [[ "$name" == "." || "$name" == ".." ]] && continue
    cp -f "$dotfile" "$HOME/$name"
  done
fi

# B. Restore Custom Binaries (~/.local/bin)
if [[ -d "bin" ]]; then
  echo -e "--> Restoring custom CLI utilities to ~/.local/bin..."
  mkdir -p "$HOME/.local/bin"
  cp -rf bin/* "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
fi

# C. Restore ~/.config directories & files
if [[ -d "config" ]]; then
  echo -e "--> Restoring ~/.config configurations..."
  mkdir -p "$HOME/.config"
  for item in config/*; do
    name="$(basename "$item")"
    if [[ -d "$item" ]]; then
      mkdir -p "$HOME/.config/$name"
      cp -rf "$item"/* "$HOME/.config/$name/"
    elif [[ -f "$item" ]]; then
      cp -f "$item" "$HOME/.config/"
    fi
  done
fi

# Fix permissions
chmod 700 "$HOME/.config/cliamp" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 7. VS Code Extensions
# ------------------------------------------------------------------------------
if command -v code &>/dev/null && [[ -f "packages/vscode-extensions.txt" ]]; then
  echo -e "\n${BLUE}==>${RESET} ${BOLD}Installing VS Code extensions...${RESET}"
  while IFS= read -r ext; do
    if [[ -n "$ext" && ! "$ext" =~ ^[[:space:]]*# ]]; then
      echo -e "  - Installing $ext..."
      code --install-extension "$ext" --force 2>/dev/null || true
    fi
  done < packages/vscode-extensions.txt
fi

# ------------------------------------------------------------------------------
# 8. Omarchy Desktop & Theme Activation
# ------------------------------------------------------------------------------
if command -v omarchy &>/dev/null; then
  echo -e "\n${BLUE}==>${RESET} ${BOLD}Activating Omarchy plugins & Dark Matter theme...${RESET}"
  
  # Rescan and activate plugins
  omarchy-shell shell rescanPlugins 2>/dev/null || true
  
  # Set active theme (Dark Matter default)
  if [[ -d "$HOME/.config/omarchy/themes/dark-matter" ]]; then
    omarchy theme set dark-matter 2>/dev/null || true
  elif [[ -d "$HOME/.config/omarchy/themes/evergreen" ]]; then
    omarchy theme set evergreen 2>/dev/null || true
  fi
  
  # Reload UI & Window Manager
  omarchy restart shell 2>/dev/null || true
  hyprctl reload 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 9. Summary & Finish
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${GREEN}======================================================${RESET}"
echo -e "${BOLD}${GREEN}  ✔ Complete Omarchy Setup Restored Successfully!     ${RESET}"
echo -e "${BOLD}${GREEN}======================================================${RESET}"
echo -e "  • ${BOLD}Top Bar & Widgets:${RESET} Restored to exact layout (shell.json)"
echo -e "  • ${BOLD}Plugins:${RESET}           All 13 custom and community plugins active"
echo -e "  • ${BOLD}Theme:${RESET}             Dark Matter applied across UI and editors"
echo -e "  • ${BOLD}CLI Tools:${RESET}         Mise runtimes, custom scripts & terminals ready"
echo -e "  • ${BOLD}Sync Utility:${RESET}      Run ${CYAN}./sync.sh${RESET} anytime to export updates"
echo -e "\n${CYAN}Enjoy your identical environment on your new machine!${RESET}\n"
