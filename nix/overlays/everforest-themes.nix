final: prev: let
  everforest-dark = prev.writeText "everforest-dark.yaml" ''
    system: "base16"
    name: "Everforest Dark"
    author: "Sainnhe Park (https://github.com/sainnhe)"
    variant: "dark"
    palette:
      base00: "#272e33" # bg0,       palette1 hard dark
      base01: "#2e383c" # bg1,       palette1 hard dark
      base02: "#414b50" # bg3,       palette1 hard dark
      base03: "#859289" # grey1,     palette2 dark
      base04: "#9da9a0" # grey2,     palette2 dark
      base05: "#d3c6aa" # fg,        palette2 dark
      base06: "#e6e2cc" # bg3,       palette1 light
      base07: "#fdf6e3" # bg0,       palette1 light
      base08: "#e67e80" # red,       palette2 dark
      base09: "#e69875" # orange,    palette2 dark
      base0A: "#dbbc7f" # yellow,    palette2 dark
      base0B: "#a7c080" # green,     palette2 dark
      base0C: "#83c092" # aqua,      palette2 dark
      base0D: "#7fbbb3" # blue,      palette2 dark
      base0E: "#d699b6" # purple,    palette2 dark
      base0F: "#9da9a0" # grey2,     palette2 dark
  '';

  everforest-light = prev.writeText "everforest-light.yaml" ''
    system: "base16"
    name: "Everforest Light"
    author: "Sainnhe Park (https://github.com/sainnhe)"
    variant: "light"
    palette:
      base00: "#f8f0dc" # bg0,       palette1 hard light
      base01: "#f0e9d2" # bg1,       palette1 hard light
      base02: "#e8ddc7" # bg3,       palette1 hard light
      base03: "#a6b0a0" # grey1,     palette2 light
      base04: "#939f91" # grey2,     palette2 light
      base05: "#5c6a72" # fg,        palette2 light
      base06: "#414b50" # bg3,       palette1 hard dark
      base07: "#272e33" # bg0,       palette1 hard dark
      base08: "#f85552" # red,       palette2 light
      base09: "#f57d26" # orange,    palette2 light
      base0A: "#dfa000" # yellow,    palette2 light
      base0B: "#8da101" # green,     palette2 light
      base0C: "#35a77c" # aqua,      palette2 light
      base0D: "#3a94c5" # blue,      palette2 light
      base0E: "#df69ba" # purple,    palette2 light
      base0F: "#939f91" # grey2,     palette2 light
  '';
in {
  base16-schemes = prev.base16-schemes.overrideAttrs (oldAttrs: {
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
        # Add custom Everforest themes
        cp ${everforest-dark} $out/share/themes/everforest-dark.yaml
        cp ${everforest-light} $out/share/themes/everforest-light.yaml
      '';
  });
}
