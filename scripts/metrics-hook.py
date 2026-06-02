#!/usr/bin/env python3
"""
metrics-hook.py — logs per-tool Claude Code metrics to ~/.claude/metrics.jsonl
Called automatically by hooks in settings.json.

Usage:
  metrics-hook.py pre  <tool_name> <tool_input_json>
  metrics-hook.py post <tool_name> <tool_input_json> <tool_response_json>
  metrics-hook.py stop <session_id> <project_dir>
"""
import sys, json, os, time
from datetime import datetime
from pathlib import Path

METRICS = Path.home() / ".claude" / "metrics.jsonl"
TIMING  = Path.home() / ".claude" / ".tool_timings.json"
METRICS.parent.mkdir(exist_ok=True)

def tok(text): return max(1, len(str(text)) // 4)

def load_timing():
    try: return json.loads(TIMING.read_text()) if TIMING.exists() else {}
    except: return {}

def save_timing(data):
    try: TIMING.write_text(json.dumps(data))
    except: pass

def append(record):
    try:
        with METRICS.open("a") as f:
            f.write(json.dumps(record) + "\n")
    except: pass

def main():
    if len(sys.argv) < 2: return
    mode = sys.argv[1]
    now  = datetime.now().isoformat(timespec="seconds")
    ts   = time.time()

    if mode == "pre" and len(sys.argv) >= 4:
        t = load_timing()
        t[sys.argv[2] + "_last"] = ts
        save_timing(t)

    elif mode == "post" and len(sys.argv) >= 5:
        tool, inp, resp = sys.argv[2], sys.argv[3], sys.argv[4]
        t       = load_timing()
        elapsed = round(ts - t.get(tool + "_last", ts), 2)
        summary = ""
        try:
            d = json.loads(inp)
            if tool == "Bash":
                cmd = str(d.get("command", d.get("input", "")))
                summary = cmd[:80] + ("…" if len(cmd) > 80 else "")
            elif tool in ("Write", "Edit", "Read"):
                summary = str(d.get("path", d.get("file_path", "")))
        except: summary = str(inp)[:80]
        append({"ts": now, "tool": tool, "summary": summary,
                "in_tok": tok(inp), "out_tok": tok(resp),
                "elapsed": elapsed, "pwd": os.environ.get("PWD", "")})

    elif mode == "stop" and len(sys.argv) >= 4:
        append({"ts": now, "tool": "_session_end",
                "summary": sys.argv[3], "session_id": sys.argv[2],
                "pwd": sys.argv[3]})

if __name__ == "__main__":
    main()
