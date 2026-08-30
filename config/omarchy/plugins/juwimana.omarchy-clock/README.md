# Omarchy Clock

A sleek, minimalist, native clock plugin for [Omarchy](https://github.com/omarchy/omarchy) on Linux (Quickshell / Hyprland).

Designed with a clean modern aesthetic, **Omarchy Clock** provides four core utilities in a single, lightweight, native bar popup:

* 🌐 **World Clock**: Live multi-timezone tracking with bold typography, contextual time-offset badges (e.g. `Tomorrow • +9h ahead` for Harare, Zimbabwe), drag-and-drop reordering, and hover-revealed deletion.
* ⏰ **Alarm**: Multi-alarm management with toggle switches, next-alarm summary countdown, custom repeat days, and audio chime alerts (`pw-play`).
* ⏱ **Stopwatch**: High-precision millisecond digital readout (`00:00.00`) with fastest & slowest lap highlighting.
* ⏳ **Timer**: Circular countdown progress ring, duration presets (`+1m`, `+5m`, `+10m`, `+15m`, `+30m`, `+1h`), custom duration picker, and completion notifications.

---

## Features

- **Minimalist & Clean**: Distraction-free typography, monoline vector icons, text-only bottom navigation, and hover-only actions.
- **Drag & Drop Reordering**: Click, hold, and drag world clock cards vertically to arrange locations in your preferred order.
- **Accurate Timezone Calculations**: Built-in UTC offset calculations and DST awareness ensuring precise global times without relying on missing runtime features.
- **Persistent State**: Alarms, tracked locations, custom ordering, and timer settings automatically persist to `state.json`.
- **Top Bar Integration**: Native Omarchy bar widget displaying live timer countdowns and quick popup toggle.

---

## Installation

1. Clone or symlink this repository into your Omarchy plugins directory:
   ```bash
   mkdir -p ~/.config/omarchy/plugins
   ln -s /path/to/omarchy-clock ~/.config/omarchy/plugins/juwimana.omarchy-clock
   ```

2. Add the widget to your `~/.config/omarchy/shell.json` in your desired bar section (e.g., center):
   ```json
   {
     "id": "juwimana.omarchy-clock"
   }
   ```

3. Restart the Omarchy shell:
   ```bash
   omarchy restart shell
   ```

---

## Usage

- **Toggle Clock**: Click the clock icon on your Omarchy top bar, or run:
  ```bash
  omarchy shell juwimana.omarchy-clock toggle
  ```
- **Add Locations**: Click the **`+`** icon in the top header and search from 50+ global cities.
- **Rearrange Locations**: Click, hold, and drag any card vertically.
- **Delete Locations**: Hover over any card and click the monoline **`×`** icon.

---

## License

MIT © [visual-zimbabwe](https://github.com/visual-zimbabwe)
