{
  inputs,
  userdata,
  pkgs,
  config,
  ...
}: {
  home.packages = [
    inputs.winapps.packages."${pkgs.system}".winapps
  ];

  xdg.configFile."winapps/compose.yaml".text = ''
    # For documentation, FAQ, additional configuration options and technical help, visit: https://github.com/dockur/windows

    name: "winapps" # Docker Compose Project Name.
    volumes:
      # Create Volume 'data'.
      # Located @ '/var/lib/docker/volumes/winapps_data/_data' (Docker).
      # Located @ '/var/lib/containers/storage/volumes/winapps_data/_data' or '~/.local/share/containers/storage/volumes/winapps_data/_data' (Podman).
      data:
    services:
      windows:
        image: ghcr.io/dockur/windows:latest
        container_name: WinApps # Created Docker VM Name.
        environment:
          # Version of Windows to configure. For valid options, visit:
          # https://github.com/dockur/windows?tab=readme-ov-file#how-do-i-select-the-windows-version
          # https://github.com/dockur/windows?tab=readme-ov-file#how-do-i-install-a-custom-image
          VERSION: "11"
          RAM_SIZE: "8G" # RAM allocated to the Windows VM.
          CPU_CORES: "8" # CPU cores allocated to the Windows VM.
          DISK_SIZE: "64G" # Size of the primary hard disk.
          # DISK2_SIZE: "32G" # Uncomment to add an additional hard disk to the Windows VM. Ensure it is mounted as a volume below.
          USERNAME: "${userdata.username}" # Edit here to set a custom Windows username. The default is 'MyWindowsUser'.
          PASSWORD: "MyWindowsPassword" # Edit here to set a password for the Windows user. The default is 'MyWindowsPassword'.
          HOME: "${config.home.homeDirectory}" # Set path to Linux user home folder.
        ports:
          - 8006:8006 # Map '8006' on Linux host to '8006' on Windows VM --> For VNC Web Interface @ http://127.0.0.1:8006.
          - 3389:3389/tcp # Map '3389' on Linux host to '3389' on Windows VM --> For Remote Desktop Protocol (RDP).
          - 3389:3389/udp # Map '3389' on Linux host to '3389' on Windows VM --> For Remote Desktop Protocol (RDP).
        cap_add:
          - NET_ADMIN  # Add network permission
        stop_grace_period: 120s # Wait 120 seconds before sending SIGTERM when attempting to shut down the Windows VM.
        restart: on-failure # Restart the Windows VM if the exit code indicates an error.
        volumes:
          - data:/storage # Mount volume 'data' to use as Windows 'C:' drive.
          - ${config.home.homeDirectory}:/shared # Mount Linux user home directory @ '\\host.lan/Data'.
          #- /path/to/second/hard/disk:/storage2 # Uncomment to create a virtual second hard disk and mount it within the Windows VM. Ensure 'DISK2_SIZE' is specified above.
          - .${./oem}:/oem # Enables automatic post-install execution of 'oem/install.bat', applying Windows registry modifications contained within 'oem/RDPApps.reg'.
          #- /path/to/windows/install/media.iso:/custom.iso # Uncomment to use a custom Windows ISO. If specified, 'VERSION' (e.g. 'tiny11') will be ignored.
        devices:
          - /dev/kvm # Enable KVM.
          - /dev/net/tun # Enable tuntap
          # Uncomment to mount a disk directly within the Windows VM.
          # WARNING: /dev/sdX paths may change after reboot. Use persistent identifiers!
          # NOTE: 'disk1' will be mounted as the main drive. THIS DISK WILL BE FORMATTED BY DOCKER.
          # All following disks (disk2, ...) WILL NOT BE FORMATTED.
          # - /dev/disk/by-id/<id>:/disk1
          # - /dev/disk/by-id/<id>:/disk2
        # group_add:      # uncomment this line and the next one for using rootless podman containers
        #   - keep-groups # to make /dev/kvm work with podman. needs "crun" installed, "runc" will not work! Add your user to the 'kvm' group or another that can access /dev/kvm.
  '';

  xdg.configFile."winapps/winapps.conf".text = ''
    ##################################
    #   WINAPPS CONFIGURATION FILE   #
    ##################################

    # INSTRUCTIONS
    # - Leading and trailing whitespace are ignored.
    # - Empty lines are ignored.
    # - Lines starting with '#' are ignored.
    # - All characters following a '#' are ignored.

    # [WINDOWS USERNAME]
    RDP_USER="${userdata.username}"

    # [WINDOWS PASSWORD]
    # NOTES:
    # - If using FreeRDP v3.9.0 or greater, you *have* to set a password
    RDP_PASS="MyWindowsPassword"

    # [WINDOWS DOMAIN]
    # DEFAULT VALUE: "" (BLANK)
    RDP_DOMAIN=""

    # [WINDOWS IPV4 ADDRESS]
    # NOTES:
    # - If using 'libvirt', 'RDP_IP' will be determined by WinApps at runtime if left unspecified.
    # DEFAULT VALUE:
    # - 'docker': '127.0.0.1'
    # - 'podman': '127.0.0.1'
    # - 'libvirt': "" (BLANK)
    RDP_IP="127.0.0.1"

    # [VM NAME]
    # NOTES:
    # - Only applicable when using 'libvirt'
    # - The libvirt VM name must match so that WinApps can determine VM IP, start the VM, etc.
    # DEFAULT VALUE: 'RDPWindows'
    VM_NAME="RDPWindows"

    # [WINAPPS BACKEND]
    # DEFAULT VALUE: 'docker'
    # VALID VALUES:
    # - 'docker'
    # - 'podman'
    # - 'libvirt'
    # - 'manual'
    WAFLAVOR="docker"

    # [DISPLAY SCALING FACTOR]
    # NOTES:
    # - If an unsupported value is specified, a warning will be displayed.
    # - If an unsupported value is specified, WinApps will use the closest supported value.
    # DEFAULT VALUE: '100'
    # VALID VALUES:
    # - '100'
    # - '140'
    # - '180'
    RDP_SCALE="100"

    # [MOUNTING REMOVABLE PATHS FOR FILES]
    # NOTES:
    # - By default, `udisks` (which you most likely have installed) uses /run/media for mounting removable devices.
    #   This improves compatibility with most desktop environments (DEs).
    # ATTENTION: The Filesystem Hierarchy Standard (FHS) recommends /media instead. Verify your system's configuration.
    # - To manually mount devices, you may optionally use /mnt.
    # REFERENCE: https://wiki.archlinux.org/title/Udisks#Mount_to_/media
    REMOVABLE_MEDIA="/run/media"

    # [ADDITIONAL FREERDP FLAGS & ARGUMENTS]
    # NOTES:
    # - You can try adding /network:lan to these flags in order to increase performance, however, some users have faced issues with this.
    # DEFAULT VALUE: '/cert:tofu /sound /microphone +home-drive'
    # VALID VALUES: See https://github.com/awakecoding/FreeRDP-Manuals/blob/master/User/FreeRDP-User-Manual.markdown
    RDP_FLAGS="/cert:tofu /sound /microphone +home-drive"

    # [DEBUG WINAPPS]
    # NOTES:
    # - Creates and appends to ~/.local/share/winapps/winapps.log when running WinApps.
    # DEFAULT VALUE: 'true'
    # VALID VALUES:
    # - 'true'
    # - 'false'
    DEBUG="true"

    # [AUTOMATICALLY PAUSE WINDOWS]
    # NOTES:
    # - This is currently INCOMPATIBLE with 'manual'.
    # DEFAULT VALUE: 'off'
    # VALID VALUES:
    # - 'on'
    # - 'off'
    AUTOPAUSE="off"

    # [AUTOMATICALLY PAUSE WINDOWS TIMEOUT]
    # NOTES:
    # - This setting determines the duration of inactivity to tolerate before Windows is automatically paused.
    # - This setting is ignored if 'AUTOPAUSE' is set to 'off'.
    # - The value must be specified in seconds (to the nearest 10 seconds e.g., '30', '40', '50', etc.).
    # - For RemoteApp RDP sessions, there is a mandatory 20-second delay, so the minimum value that can be specified here is '20'.
    # - Source: https://techcommunity.microsoft.com/t5/security-compliance-and-identity/terminal-services-remoteapp-8482-session-termination-logic/ba-p/246566
    # DEFAULT VALUE: '300'
    # VALID VALUES: >=20
    AUTOPAUSE_TIME="300"

    # [FREERDP COMMAND]
    # NOTES:
    # - WinApps will attempt to automatically detect the correct command to use for your system.
    # DEFAULT VALUE: "" (BLANK)
    # VALID VALUES: The command required to run FreeRDPv3 on your system (e.g., 'xfreerdp', 'xfreerdp3', etc.).
    FREERDP_COMMAND=""

    # [TIMEOUTS]
    # NOTES:
    # - These settings control various timeout durations within the WinApps setup.
    # - Increasing the timeouts is only necessary if the corresponding errors occur.
    # - Ensure you have followed all the Troubleshooting Tips in the error message first.

    # PORT CHECK
    # - The maximum time (in seconds) to wait when checking if the RDP port on Windows is open.
    # - Corresponding error: "NETWORK CONFIGURATION ERROR" (exit status 13).
    # DEFAULT VALUE: '5'
    PORT_TIMEOUT="5"

    # RDP CONNECTION TEST
    # - The maximum time (in seconds) to wait when testing the initial RDP connection to Windows.
    # - Corresponding error: "REMOTE DESKTOP PROTOCOL FAILURE" (exit status 14).
    # DEFAULT VALUE: '30'
    RDP_TIMEOUT="30"

    # APPLICATION SCAN
    # - The maximum time (in seconds) to wait for the script that scans for installed applications on Windows to complete.
    # - Corresponding error: "APPLICATION QUERY FAILURE" (exit status 15).
    # DEFAULT VALUE: '60'
    APP_SCAN_TIMEOUT="60"

    # WINDOWS BOOT
    # - The maximum time (in seconds) to wait for the Windows VM to boot if it is not running, before attempting to launch an application.
    # DEFAULT VALUE: '120'
    BOOT_TIMEOUT="120"

    # FREERDP RAIL HIDEF
    # - This option controls the value of the `hidef` option passed to the /app parameter of the FreeRDP command.
    # - Setting this option to 'off' may resolve window misalignment issues related to maximized windows.
    # DEFAULT VALUE: 'on'
    HIDEF="on"
  '';
}
