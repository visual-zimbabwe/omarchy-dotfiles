#!/usr/bin/env bash
set -euo pipefail

# Visual styling
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BOLD}${BLUE}=========================================${RESET}"
echo -e "${BOLD}${BLUE}   Omarchy Setup & Dotfiles Installer    ${RESET}"
echo -e "${BOLD}${BLUE}=========================================${RESET}"

OS="$(uname -s)"
REPO_URL="https://github.com/visual-zimbabwe/omarchy-dotfiles.git"
TARGET_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-dotfiles"

# 1. Determine execution context (cloned repo vs curl pipe)
if [[ -d "$(dirname "$0")/config" ]]; then
  SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
else
  if [[ -d "$TARGET_DIR/.git" ]]; then
    echo -e "${YELLOW}--> Updating existing repository at $TARGET_DIR...${RESET}"
    git -C "$TARGET_DIR" pull --ff-only || true
  else
    echo -e "${GREEN}--> Cloning setup repository to $TARGET_DIR...${RESET}"
    mkdir -p "$(dirname "$TARGET_DIR")"
    git clone "$REPO_URL" "$TARGET_DIR"
  fi
  SRC_DIR="$TARGET_DIR"
fi

cd "$SRC_DIR"

# 2. macOS Handling
if [[ "$OS" == "Darwin" ]]; then
  echo -e "${CYAN}--> Detected macOS environment.${RESET}"
  echo -e "--> Restoring cross-platform dotfiles (Alacritty, Ghostty, Kitty, Starship, Neovim, Lazygit)..."
  mkdir -p "$HOME/.config"
  for app in alacritty ghostty kitty nvim btop lazygit; do
    if [[ -d "config/$app" ]]; then
      mkdir -p "$HOME/.config/$app"
      cp -rf "config/$app"/* "$HOME/.config/$app/"
    fi
  done
  [[ -f "config/starship.toml" ]] && cp -f "config/starship.toml" "$HOME/.config/"
  
  echo -e "\n${BOLD}${GREEN}✔ macOS dotfiles successfully restored!${RESET}"
  echo -e "${YELLOW}Note: Omarchy is a Linux Hyprland desktop environment.${RESET}"
  echo -e "To run the full Omarchy desktop on your Mac, download Try Omarchy from:"
  echo -e "${CYAN}https://github.com/themartiano/try-omarchy${RESET}"
  exit 0
fi

# 3. Linux Handling
echo -e "${GREEN}--> Detected Linux environment.${RESET}"

# Check if Omarchy is installed
if ! command -v omarchy &>/dev/null; then
  echo -e "${YELLOW}--> Note: Omarchy is not yet installed on this system.${RESET}"
  if command -v pacman &>/dev/null; then
    read -rp "Would you like to install the base Omarchy desktop now? [y/N] " choice < /dev/tty || choice="n"
    if [[ "$choice" =~ ^[Yy]$ ]]; then
      echo -e "${GREEN}--> Installing Omarchy...${RESET}"
      bash <(curl -fsSL https://omarchy.org/install)
    fi
  else
    echo -e "${YELLOW}Non-Arch Linux detected. Restoring portable terminal & CLI configurations only.${RESET}"
  fi
fi

# Package installation if on Arch Linux
if command -v pacman &>/dev/null; then
  echo -e "${GREEN}--> Checking and installing native packages...${RESET}"
  if [[ -f "packages/pkglist-native.txt" ]]; then
    sudo pacman -S --needed --noconfirm - < <(comm -12 <(sort packages/pkglist-native.txt) <(pacman -Ssq | sort)) || true
  fi

  if [[ -f "packages/pkglist-aur.txt" ]] && command -v yay &>/dev/null; then
    echo -e "${GREEN}--> Checking and installing AUR packages...${RESET}"
    yay -S --needed --noconfirm - < packages/pkglist-aur.txt || true
  fi
fi

# Restore configurations
echo -e "${GREEN}--> Restoring configurations to ~/.config/...${RESET}"
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

# Reload Omarchy shell, apply theme, and reload Hyprland
if command -v omarchy &>/dev/null; then
  echo -e "${GREEN}--> Applying theme, plugins, and restarting Omarchy shell...${RESET}"
  omarchy-shell shell rescanPlugins 2>/dev/null || true
  omarchy restart shell 2>/dev/null || true
  omarchy theme set evergreen 2>/dev/null || true
  hyprctl reload 2>/dev/null || true
fi

echo -e "\n${BOLD}${GREEN}✔ Full Omarchy environment restored successfully!${RESET}"
echo -e "Your custom bar widgets, plugins, themes, and keybindings are ready."
