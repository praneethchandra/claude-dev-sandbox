#!/usr/bin/env python3
"""
metrics.py — Claude Code usage dashboard
Usage:
  metrics.py              # last 7 days
  metrics.py --detail     # per-tool breakdown
  metrics.py --today      # today only
  metrics.py --all        # full history
"""
import sys, json
from pathlib import Path
from datetime import datetime, timedelta
from collections import defaultdict

METRICS = Path.home() / ".claude" / "metrics.jsonl"
BOLD="\033[1m"; DIM="\033[2m"; CYAN="\033[0;36m"
GREEN="\033[0;32m"; AMBER="\033[0;33m"; RESET="\033[0m"

def load(since=None):
    if not METRICS.exists(): return []
    rows = []
    for line in METRICS.read_text().splitlines():
        line = line.strip()
        if not line: continue
        try:
            r = json.loads(line)
            if since and datetime.fromisoformat(r.get("ts","1970-01-01")) < since: continue
            rows.append(r)
        except: pass
    return rows

def bar(v, mx, w=18):
    f = int(w * v / mx) if mx else 0
    return "█" * f + "░" * (w - f)

def summary(rows):
    tools = [r for r in rows if not r.get("tool","").startswith("_")]
    sessions = [r for r in rows if r.get("tool") == "_session_end"]
    total_in  = sum(r.get("in_tok",  0) for r in tools)
    total_out = sum(r.get("out_tok", 0) for r in tools)
    by_tool = defaultdict(lambda: {"calls":0,"in":0,"out":0,"elapsed":0.0})
    for r in tools:
        t = r.get("tool","?")
        by_tool[t]["calls"]   += 1
        by_tool[t]["in"]      += r.get("in_tok",  0)
        by_tool[t]["out"]     += r.get("out_tok", 0)
        by_tool[t]["elapsed"] += r.get("elapsed", 0.0)
    max_calls = max((v["calls"] for v in by_tool.values()), default=1)
    print(f"\n{BOLD}Claude Code Usage Dashboard{RESET}")
    print("─" * 52)
    print(f"  {DIM}Tool calls:  {RESET}{BOLD}{len(tools):,}{RESET}")
    print(f"  {DIM}Est. input:  {RESET}{BOLD}{total_in:,}{RESET} tokens")
    print(f"  {DIM}Est. output: {RESET}{BOLD}{total_out:,}{RESET} tokens")
    print(f"  {DIM}Sessions:    {RESET}{BOLD}{len(sessions)}{RESET}")
    if by_tool:
        print()
        for tool, d in sorted(by_tool.items(), key=lambda x: -x[1]["calls"]):
            b = bar(d["calls"], max_calls)
            e = d["elapsed"]
            es = f"{e:.0f}s" if e < 60 else f"{e/60:.1f}m"
            print(f"  {CYAN}{tool:<10}{RESET} {b}  {d['calls']:>4} calls  "
                  f"{d['in']+d['out']:>6,} tok  {es:>5}")
    print(f"\n  {DIM}--detail  --today  --all{RESET}\n")

def detail(rows):
    tools = [r for r in rows if not r.get("tool","").startswith("_")]
    if not tools: print("  No tool calls recorded yet."); return
    print(f"\n{BOLD}Per-tool log{RESET}  {DIM}(most recent 40){RESET}")
    print("─" * 68)
    print(f"  {'Time':<10}  {'Tool':<8}  {'In':>6}  {'Out':>6}  {'ms':>5}  Summary")
    print("─" * 68)
    for r in tools[-40:]:
        ts  = r.get("ts","")[-8:]
        e   = r.get("elapsed", 0.0)
        smry = r.get("summary","")[:34]
        print(f"  {DIM}{ts}{RESET}  {CYAN}{r.get('tool','?'):<8}{RESET}  "
              f"{r.get('in_tok',0):>6}  {r.get('out_tok',0):>6}  "
              f"{e*1000:>5.0f}  {smry}")
    print()

def main():
    args   = sys.argv[1:]
    since  = None
    if "--today" in args:  since = datetime.now().replace(hour=0,minute=0,second=0)
    elif "--all" not in args: since = datetime.now() - timedelta(days=7)
    rows = load(since)
    if not rows:
        print(f"\n  {AMBER}No metrics yet.{RESET} Start a Claude Code session.\n"); return
    detail(rows) if "--detail" in args else summary(rows)

if __name__ == "__main__": main()
