#!/usr/bin/env python3
import json
import re
import shutil
import subprocess
import sys
from typing import List, Tuple

# Accept active workspace names like:
#   "1"            -> project 1
#   "1[main]"      -> project 1
#   "12[research]" -> project 12
ACTIVE_RE = re.compile(r"^(?P<proj>\d+)(?:\[(?P<sub>[^\]]+)\])?$")

# We only manage bracketed workspaces:
#   "1[main]", "1[1]", "1[research]"
BRACKET_RE = re.compile(r"^(?P<proj>\d+)\[(?P<sub>[^\]]+)\]$")


def run(cmd: List[str], input_text: str | None = None) -> str:
    p = subprocess.run(
        cmd,
        input=(input_text.encode("utf-8") if input_text is not None else None),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if p.returncode != 0:
        raise RuntimeError(
            f"Command failed: {' '.join(cmd)}\n{p.stderr.decode('utf-8', 'ignore')}"
        )
    return p.stdout.decode("utf-8", "ignore")


def hyprctl_json(args: List[str]) -> object:
    return json.loads(run(["hyprctl"] + args))


def current_project() -> str:
    active = hyprctl_json(["activeworkspace", "-j"])
    name = str(active.get("name", "")).strip()
    if not name:
        raise RuntimeError("Could not read active workspace name from hyprctl.")
    m = ACTIVE_RE.match(name)
    if not m:
        raise RuntimeError(f"Unexpected workspace name format: {name!r}")
    return m.group("proj")


def sort_key(name: str) -> Tuple[int, int, str]:
    """
    For a given project N:
      N[main] first
      then N[1], N[2]...
      then N[anything-else] alphabetically
    """
    m = BRACKET_RE.match(name)
    if not m:
        return (10**9, 10**9, name)

    proj = int(m.group("proj"))
    sub = m.group("sub")

    if sub == "main":
        return (proj, -1, "")
    if sub.isdigit():
        return (proj, int(sub), "")
    return (proj, 10**6, sub.lower())


def vicinae_pick(items: List[str], placeholder: str) -> str | None:
    if not shutil.which("vicinae"):
        raise RuntimeError("vicinae not found in PATH")

    menu_input = "\n".join(items) + "\n"
    sel = run(
        ["vicinae", "dmenu", "--placeholder", placeholder, "--no-quick-look"],
        input_text=menu_input,
    ).strip()
    return sel or None


def main() -> int:
    proj = current_project()
    main_ws = f"{proj}[main]"

    # Existing project bracketed workspaces only (ignore bare "1", "2", etc.)
    wss = hyprctl_json(["workspaces", "-j"])
    existing: List[str] = []
    for w in wss:
        n = str(w.get("name", "")).strip()
        if n.startswith(f"{proj}[") and n.endswith("]"):
            existing.append(n)

    # Stable defaults
    defaults = [main_ws] + [f"{proj}[{i}]" for i in range(1, 6)]

    choices = sorted(set(existing) | set(defaults), key=sort_key)

    choice = vicinae_pick(choices, placeholder=f"Project {proj} workspace")
    if not choice:
        return 0

    run(["hyprctl", "dispatch", "workspace", f"name:{choice}"])
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f"[workspace-menu] {e}", file=sys.stderr)
        raise SystemExit(1)
