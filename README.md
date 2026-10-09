# 🌌 Omarchy Setup & System Dotfiles

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-Omarchy-1793D1?logo=arch-linux&logoColor=white)](https://omarchy.org)
[![Window Manager](https://img.shields.io/badge/WM-Hyprland-00FFFF?logo=wayland&logoColor=black)](https://hyprland.org)
[![Theme](https://img.shields.io/badge/Theme-Dark_Matter-000000?logo=visualstudiocode&logoColor=white)](https://github.com/visual-zimbabwe/omarchy-dark-matter-theme)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A complete, fully reproducible, single-command setup system for my **Omarchy Linux** laptop. This repository tracks and restores all desktop configurations, custom status bar widgets, themes, terminal emulators, developer toolchains, custom CLI utilities, and package manifests.

---

## ⚡ Quick Start: Install in One Command

On your new laptop or clean installation, open a terminal and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/visual-zimbabwe/omarchy-dotfiles/main/install.sh)
```

> **What happens when you run this?**
> 1. Detects your operating system and environment.
> 2. If Omarchy is missing on Arch Linux, installs the base Omarchy desktop.
> 3. Installs all 170+ native Arch packages and AUR packages (`yay`).
> 4. Restores toolchains via **Mise** (Node.js, Python, Go, GitHub CLI, AI CLIs).
> 5. Restores home dotfiles (`.bashrc`, `.zshrc`, `.profile`) and custom binaries (`watchtv`, `watchsports`, `stream-torrent`).
> 6. Deploys all `~/.config/` application configurations (Hyprland, Alacritty, Ghostty, Kitty, Neovim, VS Code, MPV, Newsboat).
> 7. Installs and registers all **13 top-bar plugins** and activates the **Dark Matter** theme.

---

## 📦 What Is Included

### 1. 🖥️ Desktop & Window Manager (`config/hypr/` & `config/omarchy/`)
* **Hyprland Configuration**: Modular Wayland compositor rules (`looknfeel.lua`, `bindings.lua`, `input.lua`, `monitors.lua`, `autostart.lua`).
* **Dynamic Workspace Layouts**: Automated layout engine (`omarchy-workspace-layout.lua` & `workspace-layout.json`) with Golden ratio and 2x4 grid splits.
* **Status Bar Layout (`shell.json`)**: Custom top bar with center clock, weather, media player, and pinned tray.

### 2. 🧩 13 Custom & Curated Status Bar Plugins (`config/omarchy/plugins/`)
* 🔒 **`juwimana.lock`**: Custom biometric and lock screen integration.
* 📈 **`juwimana.strat-journal`**: Trading strategy journal and logger.
* 🏠 **`juwimana.surrey-rentals`**: Real-time rental tracker widget.
* 🎴 **`yamz8.omanki`**: Interactive Anki flashcard reviewer on the status bar.
* 🎬 **`alexzeitler.ytdlp`**: Instant YouTube and media downloader widget.
* 📊 **`mohamedmansour.finance`**: Real-time stock and crypto ticker tracking.
* 🪟 **`bjarneo.workspace-layout`**: Workspace layout switcher and monitor mapper.
* 🗺️ **`io.github.ejuro.omamap`**: Interactive desktop map companion.
* ☕ **`io.github.ejuro.blow-off-some-steam`**: Break and relaxation widget.
* 🔔 **`jankeesvw.notification-center`**: Wayland notification manager and log.
* 📻 **`akshar.radio-atlas`**: World internet radio station streamer.
* ⌨️ **`fkcodes.key-promoter`**: Keyboard shortcut prompter and trainer.
* 🐍 **`sebasgl23.snake`**: Classic Snake mini-game in your top bar.

### 3. 🎨 Custom Themes (`config/omarchy/themes/`)
* **`Dark Matter` (Active)**: Minimalist blank-canvas theme with `#000000` base, subtle `#0A0906` secondary tones, and glowing accents.
* **20+ Additional Themes**: `evergreen`, `oligarchy`, `batou`, `coffee`, `firesky`, `greek-noir`, `kanso`, `machineviolence`, `pina`, `pulsar`, `quattro`, `ryu`, `softwire-*`, `solitude`, `spacex-terrafab`, `starship-to-orbit`, `sunset`, `third-impact`, `vernier`, `wood`.

### 4. 🚀 Custom CLI Utilities (`bin/` $\to$ `~/.local/bin/`)
* 🎬 **`watchtv`**: Keyboard-driven CLI movie and TV show streaming engine with automatic episode pack indexing and MPV playback.
* ⚽ **`watchsports`**: Live sports fixture finder and channel streamer (EPL, UCL, F1, NBA, La Liga).
* 🧲 **`stream-torrent`**: WebTorrent/Peerflix streaming daemon with tier-1 tracker injection and zero-orphan cache cleanup.

### 5. 🛠️ Development Tools, Editors & Runtimes
* **Mise (`config/mise/config.toml`)**: Automated runtime version manager for Node.js (`26.7.0`), Python, Go, and developer CLIs (`gh`, `gemini`, `codex`).
* **Neovim (`config/nvim/`)**: Full LazyVim setup with Omarchy theme synchronization.
* **VS Code (`config/Code/` & `packages/vscode-extensions.txt`)**: Theme settings and extension manifests.
* **Terminals**: Complete setups for `Alacritty`, `Ghostty`, `Kitty`, and `Foot`.
* **Multiplexers & TUIs**: `Tmux`, `Starship` prompt, `Btop`, `Lazygit`, `Newsboat` RSS reader, `Cliamp` audio visualizer, `MPV` auto-subtitle engine.

---

## 📂 Repository Structure

```
omarchy-dotfiles/
├── install.sh                  # Master 1-command installer script
├── install.ps1                 # Windows PowerShell installer
├── sync.sh                     # System state export & sync tool
├── bin/                        # Standalone custom scripts (~/.local/bin)
│   ├── stream-torrent
│   ├── watchsports
│   ├── watchtv
│   ├── env
│   └── env.fish
├── home/                       # User home dotfiles (~/.*)
│   ├── .bashrc
│   ├── .zshrc
│   ├── .profile
│   ├── .bash_profile
│   └── .XCompose
├── packages/                   # Package & extension manifests
│   ├── pkglist-native.txt      # 170+ Arch/Omarchy repository packages
│   ├── pkglist-aur.txt         # AUR packages
│   ├── vscode-extensions.txt   # VS Code extensions list
│   └── npm-globals.txt         # Global NPM CLI tools
└── config/                     # Application configurations (~/.config)
    ├── alacritty/              # Alacritty terminal config
    ├── btop/                   # Btop monitor & themes
    ├── cliamp/                 # Cliamp audio visualizer
    ├── Code/                   # VS Code User settings
    ├── fcitx5/                 # Input method configuration
    ├── foot/                   # Foot terminal config
    ├── ghostty/                # Ghostty terminal config
    ├── git/                    # Git config (with portable gh auth)
    ├── hypr/                   # Hyprland window manager rules & scripts
    ├── kitty/                  # Kitty terminal config
    ├── lazygit/                # Lazygit configuration
    ├── mise/                   # Mise runtimes and tools configuration
    ├── mpv/                    # MPV video player & autosub scripts
    ├── newsboat/               # Newsboat RSS feeds and scripts
    ├── nvim/                   # Neovim / LazyVim IDE configuration
    ├── omarchy/                # Omarchy shell, 13 plugins, 20+ themes
    ├── starship.toml           # Starship cross-shell prompt
    ├── tmux/                   # Tmux multiplexer config
    ├── mimeapps.list           # Default MIME file associations
    ├── chrome-flags.conf       # Wayland acceleration flags for Chrome
    └── chromium-flags.conf     # Wayland acceleration flags for Chromium
```

---

## 🛠️ Step-by-Step Installation Guides

### Option A: Fresh Machine (One Command)
If you have a fresh laptop with Arch Linux or Omarchy installed:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/visual-zimbabwe/omarchy-dotfiles/main/install.sh)
```

### Option B: Clone and Inspect Manually
If you want to review all files before installing:

```bash
# 1. Clone to the standard dotfiles location
git clone https://github.com/visual-zimbabwe/omarchy-dotfiles.git ~/.local/share/omarchy-dotfiles
cd ~/.local/share/omarchy-dotfiles

# 2. Inspect the installer and configs
less install.sh

# 3. Execute installation
./install.sh
```

### Option C: macOS / Terminal-Only Setup
Restores cross-platform tools (`alacritty`, `ghostty`, `kitty`, `nvim`, `btop`, `lazygit`, `starship.toml`):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/visual-zimbabwe/omarchy-dotfiles/main/install.sh)
```
> To experience the complete Omarchy Wayland desktop on Apple Silicon Mac, install [Try Omarchy](https://github.com/themartiano/try-omarchy).

### Option D: Windows (PowerShell)
Restores cross-platform configs to `%USERPROFILE%\.config`:

```powershell
irm https://raw.githubusercontent.com/visual-zimbabwe/omarchy-dotfiles/main/install.ps1 | iex
```
> For the full desktop on Windows, install WSL2 (`wsl --install`) and run the Linux installer inside your WSL terminal.

---

## 🔄 Keeping Dotfiles in Sync

Whenever you install new packages, tweak your Hyprland bindings, add plugins, or modify your themes, update your dotfiles repository in seconds:

```bash
# 1. Navigate to your dotfiles directory
cd ~/Projects/omarchy-dotfiles

# 2. Run the synchronization script
./sync.sh

# 3. Commit and push changes
git add .
git commit -m "Update system configurations, plugins & packages"
git push
```

The `./sync.sh` script automatically:
* Dumps latest native and AUR package manifests.
* Exports VS Code extension lists and global NPM utilities.
* Sanitizes git credentials to remain machine-agnostic.
* Strips temporary cache files (`*.bak*`, `*.log`, `__pycache__`).
* Copies all custom bin scripts, shell dotfiles, and `~/.config` directories.

---

## 🔍 Post-Installation Verification

After installation finishes:
1. **Check Top Bar**: Verify widgets (Anki, Finance, Rentals, Radio Atlas, System Stats) appear in the top bar.
2. **Verify Active Theme**: Run `omarchy theme current` (should output `Dark Matter`).
3. **Verify Runtimes**: Run `mise list` to ensure Node, Python, and Go are active.
4. **Test Keybindings**: Press `Super + Return` to open terminal or `Super + Space` to summon the Omarchy menu.

---

## 📄 License

MIT © [Jean Marie Uwimana](https://github.com/visual-zimbabwe)
