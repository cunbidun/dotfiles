import Gdk from "gi://Gdk"

const systemtray = await Service.import("systemtray")

const SysTrayItem = (item: any) => Widget.Button({
    class_name: "tray-item",
    child: Widget.Icon({ icon: item.bind("icon") }),
    tooltip_markup: item.bind("tooltip_markup"),
    setup: self => {
        const { menu } = item
        if (!menu)
            return

        const id = menu.connect("popped-up", () => {
            self.toggleClassName("active")
            menu.connect("notify::visible", () => {
                self.toggleClassName("active", menu.visible)
            })
            menu.disconnect(id!)
        })

        self.connect("destroy", () => menu.disconnect(id))
    },

    on_primary_click: btn => item.menu?.popup_at_widget(
        btn, Gdk.Gravity.SOUTH, Gdk.Gravity.NORTH, null),

    on_secondary_click: btn => item.menu?.popup_at_widget(
        btn, Gdk.Gravity.SOUTH, Gdk.Gravity.NORTH, null),
})

const SysTray = Widget.Box()
    .bind("children", systemtray, "items", i => i
        .map(SysTrayItem))

export { SysTray }
