#!/usr/bin/env python3
import os, sys, socket, argparse

SOCKET = os.path.expanduser("~/.local/share/theme-manager/socket")


def client_request(msg):
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(SOCKET)
            s.sendall(msg.encode())
            resp = s.recv(4096).decode().strip()
    except FileNotFoundError:
        print("ERROR: socket not found—daemon may not be running", file=sys.stderr)
        return None, 2
    except ConnectionRefusedError:
        print("ERROR: could not connect to socket", file=sys.stderr)
        return None, 3

    if resp.startswith("OK"):
        parts = resp.split(maxsplit=1)
        return parts[1] if len(parts) == 2 else "", 0
    else:
        return resp, 1


def get_theme():
    out, code = client_request("GET-THEME\n")
    if out is not None:
        print(out)
    return code


def get_themes():
    out, code = client_request("LIST-THEMES\n")
    if out is not None:
        try:
            import json
            themes = json.loads(out)
            print("\n".join(themes))
        except ValueError:
            print("ERROR: invalid response format", file=sys.stderr)
            return 4
    return code


def set_theme(theme):
    out, code = client_request(f"SET-THEME {theme}\n")
    if out is not None:
        print(out)
    return code


def get_nvim_theme():
    out, code = client_request("GET-NVIM-THEME\n")
    if code == 0 and out is not None:
        print(out)
    elif code == 1 and out is not None:
        # Extract error message and print to stderr for better error handling
        error_msg = out.replace("ERROR ", "") if out.startswith("ERROR ") else out
        print(f"ERROR: {error_msg}", file=sys.stderr)
    return code


def build_parser():
    parser = argparse.ArgumentParser(prog="themectl", description="Control theme-manager daemon")
    sub = parser.add_subparsers(dest="cmd", required=True, help="sub-command")

    sub.add_parser("get-theme", help="Show current theme")
    sub.add_parser("list-themes", help="List all available themes")
    sub.add_parser("get-nvim-theme", help="Show current theme's Neovim colorscheme")

    pset = sub.add_parser("set-theme", help="Set a new theme")
    pset.add_argument("theme", help="Theme name (as returned by list-themes)")

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()

    exit_code = {
        "get-theme": get_theme,
        "list-themes": get_themes,
        "get-nvim-theme": get_nvim_theme,
        "set-theme": lambda: set_theme(args.theme),
    }[args.cmd]()

    sys.exit(exit_code)


if __name__ == "__main__":
    main()