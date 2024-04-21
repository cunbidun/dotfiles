
const hyprland = await Service.import("hyprland")
const apps = await Service.import("applications")


function isMinimized(client) {
    return client.workspace.name.includes("special:minimized")
}

function shortenString(str, maxLength = 30) {
    if (str.length <= maxLength) {
        return str;
    } else {
        return str.substring(0, maxLength - 3) + '...';
    }
}
function getClientAddress(client) {
    if (client.grouped.length === 0) {
        return client.address;
    }
    return client.grouped[0]

}
function TaskBar() {
    return Widget.EventBox({
        child: Widget.Box({
            class_name: "taskbar",
            spacing: 8,
            children: [
                Widget.Button({
                    child: Widget.Label({})
                })
            ],
            setup: self => {
                self.hook(hyprland, () => {
                    let current_clients = hyprland.clients.filter(client => client.workspace.id === hyprland.active.workspace.id)
                    let minimized_clients = hyprland.clients.filter(client => client.workspace.name === `special:minimized_${hyprland.active.workspace.id}`)
                    let all_clients = current_clients.concat(minimized_clients).sort((a, b) => a.pid - b.pid)
                    current_clients[0].grouped
                    self.children = all_clients.map(client => Widget.Button({
                        class_name: "taskbar-button",
                        child: Widget.Box({
                            spacing: 4,
                            hpack: 'center',
                            vpack: 'center',
                            children: [
                                Widget.Icon({ 
                                    size: 15,
                                    icon: apps.list.find(app => app.match(client.class))?.icon_name || ""
                                }),
                                Widget.Label({
                                    class_name: ((client) => {
                                        if (isMinimized(client)) {
                                            return "taskbar-minimized"
                                        }
                                        if (client.address === hyprland.active.client.address) {
                                            return "taskbar-focus"
                                        }
                                        return "taskbar-normal"
                                    })(client),
                                    label: `${shortenString(client.title)}`,
                                })
                            ]
                        }),
                        on_middle_click: () => {
                            let address = getClientAddress(client)
                            if (!isMinimized(client)) {
                                hyprland.messageAsync(`dispatch movetoworkspacesilent special:minimized_${hyprland.active.workspace.id},address:${address}`)
                            } else {
                                hyprland.messageAsync(`dispatch movetoworkspacesilent ${hyprland.active.workspace.id},address:${address}`)
                            }
                        },
                        on_clicked: () => {
                            let address = getClientAddress(client)
                            if (isMinimized(client)) {
                                hyprland.messageAsync(`dispatch movetoworkspacesilent ${hyprland.active.workspace.id},address:${address}`)
                            }
                            hyprland.messageAsync(`dispatch focuswindow address:${client.address}`)
                        }
                    }))
                })
            }
        })
    })
}

function Left() {
    return Widget.Box({
        spacing: 8,
        children: [
            Widget.Button({
                class_name: "toggle-minimized-button",
                child: Widget.Label({
                    label: "Toggle Minimized"
                }),
                on_clicked: () => {
                    hyprland.messageAsync(`dispatch togglespecialworkspace minimized_${hyprland.active.workspace.id}`)
                }
            })
        ],

    })
}

function Center() {
    return Widget.Box({
        spacing: 8,
        children: [
            TaskBar()
        ],
    })
}


function Bar(monitor = 0) {
    return Widget.Window({
        name: `bar-${monitor}`, // name has to be unique
        class_name: "bar",
        monitor,
        anchor: ["bottom", "left", "right"],
        exclusivity: "exclusive",
        child: Widget.CenterBox({
            start_widget: Left(),
            center_widget: Center(),
            
        }),
    })
}

App.config({
    style: "./style.css",
    windows: [
        Bar(),
    ],
})

export { }
