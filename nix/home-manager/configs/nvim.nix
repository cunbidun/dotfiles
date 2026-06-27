{
  config,
  hostName,
  lib,
  pkgs,
  userdata,
  ...
}:
let
  inherit (pkgs.stdenv) isLinux;

  terraform-compat = pkgs.writeShellScriptBin "terraform" ''
    exec ${pkgs.opentofu}/bin/tofu "$@"
  '';

  nvim-plugins = with pkgs.vimPlugins; [
    {
      pkg = lazy-nvim;
      dir = "lazy.nvim";
    }
    {
      pkg = LazyVim;
      dir = "LazyVim";
    }
    {
      pkg = snacks-nvim;
      dir = "snacks.nvim";
    }
    {
      pkg = which-key-nvim;
      dir = "which-key.nvim";
    }
    {
      pkg = noice-nvim;
      dir = "noice.nvim";
    }
    {
      pkg = trouble-nvim;
      dir = "trouble.nvim";
    }
    {
      pkg = todo-comments-nvim;
      dir = "todo-comments.nvim";
    }
    {
      pkg = flash-nvim;
      dir = "flash.nvim";
    }
    {
      pkg = ts-comments-nvim;
      dir = "ts-comments.nvim";
    }
    {
      pkg = lazydev-nvim;
      dir = "lazydev.nvim";
    }
    {
      pkg = persistence-nvim;
      dir = "persistence.nvim";
    }
    {
      pkg = tokyonight-nvim;
      dir = "tokyonight.nvim";
    }

    {
      pkg = nvim-lspconfig;
      dir = "nvim-lspconfig";
    }
    {
      pkg = clangd_extensions-nvim;
      dir = "clangd_extensions.nvim";
    }
    {
      pkg = mason-nvim;
      dir = "mason.nvim";
    }
    {
      pkg = mason-lspconfig-nvim;
      dir = "mason-lspconfig.nvim";
    }

    {
      pkg = nvim-treesitter;
      dir = "nvim-treesitter";
    }
    {
      pkg = nvim-treesitter-textobjects;
      dir = "nvim-treesitter-textobjects";
    }
    {
      pkg = nvim-ts-autotag;
      dir = "nvim-ts-autotag";
    }

    {
      pkg = conform-nvim;
      dir = "conform.nvim";
    }
    {
      pkg = nvim-lint;
      dir = "nvim-lint";
    }
    {
      pkg = gitsigns-nvim;
      dir = "gitsigns.nvim";
    }

    {
      pkg = lualine-nvim;
      dir = "lualine.nvim";
    }
    {
      pkg = bufferline-nvim;
      dir = "bufferline.nvim";
    }
    {
      pkg = catppuccin-nvim;
      dir = "catppuccin";
    }
    {
      pkg = everforest;
      dir = "everforest";
    }
    {
      pkg = rose-pine;
      dir = "rose-pine";
    }

    {
      pkg = mini-ai;
      dir = "mini.ai";
    }
    {
      pkg = mini-pairs;
      dir = "mini.pairs";
    }
    {
      pkg = mini-icons;
      dir = "mini.icons";
    }
    {
      pkg = friendly-snippets;
      dir = "friendly-snippets";
    }

    {
      pkg = plenary-nvim;
      dir = "plenary.nvim";
    }
    {
      pkg = nui-nvim;
      dir = "nui.nvim";
    }
    {
      pkg = sqlite-lua;
      dir = "sqlite.lua";
    }
    {
      pkg = grug-far-nvim;
      dir = "grug-far.nvim";
    }
    {
      pkg = render-markdown-nvim;
      dir = "render-markdown.nvim";
    }
    {
      pkg = markdown-preview-nvim;
      dir = "markdown-preview.nvim";
    }

    {
      pkg = nvim-web-devicons;
      dir = "nvim-web-devicons";
    }
    {
      pkg = nvim-autopairs;
      dir = "nvim-autopairs";
    }
    {
      pkg = comment-nvim;
      dir = "comment.nvim";
    }
    {
      pkg = nvim-surround;
      dir = "nvim-surround";
    }

    {
      pkg = blink-cmp;
      dir = "blink.cmp";
    }
    {
      pkg = sidekick-nvim;
      dir = "sidekick.nvim";
    }
    {
      pkg = aw-watcher-nvim;
      dir = "aw-watcher.nvim";
    }
    {
      pkg = vim-dadbod;
      dir = "vim-dadbod";
    }
    {
      pkg = vim-dadbod-completion;
      dir = "vim-dadbod-completion";
    }
    {
      pkg = vim-dadbod-ui;
      dir = "vim-dadbod-ui";
    }
    {
      pkg = venv-selector-nvim;
      dir = "venv-selector.nvim";
    }

    # User-kept extra plugin not provided by LazyVim defaults.
    {
      pkg = vscode-nvim;
      dir = "vscode";
    }
  ];

  treesitter-grammars =
    with pkgs.vimPlugins.nvim-treesitter-parsers;
    [
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
      yaml
    ]
    ++ lib.optionals (pkgs.vimPlugins.nvim-treesitter-parsers ? helm) [
      pkgs.vimPlugins.nvim-treesitter-parsers.helm
    ]
    ++ [ pkgs.tree-sitter-grammars.tree-sitter-norg ];

  formatters = with pkgs; [
    alejandra
    black
    clang-tools
    fish
    gofumpt
    gotools
    markdown-toc
    markdownlint-cli2
    nixfmt
    php84Packages.php-cs-fixer
    prettier
    rustfmt
    shfmt
    sqlfluff
    stylua
    statix
  ];

  lsp-servers = with pkgs; [
    bash-language-server
    clang-tools
    docker-compose-language-service
    gopls
    helm-ls
    lua-language-server
    marksman
    nil
    nixd
    phpactor
    prisma-language-server
    pyright
    ruff
    taplo
    terraform-ls
    vscode-langservers-extracted
    vtsls
    yaml-language-server
  ];

  linters = with pkgs; [
    eslint
    shellcheck
  ];

  tools =
    with pkgs;
    [
      cargo
      gcc
      fd
      fzf
      ghostscript
      lsof
      lua5_1
      luarocks
      mermaid-cli
      nodejs
      opentofu
      ripgrep
      sqlite
      tectonic
      terraform-compat
      tree-sitter
    ]
    ++ lib.optionals isLinux (
      with pkgs;
      [
        wl-clipboard
        xclip
        xsel
      ]
    );

  debug-tools = lib.optionals isLinux (with pkgs; [ gdb ]) ++ [ pkgs.lldb ];

  extractLang =
    grammar:
    let
      name = if grammar ? pname then grammar.pname else grammar.name;
    in
    if lib.hasPrefix "nvim-treesitter-grammar-" name then
      lib.removePrefix "nvim-treesitter-grammar-" name
    else if lib.hasPrefix "vimplugin-treesitter-grammar-" name then
      lib.removePrefix "vimplugin-treesitter-grammar-" name
    else if lib.hasPrefix "tree-sitter-" name then
      lib.removePrefix "tree-sitter-" name
    else
      name;

  neovim-with-packages = pkgs.symlinkJoin {
    name = "neovim-with-packages";
    paths = [ pkgs.nixpkgs-stable.neovim ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.sqlite ]} \
        --prefix PATH : ${lib.makeBinPath (formatters ++ lsp-servers ++ linters ++ tools ++ debug-tools)}
    '';
  };

  local-plugin-dir = pkgs.runCommand "vim-plugins" { } ''
    mkdir -p "$out"

    ${lib.concatMapStrings (plugin: ''
      ln -s "${plugin.pkg}" "$out/${plugin.dir}"
    '') nvim-plugins}

    ${lib.concatMapStrings (grammar: ''
      lang="${extractLang grammar}"
      target="$out/nvim-treesitter-grammar-$lang"

      if [ -f "${grammar}/parser" ]; then
        mkdir -p "$target/parser"
        ln -s "${grammar}/parser" "$target/parser/$lang.so"
      else
        ln -s "${grammar}" "$target"
      fi
    '') treesitter-grammars}
  '';
  nvimConfig =
    if hostName == "nixos"
    then config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/nvim"
    else ../../../utilities/nvim;
in
{
  home.file = {
    ".local/share/vim-plugins".source = local-plugin-dir;
    ".config/nvim".source = nvimConfig;
  };

  home.packages = [ neovim-with-packages ];
}
