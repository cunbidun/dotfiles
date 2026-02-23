import AstalHyprland from 'gi://AstalHyprland?version=0.1';

const hyprlandService = AstalHyprland.get_default();

const floatFilePicker = (): void => {
    hyprlandService.message('keyword windowrulev2 float, title:^((Save|Import) Hyprpanel.*)$');

    hyprlandService.connect('config-reloaded', () => {
        hyprlandService.message('keyword windowrulev2 float, title:^((Save|Import) Hyprpanel.*)$');
    });
};

export const hyprlandSettings = (): void => {
    floatFilePicker();
};
