#!/usr/bin/env python3
"""NixOS/Darwin configuration switcher script."""

import argparse
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def run_cmd(cmd: list[str], check: bool = True, capture: bool = False) -> subprocess.CompletedProcess:
    """Run a command with optional output capture."""
    kwargs = {"check": check, "text": True}
    if capture:
        kwargs["capture_output"] = True
    return subprocess.run(cmd, **kwargs)


def get_git_root() -> Path:
    """Find the git repository root directory."""
    result = run_cmd(["git", "rev-parse", "--show-toplevel"], capture=True)
    return Path(result.stdout.strip())


def get_nixos_version(profile: str) -> str:
    """Get the NixOS system version."""
    if profile == "home-server":
        cmd = ["ssh", "root@home-server", "basename $(readlink /nix/var/nix/profiles/system) | sed 's/-link$//'"]
        result = run_cmd(cmd, capture=True)
    else:
        cmd = ["bash", "-c", "basename $(readlink /nix/var/nix/profiles/system) | sed 's/-link$//'"]
        result = run_cmd(cmd, capture=True)
    return result.stdout.strip()


def copy_files_back(git_root: Path, profile: str, is_darwin: bool):
    """Copy generated configuration files back to repository."""
    dest_dir = git_root / "generated" / profile
    dest_dir.mkdir(parents=True, exist_ok=True)

    # Files to copy (OS-specific paths, we skip what doesn't exist)
    files = [
        # macOS VS Code
        "~/Library/Application Support/Code/User/keybindings.json",
        "~/Library/Application Support/Code/User/settings.json",
        "~/Library/Application Support/Code - Insiders/User/keybindings.json",
        "~/Library/Application Support/Code - Insiders/User/settings.json",
        # Linux VS Code
        "~/.config/Code/User/keybindings.json",
        "~/.config/Code/User/settings.json",
        # Common configs
        "~/.config/starship.toml",
        "~/.config/tmux/tmux.conf",
        "~/.config/nvim",
        "~/.zshrc",
    ]

    # Copy files (follow symlinks, recursive)
    for file in files:
        src = Path(file).expanduser()
        if src.exists():
            rel_path = src.relative_to(Path.home())
            dest = dest_dir / "$HOME" / rel_path
            dest.parent.mkdir(parents=True, exist_ok=True)
            run_cmd(["cp", "-rL", str(src), str(dest)])
            print(f"Copied: {file}")

    # Dump VS Code extensions list
    code_cmd = None
    for cmd in ["code-insiders", "code"]:
        result = run_cmd(["which", cmd], capture=True, check=False)
        if result.returncode == 0:
            code_cmd = cmd
            break
    
    if code_cmd:
        result = run_cmd([code_cmd, "--list-extensions"], capture=True, check=False)
        if result.returncode == 0:
            ext_list = dest_dir / "vscode" / "extensions.txt"
            ext_list.parent.mkdir(parents=True, exist_ok=True)
            ext_list.write_text(result.stdout)
            print("Copied: VS Code extensions list")


def main():
    parser = argparse.ArgumentParser(description="NixOS/Darwin configuration switcher")
    parser.add_argument("profile", choices=["macbook-m1", "nixos", "home-server"], help="Configuration profile")
    parser.add_argument("--no-commit", action="store_true", help="Skip git commit")
    parser.add_argument("--commit-message", default=f"Auto commit: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
                       help="Custom commit message")
    parser.add_argument("--build-only", action="store_true", help="Build without switching")
    parser.add_argument("--copy-back", action="store_true", help="Copy generated files back to repository")
    parser.add_argument("--copy-back-only", action="store_true", help="Only copy files back, skip build/switch")

    args = parser.parse_args()

    # Detect OS and validate git root
    is_darwin = sys.platform == "darwin"
    git_root = get_git_root()
    expected_root = Path.home() / "dotfiles"

    if git_root != expected_root:
        print(f"Error: Repository must be at {expected_root}, found at {git_root}")
        return 1

    os.chdir(git_root)

    # Handle copy-back-only mode
    if args.copy_back_only:
        import shutil
        shutil.rmtree(git_root / "generated" / args.profile, ignore_errors=True)
        print(f"Removed old generated files for {args.profile}.")
        copy_files_back(git_root, args.profile, is_darwin)
        print("Copy-back completed.")
        
        # Commit if requested
        run_cmd(["git", "add", "-A"])
        if not args.no_commit:
            result = run_cmd(["git", "diff-index", "--quiet", "HEAD", "--"], check=False)
            if result.returncode != 0:
                commit_msg = f"{args.commit_message} (profile: {args.profile}, copy-back only)"
                run_cmd(["git", "commit", "-m", commit_msg])
                print(f"Committed: {commit_msg}")
            else:
                print("No changes to commit.")
        return 0

    # Stage all changes
    run_cmd(["git", "add", "-A"])

    # Ensure sudo access
    if not is_darwin or args.profile != "home-server":
        run_cmd(["sudo", "-v"])

    # Build/switch configuration
    operation = "build" if args.build_only else "switch"
    flake_ref = f"{git_root}#{args.profile}"

    try:
        if is_darwin:
            cmd = ["sudo", "darwin-rebuild", operation, "--flake", flake_ref, "--cores", "0"]
            run_cmd(cmd)
        else:
            if args.profile == "home-server":
                print("Using remote target-host for home-server...")
                cmd = ["nixos-rebuild", "--log-format", "internal-json", operation,
                       "--flake", flake_ref, "--target-host", "root@home-server", "--cores", "0"]
                # Pipe through nom
                p1 = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                p2 = subprocess.Popen(["nom", "--json"], stdin=p1.stdout)
                p1.stdout.close()
                p2.communicate()
                if p2.returncode != 0:
                    raise subprocess.CalledProcessError(p2.returncode, cmd)
            else:
                cmd = ["sudo", "nixos-rebuild", "--log-format", "internal-json", operation,
                       "--flake", flake_ref, "--cores", "0"]
                # Pipe through nom
                p1 = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                p2 = subprocess.Popen(["nom", "--json"], stdin=p1.stdout)
                p1.stdout.close()
                p2.communicate()
                if p2.returncode != 0:
                    raise subprocess.CalledProcessError(p2.returncode, cmd)
    except subprocess.CalledProcessError:
        print(f"Error: {operation.capitalize()} failed.")
        return 1

    if args.build_only:
        print("Build completed successfully. Run again without --build-only to switch.")
        return 0

    # Copy files back if requested
    if args.copy_back:
        import shutil
        shutil.rmtree(git_root / "generated" / args.profile, ignore_errors=True)
        print(f"Removed old generated files for {args.profile}.")
        copy_files_back(git_root, args.profile, is_darwin)
    else:
        print("Skipping file copy-back (use --copy-back to enable).")

    print("Switch successful.")

    # Commit changes
    run_cmd(["git", "add", "-A"])

    if not args.no_commit:
        # Check if there are changes to commit
        result = run_cmd(["git", "diff-index", "--quiet", "HEAD", "--"], check=False)
        if result.returncode != 0:
            # Get version info
            version_info = ""
            if not is_darwin:
                try:
                    nixos_ver = get_nixos_version(args.profile)
                    version_info = f", nixos version: {nixos_ver}"
                except:
                    pass

            commit_msg = f"{args.commit_message} (profile: {args.profile}{version_info})"
            run_cmd(["git", "commit", "-m", commit_msg])
            print(f"Committed: {commit_msg}")
        else:
            print("No changes to commit.")
    else:
        print("--no-commit flag set; skipping commit.")

    print("Configuration switch completed successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
