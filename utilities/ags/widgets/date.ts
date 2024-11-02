import GLib from "gi://GLib"
import options from "options"

export const clock = Variable(GLib.DateTime.new_now_local(), {
    poll: [1000, () => GLib.DateTime.new_now_local()],
})


const format = Variable(options.bar.date)
const time = Utils.derive([clock, format], (c, f) => c.format(f.format) || "")

const Clock = Widget.Button({
    class_name: "clock",
    child: Widget.Label({
        justification: "center",
        label: time.bind(),
    }),
})


export { Clock }