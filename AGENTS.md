# AGENTS

## Workflow: Update pin/version

Use this workflow whenever the user asks to refresh one or more flake inputs.
Treat the steps below as instructions, not as the current state of the repo.

1. Run `nix run .#flake-input-versions` from the repo root to generate the latest comparison table
   between pinned and upstream versions.
2. Identify entries containing `->`; those inputs need an update unless the user specified otherwise.
3. Update the requested inputs (`nix flake lock --update-input <name>` or `nix flake update`) and
   inspect the resulting `flake.lock` diff.
4. Re-run the command to verify the table no longer shows drift for the inputs you touched,
   then report the outcome to the user.

### Example output

_Example from a past run — always regenerate fresh output before acting._

```text
| nixpkgs-stable   | https://github.com/nixos/nixpkgs/tree/nixos-25.05    | nixos-25.05 (daf6dc47aa4b) -> nixos-25.05 (6faeb062ee4c)       |
| nixpkgs-unstable | https://github.com/nixos/nixpkgs/tree/nixos-unstable | nixos-unstable (08dacfca559e) -> nixos-unstable (ae814fd3904b) |
| home-manager     | https://github.com/nix-community/home-manager        | 0562fef070a1                                                   |
```

_Entries with `->` need updating. Entries without are already up to date._

## Workflow: Commit

Use this whenever the user wants the current work committed.

1. Inspect the repo state with `git status -sb` so you know which files are staged, modified, or untracked.
2. Review the changes (`git diff` for unstaged, `git diff --cached` for staged) and ensure they align with the request.
3. Stage the appropriate files (`git add <path>` or `git add -p` for interactive selection).
4. Craft a clear commit message that summarizes the user-facing change, then run `git commit -m "<message>"`.
5. Optionally show the resulting commit hash or `git status -sb` to confirm a clean tree before handing off.

### Example

```text
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

## Workflow: Hyprland Plugin Fix / Add

Use this workflow to add a new plugin or fix one that fails to build against the current Hyprland.

### Key facts

- Plugins must be built against the **exact same Hyprland commit** that is running.
  A mismatch causes a build error or `undefined symbol` at load time.
- Get the running commit: `hyprctl version` → look for `at commit <sha>`.
- Plugins load via `exec-once=hyprctl plugin load <path>` — only on Hyprland start, not on reload.
- To reload plugin config without restarting: `hyprctl plugin unload <path> && hyprctl plugin load <path>`.

### Diagnose

```bash
hyprctl plugin list                          # see what is loaded
hyprctl plugin load /nix/store/…/lib/lib.so  # authoritative error message
```

- `undefined symbol` → ABI mismatch; plugin built against wrong Hyprland version.
- `Invalid dispatcher "foo:bar" does not exist` → plugin failed to load silently.

### Fix a broken plugin (fork workflow)

1. Fork upstream under `cunbidun` on GitHub if not already forked.
2. Clone: `git clone https://github.com/cunbidun/<name> ~/tmp/<name>`
3. Update headers to match running Hyprland:

   ```bash
   cd ~/tmp/<name>
   nix flake lock --update-input hyprland
   python3 -c "import json; d=json.load(open('flake.lock')); \
     print(d['nodes']['hyprland']['locked']['rev'])"
   ```

4. Build and test:

   ```bash
   nix develop --impure -c make
   hyprctl plugin load out/<plugin>.so
   hyprctl plugin list
   ```

5. Fix compile errors if any. Common patterns:
   - `m_renderData` → `m_renderPass`
   - `draw(element)` → `draw(element, damage)` (add `CRegion` second arg)
6. Commit and push, then update dotfiles lock:

   ```bash
   git add flake.lock && git commit -m "fix: build against hyprland <sha>" && git push
   cd ~/dotfiles && nix flake lock --update-input <name>
   ```

7. Add plugin to `plugins` list in `nix/home-manager/configs/hyprland/hyprland.nix`
   and rebuild: `nix run .#switch -- nixos`.

### Add a brand-new plugin

1. Add to `flake.nix`:

   ```nix
   my-plugin = {
     url = "github:<owner>/<repo>";
     inputs.hyprland.follows = "hyprland";
   };
   ```

2. `nix flake lock --update-input my-plugin`
3. Add to `plugins` list, add `settings.plugin.<name>` config block, add keybinds.
4. `nix run .#switch -- nixos`, then restart Hyprland.
