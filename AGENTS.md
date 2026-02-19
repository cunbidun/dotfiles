# AGENTS

## Workflow: Update pin/version

Use this workflow whenever the user asks to refresh one or more flake inputs. Treat the steps below as instructions, not as the current state of the repo.

1. Run `nix run .#flake-input-versions` from the repo root to generate the latest comparison table between pinned and upstream versions.
2. Identify entries containing `->`; those inputs need an update unless the user specified otherwise.
3. Update the requested inputs (`nix flake lock --update-input <name>` or `nix flake update`) and inspect the resulting `flake.lock` diff.
4. Re-run the command to verify the table no longer shows drift for the inputs you touched, then report the outcome to the user.

### Example output

The block below is an **example** from a past run. Use it as a reference for what the table looks like; always regenerate fresh output before acting.

```
warning: Git tree '/home/cunbidun/dotfiles' is dirty
+--------------------+------------------------------------------------------------------+----------------------------------------------------------------+
|       Input        |                               URL                                |                            Version                             |
+====================+==================================================================+================================================================+
| Hyprspace          | https://github.com/KZDKM/Hyprspace                               | e54884da1d6a                                                   |
| apple-fonts        | https://github.com/Lyndeno/apple-fonts.nix                       | aba9944f6606                                                   |
| codex-nix          | https://github.com/sadjow/codex-nix                              | 8224589397ac                                                   |
| disko              | https://github.com/nix-community/disko                           | af087d076d38                                                   |
| home-manager       | https://github.com/nix-community/home-manager                    | 0562fef070a1                                                   |
| home-manager-rpi5  | https://github.com/nix-community/home-manager/tree/release-25.05 | release-25.05 (3b955f5f0a94)                                   |
| hyprcursor-phinger | https://github.com/jappie3/hyprcursor-phinger                    | 2e244e3398a3                                                   |
| hyprfocus          | https://github.com/daxisunder/hyprfocus                          | 12d581817bbb                                                   |
| hyprland           | https://github.com/hyprwm/Hyprland/tree/v0.52.0                  | v0.52.0 (f56ec180d3a0)                                         |
| hyprland-contrib   | https://github.com/hyprwm/contrib                                | 32e1a75b6555                                                   |
| hyprpanel          | https://github.com/cunbidun/HyprPanel                            | 138bd5d72810                                                   |
| mac-app-util       | https://github.com/hraban/mac-app-util                           | 8414fa1e2cb7                                                   |
| nix-darwin         | https://github.com/LnL7/nix-darwin                               | e2b82ebd0f99                                                   |
| nix-monitored      | https://github.com/ners/nix-monitored                            | 60f3baa4701d                                                   |
| nix4nvchad         | https://github.com/nix-community/nix4nvchad                      | 9d91858966b5                                                   |
| nix4vscode         | https://github.com/nix-community/nix4vscode                      | ce1055f41c6f                                                   |
| nixos-raspberrypi  | https://github.com/nvmd/nixos-raspberrypi/tree/main              | main (09c214a30e5a)                                            |
| nixpkgs-stable     | https://github.com/nixos/nixpkgs/tree/nixos-25.05                | nixos-25.05 (daf6dc47aa4b) -> nixos-25.05 (6faeb062ee4c)       |
| nixpkgs-unstable   | https://github.com/nixos/nixpkgs/tree/nixos-unstable             | nixos-unstable (08dacfca559e) -> nixos-unstable (ae814fd3904b) |
| opnix              | https://github.com/brizzbuzz/opnix                               | 48fdb078b5a1                                                   |
| pyprland           | https://github.com/hyprland-community/pyprland                   | f47ec4f4de83                                                   |
| sops-nix           | https://github.com/Mic92/sops-nix                                | 5a7d18b5c556                                                   |
| stylix             | https://github.com/nix-community/stylix                          | 647bb8dd96a2                                                   |
| vicinae            | https://github.com/vicinaehq/vicinae/tree/v0.16.2                | v0.16.2 (b99015bc2870)                                         |
| xremap-flake       | https://github.com/xremap/nix-flake/tree/066fd14ac7dd            | 066fd14ac7dd (066fd14ac7dd) (unable to determine remote head)  |
| yazi               | https://github.com/sxyazi/yazi/tree/v25.5.31                     | v25.5.31 (b65a88075a82)                                        |
+--------------------+------------------------------------------------------------------+----------------------------------------------------------------+
```

_Example note: In this snapshot only the `nixpkgs-*` inputs showed drift because they were intentionally skipped._

## Workflow: Commit

Use this whenever the user wants the current work committed.

1. Inspect the repo state with `git status -sb` so you know which files are staged, modified, or untracked.
2. Review the changes (`git diff` for unstaged, `git diff --cached` for staged) and ensure they align with the request.
3. Stage the appropriate files (`git add <path>` or `git add -p` for interactive selection).
4. Craft a clear commit message that summarizes the user-facing change, then run `git commit -m "<message>"`.
5. Optionally show the resulting commit hash or `git status -sb` to confirm a clean tree before handing off.

### Example output

```
$ git status -sb
## main...origin/main
 M flake.nix
 M flake.lock
?? AGENTS.md

$ git commit -m "docs: document agent workflows"
[main abc1234] docs: document agent workflows
 3 files changed, 120 insertions(+)
 create mode 100644 AGENTS.md

$ git status -sb
## main...origin/main
```

_Example note: Replace the message and file list with whatever matches the current request._
