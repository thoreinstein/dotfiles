#!/usr/bin/env python3
"""Collect one week of raw material for a status update.

Prints markdown with three sections: pi sessions, engram observations, and vault
notes, all limited to [start, end] in local time. Read-only: it never writes to
pi, engram, or the vault.

Usage: week-sources.py [--start YYYY-MM-DD] [--end YYYY-MM-DD]
Default range is Monday of the current week through today.
"""
import argparse
import json
import os
import re
import subprocess
import tempfile
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

HOME = Path.home()
SESSIONS = HOME / ".pi/agent/sessions"
VAULT = HOME / "Documents/second_brain"
TICKET = re.compile(r"\b[A-Z][A-Z0-9]+-\d+\b")


def local_date(ts, utc=True):
    """ISO-ish timestamp -> local date. pi writes ISO with Z; engram writes UTC 'YYYY-MM-DD HH:MM:SS'."""
    ts = ts.replace("Z", "+00:00").split(".")[0] if "T" in ts else ts.split(".")[0]
    dt = datetime.fromisoformat(ts)
    if dt.tzinfo is None and utc:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone().date()


def clip(s, n):
    s = " ".join(s.split())
    return s if len(s) <= n else s[: n - 1] + "…"


def text_of(message):
    content = message.get("content")
    if isinstance(content, str):
        return content
    return "\n".join(c.get("text", "") for c in content or [] if c.get("type") == "text")


def pi_sessions(start, end):
    rows = []
    for f in SESSIONS.glob("*/*.jsonl"):
        # Cheap pre-filter: a session last written before the range can't be in it.
        if date.fromtimestamp(f.stat().st_mtime) < start:
            continue
        header, users, last_reply = None, [], ""
        with f.open() as fh:
            for line in fh:
                try:
                    d = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if d.get("type") == "session":
                    header = d
                elif d.get("type") == "message":
                    m = d.get("message") or {}
                    if m.get("role") == "user":
                        users.append(text_of(m))
                    elif m.get("role") == "assistant":
                        t = text_of(m).strip()
                        if t:
                            last_reply = t
        if not header or not users:
            continue
        day = local_date(header["timestamp"])
        if not start <= day <= end:
            continue
        cwd = header.get("cwd", "")
        rows.append((day, cwd, users, last_reply))
    rows.sort(key=lambda r: (r[0], r[1]))

    out = ["## pi sessions", ""]
    if not rows:
        out.append("(none)")
    for day, cwd, users, last_reply in rows:
        tickets = sorted(set(TICKET.findall(cwd)))
        out.append(f"### {day:%a %m-%d} · {cwd.replace(str(HOME), '~')}" + (f" · {', '.join(tickets)}" if tickets else ""))
        out.append(f"- turns: {len(users)}")
        for u in users[:2]:
            out.append(f"- asked: {clip(u, 300)}")
        if last_reply:
            out.append(f"- last reply: {clip(last_reply, 400)}")
        out.append("")
    return out


def engram_observations(start, end):
    out = ["## engram observations", ""]
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "export.json")
        try:
            subprocess.run(["engram", "export", "--all", path], check=True, capture_output=True, timeout=60)
            data = json.loads(Path(path).read_text())
        except (OSError, subprocess.SubprocessError, json.JSONDecodeError) as e:
            return out + [f"(engram export failed: {e}; fall back to mem_search)", ""]
    obs = [o for o in data.get("observations", []) if start <= local_date(o["created_at"]) <= end]
    obs.sort(key=lambda o: (o.get("project", ""), o["created_at"]))
    if not obs:
        return out + ["(none)", ""]
    project = None
    for o in obs:
        if o.get("project") != project:
            project = o.get("project")
            out += ["", f"### {project}"]
        day = local_date(o["created_at"])
        out.append(f"- {day:%a} [{o.get('type')}] {o.get('title')} — {clip(o.get('content', ''), 500)}")
    return out + [""]


def vault_notes(start, end):
    out = ["## vault notes", ""]
    daily = []
    d = start
    while d <= end:
        p = VAULT / f"Daily/{d:%Y/%m/%Y-%m-%d}.md"
        if p.exists():
            daily.append(p)
        d += timedelta(days=1)
    out.append("Daily notes (summaries of each day's engram activity, grouped by project):")
    out += [f"- {p}" for p in daily] or ["- (none)"]

    touched = []
    for p in (VAULT / "working").rglob("*.md"):
        day = date.fromtimestamp(p.stat().st_mtime)
        if start <= day <= end:
            touched.append((day, p))
    touched.sort()
    out += ["", "Project notes in working/ modified this week:"]
    out += [f"- {day:%a} {p}" for day, p in touched] or ["- (none)"]
    return out + [""]


def main():
    today = date.today()
    ap = argparse.ArgumentParser()
    ap.add_argument("--start", type=date.fromisoformat, default=today - timedelta(days=today.weekday()))
    ap.add_argument("--end", type=date.fromisoformat, default=today)
    a = ap.parse_args()
    lines = [f"# Week {a.start} to {a.end}", ""]
    lines += pi_sessions(a.start, a.end)
    lines += engram_observations(a.start, a.end)
    lines += vault_notes(a.start, a.end)
    print("\n".join(lines))


if __name__ == "__main__":
    main()
