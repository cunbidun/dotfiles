{ inputs, pkgs, ... }:
let
  icons = {
    ActiveLSP = "";
    ActiveTS = "";
    ArrowLeft = "";
    ArrowRight = "";
    Bookmarks = "";
    BufferClose = "󰅖";
    DapBreakpoint = "";
    DapBreakpointCondition = "";
    DapBreakpointRejected = "";
    DapLogPoint = "󰛿";
    DapStopped = "󰁕";
    Debugger = "";
    DefaultFile = "󰈙";
    Diagnostic = "󰒡";
    DiagnosticError = "";
    DiagnosticHint = "󰌵";
    DiagnosticInfo = "󰋼";
    DiagnosticWarn = "";
    Ellipsis = "…";
    Environment = "";
    FileNew = "";
    FileModified = "";
    FileReadOnly = "";
    FoldClosed = "";
    FoldOpened = "";
    FoldSeparator = " ";
    FolderClosed = "";
    FolderEmpty = "";
    FolderOpen = "";
    Git = "󰊢";
    GitAdd = "";
    GitBranch = "";
    GitChange = "";
    GitConflict = "";
    GitDelete = "";
    GitIgnored = "◌";
    GitRenamed = "➜";
    GitSign = "▎";
    GitStaged = "✓";
    GitUnstaged = "✗";
    GitUntracked = "★";
    LSPLoading1 = "";
    LSPLoading2 = "󰀚";
    LSPLoading3 = "";
    MacroRecording = "";
    Package = "󰏖";
    Paste = "󰅌";
    Refresh = "";
    Search = "";
    Selected = "❯";
    Session = "󱂬";
    Sort = "󰒺";
    Spellcheck = "󰓆";
    Tab = "󰓩";
    TabClose = "󰅙";
    Terminal = "";
    Window = "";
    WordFile = "󰈭";
  };
in
{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];
  programs.nixvim = {
    extraPackages = with pkgs; [
      clang-tools
    ];
    enable = true;
    colorschemes.vscode.enable = true;

    globals = {
      mapleader = " ";
    };

    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };

    opts = {
      updatetime = 100; # Faster completion

      # Line numbers
      relativenumber = true; # Relative line numbers
      number = true; # Display the absolute line number of the current line
      hidden = true; # Keep closed buffer open in the background
      mouse = "a"; # Enable mouse control
      mousemodel = "extend"; # Mouse right-click extends the current selection
      splitbelow = true; # A new window is put below the current one
      splitright = true; # A new window is put right of the current one

      swapfile = false; # Disable the swap file
      modeline = true; # Tags such as 'vim:ft=sh'
      modelines = 100; # Sets the type of modelines
      undofile = true; # Automatically save and restore undo history
      incsearch = true; # Incremental search: show match for partly typed search command
      inccommand = "split"; # Search and replace: preview changes in quickfix list
      ignorecase = true; # When the search query is lower-case, match both lower and upper-case
      #   patterns
      smartcase = true; # Override the 'ignorecase' option if the search pattern contains upper
      #   case characters
      scrolloff = 8; # Number of screen lines to show around the cursor
      cursorline = false; # Highlight the screen line of the cursor
      cursorcolumn = false; # Highlight the screen column of the cursor
      signcolumn = "yes"; # Whether to show the signcolumn
      colorcolumn = "120"; # Columns to highlight
      laststatus = 3; # When to use a status line for the last window
      fileencoding = "utf-8"; # File-content encoding for the current buffer
      termguicolors = true; # Enables 24-bit RGB color in the |TUI|
      spell = false; # Highlight spelling mistakes (local to window)
      wrap = false; # Prevent text from wrapping

      # Tab options
      tabstop = 2; # Number of spaces a <Tab> in the text stands for (local to buffer)
      shiftwidth = 2; # Number of spaces used for each step of (auto)indent (local to buffer)
      expandtab = true; # Expand <Tab> to spaces in Insert mode (local to buffer)
      autoindent = true; # Do clever autoindenting

      textwidth = 0; # Maximum width of text that is being inserted.  A longer line will be
      #   broken after white space to get this width.
      # Folding
      foldlevel = 99; # Folds with a level higher than this number will be closed
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>lua require('nvim-tree.api').tree.toggle()<CR>";
        options.desc = "Toggle Tree";
      }
      {
        mode = "n";
        key = "<TAB>";
        action = ":BufferLineCycleNext<CR>";
      }
      {
        mode = "n";
        key = "<S-TAB>";
        action = ":BufferLineCyclePrev<CR>";
      }
      {
        mode = "n";
        key = "<S-x>";
        action = ":Bdelete<CR>";
      }
      # +-------------------------+
      # | competitive programming |
      # +-------------------------+
      {
        mode = "n";
        key = "<leader>cb";
        action = "<cmd>Runscript<cr>";
        options.desc = "Build and Run";
      }
      {
        mode = "n";
        key = "<leader>cr";
        action = "<cmd>RunWithTerm<cr>";
        options.desc = "Build and Run in Terminal";
      }
      {
        mode = "n";
        key = "<leader>cd";
        action = "<cmd>RunWithDebug<cr>";
        options.desc = "Build and Run in Debug Mode";
      }
      {
        mode = "n";
        key = "<leader>ct";
        action = "<cmd>TaskConfig<cr>";
        options.desc = "Edit Task Info";
      }
      {
        mode = "n";
        key = "<leader>ca";
        action = "<cmd>ArchiveTask<cr>";
        options.desc = "Archive Task";
      }
      {
        mode = "n";
        key = "<leader>cn";
        action = "<cmd>NewTask<cr>";
        options.desc = "New Task";
      }
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
      }
      {
        mode = "t";
        key = "<C-h>";
        action = "<C-\\><C-N><C-w>h";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-\\><C-N><C-w>j";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-\\><C-N><C-w>l";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-\\><C-N><C-w>k";
      }
    ];

    # +------+
    # | misc |
    # +------+
    plugins.vim-bbye.enable = true; # for delete buffer
    plugins.nvim-ufo.enable = true; # for folding
    plugins.surround.enable = true;
    plugins.comment.enable = true;
    plugins.nvim-autopairs.enable = true;
    plugins.nvim-colorizer.enable = true;
    # +-------------+
    # | indentation | 
    # +-------------+
    plugins.indent-blankline = {
      enable = true;
      settings = {
        indent = {
          char = "│";
        };
        scope = {
          show_start = false;
          show_end = false;
          show_exact_scope = true;
        };
        exclude = {
          buftypes = [ "terminal" "nofile" ];
          filetypes = [
            "help"
            "alpha"
            "dashboard"
            "neo-tree"
            "Trouble"
            "trouble"
            "lazy"
            "mason"
            "notify"
            "toggleterm"
            "lazyterm"
          ];
        };
      };
    };

    # +-------------+
    # | status line |
    # +-------------+
    plugins.lualine = {
      enable = true;
      globalstatus = true;
    };

    # +----------+
    # | terminal |
    # +----------+
    plugins.toggleterm = {
      enable = true;
      settings =
        {
          open_mapping = "[[<C-\\>]]";
          terminal_mappings = true;
          insert_mappings = true;
          direction = "float";
          float_opts = {
            border = "single";
          };
          size = ''
            function (term)
              if term.direction == "horizontal" then
                return 15
              elseif term.direction == "vertical" then
                return math.min(120, math.max(vim.o.columns - 130, 35))
              else
                return 20
              end
            end
          '';
        };
    };
    # +-----+
    # | git |
    # +-----+
    plugins.gitsigns = {
      enable = true;
      settings = {
        # Show line blame with custom text
        current_line_blame = true;
        current_line_blame_formatter = " <author>, <author_time:%R> – <summary>";
        current_line_blame_formatter_nc = " Uncommitted";
        current_line_blame_opts.ignore_whitespace = true;

        # Use same icon for all signs (only color matters)
        signs = {
          add.text = icons.GitSign;
          change.text = icons.GitSign;
          changedelete.text = icons.GitSign;
          delete.text = icons.GitSign;
          topdelete.text = icons.GitSign;
          untracked.text = icons.GitSign;
        };
      };
    };
    # +---------------+
    # | file explorer |
    # +---------------+
    plugins.nvim-tree = {
      enable = true;
      git = {
        enable = true;
        ignore = false;
      };
      openOnSetup = true;
      renderer.indentWidth = 1;
      diagnostics.enable = true;
      view = {
        width = 30;
        cursorline = true;
        float = {
          enable = false;
          quitOnFocusLoss = true;
        };
      };
      updateFocusedFile.enable = true;
    };
    # +-----+
    # | lsp |
    # +-----+
    plugins.lsp = {
      enable = true;
      keymaps = {
        silent = true;
        lspBuf = {
          "<F2>" = "rename";
        };
      };
      servers = {
        clangd.enable = true;
        lua-ls.enable = true;
        nixd.enable = true;
      };
    };
    # +-----------+
    # | telescope |
    # +-----------+
    plugins.telescope = {
      enable = true;
      keymaps = {
        "<leader>f" = "find_files";
        "<leader>t" = "live_grep";
      };
      settings.defaults = {
        file_ignore_patterns = [
          "^.git/"
          "^.mypy_cache/"
          "^__pycache__/"
          "^output/"
          "^data/"
          "%.ipynb"
        ];
        set_env.COLORTERM = "truecolor";
        mappings = {
          i = {
            "<C-j>".__raw = "require('telescope.actions').move_selection_next";
            "<C-k>".__raw = "require('telescope.actions').move_selection_previous";
          };
        };
      };
    };
    # +------------+
    # | treesitter |
    # +------------+
    plugins.treesitter = {
      enable = true;
      indent = true;
      folding = true;
    };
    # +----------+
    # | task bar |
    # +----------+
    plugins.bufferline = {
      enable = true;
    };
    # +-----------+
    # | formatter |
    # +-----------+
    plugins.conform-nvim = {
      enable = true;
      formattersByFt = {
        c = [ "clang-format" ];
        cpp = [ "clang-format" ];
      };
      formatOnSave = {
        lspFallback = true;
        timeoutMs = 500;
      };
    };
    # +------------+
    # | completion |
    # +------------+
    opts.completeopt = [ "menu" "menuone" "noselect" ];
    plugins = {
      luasnip.enable = true;

      lspkind = {
        enable = true;

        cmp = {
          enable = true;
          menu = {
            nvim_lsp = "[LSP]";
            nvim_lua = "[api]";
            path = "[path]";
            luasnip = "[snip]";
            buffer = "[buffer]";
          };
        };
      };
      cmp = {
        enable = true;
        settings = {
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
          mapping = {
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
          };
          sources = [
            { name = "path"; }
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            {
              name = "buffer";
              option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
            }
          ];
        };
      };
    };
    # +-----------+
    # | which key |
    # +-----------+
    plugins.which-key = {
      enable = true;
      registrations = {
        "<leader>c" = "Competitive Programming";
      };
    };
    plugins.project-nvim = {
      enable = true;
      enableTelescope = true;
    };
    highlight = {
      IblScope.fg = "#606060";
      IblIndent.fg = "#3E3E3E";
    };
    extraConfigLua = ''
      vim.cmd([[source $HOME/.config/lvim/cp.vim]])
    '';
  };
}