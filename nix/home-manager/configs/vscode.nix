{
  config,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isLinux isDarwin;
in {
  programs.vscode = {
    enable = true;

    keybindings = [
      # +------------+
      # | navigation |
      # +------------+
      {
        "key" = "ctrl+h";
        "command" = "workbench.action.navigateLeft";
      }
      {
        "key" = "ctrl+j";
        "command" = "workbench.action.navigateDown";
      }
      {
        "key" = "ctrl+k";
        "command" = "workbench.action.navigateUp";
      }
      {
        "key" = "ctrl+l";
        "command" = "workbench.action.navigateRight";
      }

      # +----------+
      # | explorer |
      # +----------+
      {
        "key" = "o";
        "command" = "list.select";
        "when" = "filesExplorerFocus && foldersViewVisible && !inputFocus";
      }
      # Pressing "r" will invoke the rename action.
      {
        "key" = "r";
        "command" = "renameFile";
        "when" = "filesExplorerFocus && foldersViewVisible && !explorerResourceIsRoot && !explorerResourceReadonly && !inputFocus";
      }
      # Pressing "v" will open the selected file in a vertical split.
      {
        "key" = "v";
        "command" = "workbench.action.splitEditor";
        "when" = "filesExplorerFocus && foldersViewVisible && !inputFocus";
      }
      # Open in horizontal split
      {
        "key" = "s";
        "command" = "workbench.action.splitEditorDown";
        "when" = "filesExplorerFocus && foldersViewVisible && !inputFocus";
      }
      # Delete file or folder
      {
        "key" = "d";
        "command" = "deleteFile";
        "when" = "filesExplorerFocus && foldersViewVisible && !explorerResourceMoveableToTrash && !explorerResourceReadonly && !inputFocus";
      }
      {
        "key" = "d";
        "command" = "moveFileToTrash";
        "when" = "explorerResourceMoveableToTrash && filesExplorerFocus && foldersViewVisible && !explorerResourceReadonly && !inputFocus";
      }
      # Copy file with "c"
      {
        "key" = "c";
        "command" = "filesExplorer.copy";
        "when" = "filesExplorerFocus && foldersViewVisible && !inputFocus";
      }
      # Cut file with "x" (note: the correct command is "filesExplorer.cut")
      {
        "key" = "x";
        "command" = "filesExplorer.cut";
        "when" = "filesExplorerFocus && foldersViewVisible && !inputFocus";
      }
      # Paste file with "p"
      {
        "key" = "p";
        "command" = "filesExplorer.paste";
        "when" = "filesExplorerFocus && foldersViewVisible && !inputFocus";
      }
      # Create new file (nvim-tree uses "a")
      {
        "key" = "a";
        "command" = "explorer.newFile";
        "when" = "filesExplorerFocus && !inputFocus";
      }
      {
        "key" = "u";
        "command" = "list.focusParent";
        "when" = "filesExplorerFocus && foldersViewVisible && !inputFocus";
      }
      # Refresh explorer
      {
        "key" = "shift+r";
        "command" = "workbench.files.action.refreshFilesExplorer";
        "when" = "filesExplorerFocus && foldersViewVisible && !inputFocus";
      }

      {
        "key" = "alt+cmd+j";
        "command" = "editor.action.insertCursorBelow";
        "when" = "editorTextFocus";
      }

      {
        "key" = "alt+cmd+k";
        "command" = "editor.action.insertCursorAbove";
        "when" = "editorTextFocus";
      }
      {
        "key" = "ctrl+q";
        "command" = "-workbench.action.quickOpenView";
      }
      # +-----------+
      # | searching |
      # +-----------+
      {
        "key" = "ctrl+n";
        "command" = "search.action.focusNextSearchResult";
        "when" = "(hasSearchResult || inSearchEditor) && !inQuickOpen && searchViewletVisible";
      }
      {
        "key" = "ctrl+p";
        "command" = "search.action.focusPreviousSearchResult";
        "when" = "(hasSearchResult || inSearchEditor) && !inQuickOpen && searchViewletVisible";
      }
      {
        "key" = "shift+cmd+r";
        "command" = "workbench.action.replaceInFiles";
        "when" = "(hasSearchResult || inSearchEditor) && !inQuickOpen && searchViewletVisible";
      }
      {
        "key" = "cmd+r";
        "command" = "editor.action.startFindReplaceAction";
        "when" = "editorFocus || editorIsOpen";
      }
      # {
      #   "key" = "alt+cmd+i";
      #   "command" = "search.action.focusFilesToInclude";
      #   "when" = "(hasSearchResult || inSearchEditor) && !inQuickOpen && searchViewletVisible";
      # }
      # {
      #   "key" = "alt+cmd+e";
      #   "command" = "search.action.focusFilesToExclude";
      #   "when" = "(hasSearchResult || inSearchEditor) && !inQuickOpen && searchViewletVisible";
      # }
      # +----------+
      # | terminal |
      # +----------+
      {
        "key" = "ctrl+\\";
        "command" = "workbench.action.terminal.toggleTerminal";
      }
      {
        "key" = "ctrl+shift+q";
        "command" = "workbench.action.terminal.kill";
        "when" = "terminalFocus";
      }
      {
        "key" = "ctrl+`";
        "command" = "workbench.action.terminal.new";
        "when" = "terminalFocus";
      }
      {
        "key" = "ctrl+shift+j";
        "command" = "workbench.action.terminal.focusNext";
        "when" = "terminalFocus";
      }
      {
        "key" = "ctrl+shift+k";
        "command" = "workbench.action.terminal.focusPrevious";
        "when" = "terminalFocus";
      }
      {
        "key" = "ctrl+shift+h";
        "command" = "workbench.action.terminal.focusPreviousPane";
        "when" = "terminalFocus";
      }
      {
        "key" = "ctrl+shift+l";
        "command" = "workbench.action.terminal.focusNextPane";
        "when" = "terminalFocus";
      }
    ];
    userSettings = {
      "editor.minimap.enabled" = false;
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
      "vim.easymotion" = true;
      "vim.easymotionMarkerBackgroundColor" = "#7e57c2";
      "vim.leader" = " ";
      # Define a non-recursive normal-mode mapping: pressing <leader> then e runs
      # the command to toggle the sidebar (which in this case is used to show or hide the Explorer)
      "vim.normalModeKeyBindingsNonRecursive" = [
        {
          before = ["<leader>" "e"];
          commands = ["workbench.action.toggleSidebarVisibility"];
        }
      ];
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
        {
          before = ["<leader>" "m"];
          after = ["<leader>" "<leader>"];
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
      "editor.fontSize" =
        if isLinux
        then 13
        else 12;
      "terminal.integrated.fontSize" =
        if isLinux
        then 13
        else 12;

      "editor.fontFamily" = "SFMono Nerd Font";
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
        github.copilot
        github.copilot-chat

        bazelbuild.vscode-bazel

        james-yu.latex-workshop
        streetsidesoftware.code-spell-checker
      ]
      # per os extension
      ++ (
        if isLinux
        then [ms-vscode.cpptools]
        else []
      )
      # example of downloading extensions that's not in nixpackge
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "jupyter";
          publisher = "ms-toolsai";
          version = "2024.8.1";
          sha256 = "sha256-eFInKB1xwVVJFIsXHxsuRJeLKTe3Cb8svquHJOW0P+I=";
        }
      ];
  };
}
