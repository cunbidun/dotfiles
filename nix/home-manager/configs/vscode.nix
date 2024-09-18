{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.vscode = {
    enable = true;

    userSettings = {
      "editor.minimap.enabled" = false;
      "editor.fontSize" = 13;
      "explorer.confirmDelete" = false;
      "editor.rulers" = [120];
      "files.saveConflictResolution" = "overwriteFileOnDisk";

      # +--------------+
      # | vim settings |
      # +--------------+
      "vim.handleKeys" = {
        "<C-w>" = false;
        "<C-a>" = false;
        "<C-x>" = false;
        "<C-c>" = false;
        "<C-v>" = false;
        "<C-h>" = false;
        "<C-f>" = false;
        "<C-p>" = false;
        "<C-n>" = false;
      };
      "vim.normalModeKeyBindings" = [
        {
          before = ["<TAB>"];
          commands = ["workbench.action.nextEditor"];
          silent = true;
        }
        {
          before = ["<S-TAB>"];
          commands = ["workbench.action.previousEditor"];
          silent = true;
        }
      ];
      "vim.useSystemClipboard" = true;
      "workbench.colorTheme" =
        if config.lib.stylix.colors.base00 == "2e3440"
        then "Nord"
        else if config.lib.stylix.colors.base00 == "1d2021"
        then "Gruvbox Dark Hard"
        else "Default Dark+";
      "workbench.iconTheme" = "material-icon-theme";
      "terminal.integrated.fontSize" = 13;
    };

    mutableExtensionsDir = false;
    extensions = with pkgs.vscode-extensions; [
      # theme
      arcticicestudio.nord-visual-studio-code
      jdinhlife.gruvbox
      pkief.material-icon-theme

      vscodevim.vim
      ms-vscode-remote.remote-ssh

      # gramma support
      bbenoist.nix

      # linter
      timonwong.shellcheck

      # formatter
      kamadorueda.alejandra
      foxundermoon.shell-format

      # language server
      ms-python.python
    ];
  };
}
