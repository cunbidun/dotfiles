
const hyprland = await Service.import("hyprland")


function isMinimized(client) {
    return client.workspace.name.includes("special:minimized")
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
            setup: self => self.hook(hyprland, () => {
                let current_clients = hyprland.clients.filter(client => client.workspace.id === hyprland.active.workspace.id)
                let minimized_clients = hyprland.clients.filter(client => client.workspace.name == `special:minimized_${hyprland.active.workspace.id}`)
                let all_clients = current_clients.concat(minimized_clients).sort((a, b) => a.pid - b.pid)
                self.children = all_clients.map(client => Widget.Button({
                    class_name: "taskbar-button",
                    child: Widget.Label({
                        class_name: ((client) => {
                            if (isMinimized(client)) {
                                return "taskbar-minimized"
                            }
                            return "taskbar-normal"
                        })(client),
                        label: `${client.title}`,
                    }),
                    on_middle_click: () => {
                        if (!isMinimized(client)) {
                            hyprland.messageAsync(`dispatch movetoworkspacesilent special:minimized_${hyprland.active.workspace.id},address:${client.address}`)
                        } else {
                            hyprland.messageAsync(`dispatch movetoworkspacesilent ${hyprland.active.workspace.id},address:${client.address}`)
                        }
                    },
                    on_clicked: () => {
                        if (isMinimized(client)) {
                            hyprland.messageAsync(`dispatch movetoworkspacesilent ${hyprland.active.workspace.id},address:${client.address}`)
                        }
                        hyprland.messageAsync(`dispatch focuswindow address:${client.address}`)
                    }
                }))
            }),
        })
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