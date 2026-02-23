import { CustomBarModule } from 'src/components/bar/customModules/types';

export function builtinCustomModules(): Record<string, CustomBarModule> {
    const brightnessGet = `bash -lc '
brightness_cmd="$HYPRPANEL_BRIGHTNESS_CONTROL"
if [ -z "$brightness_cmd" ]; then
    brightness_cmd="brightness-control"
fi
if ! ([ -x "$brightness_cmd" ] || command -v "$brightness_cmd" >/dev/null 2>&1); then
    printf "{\\"percentage\\":0}\\n"
    exit 0
fi

out="$("$brightness_cmd" get 2>/dev/null || "$brightness_cmd" get json 2>/dev/null || true)"
if printf "%s" "$out" | grep -Eq "^[0-9]+$"; then
    pct="$out"
else
    pct="$(printf "%s" "$out" | sed -nE "s/.*\\"percentage\\"[[:space:]]*:[[:space:]]*([0-9]+).*/\\1/p" | head -n1)"
    if ! printf "%s" "$pct" | grep -Eq "^[0-9]+$"; then
        pct=0
    fi
fi
if [ "$pct" -lt 0 ]; then
    pct=0
fi
if [ "$pct" -gt 100 ]; then
    pct=100
fi
printf "{\\"percentage\\":%s}\\n" "$pct"
'`;
    const brightnessIncrease = `bash -lc 'brightness_cmd="$HYPRPANEL_BRIGHTNESS_CONTROL"; if [ -z "$brightness_cmd" ]; then brightness_cmd="brightness-control"; fi; if [ -x "$brightness_cmd" ] || command -v "$brightness_cmd" >/dev/null 2>&1; then "$brightness_cmd" increase 5; fi'`;
    const brightnessDecrease = `bash -lc 'brightness_cmd="$HYPRPANEL_BRIGHTNESS_CONTROL"; if [ -z "$brightness_cmd" ]; then brightness_cmd="brightness-control"; fi; if [ -x "$brightness_cmd" ] || command -v "$brightness_cmd" >/dev/null 2>&1; then "$brightness_cmd" decrease 5; fi'`;

    return {
        'custom/brightness': {
            execute: brightnessGet,
            signalPath: '/tmp/hyprpanel/brightness.signal',
            executeOnAction: brightnessGet,
            interval: 2,
            label: '{percentage}%',
            icon: ['󰃞', '󰃟', '󰃠', '󰃝'],
            actions: {
                onScrollUp: brightnessIncrease,
                onScrollDown: brightnessDecrease,
            },
        },
    };
}
