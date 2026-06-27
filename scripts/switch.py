import argparse
import os
import shlex
import subprocess
import sys
from datetime import datetime
from pathlib import Path

def run_cmd(
    cmd: list[str], check: bool = True, capture: bool = False, env: dict[str, str] | None = None
) -> subprocess.CompletedProcess:
    """Run a command with optional output capture."""
    kwargs = {"check": check, "text": True}
    if capture:
        kwargs["capture_output"] = True
    if env is not None:
        kwargs["env"] = env
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


def selected_targets(args: argparse.Namespace) -> tuple[bool, bool]:
    """Return (run_system, run_home)."""
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

def run_build_with_nom(cmd: list[str], env: dict[str, str] | None = None) -> str:
    p1 = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=env,
    )
    p2 = subprocess.Popen(["nom", "--json"], stdin=p1.stderr)
    p1.stderr.close()
    stdout, _ = p1.communicate()
    p2.wait()
    if p1.returncode != 0 or p2.returncode != 0:
        raise subprocess.CalledProcessError(p1.returncode or p2.returncode, cmd)
    return stdout


def remote_profile(profile: str) -> tuple[str, str]:
    if profile == "home-server":
        return "root@home-server", ""
    if profile == "test-vm":
        return "root@localhost", "-p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    raise ValueError(f"profile {profile} is not remote")

def build_home_activation(attr: str, max_jobs: int | None = None) -> str:
    build_cmd = ["nix", "build", "--log-format", "internal-json", "--print-out-paths", attr]
    if max_jobs is not None:
        build_cmd += ["--option", "max-jobs", str(max_jobs)]
    return run_build_with_nom(build_cmd).strip().splitlines()[-1]

def activate_home_generation(generation: str):
    run_cmd(["nix-env", "--profile", str(Path.home() / ".local/state/nix/profiles/home-manager"), "--set", generation])
    activate = Path(generation) / "activate"
    if not activate.is_file() or not os.access(activate, os.X_OK):
        raise RuntimeError(f"activation script not found or not executable: {activate}")
    run_cmd([str(activate), "--driver-version", "1"])


def switch_system(args: argparse.Namespace, git_root: Path, is_darwin: bool):
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
            "switch",
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
            "switch",
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
        "switch",
        "--flake",
        flake_ref,
        "--cores",
        "0",
    ] + max_jobs_opts
    run_with_nom(cmd)


def switch_home(args: argparse.Namespace, git_root: Path):
    username = os.environ.get("USER", "cunbidun")
    flake_ref = f"{git_root}#{username}@{args.profile}"
    if args.profile in ("home-server", "test-vm"):
        target, ssh_opts = remote_profile(args.profile)
        attr = f"{git_root}#homeConfigurations.\"{username}@{args.profile}\".activationPackage"
        activation = build_home_activation(attr, args.max_jobs)
        env = os.environ.copy()
        if ssh_opts:
            env["NIX_SSHOPTS"] = ssh_opts
        run_cmd(["nix", "copy", "--to", f"ssh://{target}", activation], env=env)
        remote_cmd = (
            f"sudo -u {shlex.quote(username)} --set-home sh -lc "
            + shlex.quote('export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"; exec "$1"')
            + f" sh {shlex.quote(f'{activation}/activate')}"
        )
        ssh_cmd = ["ssh"] + ssh_opts.split() + [target, remote_cmd]
        run_cmd(ssh_cmd)
        return

    if args.profile == "nixos":
        attr = f"{git_root}#homeConfigurations.\"{username}@{args.profile}\".activationPackage"
        activation = build_home_activation(attr, args.max_jobs)
        activate_home_generation(activation)
        return

    run_cmd(["home-manager", "switch", "--flake", flake_ref])


def main():
    parser = argparse.ArgumentParser(description="NixOS/Darwin configuration switcher")
    parser.add_argument(
        "profile",
        choices=["macbook-m1", "nixos", "home-server", "test-vm"],
        help="Configuration profile",
    )
    parser.add_argument("--no-commit", action="store_true", help="Skip git commit (autocommit is the default)")
    parser.add_argument(
        "--commit-message",
        default=f"Auto commit: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        help="Custom commit message",
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
        "--max-jobs",
        type=int,
        default=None,
        metavar="N",
        help="Max parallel nix build jobs (passed to nixos-rebuild as --option max-jobs N)",
    )

    args = parser.parse_args()

    # Detect target platform and validate git root
    is_darwin = args.profile == "macbook-m1"
    git_root = get_git_root()
    expected_root = Path.home() / "dotfiles"

    if git_root != expected_root:
        print(f"Error: Repository must be at {expected_root}, found at {git_root}")
        return 1

    os.chdir(git_root)
    run_system, run_home = selected_targets(args)

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
        print("Error: Switch failed.")
        return 1
    except RuntimeError as exc:
        print(f"Error: {exc}")
        return 1

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
        print("Commit disabled; skipping commit.")

    print("Configuration switch completed successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
