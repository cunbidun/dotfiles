import { Client } from "lib/types/service/hyprland";
import Button from "lib/types/widgets/button";

const hyprland = await Service.import("hyprland")
const apps = await Service.import("applications")


function isMinimized(client: Client) {
    return client.workspace.name.includes("special:minimized")
}

function shortenString(str: string, maxLength = 30): string {
    if (str.length <= maxLength) {
        return str;
    } else {
        return str.substring(0, maxLength - 3) + '...';
    }
}
function getClientAddress(client: Client): string {
    if (client.grouped.length < 1) {
        return client.address;
    }
    return client.grouped[client.grouped.length - 1]
}

function isInGroup(client: Client) {
    return client.grouped.length > 0
}

function getButton(client: Client) {
    return Widget.Button({
        class_name: "dock-button",
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
                            return "dock-minimized"
                        }
                        if (client.address === hyprland.active.client.address) {
                            return "dock-focus"
                        }
                        return "dock-normal"
                    })(client),
                    label: `${shortenString(client.title)}`,
                })
            ]
        }),
        on_middle_click: () => {
            let address = client.address
            if (!isMinimized(client)) {
                hyprland.messageAsync(`dispatch focuswindow address:${address}`)
                hyprland.messageAsync(`dispatch movetoworkspacesilent special:minimized_${hyprland.active.workspace.id}`)
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
    })
}

function TaskDock() {
    return Widget.EventBox({
        child: Widget.Box({
            class_name: "taskdock",
            spacing: 8,
            children: [
                Widget.Button({
                    child: Widget.Label({})
                })
            ],
            setup: self => {
                self.hook(hyprland, () => {
                    let current_clients = hyprland.clients.filter(client => client.workspace.id === hyprland.active.workspace.id)
                    current_clients = current_clients.filter(client => client.title !== '')
                    let minimized_clients = hyprland.clients.filter(client => client.workspace.name === `special:minimized_${hyprland.active.workspace.id}`)
                    let all_clients = current_clients.concat(minimized_clients).sort((a, b) => a.pid - b.pid)
                    self.children = all_clients.map(
                        client =>getButton(client)
                    )
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
            TaskDock()
        ],
    })
}


function Dock(monitor = 0) {
    return Widget.Window({
        name: `dock-${monitor}`, // name has to be unique
        class_name: "dock",
        monitor,
        anchor: ["bottom", "left", "right"],
        exclusivity: "exclusive",
        child: Widget.CenterBox({
            start_widget: Left(),
            center_widget: Center(),

        }),
    })
}

export { Dock }