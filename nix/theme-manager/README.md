# theme-manager

Internal theme management daemon and CLI for dotfiles.

## CLI (themectl)

Subcommands:

```
themectl get-theme         # Print current theme
themectl list-themes       # List available themes
themectl set-theme <name>  # Set theme (must be in list)
themectl get-nvim-theme    # Resolve current Neovim colorscheme (theme+polarity)
themectl set-polarity <dark|light>  # Force polarity via darkman
```

Polarity is managed externally by `darkman`; the daemon exposes GET/SET and toggle logic so scripts (e.g. `theme-switch`) can coordinate theme + polarity changes cleanly.