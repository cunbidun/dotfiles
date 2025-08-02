{pkgs, ...}: let
  inherit (pkgs.stdenv) isLinux isDarwin;
in {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    profiles.default = {
      userSettings = {
        "editor.fontFamily" = "SFMono Nerd Font";
        "editor.minimap.enabled" = false;
        "editor.rulers" = [120];
        "files.saveConflictResolution" = "overwriteFileOnDisk";
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "vim.leader" = " ";
        "vim.handleKeys" = {
          "J" = false;
          "gJ" = false;
        };
        "vim.normalModeKeyBindings" = [
          {
            before = ["<TAB>"];
            commands = ["workbench.action.nextEditorInGroup"];
            silent = true;
          }
          {
            before = ["<S-TAB>"];
            commands = ["workbench.action.previousEditorInGroup"];
            silent = true;
          }
          {
            before = ["<S-x>"];
            commands = ["workbench.action.closeActiveEditor"];
            silent = true;
          }
        ];
        "vim.normalModeKeyBindingsNonRecursive" = [
          {
            before = ["<leader>" "b"];
            commands = ["workbench.action.toggleSidebarVisibility"];
          }
          {
            before = ["<leader>" "e"];
            commands = ["workbench.files.action.showActiveFileInExplorer"];
          }
          {
            before = ["s"];
            commands = ["flash-vscode.start"];
          }
          {
            before = ["S"];
            commands = ["flash-vscode.startSelection"];
          }
          {
            before = ["<BS>"];
            commands = ["flash-vscode.backspace"];
          }
          {
            before = ["<C-o>"];
            commands = ["workbench.action.navigateBack"];
            silent = true;
          }
        ];
        "vim.useSystemClipboard" = true;
        "flash-vscode.caseSensitive" = false;
        "workbench.iconTheme" = "material-icon-theme";
        "explorer.confirmDragAndDrop" = false;
        "files.exclude" = {
          "**/__pycache__" = true;
          "**/.pytest_cache" = true;
        };
        "[python]".editor.defaultFormatter = "ms-python.black-formatter";
        "cSpell.userWords" = [
          "opensearch"
          "opensearchservice"
          "openserach"
          "powertools"
        ];
        "black-formatter.args" = ["--line-length" "120"];
        "window.customMenuBarAltFocus" = false;
        "window.enableMenuBarMnemonics" = false;
        "diffEditor.hideUnchangedRegions.enabled" = true;
        "json.format.keepLines" = true;
        "[jsonc]".editor.formatOnSave = true;
        "github.copilot.enable" = {
          "*" = true;
          plaintext = false;
          markdown = true;
          scminput = false;
        };
        "python.languageServer" = "Default";
        "python.pyrefly.disableLanguageServices" = true;
        "security.workspace.trust.untrustedFiles" = "open";
        "terminal.integrated.enableMultiLinePasteWarning" = "never";
        "git.blame.editorDecoration.enabled" = true;
        "explorer.confirmDelete" = false;
        "accessibility.dimUnfocused.enabled" = true;
      };

      extensions = with pkgs.vscode-extensions;
        [
          # theme
          arcticicestudio.nord-visual-studio-code
          pkief.material-icon-theme
          catppuccin.catppuccin-vsc

          # navigation
          vscodevim.vim

          # remote
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-ssh-edit
          ms-vscode.remote-explorer

          # nix
          kamadorueda.alejandra
          bbenoist.nix

          # shell
          timonwong.shellcheck
          foxundermoon.shell-format

          # latex
          james-yu.latex-workshop

          # python
          ms-python.debugpy
          # ms-python.python
          ms-python.vscode-pylance
          ms-python.isort
          ms-python.black-formatter
          ms-python.flake8

          # jupyter
          ms-toolsai.jupyter
          ms-toolsai.jupyter-keymap
          ms-toolsai.jupyter-renderers
          ms-toolsai.vscode-jupyter-cell-tags
          ms-toolsai.vscode-jupyter-slideshow
          ms-toolsai.datawrangler
          github.vscode-pull-request-github

          # AI
          github.copilot
          github.copilot-chat

          # Build tools
          bazelbuild.vscode-bazel

          # Mics
          streetsidesoftware.code-spell-checker
        ]
        # per os extension
        ++ (
          if isLinux
          then [
            ms-vscode.cpptools
          ]
          else []
        )
        # example of downloading extensions that's not in nixpackge
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "aw-watcher-vscode";
            publisher = "ActivityWatch";
            version = "0.5.0";
            sha256 = "sha256-OrdIhgNXpEbLXYVJAx/jpt2c6Qa5jf8FNxqrbu5FfFs=";
          }
          {
            name = "flash-vscode";
            publisher = "cunbidun";
            version = "0.0.9";
            sha256 = "sha256-hZ1QPSOvlaG9SyQ2NWbe9Xv1l6UdVqYmt7ifJE8yxtg=";
          }
          # TODO: move back to the packaged extensions above
          {
            name = "python";
            publisher = "ms-python";
            version = "2025.11.2025072501";
            sha256 = "sha256-A24xf51GqtzKhgrigkOtcQqKQa+aFCajxaWxiL6fMfM=";
          }
        ];
    };
    mutableExtensionsDir =
      if isLinux
      then false
      else true;
  };
}
