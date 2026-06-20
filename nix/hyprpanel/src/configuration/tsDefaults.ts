const tsDefaults: Record<string, unknown> = {
    bar: {
        workspaces: {
            ignored: '-\\d+',
            numbered_active_indicator: 'highlight',
            show_icons: false,
            show_numbered: false,
            showWsIcons: true,
            workspaceIconMap: {
                '1': 'SYS',
                '2': '2',
                '3': '3',
                '4': '4',
                '5': 'WEB',
                '6': 'VN',
                '7': 'Q&Q',
                '8': 'GAME',
                '9': 'VI',
            },
            workspaces: 9,
            spacing: 1,
        },
        autoHide: 'never',
        notifications: {
            show_total: false,
            hideCountWhenZero: true,
        },
        media: {
            show_label: true,
        },
        launcher: {
            icon: '',
        },
        layouts: {
            '0': {
                left: ['workspaces', 'hyprlayout', 'submap', 'windowtitle'],
                middle: [],
                right: [
                    'systray',
                    'separator',
                    'dashboard',
                    'separator',
                    'notifications',
                    'clock',
                ],
            },
        },
        volume: {
            label: false,
        },
        network: {
            truncation_size: 15,
            label: false,
        },
        bluetooth: {
            label: false,
        },
        clock: {
            showIcon: false,
            showTime: true,
            format: '%a %b %-d %I:%M %p',
        },
        customModules: {
            submap: {
                label: true,
                showSubmapName: true,
                enabledIcon: '󰌐',
                disabledIcon: '󰌌',
                enabledText: 'Submap On',
                disabledText: 'Submap Off',
            },
            hyprlayout: {
                label: true,
                icon: '󰙀',
            },
        },
    },
    menus: {
        clock: {
            time: {
                hideSeconds: false,
                military: false,
            },
            weather: {
                enabled: true,
                location: '10001',
                unit: 'metric',
                key: '/etc/hyprpanel/weather_api_key',
            },
        },
        media: {
            displayTime: false,
        },
        volume: {
            raiseMaximumVolume: true,
        },
        dashboard: {
            shortcuts: {
                left: {
                    shortcut1: {
                        command: 'google-chrome-stable',
                        tooltip: 'Chromium',
                    },
                    shortcut4: {
                        command: 'vicinae dmenu-apps',
                    },
                },
            },
        },
    },
    theme: {
        shared: {
            radius: '0.4em',
        },
        bar: {
            transparent: false,
            floating: false,
            enableShadow: false,
            outer_spacing: '0.5em',
            border: {
                width: '0em',
            },
            buttons: {
                padding_x: '0.6rem',
                padding_y: '0em',
                y_margins: '0.1em',
                separator: {
                    margins: '0.25em',
                    width: '0.08em',
                },
                workspaces: {
                    enableBorder: false,
                    numbered_active_highlight_padding: '0.4em',
                    numbered_inactive_padding: '0.4em',
                    fontSize: '1em',
                },
                media: {
                    enableBorder: false,
                },
                windowtitle: {
                    spacing: '1em',
                },
                modules: {
                    hypridle: {
                        spacing: '0.5em',
                    },
                },
            },
            menus: {
                border: {
                    size: '0em',
                },
            },
        },
        font: {
            name: 'SFMono Nerd Font',
            label: 'SFMono Nerd Font',
            size: '13px',
            weight: '400',
            style: 'normal',
        },
        notification: {},
        osd: {
            orientation: 'horizontal',
            location: 'top right',
            margins: '0.8em 12em 0 0',
        },
    },
};

export default tsDefaults;
