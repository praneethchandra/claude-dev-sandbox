#!/usr/bin/env python3
"""
metrics.py  —  Claude Code usage dashboard
Usage:
  python3 metrics.py            # summary (last 7 days)
  python3 metrics.py --detail   # per-tool breakdown
  python3 metrics.py --today    # today only
  python3 metrics.py --all      # full history
"""

import sys
import json
from pathlib import Path
from datetime import datetime, timedelta
from collections import defaultdict

METRICS_FILE = Path.home() / ".claude" / "metrics.jsonl"

BOLD  = "\033[1m"
DIM   = "\033[2m"
CYAN  = "\033[0;36m"
GREEN = "\033[0;32m"
AMBER = "\033[0;33m"
RESET = "\033[0m"

def load(since: datetime | None = None) -> list[dict]:
    if not METRICS_FILE.exists():
        return []
    rows = []
    for line in METRICS_FILE.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            r = json.loads(line)
            if since:
                row_dt = datetime.fromisoformat(r.get("ts","1970-01-01"))
                if row_dt < since:
                    continue
            rows.append(r)
        except Exception:
            pass
    return rows

def bar(value: int, max_val: int, width: int = 20) -> str:
    if max_val == 0:
        return " " * width
    filled = int(width * value / max_val)
    return "█" * filled + "░" * (width - filled)

def fmt_tokens(n: int) -> str:
    return f"{n:,}"

def show_summary(rows: list[dict]):
    tools = [r for r in rows if r.get("tool","").startswith("_") is False]
    sessions = [r for r in rows if r.get("tool") == "_session_end"]

    total_in  = sum(r.get("in_tok",  0) for r in tools)
    total_out = sum(r.get("out_tok", 0) for r in tools)
    total_calls = len(tools)

    # Per-tool breakdown
    by_tool: dict[str, dict] = defaultdict(lambda: {"calls":0,"in":0,"out":0,"elapsed":0.0})
    for r in tools:
        t = r.get("tool","?")
        by_tool[t]["calls"]   += 1
        by_tool[t]["in"]      += r.get("in_tok",  0)
        by_tool[t]["out"]     += r.get("out_tok", 0)
        by_tool[t]["elapsed"] += r.get("elapsed", 0.0)

    max_calls = max((v["calls"] for v in by_tool.values()), default=1)

    print()
    print(f"{BOLD}Claude Code · Usage Dashboard{RESET}")
    print("─" * 54)
    print(f"  {DIM}Tool calls:{RESET}    {BOLD}{total_calls:,}{RESET}")
    print(f"  {DIM}Est. input: {RESET}   {BOLD}{fmt_tokens(total_in)}{RESET} tokens")
    print(f"  {DIM}Est. output:{RESET}   {BOLD}{fmt_tokens(total_out)}{RESET} tokens")
    print(f"  {DIM}Sessions:   {RESET}   {BOLD}{len(sessions)}{RESET}")
    print()

    if by_tool:
        print(f"  {DIM}Tool breakdown:{RESET}")
        for tool, data in sorted(by_tool.items(), key=lambda x: -x[1]["calls"]):
            b = bar(data["calls"], max_calls, 16)
            elapsed = data["elapsed"]
            elapsed_str = f"{elapsed:.0f}s" if elapsed < 60 else f"{elapsed/60:.1f}m"
            print(f"  {CYAN}{tool:<10}{RESET} {b}  {data['calls']:>4} calls  "
                  f"{fmt_tokens(data['in']+data['out']):>7} tok  {elapsed_str:>5}")
    print()

def show_detail(rows: list[dict]):
    tools = [r for r in rows if not r.get("tool","").startswith("_")]
    if not tools:
        print("  No tool calls recorded yet.")
        return
    print()
    print(f"{BOLD}Per-tool log{RESET}  {DIM}(most recent 40){RESET}")
    print("─" * 70)
    print(f"  {'Time':<10}  {'Tool':<8}  {'In':>6}  {'Out':>6}  {'ms':>5}  Summary")
    print("─" * 70)
    for r in tools[-40:]:
        ts      = r.get("ts","")[-8:] if len(r.get("ts","")) >= 8 else r.get("ts","")
        tool    = r.get("tool","?")[:8]
        in_tok  = r.get("in_tok",  0)
        out_tok = r.get("out_tok", 0)
        elapsed = r.get("elapsed", 0.0)
        summary = r.get("summary","")[:35]
        print(f"  {DIM}{ts}{RESET}  {CYAN}{tool:<8}{RESET}  {in_tok:>6}  {out_tok:>6}  "
              f"{elapsed*1000:>5.0f}  {summary}")
    print()

def main():
    args    = sys.argv[1:]
    detail  = "--detail"  in args
    today   = "--today"   in args
    all_    = "--all"     in args

    since = None
    if today:
        since = datetime.now().replace(hour=0, minute=0, second=0)
    elif not all_:
        since = datetime.now() - timedelta(days=7)

    rows = load(since)
    if not rows:
        print(f"\n  {AMBER}No metrics recorded yet.{RESET}")
        print(f"  Start a Claude Code session — metrics are logged automatically.\n")
        return

    if detail:
        show_detail(rows)
    else:
        show_summary(rows)
        print(f"  {DIM}Run with --detail for per-tool log · --today · --all{RESET}\n")

if __name__ == "__main__":
    main()
