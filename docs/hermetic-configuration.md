# Hermetic Configuration

Hermetic config means Nix can know the final app config before the app starts. If runtime state is not needed, generate
the final file in Home Manager and stop there.

Use this for non-runtime apps such as Codex and Claude. Plugin lists, hooks, MCP servers, and hook trust are startup
inputs, so Nix should own the final config directly.

Rule: keep apps out of runtime managers unless they need runtime changes.

Local edit exceptions should be host-gated, not user-gated. The same user exists on multiple machines, but only one host
has the editable checkout path.

Define each `hostName` once in `flake.nix`, then pass it to both NixOS `specialArgs` and Home Manager
`extraSpecialArgs`.

```nix
".config/nvim".source =
  if hostName == "nixos"
  then config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/nvim"
  else ../../../utilities/nvim;
```

Use this only when local live edits matter. Remote hosts should use the store source so `home-manager switch` works
without requiring `~/dotfiles` at runtime.

## Runtime Config

Runtime config is different: the app changes while it is running, so Home Manager must not own the live file edited by
that runtime path.

For theme switching, the persisted runtime state is:

```text
~/.local/state/theme-manager/current-theme-name.txt
```

Generated theme inputs live under:

```text
~/.local/state/theme-manager/nix/
  themes.json
  code/settings.base.json
```

## Runtime Classes

| Type | Use when | Apps | Owner | Switch |
| --- | --- | --- | --- | --- |
| Hermetic | Known before startup | Codex, Claude | Home Manager | Rebuild writes final config |
| Class 1 | Config can run code | Neovim, Quickshell, Hyprland | App config | App hot reloads |
| Class 2 | App watches data | VS Code | Nix input + live file | Runtime writes live file |
| Class 3 | Needs signal/API | Kitty, Chrome, Hyprpaper | Live file/API | Runtime writes, then signals |
| Class 4 | Cannot reload safely | Startup-only apps | Generated/live config | Next start picks it up |
| Shell env CLI | Reads env at launch | bat, fzf | Shell hook | Next prompt refreshes env |

### Class 1: Code Config

Best case. App config is code, so the app can read state and hot reload itself without systemd restarts or external
reload glue.

Current examples:

- Neovim watches `current-theme-name.txt` with Lua `uv` fs events and applies its colorscheme.
- Quickshell watches `current-theme-name.txt` and resolved theme JSON with QML `FileView`.
- Hyprland reads `current-theme-name.txt`, keeps palette data in `~/.config/hypr/user/theme.lua`, and applies changes
  from Lua.

Rule: put reload logic inside app config. `theme-manager` only changes shared state.

### Class 2: Watched Data Config

Use this when the app watches a data file but cannot execute logic from it.

Current example:

- VS Code watches `~/.config/Code/User/settings.json`. Nix writes
  `~/.local/state/theme-manager/nix/code/settings.base.json`; `theme-manager` writes live settings with the current
  `workbench.colorTheme`.

Rule: Nix owns generated input. Runtime code owns the live file.

### Class 3: Config Plus Signal

Use this when the app needs a file/API update plus an explicit reload signal.

Current examples:

- Kitty reads `~/.local/state/theme-manager/kitty-theme.conf`; `theme-manager` updates it and sends `SIGUSR1`.
- Chrome policy is copied to `~/.local/etc/chrome-policy.json`; Chrome refresh runs only when Chrome is running.
- Hyprpaper is updated through `hyprctl hyprpaper ...`.

Rule: signal only after content changes, or when the app API requires reasserting runtime state.

### Class 4: No Runtime Reload

Use this when the app cannot safely reload while running.

Rule: write config for next start. Forced restart is a user action, not a normal switch.

### Shell Env CLI

Use this when a CLI app supports a native environment variable and reads it at process start.

Current examples:

- `bat` reads `BAT_THEME`.
- `fzf` reads `FZF_DEFAULT_OPTS`.

Zsh refreshes these environment variables from `current-theme-name.txt` with `precmd` and `preexec`, so each prompt and
next command get the current theme without shadowing app binaries.

Rule: prefer app-native environment variables over shell wrappers. Use a shell hook only to keep the env var fresh in
long-running shells.

## Adding Apps

1. If the config is known before startup, use hermetic Nix config and stop.
2. If the app config is code, make it self-react to runtime state.
3. If it needs generated data, put Nix inputs under `~/.local/state/theme-manager/nix/<app>/...`.
4. If it needs a live mutable file, keep Home Manager off that target and let runtime code write it atomically.
5. If it supports a native environment variable, refresh that env var from shell hooks instead of wrapping commands.
6. Keep shared mappings in Nix-generated data, not duplicated in runtime scripts.
