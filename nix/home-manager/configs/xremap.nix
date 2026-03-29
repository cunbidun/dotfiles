{
  ...
}: {
  services.xremap = {
    withWlroots = true;
    watch = true;
    enable = true;
    yamlConfig = ''
      shared:
        noSuperToCtrlApps: &noSuperToCtrlApps
          - kitty
          - steam
          - cs2
          - dota2
          - qemu-system-x86_64
          - qemu
          - Qemu-system-x86_64
          - code
          - code-insiders
          - blender
          - prismlauncher
          - minecraft
          - "Minecraft 1.21.11"

        noCtrlSpaceVicinaeApps: &noCtrlSpaceVicinaeApps
          - "/^Minecraft.*$/"

      modmap:
        - name: Global
          application:
          remap:
            ALT_L: SUPER_L

        - name: Almost
          application:
            not: *noSuperToCtrlApps
          remap:
            SUPER_L: CONTROL_L

        - name: Other
          application:
            only: *noSuperToCtrlApps
          remap:
            SUPER_L: ALT_L

      keymap:
        - name: Ctrl+Space opens Vicinae except in Minecraft
          application:
            not: *noCtrlSpaceVicinaeApps
          remap:
            C-space: Alt-space
    '';
  };
}
