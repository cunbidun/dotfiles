{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;

  themeConfigs = import ./shared/theme-configs.nix;
  chromeConfig = import ./shared/chrome-config.nix;

  kittyThemes = {
    catppuccin = {
      light = "Catppuccin-Latte.conf";
      dark = "Catppuccin-Mocha.conf";
    };
  };

  quickshellTheme = theme: polarity:
    lib.importJSON (../../quickshell/themes + "/${theme}-${polarity}.json");

  vicinaeThemeToml = theme: polarity: let
    quickshell = quickshellTheme theme polarity;
    colors = quickshell.colors;
    inherit (quickshell) variant;
    inheritName = if variant == "light" then "vicinae-light" else "vicinae-dark";
  in ''
    [meta]
    name = "Theme Manager ${theme} ${polarity}"
    description = "Generated from theme-manager ${theme}-${polarity} palette"
    variant = "${variant}"
    inherits = "${inheritName}"

    [colors.core]
    accent = "${colors.selectedBackground}"
    accent_foreground = "${colors.selectedForeground}"
    background = "${colors.popupBackground.color}"
    foreground = "${colors.popupText}"
    secondary_background = "${colors.popupElevatedBackground.color}"
    border = "${colors.popupBorder.color}"

    [colors.main_window]
    border = "${colors.popupBorder.color}"
    footer = { background = "${colors.popupSectionBackground.color}" }

    [colors.settings_window]
    border = "${colors.popupBorder.color}"

    [colors.shortcut]
    border = "${colors.popupBorder.color}"

    [colors.text]
    default = "${colors.popupText}"
    muted = "${colors.popupMutedText}"
    danger = "${colors.popupDanger}"
    success = "${colors.popupSuccess}"
    placeholder = "${colors.popupMutedText}"
    selection = { background = "${colors.selectedBackground}", foreground = "${colors.selectedForeground}" }

    [colors.input]
    border = "${colors.popupBorder.color}"
    border_focus = "${colors.selectedBackground}"
    border_error = "${colors.popupDanger}"

    [colors.button.primary]
    background = "${colors.popupElevatedBackground.color}"
    foreground = "${colors.popupText}"
    hover = { background = "${colors.moduleHoverBackground.color}" }
    focus = { outline = "${colors.selectedBackground}" }

    [colors.list.item.hover]
    foreground = "${colors.popupText}"
    secondary_foreground = "${colors.popupMutedText}"

    [colors.list.item.selection]
    background = "${colors.selectedBackground}"
    foreground = "${colors.selectedForeground}"
    secondary_background = "${colors.popupElevatedBackground.color}"
    secondary_foreground = "${colors.popupText}"

    [colors.grid.item]
    background = "${colors.popupElevatedBackground.color}"
    hover = { outline = "${colors.selectedBackground}" }
    selection = { outline = "${colors.selectedBackground}" }

    [colors.scrollbars]
    background = "${colors.popupBorder.color}"

    [colors.loading]
    bar = "${colors.selectedBackground}"
    spinner = "${colors.popupText}"
  '';

  kittyThemeConf = polarity: let
    quickshell = quickshellTheme "default" polarity;
    colors = quickshell.colors;
    ansi = if polarity == "light" then {
      black = "#1D1D1F";
      brightBlack = colors.popupMutedText;
      red = colors.popupDanger;
      brightRed = "#FF6961";
      green = colors.popupSuccess;
      brightGreen = "#30D158";
      yellow = colors.popupWarning;
      brightYellow = "#FFD60A";
      blue = colors.selectedBackground;
      brightBlue = "#0A84FF";
      magenta = "#AF52DE";
      brightMagenta = "#BF5AF2";
      cyan = "#32ADE6";
      brightCyan = "#64D2FF";
      white = "#F5F5F7";
      brightWhite = "#FFFFFF";
    } else {
      black = colors.popupBackground.color;
      brightBlack = colors.popupBorder.color;
      red = colors.popupDanger;
      brightRed = "#FF6961";
      green = colors.popupSuccess;
      brightGreen = "#34C759";
      yellow = colors.popupWarning;
      brightYellow = "#FFE066";
      blue = colors.selectedBackground;
      brightBlue = "#5AC8FA";
      magenta = "#BF5AF2";
      brightMagenta = "#DA8FFF";
      cyan = "#64D2FF";
      brightCyan = "#5AC8FA";
      white = "#D1D1D6";
      brightWhite = colors.popupText;
    };
    backgroundOpacity = "0.75";
  in ''
    # vim:ft=kitty

    ## name: Theme Manager Default ${polarity}
    ## author: cunbidun

    foreground ${colors.popupText}
    background ${colors.popupBackground.color}
    background_opacity ${backgroundOpacity}
    selection_foreground ${colors.selectedForeground}
    selection_background ${colors.selectedBackground}

    cursor ${colors.selectedBackground}
    cursor_text_color ${colors.selectedForeground}

    url_color ${colors.selectedBackground}

    active_tab_foreground ${colors.selectedForeground}
    active_tab_background ${colors.selectedBackground}
    inactive_tab_foreground ${colors.popupMutedText}
    inactive_tab_background ${colors.popupElevatedBackground.color}
    tab_bar_background ${colors.popupBackground.color}

    color0 ${ansi.black}
    color8 ${ansi.brightBlack}

    color1 ${ansi.red}
    color9 ${ansi.brightRed}

    color2 ${ansi.green}
    color10 ${ansi.brightGreen}

    color3 ${ansi.yellow}
    color11 ${ansi.brightYellow}

    color4 ${ansi.blue}
    color12 ${ansi.brightBlue}

    color5 ${ansi.magenta}
    color13 ${ansi.brightMagenta}

    color6 ${ansi.cyan}
    color14 ${ansi.brightCyan}

    color7 ${ansi.white}
    color15 ${ansi.brightWhite}
  '';

  kittyThemeFile = theme: polarity:
    if theme == "default"
    then "${config.home.homeDirectory}/.local/share/theme-manager/kitty/theme-manager-default-${polarity}.conf"
    else "${pkgs.kitty-themes}/share/kitty-themes/themes/${kittyThemes.${theme}.${polarity}}";

  runtimeTheme = theme: polarity: themeConfig: let
    quickshell = quickshellTheme theme polarity;
    colors = quickshell.colors;
    extensionList =
      chromeConfig.baseExtensions
      ++ lib.optional (themeConfig.chromeExtension != null) themeConfig.chromeExtension;
  in
    themeConfig
    // {
      inherit theme polarity extensionList;
      name = "${theme}-${polarity}";
      gtkColorScheme =
        if polarity == "light"
        then "prefer-light"
        else "prefer-dark";
      gtkTheme =
        if polarity == "light"
        then "adw-gtk3"
        else "adw-gtk3-dark";
      kittyTheme = kittyThemeFile theme polarity;
    };

  runtimeThemes = lib.mapAttrs (theme: polarities:
    lib.mapAttrs (polarity: themeConfig: runtimeTheme theme polarity themeConfig) polarities)
  themeConfigs;

  chromePolicyFiles = lib.listToAttrs (lib.flatten (lib.mapAttrsToList (theme: polarities:
    lib.mapAttrsToList (polarity: themeConfig: {
      name = ".local/share/theme-manager/chrome-policy/${theme}-${polarity}.json";
      value.text = chromeConfig.mkChromePolicy runtimeThemes.${theme}.${polarity}.extensionList;
    })
    polarities)
  themeConfigs));

  vicinaeThemeFiles = lib.listToAttrs (lib.mapAttrsToList (polarity: _themeConfig: {
    name = ".local/share/vicinae/themes/theme-manager-default-${polarity}.toml";
    value.text = vicinaeThemeToml "default" polarity;
  })
  themeConfigs.default);

  kittyThemeFiles = lib.listToAttrs (lib.mapAttrsToList (polarity: _themeConfig: {
    name = ".local/share/theme-manager/kitty/theme-manager-default-${polarity}.conf";
    value.text = kittyThemeConf polarity;
  })
  themeConfigs.default);

in {
  config = lib.mkIf isLinux {
    services.theme-manager = {
      enable = true;
      enableTray = true;
      themes = builtins.attrNames themeConfigs;
    };

    home.file = chromePolicyFiles // vicinaeThemeFiles // kittyThemeFiles // {
      ".local/state/theme-manager/nix/themes.json".text = builtins.toJSON runtimeThemes;
    };

  };
}
