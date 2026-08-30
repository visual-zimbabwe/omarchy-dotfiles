# Omarchy Setup & Cross-Platform Dotfiles

Complete, reproducible backup and installation system for my **Omarchy Linux** desktop, custom shell plugins, custom themes, Hyprland rules, and cross-platform terminal configurations.

---

## ⚡ Quick Start: One-Command Restores

Run the appropriate command for your platform in any terminal:

### 🐧 Omarchy / Arch Linux (Full Desktop Setup)
Restores the complete desktop environment, status bar, custom plugins, themes, Hyprland bindings, and package manifests:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/visual-zimbabwe/omarchy-dotfiles/main/install.sh)
```

### 🍎 macOS (Terminal / Ghostty / iTerm)
Restores cross-platform configurations (`alacritty`, `ghostty`, `kitty`, `nvim`, `btop`, `lazygit`, `starship.toml`):
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/visual-zimbabwe/omarchy-dotfiles/main/install.sh)
```
> **Want the full Omarchy desktop on Mac?** Download and run [Try Omarchy](https://github.com/themartiano/try-omarchy) (hardware-accelerated native macOS app for Apple Silicon).

### 🪟 Windows (PowerShell)
Restores cross-platform CLI & terminal configs to `%USERPROFILE%\.config`:
```powershell
irm https://raw.githubusercontent.com/visual-zimbabwe/omarchy-dotfiles/main/install.ps1 | iex
```
> **Want the full Omarchy desktop on Windows?** Run it inside WSL2 (Arch/Ubuntu) using the Linux command above.

---

## ℹ️ Do I Need Omarchy Pre-Installed?

* **If Omarchy IS already installed**: The script directly restores your custom bar layout (`shell.json`), custom themes, custom plugins, and Hyprland rules, then triggers `omarchy refresh shell`.
* **If Omarchy is NOT installed**:
  * **On Arch Linux**: The script detects missing `omarchy` and prompts to automatically install the base Omarchy desktop first via `omarchy.org/install`.
  * **On macOS / Windows**: The script restores portable terminal/CLI configs and directs you to virtualization options (`Try Omarchy` or `WSL2`) to run the Omarchy desktop.

---

## 📦 What Is Included

### 1. Omarchy Shell & UI (`config/omarchy/`)
* **`shell.json` & `shell.toml`**: Custom top bar layout with pinned tray items, weather, and clock formatting.
* **Custom User Plugins (`config/omarchy/plugins/`)**:
  * `juwimana.omarchy-clock`: Custom full-featured clock with World Clock, Stopwatch, Timers, and Alarms.
  * `akshar.radio-atlas`: Internet radio streamer.
  * `jankeesvw.notification-center`: Notification manager.
  * `jankeesvw.workspace-name`: Dynamic workspace naming widget.
  * `sebasgl23.snake`: Status bar snake game.
  * `slcode777.omagotchi`: Status bar virtual pet widget.
* **Custom Themes (`config/omarchy/themes/`)**:
  * `evergreen`: Custom forest green theme.
  * `oligarchy`: Custom dark theme.
* **Hooks, Extensions & Backgrounds**: System event automations and menu extensions (`omarchy-menu.jsonc`).

### 2. Desktop & Window Manager (`config/hypr/`)
* Hyprland Lua configurations: `bindings.lua`, `looknfeel.lua`, `input.lua`, `monitors.lua`, `autostart.lua`, `hyprsunset.conf`.

### 3. Terminals & Development Tools (`config/`)
* `alacritty/` & `foot/` & `ghostty/` & `kitty/`: Terminal configurations.
* `nvim/`: Neovim editor configuration.
* `starship.toml`: Custom shell prompt.
* `btop/` & `lazygit/`: TUI utilities.

### 4. Package Manifests (`packages/`)
* `pkglist-native.txt`: Explicitly installed native Arch Linux packages.
* `pkglist-aur.txt`: Explicitly installed AUR packages.

---

## 🛠 Manual Installation

If you prefer to clone and inspect before installing:

```bash
# Clone the repository
git clone https://github.com/visual-zimbabwe/omarchy-dotfiles.git ~/.local/share/omarchy-dotfiles
cd ~/.local/share/omarchy-dotfiles

# Run the installer
./install.sh
```

---

## 📄 License
MIT
