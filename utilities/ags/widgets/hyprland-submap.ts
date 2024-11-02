const hyprland = await Service.import('hyprland');
import { Variable as VariableType } from 'lib/types/variable';

const submapStatus: VariableType<string> = Variable('default');

hyprland.connect('submap', (_, currentSubmap) => {
    if (currentSubmap.length === 0) {
        submapStatus.value = 'default';
    } else {
        submapStatus.value = currentSubmap;
    }
});

const SubMap = () => Widget.Label({
    class_name: "hyprland-submap",
    label: submapStatus.bind('value'),
    visible: submapStatus.bind('value')
        .as(value => value !== "default"),
})

export { SubMap }