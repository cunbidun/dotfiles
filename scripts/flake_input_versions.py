#!/usr/bin/env python3
"""
Report current versus upstream versions for flake inputs and container images.

For each direct input declared by the flake this tool shows:
* The locked version (tag + Nix commit when available).
* The latest version upstream (tag + commit or branch head).
* A color-coded status (green when up to date, yellow when newer upstream).
* The source URL for quick navigation.

Container images from nix/hosts/home-server/container-images.json are also
included in the status table with digest and last-pushed date.

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
from urllib.error import URLError
from urllib.request import Request, urlopen

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
    re.compile(r"^v?\d+(?:\.\d+)*(?:[-+._][0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?$"),
    re.compile(r"^\d+(?:\.\d+)*$"),
)

GIT_REV_PATTERN = re.compile(r"^[0-9a-f]{7,40}$")

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


def is_git_rev(rev: Optional[str]) -> bool:
    if not rev:
        return False
    return bool(GIT_REV_PATTERN.match(rev))


def short_rev(rev: Optional[str]) -> str:
    if not rev:
        return "unknown"
    return rev[:12]


def short_digest(digest: str) -> str:
    if digest.startswith("sha256:"):
        return f"sha256:{digest[7:15]}"
    return short_rev(digest)


def format_container_display(digest: str, last_pushed: Optional[str]) -> str:
    short = short_digest(digest)
    if last_pushed:
        date = last_pushed[:10] if len(last_pushed) >= 10 else last_pushed
        return f"{short} ({date})"
    return short


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


def fetch_latest_release_tag(
    owner: str,
    repo: str,
    *,
    env: Dict[str, str],
) -> Optional[str]:
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    request = Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "flake-inputs-report",
        },
    )
    try:
        with urlopen(request, timeout=20) as response:
            payload = json.load(response)
    except (URLError, TimeoutError, ValueError, OSError):
        return None

    tag = payload.get("tag_name")
    if isinstance(tag, str) and tag:
        return tag
    return None


def fetch_tag_commit(
    owner: str,
    repo: str,
    ref: str,
    *,
    env: Dict[str, str],
) -> Optional[str]:
    url = f"https://github.com/{owner}/{repo}.git"
    cmd = (
        "git",
        "ls-remote",
        "--tags",
        url,
    )
    try:
        stdout = run_command(cmd, env=env)
    except RuntimeError:
        return None

    direct_commit: Optional[str] = None
    for line in stdout.strip().splitlines():
        if not line:
            continue
        commit, remote_ref = line.split("\t", 1)
        if remote_ref == f"refs/tags/{ref}^{{}}":
            return commit
        if remote_ref == f"refs/tags/{ref}":
            direct_commit = commit

    return direct_commit


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

    owner = (
        locked.get("owner") or refreshed_locked.get("owner") or original.get("owner")
    )
    repo = locked.get("repo") or refreshed_locked.get("repo") or original.get("repo")
    if not owner or not repo:
        display = build_display(ref, base_rev)
        return (
            VersionDetails(ref=ref, rev=base_rev, display=display),
            "missing owner/repo metadata",
        )

    if is_probable_tag(ref):
        latest_tag = fetch_latest_release_tag(owner, repo, env=env)
        if not latest_tag:
            display = build_display(ref, base_rev)
            return (
                VersionDetails(ref=ref, rev=base_rev, display=display),
                "unable to resolve latest release",
            )
        latest_commit = fetch_tag_commit(owner, repo, latest_tag, env=env)
        if not latest_commit:
            display = build_display(ref, base_rev)
            return (
                VersionDetails(ref=ref, rev=base_rev, display=display),
                "unable to resolve latest release commit",
            )
        display = build_display(latest_tag, latest_commit)
        return VersionDetails(ref=latest_tag, rev=latest_commit, display=display), None

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
    return VersionDetails(
        ref=ref, rev=base_rev, display=display
    ), "unable to determine remote head"


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
    table.set_cols_dtype(["t", "t", "t"])
    table.header(["Input", "URL", "Version"])

    plain_versions = []
    color_versions = []

    for row in rows:
        plain_text = build_version_text(
            row.current, row.remote, row.message, color=False
        )
        color_text = build_version_text(
            row.current, row.remote, row.message, color=True
        )
        table.add_row([row.name, row.url, plain_text])
        plain_versions.append(plain_text)
        color_versions.append(color_text)

    output = table.draw()
    if USE_COLOR:
        for plain, colored in zip(plain_versions, color_versions):
            output = output.replace(plain, colored, 1)
    return output


def get_git_root() -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        text=True,
        capture_output=True,
        check=True,
    )
    return Path(result.stdout.strip())


def resolve_flake_dir(flake_arg: str) -> Path:
    return Path(flake_arg).expanduser().resolve()


def build_env(flake_dir: Path) -> Dict[str, str]:
    cache_dir = flake_dir / ".nix-cache"
    cache_dir.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.setdefault("XDG_CACHE_HOME", str(cache_dir))
    env.setdefault("GIT_TERMINAL_PROMPT", "0")
    return env


def gather_container_versions(flake_dir: Path) -> list[InputVersion]:
    container_file = flake_dir / "nix/hosts/home-server/container-images.json"
    if not container_file.exists():
        return []

    try:
        data = json.loads(container_file.read_text())
    except (json.JSONDecodeError, OSError):
        return []

    versions = []
    for name, entry in data.items():
        repository = entry.get("repository", "")
        tag = entry.get("tag", "")
        digest = entry.get("digest", "")
        last_pushed = entry.get("lastPushed")

        current_display = format_container_display(digest, last_pushed)
        current_info = VersionDetails(ref=last_pushed, rev=digest, display=current_display)

        try:
            remote_digest, remote_pushed = fetch_container_registry_info(repository, tag)
            remote_display = format_container_display(remote_digest, remote_pushed)
            remote_info = VersionDetails(ref=remote_pushed, rev=remote_digest, display=remote_display)
            remote_note: Optional[str] = None
        except RuntimeError:
            remote_info = current_info
            remote_note = "unable to check registry"

        url = build_container_web_url(repository)

        versions.append(
            InputVersion(
                name=name,
                url=url,
                current=current_info,
                remote=remote_info,
                message=remote_note,
            )
        )

    return versions


def show_status(flake_dir: Path, no_color: bool) -> int:
    lock_path = flake_dir / "flake.lock"
    if not lock_path.exists():
        print(f"error: no flake.lock at {lock_path}", file=sys.stderr)
        return 1

    env = build_env(flake_dir)

    set_color_enabled(not no_color and sys.stdout.isatty())

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
    container_versions = gather_container_versions(flake_dir)
    all_versions = tuple(sorted(list(versions) + container_versions, key=lambda v: v.name))
    print(format_table(all_versions))
    return 0


def run_checked(cmd: list[str], *, cwd: Path) -> None:
    subprocess.run(cmd, cwd=str(cwd), text=True, check=True)


def run_capture(cmd: list[str], *, cwd: Path, env: Optional[Dict[str, str]] = None) -> str:
    result = subprocess.run(
        cmd,
        cwd=str(cwd),
        text=True,
        capture_output=True,
        check=True,
        env=env,
    )
    return result.stdout


def update_flake_inputs(flake_dir: Path, inputs: Optional[list[str]]) -> None:
    bump_pinned_flake_input_refs(flake_dir, inputs)

    cmd = ["nix", "flake", "update", "--flake", str(flake_dir)]
    if inputs:
        cmd.extend(inputs)
        print(f"Updating flake inputs: {', '.join(inputs)}")
    else:
        print("Updating all flake inputs")
    run_checked(cmd, cwd=flake_dir)


def bump_pinned_flake_input_refs(flake_dir: Path, selected_inputs: Optional[list[str]]) -> None:
    lock_path = flake_dir / "flake.lock"
    flake_nix_path = flake_dir / "flake.nix"

    if not lock_path.exists() or not flake_nix_path.exists():
        return

    nodes = load_lock_nodes(lock_path)
    env = build_env(flake_dir)
    try:
        refreshed_nodes = run_flake_metadata(str(flake_dir), refresh=True, env=env)
    except Exception:
        return

    root_inputs = nodes.get("root", {}).get("inputs", {})
    known_inputs = set(root_inputs.keys())

    if selected_inputs:
        unknown = [name for name in selected_inputs if name not in known_inputs]
        if unknown:
            raise SystemExit(f"Unknown flake input(s): {', '.join(unknown)}")
        target_inputs = selected_inputs
    else:
        target_inputs = sorted(known_inputs)

    content = flake_nix_path.read_text(encoding="utf-8")
    changed = False

    for input_name in target_inputs:
        node_name = root_inputs.get(input_name)
        if not node_name:
            continue

        node = nodes.get(node_name, {})
        locked = node.get("locked", {})
        original = node.get("original", {})

        owner = locked.get("owner") or original.get("owner")
        repo = locked.get("repo") or original.get("repo")
        current_ref = original.get("ref") or locked.get("ref")
        current_rev = locked.get("rev")

        if not owner or not repo:
            continue

        remote_info, _ = determine_remote_info(node_name, node, refreshed_nodes, env=env)

        pattern = re.compile(
            rf'({re.escape(input_name)}\s*=\s*\{{[^}}]*?url\s*=\s*"github:{re.escape(owner)}/{re.escape(repo)}/)'
            rf'([^"\n?]+)'
            rf'([^"\n]*";)',
            re.S,
        )
        match = pattern.search(content)
        if not match:
            continue

        pinned_token = match.group(2)
        new_token = None

        # Tag-pinned input: github:owner/repo/vX.Y.Z
        if current_ref and is_probable_tag(current_ref) and is_probable_tag(remote_info.ref):
            if remote_info.ref != current_ref:
                new_token = remote_info.ref

        # Commit-pinned input: github:owner/repo/<rev>
        elif is_git_rev(pinned_token) and is_git_rev(remote_info.rev):
            if remote_info.rev != current_rev:
                new_token = remote_info.rev

        if not new_token:
            continue

        content, count = pattern.subn(rf"\g<1>{new_token}\g<3>", content, count=1)
        if count > 0:
            print(f"Bumping {input_name} ref in flake.nix: {pinned_token} -> {new_token}")
            changed = True

    if changed:
        flake_nix_path.write_text(content, encoding="utf-8")


def parse_container_repository(repository: str) -> tuple[str, str, str]:
    """Parse a container repository string into (host, owner, repo_name).

    Accepts formats like docker.io/owner/repo or owner/repo (implies Docker Hub).
    """
    parts = repository.split("/")
    if len(parts) == 3:
        return parts[0], parts[1], parts[2]
    if len(parts) == 2:
        return "docker.io", parts[0], parts[1]
    if len(parts) == 1 and "/" not in repository:
        return "docker.io", parts[0], parts[0]
    raise RuntimeError(f"Unable to parse container repository: {repository}")


def build_container_web_url(repository: str) -> str:
    """Build a human-friendly web URL for a container repository."""
    host, owner, repo = parse_container_repository(repository)
    if host in ("docker.io", "index.docker.io"):
        return f"https://hub.docker.com/r/{owner}/{repo}"
    if host == "ghcr.io":
        return f"https://github.com/{owner}/{repo}/pkgs/container/{repo}"
    return repository


def fetch_container_registry_info(repository: str, tag: str) -> tuple[str, str]:
    """Fetch digest and tag_last_pushed from a container registry via HTTP API.

    Currently supports Docker Hub via the hub.docker.com API.
    Returns (digest, lastPushed) where lastPushed is an ISO-8601 timestamp string.
    Raises RuntimeError if the registry is not supported or the request fails.
    """
    host, owner, repo_name = parse_container_repository(repository)

    if host not in ("docker.io", "index.docker.io"):
        raise RuntimeError(f"Registry not supported for HTTP check: {host}")

    url = f"https://hub.docker.com/v2/repositories/{owner}/{repo_name}/tags/{tag}"
    request = Request(url, headers={"User-Agent": "flake-inputs-report"})
    try:
        with urlopen(request, timeout=20) as response:
            payload = json.load(response)
    except (URLError, TimeoutError, ValueError, OSError) as exc:
        raise RuntimeError(f"Unable to fetch tag info from Docker Hub: {exc}") from exc

    digest = payload.get("digest", "")
    if not digest:
        raise RuntimeError(f"No digest in Docker Hub response for {repository}:{tag}")
    last_pushed = payload.get("tag_last_pushed", "")
    return digest, last_pushed or ""


def fetch_container_info_skopeo(flake_dir: Path, repository: str, tag: str) -> tuple[str, str]:
    """Fetch digest using skopeo (works for any registry, but lastPushed is unavailable).

    Returns (digest, "").
    """
    env = os.environ.copy()
    env["CONTAINERS_REGISTRIES_CONF"] = "/dev/null"
    payload = run_capture(
        ["nix", "run", "nixpkgs#skopeo", "--", "inspect", f"docker://{repository}:{tag}"],
        cwd=flake_dir,
        env=env,
    )
    digest = json.loads(payload).get("Digest")
    if not digest:
        raise RuntimeError(f"Unable to resolve digest for {repository}:{tag}")
    return digest, ""


def update_container_inputs(flake_dir: Path, names: Optional[list[str]]) -> None:
    input_file = flake_dir / "nix/hosts/home-server/container-images.json"
    data = json.loads(input_file.read_text())

    selected = names if names else list(data.keys())
    unknown = [name for name in selected if name not in data]
    if unknown:
        raise SystemExit(f"Unknown container input(s): {', '.join(unknown)}")

    changed = False
    for name in selected:
        entry = data[name]
        repository = entry["repository"]
        tag = entry["tag"]
        old_digest = entry.get("digest", "")

        try:
            new_digest, last_pushed = fetch_container_registry_info(repository, tag)
        except RuntimeError:
            new_digest, last_pushed = fetch_container_info_skopeo(flake_dir, repository, tag)

        changed_entry = False
        if new_digest != old_digest:
            print(f"Updating {name}: {old_digest} -> {new_digest}")
            entry["digest"] = new_digest
            changed_entry = True

        if last_pushed and entry.get("lastPushed") != last_pushed:
            print(f"Updating {name} lastPushed: {entry.get('lastPushed', 'N/A')} -> {last_pushed}")
            entry["lastPushed"] = last_pushed
            changed_entry = True

        if not changed_entry:
            print(f"{name} is already up to date ({new_digest})")

        if changed_entry:
            changed = True

    if changed:
        input_file.write_text(json.dumps(data, indent=2) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command")

    show_parser = subparsers.add_parser("show", help="Show flake input drift table")
    show_parser.add_argument(
        "--flake",
        default=".",
        help="Path to the flake (defaults to current directory).",
    )
    show_parser.add_argument(
        "--no-color",
        action="store_true",
        help="Disable ANSI color codes in output.",
    )

    update_parser = subparsers.add_parser("update", help="Update flake and container inputs")
    update_parser.add_argument(
        "inputs",
        nargs="*",
        metavar="INPUT",
        help="Positional flake input names to update (same as --flake).",
    )
    update_parser.add_argument(
        "--flake",
        nargs="*",
        metavar="INPUT",
        help="Update specific flake inputs (empty means all).",
    )
    update_parser.add_argument(
        "--container",
        nargs="*",
        metavar="NAME",
        help="Update specific container image entries (empty means all).",
    )
    update_parser.add_argument("--no-flake", action="store_true", help="Skip flake updates")
    update_parser.add_argument("--no-container", action="store_true", help="Skip container image updates")
    update_parser.add_argument(
        "--flake-path",
        default=None,
        help="Path to the flake root (defaults to git root).",
    )
    update_parser.add_argument(
        "--no-status",
        action="store_true",
        help="Skip status table after update.",
    )
    update_parser.add_argument(
        "--no-color",
        action="store_true",
        help="Disable ANSI color codes in status output.",
    )

    args = parser.parse_args()
    command = args.command or "show"

    if command == "show":
        flake_dir = resolve_flake_dir(args.flake)
        return show_status(flake_dir, args.no_color)

    flake_dir = resolve_flake_dir(args.flake_path) if args.flake_path else get_git_root()

    selected_flake_inputs = args.flake if args.flake is not None else args.inputs

    default_mode = args.flake is None and len(args.inputs) == 0 and args.container is None
    run_flake = not args.no_flake and (default_mode or args.flake is not None or len(args.inputs) > 0)
    run_container = not args.no_container and (default_mode or args.container is not None)

    if not run_flake and not run_container:
        print("Nothing to do")
        return 0

    if run_flake:
        update_flake_inputs(flake_dir, selected_flake_inputs)
    if run_container:
        update_container_inputs(flake_dir, args.container)

    if not args.no_status:
        return show_status(flake_dir, args.no_color)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
