{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  nvim-plugin-list = with pkgs; [
    vimPlugins.bufdelete-nvim
    vimPlugins.nvim-autopairs
    vimPlugins.nvim-surround
    vimPlugins.gitsigns-nvim
    vimPlugins.indent-blankline-nvim
    vimPlugins.neo-tree-nvim
    vimPlugins.bufferline-nvim
    vimPlugins.conform-nvim
    vimPlugins.which-key-nvim
    vimPlugins.comment-nvim
    vimPlugins.toggleterm-nvim
    vimPlugins.telescope-nvim
    vimPlugins.nvim-cmp
    vimPlugins.nvim-treesitter
    vimPlugins.lualine-nvim
  ];

  treesitter-grammars = with pkgs.vimPlugins.nvim-treesitter-parsers; [
    bash
    lua
    python
    nix
    c
    cpp
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
}
