{
  pkgs,
  lib,
  ...
}: let
  nvim-plugin-list = with pkgs.vimPlugins; [
    bufdelete-nvim
    nvim-autopairs
    nvim-surround
    gitsigns-nvim
    indent-blankline-nvim
    neo-tree-nvim
    bufferline-nvim
    conform-nvim
    which-key-nvim
    comment-nvim
    toggleterm-nvim
    telescope-nvim
    lspkind-nvim
    cmp-nvim-lsp
    nvim-lspconfig
    nui-nvim
    plenary-nvim
    nvim-web-devicons
    nvim-cmp
    nvim-treesitter
    lualine-nvim
    lazydev-nvim
    vscode-nvim # theme
    lazy-nvim
    mini-icons
    luasnip
  ];

  treesitter-grammars = with pkgs.vimPlugins.nvim-treesitter-parsers; [
    bash
    lua
    python
    nix
    c
    cpp
  ];

  formatters = with pkgs; [
    stylua
    clang-tools
    shfmt
    black
    alejandra
  ];

  lsp-servers = with pkgs; [
    nixd
    pyright
    lua-language-server
    bash-language-server
  ];

  linters = with pkgs; [
    ruff
  ];

  extra-packages = with pkgs; [
    lua51Packages.luarocks
    lua51Packages.lua
  ];

  # Function to extract language name from grammar package name
  extractLang = grammar: let
    # Remove "vimplugin-treesitter-grammar-" prefix
    withoutPrefix = lib.removePrefix "vimplugin-treesitter-grammar-" grammar.name;
  in
    withoutPrefix;

  local-plugin-dir = pkgs.runCommand "vim-plugins" {} ''
    mkdir -p $out

    # Regular plugins
    ${lib.concatMapStrings (plugin: ''
        ln -s "${plugin}" "$out/${plugin.pname}"
      '')
      nvim-plugin-list}

    # Treesitter grammars
    ${lib.concatMapStrings (grammar: ''
        lang="${extractLang grammar}"
        ln -s "${grammar}" "$out/nvim-treesitter-grammar-$lang"
      '')
      treesitter-grammars}
  '';
in {
  home.file.".local/share/vim-plugins".source = local-plugin-dir;
  home.packages = formatters ++ lsp-servers ++ linters ++ extra-packages;
}
