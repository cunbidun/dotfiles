{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
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
    backup = true;
    hm-activation = true;
  };
}
