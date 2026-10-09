# Strat Journal (Omarchy Bar Plugin)

Dedicated Omarchy status bar plugin for GOOGL Strat execution logging, live Full Time Frame Continuity (FTFC) monitoring, and statistical performance review.

## Features

### 1. Status Bar Widget
* Displays real-time GOOGL market price and higher timeframe continuity state.
* Highlights active position status, direction, and Strat pattern in real time.
* Left-click to open popup; middle-click to trigger immediate Wayland chart screenshot.

### 2. Session Logger (In-Trade Execution)
* Higher Time Frame Continuity (FTFC) matrix for Month, Week, Day, and 60-minute candles.
* Rapid Strat pattern selection: 60m 2-1-2 Bull/Bear, 15m 2-2 Reversal, Daily 3-1-2, 1-2-2 Continuation.
* Risk calculator for fixed $1R dollar risk sizing.
* Automatic Wayland chart screenshot attachment via Grim.
* Execution discipline grading (Grade A, B, C, F).

### 3. Review Station & Analytics
* Performance breakdown by individual Strat combo to isolate statistical edge.
* Core metrics: Realized R-multiples, Win Rate %, Profit Factor, Average Winner/Loser.
* Execution discipline audit comparing rule-adherent trades against rule-breaking trades.

### 4. Trade Replay & History
* Complete chronological log of entries and exits.
* One-click access to attached chart screenshots.

## Data Storage
* Database: `~/.local/state/omarchy/strat-journal/trades.json`
* Screenshots: `~/.local/state/omarchy/strat-journal/screenshots/`
