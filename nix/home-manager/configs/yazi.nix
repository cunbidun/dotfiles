{
  inputs,
  lib,
  pkgs,
  ...
}: {
  programs.yazi = {
    package = inputs.yazi.packages.${pkgs.stdenv.hostPlatform.system}.default;
    shellWrapperName = "y";
    enableZshIntegration = true;
    enable = true;
    settings = {
      log = {
        enabled = false;
      };
      manager = {
        show_hidden = true;
        sort_by = "mtime";
        sort_dir_first = true;
        sort_reverse = true;
      };
      plugin = {
        prepend_fetchers = [
          {
            id = "git";
            name = "*";
            run = "git";
          }
          {
            id = "git";
            name = "*/";
            run = "git";
          }
        ];
      };
      # "plugin.prepend_fetchers" = {
      #   id = "git";
      #   name = "*/";
      #   run = "git";
      # };
      opener = {
        play =
          lib.singleton
          {
            run = "xdg-open \"$@\"";
            orphan = true;
            desc = "Open";
          };
      };
    };
    initLua = ''
      require("full-border"):setup()
      -- +-----+
      -- | git |
      -- +-----+
      require("git"):setup()

      -- +---------+
      -- | restore |
      -- +---------+
      require("restore"):setup({
        -- Set the position for confirm and overwrite dialogs.
        -- don't forget to set height: `h = xx`
        -- https://yazi-rs.github.io/docs/plugins/utils/#ya.input
        position = { "center", w = 70, h = 40 }, -- Optional

        -- Show confirm dialog before restore.
        -- NOTE: even if set this to false, overwrite dialog still pop up
        show_confirm = true,  -- Optional

        -- colors for confirm and overwrite dialogs
        theme = { -- Optional
          -- Default using style from your flavor or theme.lua -> [confirm] -> title.
          -- If you edit flavor or theme.lua you can add more style than just color.
          -- Example in theme.lua -> [confirm]: title = { fg = "blue", bg = "green"  }
          title = "blue", -- Optional. This valid has higher priority than flavor/theme.lua

          -- Default using style from your flavor or theme.lua -> [confirm] -> content
          -- Sample logic as title above
          header = "green", -- Optional. This valid has higher priority than flavor/theme.lua

          -- header color for overwrite dialog
          -- Default using color "yellow"
          header_warning = "yellow", -- Optional
          -- Default using style from your flavor or theme.lua -> [confirm] -> list
          -- Sample logic as title and header above
          list_item = { odd = "blue", even = "blue" }, -- Optional. This valid has higher priority than flavor/theme.lua
          },
      })

      -- +-------+
      -- | bunny |
      -- +-------+
      require("bunny"):setup({
        hops = {
          -- competitive programming
          { key = "c",          path = "~/competitive_programming/output/",       desc = "competitive_programming/output"   },
          { key = "t",          path = "~/Project/trading/",                      desc = "trading project"                  },
          { key = "r",          path = "/",                                                                                 },
          -- home
          { key = { "h", "h" }, path = "~",                                       desc = "Home"                             },
          { key = { "h", "d" }, path = "~/Downloads/",                            desc = "Downloads"                        },
          { key = { "h", "c" }, path = "~/.config",                               desc = "Config files"                     },
          -- local
          { key = { "l", "s" }, path = "~/.local/share",                          desc = "Local share"                      },
          { key = { "l", "b" }, path = "~/.local/bin",                            desc = "Local bin"                        },
          { key = { "l", "t" }, path = "~/.local/state",                          desc = "Local state"                      },
          -- key and path attributes are required, desc is optional
        },
        desc_strategy = "path", -- If desc isn't present, use "path" or "filename", default is "path"
        notify = false, -- Notify after hopping, default is false
        fuzzy_cmd = "fzf", -- Fuzzy searching command, default is "fzf"
      })
    '';
    keymap = {
      manager.prepend_keymap = [
        {
          on = "u";
          run = "plugin restore";
          desc = "Restore last deleted files/folders";
        }
        {
          on = "`";
          desc = "Start bunny.yazi";
          run = "plugin bunny";
        }
        {
          on = ["c" "m"];
          run = "plugin chmod";
          desc = "Chmod on selected files";
        }
      ];
    };
    plugins = {
      restore = inputs.yazi-restore;
      bunny = inputs.yazi-bunny;

      git = "${inputs.yazi-plugins}/git.yazi";
      full-border = "${inputs.yazi-plugins}/full-border.yazi";
      chmod = "${inputs.yazi-plugins}/chmod.yazi";
    };
  };
}
