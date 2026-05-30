#!/usr/bin/env python3
import argparse
import json
import subprocess
from pathlib import Path


def run_cmd(cmd: list[str], cwd: Path, capture: bool = False) -> subprocess.CompletedProcess:
    kwargs = {
        "cwd": str(cwd),
        "text": True,
        "check": True,
    }
    if capture:
        kwargs["capture_output"] = True
    return subprocess.run(cmd, **kwargs)


def get_git_root() -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        text=True,
        capture_output=True,
        check=True,
    )
    return Path(result.stdout.strip())


def update_flake_inputs(git_root: Path, inputs: list[str] | None) -> None:
    cmd = ["nix", "flake", "update", "--flake", str(git_root)]
    if inputs:
        cmd.extend(inputs)
        print(f"Updating flake inputs: {', '.join(inputs)}")
    else:
        print("Updating all flake inputs")
    run_cmd(cmd, cwd=git_root)


def fetch_digest(git_root: Path, repository: str, tag: str) -> str:
    image_ref = f"docker://{repository}:{tag}"
    result = run_cmd(
        ["nix", "run", "nixpkgs#skopeo", "--", "inspect", image_ref],
        cwd=git_root,
        capture=True,
    )
    payload = json.loads(result.stdout)
    digest = payload.get("Digest")
    if not digest:
        raise RuntimeError(f"Unable to resolve digest for {repository}:{tag}")
    return digest


def update_container_inputs(git_root: Path, names: list[str] | None) -> None:
    input_file = git_root / "nix/hosts/home-server/container-images.json"
    data = json.loads(input_file.read_text())

    selected = names if names is not None else list(data.keys())
    unknown = [name for name in selected if name not in data]
    if unknown:
        raise SystemExit(f"Unknown container input(s): {', '.join(unknown)}")

    changed = False
    for name in selected:
        entry = data[name]
        repository = entry["repository"]
        tag = entry["tag"]
        old_digest = entry.get("digest", "")
        new_digest = fetch_digest(git_root, repository, tag)
        if new_digest != old_digest:
            print(f"Updating {name}: {old_digest} -> {new_digest}")
            entry["digest"] = new_digest
            changed = True
        else:
            print(f"{name} is already up to date ({new_digest})")

    if changed:
        input_file.write_text(json.dumps(data, indent=2) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Update flake and container inputs")
    parser.add_argument(
        "--flake",
        nargs="+",
        metavar="INPUT",
        help="Specific flake input names to update",
    )
    parser.add_argument(
        "--container",
        nargs="+",
        metavar="NAME",
        help="Specific container image entries to update",
    )
    parser.add_argument("--no-flake", action="store_true", help="Skip flake updates")
    parser.add_argument(
        "--no-container", action="store_true", help="Skip container image updates"
    )
    args = parser.parse_args()

    git_root = get_git_root()

    default_mode = args.flake is None and args.container is None
    run_flake = not args.no_flake and (default_mode or args.flake is not None)
    run_container = not args.no_container and (default_mode or args.container is not None)

    if not run_flake and not run_container:
        print("Nothing to do")
        return 0

    if run_flake:
        update_flake_inputs(git_root, args.flake)
    if run_container:
        update_container_inputs(git_root, args.container)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
