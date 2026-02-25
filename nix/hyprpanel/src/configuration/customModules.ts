import { CustomBarModule } from 'src/components/bar/customModules/types';

export function builtinCustomModules(): Record<string, CustomBarModule> {
    const brightnessGet = `bash -lc '
if ! command -v brightnessctl >/dev/null 2>&1; then
    printf "{\\"percentage\\":0}\\n"
    exit 0
fi

pct="$(brightnessctl --class=backlight -m 2>/dev/null | head -n1 | cut -d, -f4 | tr -d '%')"
if ! printf "%s" "$pct" | grep -Eq "^[0-9]+$"; then
    pct=0
fi
if [ "$pct" -lt 0 ]; then
    pct=0
fi
if [ "$pct" -gt 100 ]; then
    pct=100
fi
printf "{\\"percentage\\":%s}\\n" "$pct"
'`;
    const brightnessIncrease = `bash -lc 'command -v brightnessctl >/dev/null 2>&1 && brightnessctl --class=backlight set +5%'`;
    const brightnessDecrease = `bash -lc 'command -v brightnessctl >/dev/null 2>&1 && brightnessctl --class=backlight set 5%-'`;

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
