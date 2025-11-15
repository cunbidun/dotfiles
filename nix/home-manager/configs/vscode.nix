{
  pkgs,
  inputs,
  ...
}: let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv) isLinux isDarwin;
  vscodeVersion = pkgs.nixpkgs-master.vscode;
  # Common keybindings for both platforms
  commonKeybindings = [
    # Navigation keys
    {
      command = "workbench.action.navigateLeft";
      key = "ctrl+h";
    }
    {
      command = "workbench.action.navigateDown";
      key = "ctrl+j";
    }
    {
      command = "workbench.action.navigateUp";
      key = "ctrl+k";
    }
    {
      command = "workbench.action.navigateRight";
      key = "ctrl+l";
    }

    # Explorer Tree
    {
      command = "list.select";
      key = "o";
      when = "filesExplorerFocus && foldersViewVisible && !inputFocus";
    }
    {
      command = "renameFile";
      key = "r";
      when = "filesExplorerFocus && foldersViewVisible && !explorerResourceIsRoot && !explorerResourceReadonly && !inputFocus";
    }
    {
      command = "workbench.action.splitEditor";
      key = "v";
      when = "filesExplorerFocus && foldersViewVisible && !inputFocus";
    }
    {
      command = "workbench.action.splitEditorDown";
      key = "s";
      when = "filesExplorerFocus && foldersViewVisible && !inputFocus";
    }
    {
      command = "deleteFile";
      key = "d";
      when = "filesExplorerFocus && foldersViewVisible && !explorerResourceMoveableToTrash && !explorerResourceReadonly && !inputFocus";
    }
    {
      command = "moveFileToTrash";
      key = "d";
      when = "explorerResourceMoveableToTrash && filesExplorerFocus && foldersViewVisible && !explorerResourceReadonly && !inputFocus";
    }
    {
      command = "filesExplorer.copy";
      key = "c";
      when = "filesExplorerFocus && foldersViewVisible && !inputFocus";
    }
    {
      command = "copyRelativeFilePath";
      key = "shift+c";
      when = "filesExplorerFocus && foldersViewVisible && !inputFocus";
    }
    {
      command = "filesExplorer.cut";
      key = "x";
      when = "filesExplorerFocus && foldersViewVisible && !inputFocus";
    }
    {
      command = "filesExplorer.paste";
      key = "p";
      when = "filesExplorerFocus && foldersViewVisible && !inputFocus";
    }
    {
      command = "explorer.newFile";
      key = "a";
      when = "filesExplorerFocus && !inputFocus";
    }
    {
      command = "list.focusParent";
      key = "u";
      when = "filesExplorerFocus && foldersViewVisible && !inputFocus";
    }
    {
      command = "workbench.files.action.refreshFilesExplorer";
      key = "shift+r";
      when = "filesExplorerFocus && foldersViewVisible && !inputFocus";
    }
    {
      key = "space e";
      command = "workbench.action.focusActiveEditorGroup";
      when = "sideBarFocus && activeViewlet == 'workbench.view.explorer'";
    }

    # Multi cursor
    {
      command = "editor.action.insertCursorBelow";
      key = "alt+cmd+j";
      when = "editorTextFocus";
    }
    {
      command = "editor.action.insertCursorAbove";
      key = "alt+cmd+k";
      when = "editorTextFocus";
    }

    # Search & Replace
    {
      command = "search.action.focusNextSearchResult";
      key = "ctrl+n";
      when = "(hasSearchResult || inSearchEditor) && !inQuickOpen && searchViewletVisible && !suggestWidgetVisible";
    }
    {
      command = "search.action.focusPreviousSearchResult";
      key = "ctrl+p";
      when = "(hasSearchResult || inSearchEditor) && !inQuickOpen && searchViewletVisible && !suggestWidgetVisible";
    }
    {
      command = "workbench.action.replaceInFiles";
      key = "shift+cmd+r";
      when = "(hasSearchResult || inSearchEditor) && !inQuickOpen && searchViewletVisible && !suggestWidgetVisible";
    }
    {
      key = "ctrl+n";
      command = "selectNextCodeAction";
      when = "codeActionMenuVisible";
    }
    {
      key = "ctrl+p";
      command = "selectPrevCodeAction";
      when = "codeActionMenuVisible";
    }
    {
      key = "ctrl+n";
      command = "workbench.action.quickOpenSelectNext";
      when = "inQuickOpen";
    }
    {
      key = "ctrl+p";
      command = "workbench.action.quickOpenSelectPrevious";
      when = "inQuickOpen";
    }

    # Terminal
    {
      command = "workbench.action.terminal.toggleTerminal";
      key = "ctrl+\\";
    }
    {
      command = "workbench.action.terminal.kill";
      key = "ctrl+shift+q";
      when = "terminalFocus";
    }
    {
      command = "workbench.action.terminal.new";
      key = "ctrl+`";
      when = "terminalFocus";
    }
    {
      command = "workbench.action.terminal.focusNext";
      key = "ctrl+shift+j";
      when = "terminalFocus";
    }
    {
      command = "workbench.action.terminal.focusPrevious";
      key = "ctrl+shift+k";
      when = "terminalFocus";
    }
    {
      command = "workbench.action.terminal.focusPreviousPane";
      key = "ctrl+shift+h";
      when = "terminalFocus";
    }
    {
      command = "workbench.action.terminal.focusNextPane";
      key = "ctrl+shift+l";
      when = "terminalFocus";
    }
    {
      key = "escape";
      command = "notebook.cell.quitEdit";
      when = "inputFocus && notebookEditorFocused && vim.active && !editorHasMultipleSelections && !editorHasSelection && !editorHoverVisible && vim.mode == 'Normal'";
    }
    {
      key = "escape";
      command = "flash-vscode.exit";
      when = "notebookEditorFocused && flash-vscode.active";
    }
  ];

  # Linux-only keybindings
  linuxKeybindings = [
    {
      command = "workbench.action.files.newUntitledFile";
      key = "alt+n";
    }
    {
      key = "alt+d";
      command = "editor.action.addSelectionToNextFindMatch";
    }
    {
      key = "alt+f";
      command = "actions.find";
      when = "editorFocus || editorIsOpen";
    }
    {
      key = "alt+shift+p";
      command = "workbench.action.showCommands";
    }
    {
      key = "alt+s";
      command = "workbench.action.files.save";
    }
    {
      key = "alt+p";
      command = "workbench.action.quickOpen";
    }
    {
      key = "alt+c";
      command = "editor.action.clipboardCopyAction";
    }
    {
      key = "alt+x";
      command = "editor.action.clipboardCutAction";
    }
    {
      key = "alt+v";
      command = "editor.action.clipboardPasteAction";
    }
    {
      key = "alt+z";
      command = "undo";
    }
    {
      key = "alt+,";
      command = "workbench.action.openSettings";
    }
    {
      key = "alt+w";
      command = "workbench.action.closeActiveEditor";
    }
    {
      key = "alt+a";
      command = "editor.action.selectAll";
    }
    {
      key = "alt+shift+f";
      command = "workbench.action.findInFiles";
    }
    {
      key = "alt+shift+f";
      command = "workbench.view.search";
      when = "workbench.view.search.active && neverMatch =~ /doesNotMatch/";
    }
    {
      key = "alt+shift+e";
      command = "workbench.view.explorer";
      when = "viewContainer.workbench.view.explorer.enabled";
    }
    {
      key = "alt+shift+e";
      command = "workbench.action.quickOpenNavigatePreviousInFilePicker";
      when = "inFilesPicker && inQuickOpen";
    }
    {
      key = "alt+shift+t";
      command = "workbench.action.reopenClosedEditor";
    }
    {
      key = "alt+f";
      command = "workbench.action.terminal.focusFind";
      when = "(terminalFindFocused && terminalHasBeenCreated || terminalFindFocused && terminalProcessSupported || terminalFocusInAny && terminalHasBeenCreated || terminalFocusInAny && terminalProcessSupported)";
    }
    {
      key = "alt+.";
      command = "problems.action.showQuickFixes";
      when = "problemFocus";
    }
    {
      key = "alt+.";
      command = "editor.action.quickFix";
      when = "editorHasCodeActionsProvider && textInputFocus && !editorReadonly";
    }
    {
      key = "alt+c";
      command = "workbench.action.terminal.copySelection";
      when = "terminalFocus";
    }
    {
      key = "alt+v";
      command = "workbench.action.terminal.paste";
      when = "terminalFocus";
    }
    {
      key = "alt+r";
      command = "editor.action.startFindReplaceAction";
      when = "editorFocus || editorIsOpen";
    }

    # Copilot keybindings for Linux
    {
      key = "alt+i";
      command = "inlineChat.start";
      when = "inlineChatHasEditsAgent && inlineChatPossible && !editorReadonly && !editorSimpleInput || editorFocus && inlineChatHasProvider && inlineChatPossible && !editorReadonly && !editorSimpleInput";
    }
    {
      key = "alt+i";
      command = "workbench.action.terminal.chat.start";
      when = "chatIsEnabled && terminalChatAgentRegistered && terminalFocusInAny && terminalHasBeenCreated || chatIsEnabled && terminalChatAgentRegistered && terminalFocusInAny && terminalProcessSupported";
    }

    # SQL Tools for Linux
    {
      key = "alt+e alt+e";
      command = "sqltools.executeQuery";
      when = "editorHasSelection && editorTextFocus && !config.sqltools.disableChordKeybindings";
    }
    {
      key = "ctrl+e ctrl+e";
      command = "-sqltools.executeQuery";
      when = "editorTextFocus && !config.sqltools.disableChordKeybindings";
    }
    {
      key = "alt+\\";
      command = "workbench.action.terminal.split";
      when = "(terminalFocus && terminalProcessSupported || terminalFocus && terminalWebExtensionContributedProfile)";
    }

    # Notebook keybindings for Linux
    {
      key = "alt+enter";
      command = "-notebook.cell.executeAndInsertBelow";
      when = "notebookCellListFocused && notebookCellType == 'markup' || notebookCellListFocused && notebookMissingKernelExtension && !notebookCellExecuting && notebookCellType == 'code' || notebookCellListFocused && !notebookCellExecuting && notebookCellType == 'code' && notebookKernelCount > 0 || notebookCellListFocused && !notebookCellExecuting && notebookCellType == 'code' && notebookKernelSourceCount > 0";
    }
    {
      key = "alt+enter";
      command = "notebook.cell.execute";
      when = "(notebookMissingKernelExtension && !notebookCellExecuting && notebookCellType == 'code' || notebookCellListFocused && !notebookCellExecuting && notebookCellType == 'code' && notebookKernelCount > 0 || notebookCellListFocused && !notebookCellExecuting && notebookCellType == 'code' && notebookKernelSourceCount > 0)";
    }
  ];

  # macOS-only keybindings
  macKeybindings = [
    {
      key = "cmd+r";
      command = "editor.action.startFindReplaceAction";
      when = "editorFocus || editorIsOpen";
    }
  ];
in {
  programs.vscode = {
    enable = true;
    package = vscodeVersion;
    mutableExtensionsDir = false;

    profiles.default = {
      keybindings =
        commonKeybindings
        ++ (
          if isLinux
          then linuxKeybindings
          else []
        )
        ++ (
          if isDarwin
          then macKeybindings
          else []
        );

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
        "window.autoDetectColorScheme" = lib.mkIf isDarwin true;
        "[python]".editor.defaultFormatter = "ms-python.black-formatter";
        "cSpell.userWords" = [
          "opensearch"
          "opensearchservice"
          "openserach"
          "powertools"
        ];
        "chat.tools.autoApprove" = true;
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
        "everforest.darkContrast" = "hard";
        "everforest.darkWorkbench" = "flat";
      };
      # to search extensions: https://nix-community.github.io/nix4vscode/
      extensions = pkgs.nix4vscode.forVscodeVersion "1.106.0-20251103" [
        "sainnhe.everforest"
        "activitywatch.aw-watcher-vscode"
        "arcticicestudio.nord-visual-studio-code"
        "bazelbuild.vscode-bazel"
        "bbenoist.nix"
        "catppuccin.catppuccin-vsc"
        "charliermarsh.ruff"
        "cunbidun.flash-vscode"
        "foxundermoon.shell-format"
        "github.copilot"
        "github.copilot-chat"
        "github.vscode-pull-request-github"
        "james-yu.latex-workshop"
        "kamadorueda.alejandra"
        "ms-python.black-formatter"
        "ms-python.debugpy"
        "ms-python.isort"
        "ms-python.python"
        "ms-python.vscode-pylance"
        "ms-python.vscode-python-envs"
        "ms-toolsai.datawrangler"
        "ms-toolsai.jupyter"
        "ms-toolsai.jupyter-keymap"
        "ms-toolsai.jupyter-renderers"
        "ms-toolsai.vscode-jupyter-cell-tags"
        "ms-toolsai.vscode-jupyter-slideshow"
        "ms-vscode-remote.remote-ssh"
        "ms-vscode-remote.remote-ssh-edit"
        "ms-vscode.cpptools"
        "ms-vscode.remote-explorer"
        "pkief.material-icon-theme"
        "streetsidesoftware.code-spell-checker"
        "tamasfe.even-better-toml"
        "timonwong.shellcheck"
        "vscodevim.vim"
        "akamud.vscode-theme-onedark"
        "akamud.vscode-theme-onelight"
        "huytd.nord-light"
        "MS-vsliveshare.vsliveshare"
      ];
    };
  };
}
