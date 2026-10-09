#!/usr/bin/env bash
# Trade Storage Manager for Strat Journal
set -e

DIR="${HOME}/.local/state/omarchy/strat-journal"
mkdir -p "${DIR}"
DB_FILE="${DIR}/trades.json"

if [ ! -f "${DB_FILE}" ]; then
    echo "[]" > "${DB_FILE}"
fi

ACTION="${1:-list}"

python3 -c '
import sys, os, json

db_file = "'"${DB_FILE}"'"
action = "'"${ACTION}"'"

def load_trades():
    if not os.path.exists(db_file):
        return []
    try:
        with open(db_file, "r") as f:
            return json.load(f)
    except Exception:
        return []

def save_trades(trades):
    with open(db_file, "w") as f:
        json.dump(trades, f, indent=2)

if action == "list":
    trades = load_trades()
    print(json.dumps(trades))

elif action == "add":
    raw_payload = sys.stdin.read().strip()
    if raw_payload:
        new_trade = json.loads(raw_payload)
        trades = load_trades()
        # Prepend to front
        trades.insert(0, new_trade)
        save_trades(trades)
        print(json.dumps(new_trade))

elif action == "close":
    raw_payload = sys.stdin.read().strip()
    if raw_payload:
        close_data = json.loads(raw_payload)
        trade_id = close_data.get("id")
        trades = load_trades()
        for t in trades:
            if t.get("id") == trade_id:
                t["status"] = "closed"
                t["exit_price"] = close_data.get("exit_price", t.get("trigger_price"))
                t["exit_time"] = close_data.get("exit_time", "")
                t["exit_screenshot"] = close_data.get("exit_screenshot", "")
                t["realized_r"] = close_data.get("realized_r", 0.0)
                t["notes"] = close_data.get("notes", t.get("notes", ""))
                t["grade"] = close_data.get("grade", t.get("grade", "A"))
                t["mistake"] = close_data.get("mistake", "")
                break
        save_trades(trades)
        print(json.dumps({"status": "ok", "id": trade_id}))

elif action == "delete":
    trade_id = sys.argv[2] if len(sys.argv) > 2 else ""
    trades = load_trades()
    trades = [t for t in trades if t.get("id") != trade_id]
    save_trades(trades)
    print(json.dumps({"status": "ok"}))

elif action == "clear":
    save_trades([])
    print(json.dumps({"status": "ok"}))
' "$@"
