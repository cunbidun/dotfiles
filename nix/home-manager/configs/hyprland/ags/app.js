import app from "ags/gtk4/app"
import { Astal } from "ags/gtk4"
import { createPoll } from "ags/time"
import Hyprland from "gi://AstalHyprland"

function Workspaces() {
  const hypr = Hyprland.get_default()

  // Define workspace icons similar to Waybar config
  const workspaceIcons = {
    1: "1",
    2: "2", 
    3: "3",
    4: "4",
    5: "WEB",
    6: "EXTRA",
    7: "QUANT",
    8: "8",
    9: "VI"
  }

  return (
    <box>
      {hypr.workspaces.map(workspace => (
        <button
          key={workspace.id}
          onClick={() => workspace.focus()}
          className={workspace === hypr.focusedWorkspace ? "active" : ""}
        >
          {workspaceIcons[workspace.id] || workspace.id}
        </button>
      ))}
    </box>
  )
}

function Clock() {
  const clock = createPoll("", 1000, () => {
    const now = new Date()
    const dateFormatter = new Intl.DateTimeFormat('en-US', {
      weekday: 'short',
      month: 'short', 
      day: '2-digit'
    })
    const timeFormatter = new Intl.DateTimeFormat('en-US', {
      hour: '2-digit',
      minute: '2-digit', 
      second: '2-digit',
      hour12: false
    })
    
    return `${dateFormatter.format(now)}, ${timeFormatter.format(now)}`
  })

  return <label label={clock} />
}

app.start({
  main() {
    const { BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor
    const { EXCLUSIVE } = Astal.Exclusivity

    return (
      <window visible anchor={BOTTOM | LEFT | RIGHT} exclusivity={EXCLUSIVE}>
        <centerbox>
          <box halign="start">
            <Workspaces />
          </box>
          <box halign="center">
            {/* Window title can go here later */}
          </box>
          <box halign="end">
            <Clock />
          </box>
        </centerbox>
      </window>
    )
  },
})