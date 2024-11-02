import { Clock } from "widgets/date";
import { SubMap } from "widgets/hyprland-submap";
import { SysTray } from "widgets/systray";

const hyprland = await Service.import("hyprland")
const bluetooth = await Service.import('bluetooth')

const FocusedTitle = Widget.Label({
  class_name: "focused-title",
  label: hyprland.active.client.bind('title'),
  visible: hyprland.active.client.bind('address')
    .as(addr => addr !== "0x"),
})

const dispatch = (ws: string | number) => hyprland.messageAsync(`dispatch workspace ${ws}`);

const Workspaces = () => Widget.EventBox({
  onScrollUp: () => dispatch('+1'),
  onScrollDown: () => dispatch('-1'),
  child: Widget.Box({
    spacing: 2,
    setup: self => self.hook(hyprland, () => {
      self.children = hyprland.workspaces.sort((a, b) => a.id - b.id).filter(ws => !ws.name.startsWith("special:")).map(ws => Widget.Button({
        class_name: (ws => {
          if (ws.id === hyprland.active.workspace.id) {
            return "workspace-focus"
          }
          return "workspace-normal"
        })(ws),
        attribute: ws.id,
        label: `${ws.name}`,
        onClicked: () => dispatch(ws.id),
      }))
    }
    ),
  }),
})

const TopBar = (monitor: number) => Widget.Window({
  monitor,
  name: `top-bar-${monitor}`,
  anchor: ['top', 'left', 'right'],
  class_name: 'top-bar',
  exclusivity: 'exclusive',
  child: Widget.CenterBox({
    startWidget: Widget.Box({ children: [Workspaces(), SubMap()] }),
    centerWidget: Widget.Box({ hpack: "center", children: [FocusedTitle] }),
    endWidget: Widget.Box({ children: [Widget.Box({ expand: true }), SysTray, Clock] }),
  }),
});


export { TopBar }
