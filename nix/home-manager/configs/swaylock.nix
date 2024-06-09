{ color-scheme, ... }: {
  settings = ''
    clock
    screenshots
    indicator
    indicator-radius=100
    indicator-thickness=10
    indicator-caps-lock
    effect-blur=7x5
    effect-vignette=0.5:0.5
    grace=0
    fade-in=0.2
    line-uses-inside
    font=SFMono Nerd Font
    font-size=20
    ring-color=${color-scheme.blue}
    ring-ver-color=${color-scheme.blue}
    ring-clear-color=${color-scheme.blue}
    ring-caps-lock-color=${color-scheme.blue}
    ring-wrong-color=${color-scheme.blue}
    key-hl-color=${color-scheme.magenta}
    bs-hl-color=${color-scheme.red}
    separator-color=${color-scheme.fg}
    inside-color=${color-scheme.fg}
    inside-caps-lock-color=${color-scheme.fg}
    inside-clear-color=${color-scheme.fg}
    inside-ver-color=${color-scheme.green}
    inside-wrong-color=${color-scheme.fg}
    text-color=${color-scheme.bg}
    text-clear-color=${color-scheme.bg}
    text-caps-lock-color=${color-scheme.orange}
    text-ver-color=${color-scheme.bg}
    text-wrong-color=${color-scheme.red}
  '';
}
