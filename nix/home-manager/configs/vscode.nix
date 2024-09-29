{
  config,
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
        if config.lib.stylix.scheme.scheme-name == "Nord"
        then "Nord"
        else if config.lib.stylix.scheme.scheme-name == "Gruvbox dark, hard"
        then "Gruvbox Dark Hard"
        else if config.lib.stylix.scheme.scheme-name == "Gruvbox light, hard"
        then "Gruvbox Light Hard"
        else if builtins.elem config.lib.stylix.scheme.scheme-name ["Default Dark" "standardized-dark"]
        then "Default Dark Modern"
        else "Default Light Modern";
      "workbench.iconTheme" = "material-icon-theme";
      "terminal.integrated.fontSize" = 13;
      "explorer.confirmDragAndDrop" = false;
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
      ms-python.vscode-pylance
      ms-python.isort
      ms-python.black-formatter
      ms-toolsai.jupyter

      james-yu.latex-workshop
    ];
    # example of downloading extensions that's not in nixpackge
    # ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    #   {
    #     name = "glassit";
    #     publisher = "s-nlf-fh";
    #     version = "0.2.6";
    #     sha256 = "sha256-LcAomgK91hnJWqAW4I0FAgTOwr8Kwv7ZhvGCgkokKuY=";
    #   }
    # ];
  };
}
