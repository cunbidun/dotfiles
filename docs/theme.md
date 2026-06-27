# Theme System

This repo has one runtime theme manager. Add a theme by wiring the same theme name through every consumer, then verify
the generated files and live runtime state.

Theme names use this shape:

```text
<theme>-light
<theme>-dark
```

Example:

```text
everforest-light
everforest-dark
```

## Runtime State

Persisted current theme:

```text
~/.local/state/theme-manager/current-theme-name.txt
```

Nix-generated runtime inputs:

```text
~/.local/state/theme-manager/nix/themes.json
~/.local/state/theme-manager/nix/code/settings.base.json
```

Live files written by `theme-manager`:

```text
~/.config/Code/User/settings.json
~/.local/etc/chrome-policy.json
~/.local/state/theme-manager/kitty-theme.conf
~/.local/state/theme-manager/tmux-theme.conf
~/.config/vicinae/settings.json
```

`theme-manager.service` restarts when its unit changes. The daemon reloads
`~/.config/theme-manager/config.yaml` on client requests.

## Add Theme Checklist

### 1. Main Theme Map

Edit:

```text
nix/home-manager/configs/shared/theme-configs.nix
```

Add `light` and `dark` entries:

```nix
mytheme = {
  light = {
    scheme = "...";
    wallpaper = ../../../../wallpapers/...;
    vscodeTheme = "...";
    vicinaeTheme = "theme-manager-mytheme-light";
    gtkTheme = "...";
    spicetify = {
      theme = "default";
      colorScheme = "Ocean";
    };
    localChromeExtensions = [];
    chromeExtensions = [];
  };
  dark = {
    scheme = "...";
    wallpaper = ../../../../wallpapers/...;
    vscodeTheme = "...";
    vicinaeTheme = "theme-manager-mytheme-dark";
    gtkTheme = "...";
    spicetify = {
      theme = "default";
      colorScheme = "Ocean";
    };
    localChromeExtensions = [];
    chromeExtensions = [];
  };
};
```

Prefer packaged values:

- `scheme`: use a packaged Base16/Tinted scheme when available.
- `gtkTheme`: use a packaged GTK theme name when available.
- `chromeExtensions`: use Chrome Web Store extension IDs only when the theme exists.
- `localChromeExtensions`: use only for locally packaged Chrome themes registered in `theme-runtime.nix`.
- `spicetify`: use a packaged Spicetify theme if one exists; otherwise map to default.

### 2. Kitty Theme

Edit:

```text
nix/home-manager/configs/theme-runtime.nix
```

Add packaged kitty theme filenames when possible:

```nix
kittyThemes = {
  mytheme = {
    light = "mytheme_light.conf";
    dark = "mytheme_dark.conf";
  };
};
```

Check package contents:

```bash
nix eval --raw nixpkgs#kitty-themes.outPath
ls /nix/store/...-kitty-themes*/share/kitty-themes/themes | rg -i mytheme
```

Only generate local kitty configs when `kitty-themes` does not provide the theme.

### 3. QuickShell Palette

Add files:

```text
nix/quickshell/themes/mytheme-light.json
nix/quickshell/themes/mytheme-dark.json
```

Register names in:

```text
nix/quickshell/Theme.qml
```

Update `resolveThemeName` allowlist:

```qml
["default-dark", "default-light", "catppuccin-dark", "catppuccin-light", "everforest-dark", "everforest-light", "mytheme-dark", "mytheme-light"]
```

QuickShell watches `current-theme-name.txt` and the JSON theme file, so no external reload should be needed beyond the
existing IPC reload.

### 4. Hyprland Palette

Edit:

```text
nix/home-manager/configs/hyprland/lua/theme.lua
```

Add entries for:

```lua
["mytheme-dark"] = { ... }
["mytheme-light"] = { ... }
```

Hyprland reads `current-theme-name.txt` and applies changes from Lua. Keep all Hyprland color data in this Lua file, not
in generated JSON.

### 5. Neovim Theme

Install the package in:

```text
nix/home-manager/configs/nvim.nix
```

Example:

```nix
{
  pkg = everforest;
  dir = "everforest";
}
```

Register the Lazy plugin in:

```text
utilities/nvim/init.lua
```

Example:

```lua
{
  "sainnhe/everforest",
  dir = root .. "/everforest",
  name = "everforest",
  lazy = false,
  priority = 1000,
}
```

Map runtime names in:

```text
utilities/nvim/lua/user/theme.lua
```

Example:

```lua
["mytheme-dark"] = { background = "dark", colorscheme = "mytheme" },
["mytheme-light"] = { background = "light", colorscheme = "mytheme" },
```

Add any theme-specific globals before `vim.cmd.colorscheme`.

### 6. VS Code Theme

Install extension in:

```text
nix/home-manager/configs/vscode.nix
```

Example:

```nix
"sainnhe.everforest"
```

Set theme labels in `theme-configs.nix`:

```nix
vscodeTheme = "Everforest Dark";
```

Labels must match the extension `package.json` exactly:

```bash
jq '.contributes.themes[].label' ~/.vscode/extensions/sainnhe.everforest/package.json
```

Put static extension settings in `vscodeSettings` in `vscode.nix`:

```nix
"everforest.darkContrast" = "hard";
"everforest.lightContrast" = "hard";
```

Home Manager can rewrite VS Code profiles during switch, so `theme-runtime.nix` has `reapplyRuntimeTheme` after
`vscodeProfiles`. Keep it after `vscodeProfiles`; otherwise `settings.json` can drift back to the previous theme.

### 7. Chrome Theme

Add Chrome Web Store extension IDs in `theme-configs.nix`:

```nix
chromeExtensions = [
  "neffpnembhpgfdhfpodffkoefklmodoi"
  "dlcadbmcfambdjhecipbnolmjchgnode"
];
```

`theme-runtime.nix` adds it to `ExtensionInstallForcelist` for that polarity. `theme-manager` copies the generated
policy to:

```text
~/.local/etc/chrome-policy.json
```

Then it refreshes Chrome policy when Chrome is running.

Verify live policy:

```bash
jq '.ExtensionInstallForcelist | contains(["<extension-id>"])' ~/.local/etc/chrome-policy.json
```

For local Chrome themes, add a package under:

```text
nix/home-manager/configs/chrome/themes/
```

Register it in `localChromeThemes` in `theme-runtime.nix`, then list the local name in `localChromeExtensions`.

### 8. GTK Theme

If a GTK package exists, add it to `home.packages` in:

```text
nix/home-manager/configs/theme-runtime.nix
```

Example:

```nix
home.packages = [
  pkgs.everforest-gtk-theme
  pkgs.rose-pine-gtk-theme
];
```

Set `gtkTheme` in `theme-configs.nix`:

```nix
gtkTheme = "Everforest-Dark";
```

Runtime writes:

```bash
dconf write /org/gnome/desktop/interface/color-scheme ...
dconf write /org/gnome/desktop/interface/gtk-theme ...
```

### 9. Vicinae Theme

Prefer a Vicinae bundled theme name when available. Check the active package:

```bash
find $(nix eval --raw ~/dotfiles#homeConfigurations."cunbidun@nixos".config.services.vicinae.package.outPath)/share/vicinae/themes -maxdepth 1 -type f | rg -i mytheme
```

Set in `theme-configs.nix`:

```nix
vicinaeTheme = "mytheme-dark";
```

If Vicinae does not ship the theme, add static TOML files under:

```text
nix/home-manager/configs/vicinae/
```

Register them in `nix/home-manager/configs/vicinae/default.nix`, then use the `theme-manager-*` name in
`theme-configs.nix`.

Runtime runs:

```bash
vicinae theme set <theme>
```

and writes:

```text
~/.config/vicinae/settings.json
```

### 10. CLI Theme

Edit:

```text
nix/home-manager/configs/zsh.nix
```

Add `BAT_THEME` and `FZF_DEFAULT_OPTS` cases for both polarities.

Use packaged `bat` themes when available:

```bash
bat --list-themes | rg -i mytheme
```

If no theme exists, use `base16` or nearest packaged theme. Do not wrap `bat` or `fzf`; the zsh hook updates environment
variables before prompts and commands.

### 11. Tmux Theme

Edit:

```text
nix/home-manager/configs/tmux/default.nix
```

Prefer packaged tmux plugins when possible. Rosé Pine uses `pkgs.tmuxPlugins.rose-pine`; simple themes use local files:

```text
nix/home-manager/configs/tmux/mytheme-light.conf
nix/home-manager/configs/tmux/mytheme-dark.conf
```

Register both as `theme-manager-mytheme-light.conf` and `theme-manager-mytheme-dark.conf`. `theme-manager` copies the
selected file to `~/.local/state/theme-manager/tmux-theme.conf` and sources it into the running tmux server.

### 12. Spotify

Edit:

```text
nix/home-manager/configs/spicetify.nix
```

If a packaged Spicetify theme exists, map it in `theme-configs.nix`. If not, map wrapper cases to default light/dark.

Example fallback:

```bash
mytheme-light) exec ${spotifyPackages.default.light}/share/spotify/spotify "$@" ;;
```

## Verify

Build local Home Manager:

```bash
nix build ~/dotfiles#homeConfigurations."cunbidun@nixos".activationPackage --no-link
```

Switch:

```bash
nix run ~/dotfiles#switch -- nixos --home
```

Check daemon list:

```bash
themectl list-themes
```

Apply theme:

```bash
themectl set-theme mytheme
```

Check generated runtime data:

```bash
jq '.mytheme' ~/.local/state/theme-manager/nix/themes.json
```

Check terminal runtimes:

```bash
readlink -f ~/.local/state/theme-manager/kitty-theme.conf
cat ~/.local/state/theme-manager/tmux-theme.conf
```

Check Vicinae theme:

```bash
jq '.theme.light.name, .theme.dark.name' ~/.config/vicinae/settings.json
```

Check Neovim plugin:

```bash
nvim --headless '+lua assert(require("lazy.core.config").plugins.mytheme)' '+qa'
```

Check VS Code:

```bash
code --list-extensions | rg '<publisher>.<extension>'
jq '.["workbench.colorTheme"]' ~/.config/Code/User/settings.json
```

Check Chrome:

```bash
jq '.ExtensionInstallForcelist | contains(["<extension-id>"])' ~/.local/etc/chrome-policy.json
```

Check current state:

```bash
cat ~/.local/state/theme-manager/current-theme-name.txt
```

## Common Failures

- Theme missing from tray: `~/.config/theme-manager/config.yaml` is old, or old daemon code is still running. Run
  `systemctl --user restart theme-manager.service` once after daemon code changes.
- New QuickShell JSON ignored by Nix: file is untracked. Track it before building through flakes.
- Neovim package installed but theme missing: `nvim.nix` has package, but `utilities/nvim/init.lua` lacks Lazy plugin
  spec.
- VS Code extension installed but wrong theme: `vscodeTheme` label does not match extension `package.json`.
- VS Code switches back after rebuild: `reapplyRuntimeTheme` must run after `vscodeProfiles`.
- Chrome theme not installed: active theme was not reapplied after changing `chromeExtensions`, or live policy does not
  contain the extension ID.
- Chrome policy not refreshed: Chrome process detection may miss unusual launch names; check
  `~/.local/etc/chrome-policy.json` first.
- `bat` has wrong colors: no packaged theme exists; `BAT_THEME` fallback is being used.
