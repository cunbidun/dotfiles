{
  pkgs,
  lib,
  ...
}: let
  nvim-plugin-list = with pkgs.vimPlugins; [
    # -------------------------------------------------------------------
    # File Explorer Plugins
    # -------------------------------------------------------------------
    neo-tree-nvim # A modern file explorer tree for Neovim.
    nvim-tree-lua # A lightweight file tree for Neovim implemented in Lua.

    # -------------------------------------------------------------------
    # Git Integration
    # -------------------------------------------------------------------
    gitsigns-nvim # Displays Git change signs in the gutter for a better VCS workflow.

    # -------------------------------------------------------------------
    # LSP and Completion Ecosystem
    # -------------------------------------------------------------------
    nvim-lspconfig # Quickstart configurations for Neovim’s built-in LSP client.
    cmp-nvim-lsp # LSP source for nvim-cmp, enhancing completion capabilities.
    nvim-cmp # A powerful autocompletion plugin for Neovim.
    luasnip # A snippet engine for Neovim written in Lua.
    lspkind-nvim # Adds VSCode-like icons to LSP completions for better visual cues.
    lspsaga-nvim
    # trouble-nvim # Provides a pretty list for diagnostics, references, and quickfixes.

    # -------------------------------------------------------------------
    # Fuzzy Finder and Searching
    # -------------------------------------------------------------------
    telescope-nvim # An extendable fuzzy finder over lists (files, buffers, etc.) for Neovim.
    nvim-spectre # find and replace

    # -------------------------------------------------------------------
    # Syntax Highlighting and Treesitter
    # -------------------------------------------------------------------
    nvim-treesitter # Enhanced syntax highlighting and code understanding using Treesitter.

    # -------------------------------------------------------------------
    # Buffer Management and Editing Enhancements
    # -------------------------------------------------------------------
    bufdelete-nvim # Allows deleting buffers without messing up the window layout.
    nvim-autopairs # Automatically inserts matching brackets, quotes, and more.
    nvim-surround # Provides convenient mappings to add, change, or delete surrounding characters.
    comment-nvim # Simplifies commenting out code with easy keybindings.

    # -------------------------------------------------------------------
    # UI Enhancements
    # -------------------------------------------------------------------
    bufferline-nvim # Renders buffers as a tab-like line for easy navigation.
    lualine-nvim # A fast and easy-to-configure status line plugin.
    nvim-web-devicons # Supplies filetype icons for improved UI appearance.
    mini-icons # Offers a minimal set of icons to further enhance the Neovim interface.

    # -------------------------------------------------------------------
    # Visual Guides and Indentation
    # -------------------------------------------------------------------
    indent-blankline-nvim # Displays indentation levels with subtle vertical lines.

    # -------------------------------------------------------------------
    # Terminal Integration
    # -------------------------------------------------------------------
    toggleterm-nvim # Easily toggles terminal windows within Neovim.

    # -------------------------------------------------------------------
    # Keybinding Helpers
    # -------------------------------------------------------------------
    which-key-nvim # Pops up a list of available keybindings to help discover shortcuts.

    # -------------------------------------------------------------------
    # Code Formatting
    # -------------------------------------------------------------------
    conform-nvim # A code formatter that integrates with various formatters for Neovim.

    # -------------------------------------------------------------------
    # Utility Libraries and Development Tools
    # -------------------------------------------------------------------
    plenary-nvim # A collection of Lua functions that many other plugins depend on.
    nui-nvim # A library of UI components to help build Neovim plugins.

    # -------------------------------------------------------------------
    # Themes and Appearance
    # -------------------------------------------------------------------
    vscode-nvim # A theme for Neovim inspired by Visual Studio Code aesthetics.

    # -------------------------------------------------------------------
    # Plugin Management and Lazy Loading
    # -------------------------------------------------------------------
    lazy-nvim # Facilitates lazy loading of plugins to optimize startup time.
    lazydev-nvim # Tools to assist with development using lazy.nvim.
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
