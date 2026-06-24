import argparse
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path


HOME_PROFILES = {"nixos"}



def run_cmd(
    cmd: list[str], check: bool = True, capture: bool = False
) -> subprocess.CompletedProcess:
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
        cmd = [
            "ssh",
            "root@home-server",
            "basename $(readlink /nix/var/nix/profiles/system) | sed 's/-link$//'",
        ]
        result = run_cmd(cmd, capture=True)
    else:
        cmd = [
            "bash",
            "-c",
            "basename $(readlink /nix/var/nix/profiles/system) | sed 's/-link$//'",
        ]
        result = run_cmd(cmd, capture=True)
    return result.stdout.strip()


def selected_targets(args: argparse.Namespace, is_darwin: bool) -> tuple[bool, bool]:
    """Return (run_system, run_home)."""
    if is_darwin:
        return True, False
    if args.home:
        return False, True
    if args.system:
        return True, False
    return True, True


def run_with_nom(cmd: list[str], env: dict[str, str] | None = None):
    p1 = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env)
    p2 = subprocess.Popen(["nom", "--json"], stdin=p1.stdout)
    p1.stdout.close()
    p2.communicate()
    p1.wait()
    if p1.returncode != 0 or p2.returncode != 0:
        raise subprocess.CalledProcessError(p1.returncode or p2.returncode, cmd)


def switch_system(args: argparse.Namespace, git_root: Path, is_darwin: bool):
    operation = "build" if args.build_only else "switch"
    flake_ref = f"{git_root}#{args.profile}"
    max_jobs_opts = (
        ["--option", "max-jobs", str(args.max_jobs)]
        if args.max_jobs is not None
        else []
    )

    if is_darwin:
        cmd = [
            "sudo",
            "darwin-rebuild",
            operation,
            "--flake",
            flake_ref,
            "--cores",
            "0",
        ]
        run_cmd(cmd)
        return

    if args.profile in ("home-server", "test-vm"):
        if args.profile == "home-server":
            target = "root@home-server"
            ssh_opts = ""
        else:
            target = "root@localhost"
            ssh_opts = "-p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
        print(f"Using remote target-host for {args.profile}...")
        cmd = [
            "nixos-rebuild",
            "--log-format",
            "internal-json",
            operation,
            "--flake",
            flake_ref,
            "--target-host",
            target,
            "--cores",
            "0",
        ] + max_jobs_opts
        env = os.environ.copy()
        if ssh_opts:
            env["NIX_SSHOPTS"] = ssh_opts
        run_with_nom(cmd, env=env)
        return

    cmd = [
        "sudo",
        "nixos-rebuild",
        "--log-format",
        "internal-json",
        operation,
        "--flake",
        flake_ref,
        "--cores",
        "0",
    ] + max_jobs_opts
    run_with_nom(cmd)


def switch_home(args: argparse.Namespace, git_root: Path):
    operation = "build" if args.build_only else "switch"
    username = os.environ.get("USER", "cunbidun")
    flake_ref = f"{git_root}#{username}@{args.profile}"
    cmd = ["home-manager", operation]
    if operation == "switch":
        cmd += ["-b", "bak"]
    cmd += ["--flake", flake_ref]
    run_cmd(cmd)


def copy_files_back(git_root: Path, profile: str, is_darwin: bool):
    """Copy generated configuration files back to repository."""
    dest_dir = git_root / "generated" / profile
    dest_dir.mkdir(parents=True, exist_ok=True)

    # Files to copy (OS-specific paths, we skip what doesn't exist)
    files = [
        # macOS VS Code
        "~/Library/Application Support/Code/User/keybindings.json",
        "~/Library/Application Support/Code/User/settings.json",
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
    for cmd in ["code"]:
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
    parser.add_argument(
        "profile",
        choices=["macbook-m1", "nixos", "home-server", "test-vm"],
        help="Configuration profile",
    )
    parser.add_argument("--no-commit", action="store_true", help="Skip git commit")
    parser.add_argument(
        "--commit-message",
        default=f"Auto commit: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        help="Custom commit message",
    )
    parser.add_argument(
        "--build-only", action="store_true", help="Build without switching"
    )
    target_group = parser.add_mutually_exclusive_group()
    target_group.add_argument(
        "--system", action="store_true", help="Build/switch only system config"
    )
    target_group.add_argument(
        "--home", action="store_true", help="Build/switch only Home Manager config"
    )
    target_group.add_argument(
        "--all", action="store_true", help="Build/switch system and Home Manager configs"
    )
    parser.add_argument(
        "--copy-back",
        action="store_true",
        help="Copy generated files back to repository",
    )
    parser.add_argument(
        "--copy-back-only",
        action="store_true",
        help="Only copy files back, skip build/switch",
    )
    parser.add_argument(
        "--max-jobs",
        type=int,
        default=None,
        metavar="N",
        help="Max parallel nix build jobs (passed to nixos-rebuild as --option max-jobs N)",
    )

    args = parser.parse_args()

    # Detect OS and validate git root
    is_darwin = sys.platform == "darwin"
    git_root = get_git_root()
    expected_root = Path.home() / "dotfiles"

    if git_root != expected_root:
        print(f"Error: Repository must be at {expected_root}, found at {git_root}")
        return 1

    os.chdir(git_root)
    run_system, run_home = selected_targets(args, is_darwin)

    if run_home and args.profile not in HOME_PROFILES and not args.build_only:
        print(
            f"Error: --home/--all switch is only enabled for local profiles: {', '.join(sorted(HOME_PROFILES))}."
        )
        print("Use --system for remote machines, or --build-only to test their home configs.")
        return 1

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
            result = run_cmd(
                ["git", "diff-index", "--quiet", "HEAD", "--"], check=False
            )
            if result.returncode != 0:
                commit_msg = (
                    f"{args.commit_message} (profile: {args.profile}, copy-back only)"
                )
                run_cmd(["git", "commit", "-m", commit_msg])
                print(f"Committed: {commit_msg}")
            else:
                print("No changes to commit.")
        return 0

    # Stage all changes
    run_cmd(["git", "add", "-A"])

    # Ensure sudo access
    if run_system and (not is_darwin or args.profile != "home-server"):
        run_cmd(["sudo", "-v"])

    try:
        if run_system:
            switch_system(args, git_root, is_darwin)
        if run_home:
            switch_home(args, git_root)
    except subprocess.CalledProcessError:
        operation = "build" if args.build_only else "switch"
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

            commit_msg = (
                f"{args.commit_message} (profile: {args.profile}{version_info})"
            )
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
