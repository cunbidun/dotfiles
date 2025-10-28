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
    extraConfig = ''
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
      local function TermWrapper(command)
        vim.cmd("wa")
        local function get_terminal_buffers()
          local buffers = vim.api.nvim_list_bufs()
          local terminal_buffers = {}

          for _, buf in ipairs(buffers) do
          if vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
              table.insert(terminal_buffers, buf)
          end
        end
        return terminal_buffers
      end
      -- Conditional competitive programming configuration
      if vim.env.CP_ENV then
        print("loading cp.lua")


        local buf_id = get_terminal_buffers()
        if #buf_id > 0 then
            vim.cmd(string.format("%sbdelete!", buf_id[1]))
        end

        vim.cmd(string.format("TermExec direction=vertical cmd='%s'", command))
        end

        vim.api.nvim_create_user_command("Runscript", function()
          TermWrapper(string.format('clear; cpcli_app task --root-dir="%s" --build', vim.fn.expand("%:p:h")))
        end, {})

        vim.api.nvim_create_user_command("RunWithDebug", function()
          TermWrapper(string.format('clear; cpcli_app task --root-dir="%s" --build-with-debug', vim.fn.expand("%:p:h")))
        end, {})

        vim.api.nvim_create_user_command("RunWithTerm", function()
          TermWrapper(string.format('clear; cpcli_app task --root-dir="%s" --build-with-term', vim.fn.expand("%:p:h")))
        end, {})

        vim.api.nvim_create_user_command("TaskConfig", function()
          TermWrapper(string.format('clear; cpcli_app task --root-dir="%s" --edit-problem-config', vim.fn.expand("%:p:h")))
        end, {})

        vim.api.nvim_create_user_command("ArchiveTask", function()
          TermWrapper(string.format('clear; cpcli_app task --root-dir="%s" --archive', vim.fn.expand("%:p:h")))
        end, {})

        vim.api.nvim_create_user_command("NewTask", function()
          TermWrapper("clear; cpcli_app project --new-task")
        end, {})

        vim.api.nvim_create_user_command("DeleteTask", function()
          TermWrapper(string.format('mv "%s" ~/.local/share/Trash/files/', vim.fn.expand("%:p:h")))
        end, {})

        local binds = {
          { action = "<cmd>Runscript<cr>", key = "<leader>cb", mode = "n", desc = "Build and Run" },
          { action = "<cmd>RunWithTerm<cr>", key = "<leader>cr", mode = "n", desc = "Build and Run in Terminal" },
          { action = "<cmd>RunWithDebug<cr>", key = "<leader>cd", mode = "n", desc = "Build and Run in Debug Mode" },
          { action = "<cmd>TaskConfig<cr>", key = "<leader>ct", mode = "n", desc = "Edit Task Info" },
          { action = "<cmd>ArchiveTask<cr>", key = "<leader>ca", mode = "n", desc = "Archive Task" },
          { action = "<cmd>TaskFiles<CR>", key = "<leader>cf", mode = "n", desc = "Find Task Files" },
          { action = "<cmd>NewTask<cr>", key = "<leader>cn", mode = "n", desc = "New Task" },
        }

        for _, map in ipairs(binds) do
          vim.keymap.set(map.mode, map.key, map.action, map.options)
        end

        local function find_task_files()
        require("telescope.builtin").find_files({
            prompt_title = "Task Files",
            find_command = {
            "find",
            "task",
            "-type",
            "f",
            "!",
            "-name",
            "*.json",
            "!",
            "-path",
            "*.dSYM*",
            "!",
            "-name",
            ".gitkeep",
            },
        })
        end

        -- Create command
        vim.api.nvim_create_user_command("TaskFiles", find_task_files, {})
      end
    '';
    backup = true;
    hm-activation = true;
  };
}
