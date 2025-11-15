{
  inputs,
  config,
  pkgs,
  lib,
  userdata,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;
in {
  imports = [
    inputs.nix4nvchad.homeManagerModule
  ];

  programs.nvchad = {
    enable = true;
    extraPackages = with pkgs; [
      # Language Servers
      nil # Nix LS
      nixd # Nix language server
      lua-language-server # Lua LS
      python3 # Python
      nodePackages.bash-language-server # Bash LS
      clang-tools # C/C++ LSP
      cargo # Rust

      # Formatters
      stylua # Lua formatter
      black # Python formatter
      rustfmt # Rust formatter
      alejandra # Nix formatter

      # Linters & Tools
      eslint # JavaScript/TypeScript linter
      shellcheck # Shell script linter
      ripgrep # Better grep
      fd # Better find
      fzf # Fuzzy finder

      # Debugging
      lldb # LLDB debugger
      gdb # GDB debugger
    ];

    extraPlugins = ''
      return {
        ${builtins.readFile ../../../utilities/nvim/lua/user/plugins/terminal.lua},
        ${builtins.readFile ../../../utilities/nvim/lua/user/plugins/flash.lua},
        ${builtins.readFile ../../../utilities/nvim/lua/user/plugins/aw-awatcher.lua},
        ${builtins.readFile ../../../utilities/nvim/lua/user/plugins/nvim-surround.lua},
        ${builtins.readFile ../../../utilities/nvim/lua/user/plugins/sidekick.lua},
      }
    '';

    chadrcConfig = ''
      local M = {}
      M.base46 = {
        theme = "vscode_dark";
      }
      return M
    '';

    extraConfig = ''
      ${builtins.readFile ../../../utilities/nvim/lua/user/config/lsp.lua}
      ${builtins.readFile ../../../utilities/nvim/lua/user/config/keymaps.lua}
      ${builtins.readFile ../../../utilities/nvim/lua/user/config/conform.lua}
      if vim.env.CP_ENV then
        ${builtins.readFile ../../../utilities/nvim/lua/user/config/cp.lua}
      end
    '';
    backup = true;
    hm-activation = true;
  };

  home.activation.updateNvimTheme = lib.mkIf isLinux ''
    shopt -s nullglob
    # check if XDG_RUNTIME_DIR is set before using it
    if [ -n "$XDG_RUNTIME_DIR" ]; then
      for addr in "$XDG_RUNTIME_DIR"/nvim.*; do
        /etc/profiles/per-user/${userdata.username}/bin/nvim --server "$addr" --remote-expr "luaeval('require(\"nvchad.utils\").reload() or \"\"')" || true
      done
    else
      echo "XDG_RUNTIME_DIR is not set; skipping Neovim theme update."
    fi
  '';
}
