{
  config,
  lib,
  pkgs,
  userdata,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;

  nvim-plugin-list = with pkgs.vimPlugins; [
    lazy-nvim

    # Navigation and search
    flash-nvim

    # File explorer and buffers
    bufdelete-nvim
    nvim-web-devicons
    mini-icons

    # Editing
    nvim-autopairs
    nvim-surround
    comment-nvim

    # UI
    lualine-nvim
    which-key-nvim
    indent-blankline-nvim
    nui-nvim
    sqlite-lua

    # Git
    gitsigns-nvim

    # LSP, completion, treesitter, formatting
    blink-cmp
    conform-nvim
    nvim-treesitter

    # Terminal and agents
    toggleterm-nvim
    sidekick-nvim
    snacks-nvim
    aw-watcher-nvim

    # Themes
    vscode-nvim
    catppuccin-nvim
  ];

  treesitter-grammars = with pkgs.vimPlugins.nvim-treesitter-parsers; [
    bash
    css
    lua
    html
    javascript
    latex
    python
    nix
    regex
    scss
    svelte
    tsx
    typst
    vue
    c
    cpp
  ] ++ [pkgs.tree-sitter-grammars.tree-sitter-norg];

  formatters = with pkgs; [
    alejandra
    black
    clang-tools
    rustfmt
    shfmt
    stylua
  ];

  lsp-servers = with pkgs; [
    bash-language-server
    clang-tools
    lua-language-server
    nil
    nixd
    pyright
    ruff
  ];

  linters = with pkgs; [
    eslint
    shellcheck
  ];

  tools = with pkgs; [
    cargo
    fd
    fzf
    ghostscript
    lsof
    lua5_1
    luarocks
    mermaid-cli
    ripgrep
    sqlite
    tectonic
    tree-sitter
    copilot-language-server
  ] ++ lib.optionals isLinux (with pkgs; [
    wl-clipboard
    xclip
    xsel
  ]);

  debug-tools = lib.optionals isLinux (with pkgs; [gdb]) ++ [pkgs.lldb];

  extractLang = grammar: let
    name = if grammar ? pname then grammar.pname else grammar.name;
  in
    if lib.hasPrefix "nvim-treesitter-grammar-" name
    then lib.removePrefix "nvim-treesitter-grammar-" name
    else if lib.hasPrefix "vimplugin-treesitter-grammar-" name
    then lib.removePrefix "vimplugin-treesitter-grammar-" name
    else if lib.hasPrefix "tree-sitter-" name
    then lib.removePrefix "tree-sitter-" name
    else name;

  neovim-with-packages = pkgs.symlinkJoin {
    name = "neovim-with-packages";
    paths = [pkgs.neovim];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.sqlite]} \
        --prefix PATH : ${lib.makeBinPath (formatters ++ lsp-servers ++ linters ++ tools ++ debug-tools)}
    '';
  };

  local-plugin-dir = pkgs.runCommand "vim-plugins" {} ''
    mkdir -p "$out"

    ${lib.concatMapStrings (plugin: ''
        ln -s "${plugin}" "$out/${plugin.pname}"
      '')
      nvim-plugin-list}

    ${lib.concatMapStrings (grammar: ''
        lang="${extractLang grammar}"
        target="$out/nvim-treesitter-grammar-$lang"

        if [ -f "${grammar}/parser" ]; then
          mkdir -p "$target/parser"
          ln -s "${grammar}/parser" "$target/parser/$lang.so"
        else
          ln -s "${grammar}" "$target"
        fi
      '')
      treesitter-grammars}
  '';
in {
  home.file = {
    ".local/share/vim-plugins".source = local-plugin-dir;
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/nvim";
  };

  home.packages = [neovim-with-packages];

  home.activation.updateNvimTheme = lib.mkIf isLinux ''
    shopt -s nullglob
    if [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
      for addr in "''${XDG_RUNTIME_DIR}"/nvim.*; do
        /etc/profiles/per-user/${userdata.username}/bin/nvim --server "$addr" --remote-expr "luaeval('pcall(function() require(\"user.theme\").apply() end) or \"\"')" || true
      done
    fi
  '';
}
