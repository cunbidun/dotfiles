import { number_parser_error_quark } from "lib/types/@girs/glib-2.0/glib-2.0.cjs";

const hyprland = await Service.import("hyprland")
const bluetooth = await Service.import('bluetooth')
const audio = await Service.import('audio')

const focusedTitle = Widget.Label({
  label: hyprland.active.client.bind('title'),
  visible: hyprland.active.client.bind('address')
    .as(addr => addr !== "0x"),
})

const dispatch = (ws: string | number) => hyprland.messageAsync(`dispatch workspace ${ws}`);


const Workspaces = () => Widget.EventBox({
  onScrollUp: () => dispatch('+1'),
  onScrollDown: () => dispatch('-1'),
  child: Widget.Box({
    setup: self => self.hook(hyprland, () => {
      self.children = hyprland.workspaces.filter(ws => !ws.name.startsWith("special:")).map(ws => Widget.Button({
        class_name: (ws => {
          if (ws.id === hyprland.active.workspace.id) {
            return "taskbar-focus"
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

const connectedList = Widget.Box({
  setup: self => self.hook(bluetooth, self => {
      self.children = bluetooth.connected_devices
          .map(({ icon_name, name }) => Widget.Box([
              Widget.Icon(icon_name + '-symbolic'),
              Widget.Label(name),
          ]));

      self.visible = bluetooth.connected_devices.length > 0;
  }, 'notify::connected-devices'),
})

const indicator = Widget.Icon({
  icon: bluetooth.bind('enabled').as(on =>
      `bluetooth-${on ? 'active' : 'disabled'}-symbolic`),
})

const TopBar = () => Widget.Window({
  name: 'top-bar',
  anchor: ['top', 'left', 'right'],
  exclusivity: 'exclusive',
  child: Widget.CenterBox({
    className: 'top-bar',
    startWidget: Workspaces(),
    center_widget: Widget.Box({ children: [focusedTitle] }),
    end_widget: Widget.Box({ children: [indicator, connectedList] }),
  }),
});


const volumeIndicator = Widget.Button({
    on_clicked: () => audio.speaker.is_muted = !audio.speaker.is_muted,
    child: Widget.Icon().hook(audio.speaker, self => {
        const vol = audio.speaker.volume * 100;
        const icon = [
            [101, 'overamplified'],
            [67, 'high'],
            [34, 'medium'],
            [1, 'low'],
            [0, 'muted'],
        ].find(([threshold]: [number]) => threshold <= vol)?.[1];

        self.icon = `audio-volume-${icon}-symbolic`;
        self.tooltip_text = `Volume ${Math.floor(vol)}%`;
    }),
})

export { TopBar }