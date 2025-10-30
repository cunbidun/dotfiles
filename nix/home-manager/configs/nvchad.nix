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
    extraConfig = let
      cpLua = builtins.readFile ../../../utilities/nvim/lua/user/config/cp.lua;
      cpLuaIndented =
        "        "
        + builtins.replaceStrings ["\n"] ["\n        "] cpLua;
    in ''
      -- Lua LSP configurations
      vim.lsp.config.luals = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".luarc.json", ".luarc.jsonc" },
        settings = {
          Lua = {
            workspace = {
              library = { vim.env.VIMRUNTIME },
            },
          },
        },
      }

      -- C/C++ Language Server configuration
      vim.lsp.config.clangd = {
        cmd = { "clangd", "--background-index" },
        root_markers = { "compile_commands.json", "compile_flags.txt" },
        filetypes = { "c", "cpp" },
      }

      vim.lsp.config.nixd = {
        cmd = { "nixd" },
        root_markers = { "flake.nix", "default.nix", "shell.nix" },
        filetypes = { "nix" },
        settings = {
          nix = {
            format = {
              enable = true,
            },
          },
        },
      }

      vim.diagnostic.config({ virtual_lines = true })
      vim.lsp.enable({ "luals", "nil_ls", "nixd", "pyright", "ruff", "bashls", "clangd" })

      -- C/C++ Auto-formatting configuration
      local conform = require("conform")
      conform.setup({
        formatters_by_ft = {
          c = { "clang-format" },
          cpp = { "clang-format" },
          h = { "clang-format" },
          hpp = { "clang-format" },
        },
        formatters = {
          ["clang-format"] = {
            command = "clang-format",
            args = { "--style=file" },
          },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })

      -- Conditional competitive programming configuration
      if vim.env.CP_ENV then
${cpLuaIndented}
      end
    '';
    backup = true;
    hm-activation = true;
  };
}
