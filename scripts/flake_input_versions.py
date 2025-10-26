#!/usr/bin/env python3
"""
Report current versus upstream versions for flake inputs.

For each direct input declared by the flake this tool shows:
* The locked version (tag + Nix commit when available).
* The latest version upstream (tag + commit or branch head).
* A color-coded status (green when up to date, yellow when newer upstream).
* The source URL for quick navigation.

Usage:
    ./scripts/flake_input_versions.py [--flake PATH] [--no-color]
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, Optional, Tuple

try:
    from texttable import Texttable
except ImportError as exc:  # pragma: no cover - dependency check
    print(
        "error: python module 'texttable' is required. "
        "Install it or run via `nix run .#flake-input-versions`.",
        file=sys.stderr,
    )
    raise SystemExit(1) from exc


TAG_PATTERNS = (
    re.compile(r"^v?\d+(?:\.\d+)*(?:[-_][0-9A-Za-z]+)?$"),
    re.compile(r"^\d+(?:\.\d+)*$"),
)

# ANSI handling
COLOR_RESET = "\x1b[0m"
COLOR_GREEN = "\x1b[32m"
COLOR_YELLOW = "\x1b[33m"
USE_COLOR = True


@dataclass
class VersionDetails:
    ref: Optional[str]
    rev: Optional[str]
    display: str


@dataclass
class InputVersion:
    name: str
    url: str
    current: VersionDetails
    remote: VersionDetails
    message: Optional[str] = None


def is_probable_tag(ref: Optional[str]) -> bool:
    if not ref:
        return False
    return any(pattern.match(ref) for pattern in TAG_PATTERNS)


def short_rev(rev: Optional[str]) -> str:
    if not rev:
        return "unknown"
    return rev[:12]


def build_display(ref: Optional[str], rev: Optional[str]) -> str:
    rev_part = short_rev(rev) if rev else None
    if ref:
        base = ref
        if rev_part:
            base = f"{base} ({rev_part})"
        return base
    if rev_part:
        return rev_part
    return "unknown"


def set_color_enabled(enabled: bool) -> None:
    global USE_COLOR
    USE_COLOR = enabled


def colorize(text: str, color: Optional[str]) -> str:
    if not USE_COLOR or not color:
        return text
    return f"{color}{text}{COLOR_RESET}"


def compare_versions(current: VersionDetails, remote: VersionDetails) -> Optional[bool]:
    if current.rev and remote.rev:
        return current.rev == remote.rev
    return None


def build_version_text(
    current: VersionDetails,
    remote: VersionDetails,
    message: Optional[str],
    *,
    color: bool,
) -> str:
    status = compare_versions(current, remote)
    current_display = current.display
    remote_display = remote.display

    if status is True:
        text = current_display
    else:
        if status is False or current_display != remote_display:
            text = f"{current_display} -> {remote_display}"
        else:
            text = current_display

    if message:
        text = f"{text} ({message})"

    if not color:
        return text

    if status is True:
        return colorize(text, COLOR_GREEN)
    if status is False:
        return colorize(text, COLOR_YELLOW)
    return text


def run_command(cmd: Tuple[str, ...], *, env: Dict[str, str]) -> str:
    result = subprocess.run(
        cmd,
        check=False,
        text=True,
        capture_output=True,
        env=env,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Command {' '.join(cmd)} failed with code {result.returncode}: "
            f"{result.stderr.strip() or result.stdout.strip()}"
        )
    return result.stdout


def load_lock_nodes(lock_path: Path) -> Dict[str, dict]:
    with lock_path.open("r", encoding="utf-8") as fh:
        lock_data = json.load(fh)
    return lock_data["nodes"]


def run_flake_metadata(
    flake_uri: str,
    *,
    refresh: bool,
    env: Dict[str, str],
) -> Dict[str, dict]:
    cmd = ["nix", "flake", "metadata", "--json"]
    if refresh:
        cmd.append("--refresh")
    cmd.append(flake_uri)
    raw = run_command(tuple(cmd), env=env)
    data = json.loads(raw)
    return data["locks"]["nodes"]


def fetch_latest_tag(
    owner: str,
    repo: str,
    *,
    env: Dict[str, str],
) -> Optional[Tuple[str, str]]:
    url = f"https://github.com/{owner}/{repo}.git"
    cmd = (
        "git",
        "ls-remote",
        "--refs",
        "--tags",
        "--sort=-v:refname",
        url,
    )
    try:
        stdout = run_command(cmd, env=env)
    except RuntimeError:
        return None
    for line in stdout.strip().splitlines():
        if not line:
            continue
        commit, ref = line.split("\t", 1)
        tag = ref.split("/")[-1]
        if tag.endswith("^{}"):
            continue
        return tag, commit
    return None


def fetch_branch_head(
    owner: str,
    repo: str,
    ref: Optional[str],
    *,
    env: Dict[str, str],
) -> Optional[str]:
    url = f"https://github.com/{owner}/{repo}.git"
    candidates: Iterable[str]
    if ref:
        if ref.startswith("refs/"):
            candidates = (ref,)
        else:
            candidates = (f"refs/heads/{ref}", ref)
    else:
        candidates = ("HEAD",)

    for candidate in candidates:
        try:
            stdout = run_command(("git", "ls-remote", url, candidate), env=env)
        except RuntimeError:
            continue

        for line in stdout.strip().splitlines():
            if not line:
                continue
            commit, name = line.split("\t", 1)
            name = name.strip()
            if candidate == "HEAD":
                return commit
            if name.endswith(f"/{ref}") or name == candidate:
                return commit
    return None


def determine_remote_info(
    node_name: str,
    node: dict,
    refreshed_nodes: Dict[str, dict],
    *,
    env: Dict[str, str],
) -> Tuple[VersionDetails, Optional[str]]:
    locked = node.get("locked", {})
    original = node.get("original", {})
    refreshed_locked = refreshed_nodes.get(node_name, {}).get("locked", {})
    node_type = locked.get("type") or refreshed_locked.get("type")

    ref = original.get("ref") or locked.get("ref")
    base_rev = refreshed_locked.get("rev") or locked.get("rev")

    if node_type != "github":
        display = build_display(ref, base_rev)
        return VersionDetails(ref=ref, rev=base_rev, display=display), None

    owner = locked.get("owner") or refreshed_locked.get("owner") or original.get("owner")
    repo = locked.get("repo") or refreshed_locked.get("repo") or original.get("repo")
    if not owner or not repo:
        display = build_display(ref, base_rev)
        return (
            VersionDetails(ref=ref, rev=base_rev, display=display),
            "missing owner/repo metadata",
        )

    if is_probable_tag(ref):
        latest_tag = fetch_latest_tag(owner, repo, env=env)
        if not latest_tag:
            display = build_display(ref, base_rev)
            return (
                VersionDetails(ref=ref, rev=base_rev, display=display),
                "unable to resolve latest tag",
            )
        tag, commit = latest_tag
        display = build_display(tag, commit)
        return VersionDetails(ref=tag, rev=commit, display=display), None

    branch_rev = fetch_branch_head(owner, repo, ref, env=env)
    if branch_rev:
        display = build_display(ref, branch_rev)
        return VersionDetails(ref=ref, rev=branch_rev, display=display), None

    spec = f"github:{owner}/{repo}"
    if ref:
        spec = f"{spec}?ref={ref}"
    try:
        branch_nodes = run_flake_metadata(spec, refresh=True, env=env)
        branch_rev = branch_nodes.get("root", {}).get("locked", {}).get("rev")
        if branch_rev:
            display = build_display(ref, branch_rev)
            return VersionDetails(ref=ref, rev=branch_rev, display=display), None
    except Exception:
        pass

    display = build_display(ref, base_rev)
    return VersionDetails(ref=ref, rev=base_rev, display=display), "unable to determine remote head"


def gather_versions(
    nodes: Dict[str, dict],
    refreshed_nodes: Dict[str, dict],
    env: Dict[str, str],
) -> Tuple[InputVersion, ...]:
    root_inputs = nodes["root"]["inputs"]
    versions = []
    for attr_name, node_name in sorted(root_inputs.items()):
        node = nodes.get(node_name, {})
        locked = node.get("locked", {})
        original = node.get("original", {})

        ref = original.get("ref") or locked.get("ref")
        locked_rev = locked.get("rev")
        current_display = build_display(ref, locked_rev)
        current_info = VersionDetails(ref=ref, rev=locked_rev, display=current_display)

        remote_info, remote_note = determine_remote_info(
            node_name, node, refreshed_nodes, env=env
        )

        url = locked.get("url") or original.get("url") or "-"
        owner = locked.get("owner") or original.get("owner")
        repo = locked.get("repo") or original.get("repo")
        if owner and repo:
            url = f"https://github.com/{owner}/{repo}"
            if ref:
                url = f"{url}/tree/{ref}"

        versions.append(
            InputVersion(
                name=attr_name,
                url=url,
                current=current_info,
                remote=remote_info,
                message=remote_note,
            )
        )
    return tuple(versions)


def format_table(rows: Tuple[InputVersion, ...]) -> str:
    table = Texttable(max_width=0)
    table.set_deco(Texttable.HEADER | Texttable.VLINES | Texttable.BORDER)
    table.set_cols_align(["l", "l", "l"])
    table.header(["Input", "URL", "Version"])

    plain_versions = []
    color_versions = []

    for row in rows:
        plain_text = build_version_text(row.current, row.remote, row.message, color=False)
        color_text = build_version_text(row.current, row.remote, row.message, color=True)
        table.add_row([row.name, row.url, plain_text])
        plain_versions.append(plain_text)
        color_versions.append(color_text)

    output = table.draw()
    if USE_COLOR:
        for plain, colored in zip(plain_versions, color_versions):
            output = output.replace(plain, colored, 1)
    return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--flake",
        default=".",
        help="Path to the flake (defaults to current directory).",
    )
    parser.add_argument(
        "--no-color",
        action="store_true",
        help="Disable ANSI color codes in output.",
    )
    args = parser.parse_args()

    flake_dir = Path(args.flake).expanduser().resolve()
    lock_path = flake_dir / "flake.lock"
    if not lock_path.exists():
        print(f"error: no flake.lock at {lock_path}", file=sys.stderr)
        return 1

    cache_dir = flake_dir / ".nix-cache"
    cache_dir.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.setdefault("XDG_CACHE_HOME", str(cache_dir))
    env.setdefault("GIT_TERMINAL_PROMPT", "0")

    set_color_enabled(not args.no_color and sys.stdout.isatty())

    try:
        nodes = load_lock_nodes(lock_path)
    except Exception as exc:
        print(f"error: unable to parse lock file: {exc}", file=sys.stderr)
        return 1

    try:
        refreshed_nodes = run_flake_metadata(str(flake_dir), refresh=True, env=env)
    except Exception as exc:
        refreshed_nodes = {}
        print(f"warning: unable to refresh metadata: {exc}", file=sys.stderr)

    versions = gather_versions(nodes=nodes, refreshed_nodes=refreshed_nodes, env=env)
    print(format_table(versions))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
