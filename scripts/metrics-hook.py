#!/usr/bin/env python3
"""
metrics-hook.py
Called by Claude Code hooks to log per-tool usage metrics.

Usage (from settings.json):
  pre  <tool_name> <tool_input_json>
  post <tool_name> <tool_input_json> <tool_response_json>
  stop <session_id> <project_dir>
"""

import sys
import json
import os
import time
from datetime import datetime
from pathlib import Path

METRICS_FILE = Path.home() / ".claude" / "metrics.jsonl"
TIMING_FILE  = Path.home() / ".claude" / ".tool_start_times.json"
METRICS_FILE.parent.mkdir(exist_ok=True)

def tok(text: str) -> int:
    """Rough token estimate: chars / 4."""
    return max(1, len(str(text)) // 4)

def load_timing() -> dict:
    try:
        return json.loads(TIMING_FILE.read_text()) if TIMING_FILE.exists() else {}
    except Exception:
        return {}

def save_timing(data: dict):
    try:
        TIMING_FILE.write_text(json.dumps(data))
    except Exception:
        pass

def append_metric(record: dict):
    try:
        with METRICS_FILE.open("a") as f:
            f.write(json.dumps(record) + "\n")
    except Exception:
        pass

def main():
    if len(sys.argv) < 2:
        return

    mode = sys.argv[1]
    now  = datetime.now().isoformat(timespec="seconds")
    ts   = time.time()

    if mode == "pre" and len(sys.argv) >= 4:
        tool_name  = sys.argv[2]
        tool_input = sys.argv[3]
        timing = load_timing()
        timing[tool_name + "_last"] = ts
        save_timing(timing)

    elif mode == "post" and len(sys.argv) >= 5:
        tool_name     = sys.argv[2]
        tool_input    = sys.argv[3]
        tool_response = sys.argv[4]

        timing   = load_timing()
        start_ts = timing.get(tool_name + "_last", ts)
        elapsed  = round(ts - start_ts, 2)

        input_tokens  = tok(tool_input)
        output_tokens = tok(tool_response)

        # Extract human-readable summary
        summary = ""
        try:
            inp = json.loads(tool_input)
            if tool_name == "Bash":
                cmd = str(inp.get("command", inp.get("input", "")))
                summary = cmd[:80] + ("…" if len(cmd) > 80 else "")
            elif tool_name in ("Write", "Edit"):
                summary = str(inp.get("path", ""))
            elif tool_name == "Read":
                summary = str(inp.get("file_path", inp.get("path", "")))
        except Exception:
            summary = str(tool_input)[:80]

        record = {
            "ts":      now,
            "tool":    tool_name,
            "summary": summary,
            "in_tok":  input_tokens,
            "out_tok": output_tokens,
            "elapsed": elapsed,
            "pwd":     os.environ.get("PWD", ""),
        }
        append_metric(record)

    elif mode == "stop" and len(sys.argv) >= 4:
        session_id  = sys.argv[2]
        project_dir = sys.argv[3]
        record = {
            "ts":         now,
            "tool":       "_session_end",
            "summary":    project_dir,
            "session_id": session_id,
            "pwd":        project_dir,
        }
        append_metric(record)

if __name__ == "__main__":
    main()
