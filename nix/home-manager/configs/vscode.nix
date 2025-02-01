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
      "cloudcode.duetAI.project" = "test-api-moel";
      "terminal.integrated.defaultProfile.linux" = "zsh";
    };

    mutableExtensionsDir = false;
    extensions = with pkgs.vscode-extensions;
      [
        # theme
        arcticicestudio.nord-visual-studio-code
        jdinhlife.gruvbox
        pkief.material-icon-theme

        vscodevim.vim
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-containers

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

        ms-vscode.cpptools

        bazelbuild.vscode-bazel

        james-yu.latex-workshop
        streetsidesoftware.code-spell-checker
      ]
      # example of downloading extensions that's not in nixpackge
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "jupyter";
          publisher = "ms-toolsai";
          version = "2024.8.1";
          sha256 = "sha256-eFInKB1xwVVJFIsXHxsuRJeLKTe3Cb8svquHJOW0P+I=";
        }
        {
          name = "cloudcode";
          publisher = "GoogleCloudTools";
          version = "2.17.0";
          sha256 = "sha256-ZN4ZVl5WE32sHAfqAz0+vxTYBp6iJxAjvsXNJahrGY0=";
        }
      ];
  };
}
