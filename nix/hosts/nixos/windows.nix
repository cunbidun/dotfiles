{
  config,
  pkgs,
  userdata,
  ...
}: let
  vmName = "windows11";
  vmUuid = "579eaa34-a464-4ede-b718-db39e5b19d03";
  networkUuid = "b2ac6241-b387-4fa6-b101-7b4b3cf8a266";
  diskSize = "256G";
  memoryMiB = 12288;
  vcpuCount = 12;
  lookingGlassMemMiB = 128; # 4K SDR per Looking Glass B7 sizing table.
  lookingGlassMemBytes = lookingGlassMemMiB * 1024 * 1024;
  intelIgdPciId = "8086:a780";
  windowsRoot = "/var/lib/libvirt/windows";
  windowsSharePath = "/home/${userdata.username}/windows";
  windowsShareTag = "hostwindows";
  windowsIsoPath = "${windowsRoot}/iso/windows11.iso";
  windowsDiskPath = "${windowsRoot}/${vmName}.qcow2";
  windowsNvramPath = "${windowsRoot}/${vmName}-VARS.fd";
  ovmfCodePath = "/run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd";
  ovmfVarsTemplate = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.fd";
  intelIgdRom = pkgs.fetchurl {
    url = "https://github.com/LongQT-sea/intel-igpu-passthru/releases/download/v0.1/Universal_noGOP_igd.rom";
    sha256 = "d1c95f6062eba9d3164263bf11626d5d958d82439525d41570256e5a72d9b18f"; # pragma: allowlist secret
  };
  # Declarative here:
  # - libvirt network, qcow2 disk creation, OVMF vars path, TPM, virtio devices
  # - virtiofs share (${windowsSharePath} -> ${windowsShareTag})
  # - Intel iGPU passthrough on the host and in the VM XML
  # - Intel UPT mode details: Universal_noGOP_igd.rom, x-igd-opregion, maxphysaddr
  # - Looking Glass host-side support: client package, KVMFR module, /dev/kvmfr0,
  #   and IVSHMEM device for 4K SDR capture
  # - local-only SPICE control path for Looking Glass keyboard/mouse input
  #
  # Still manual inside Windows after a reinstall:
  # 1. During setup, load VirtIO drivers from VIRTIO_WIN:
  #    - storage: E:\viostor\w11\amd64
  #    - network: E:\NetKVM\w11\amd64
  # 2. Install the Intel iGPU driver from Intel's official download page using the
  #    normal installer / installation assistant widget. Do not force random INF
  #    packages manually for the passthrough GPU.
  # 3. Install Looking Glass Host in Windows after the VM hardware change is active:
  #    - attach a physical display or dummy plug to the passed-through Intel iGPU
  #    - download the stable Windows Host Binary from https://looking-glass.io/downloads
  #    - run the installer as administrator; for unattended install:
  #      .\looking-glass-host-setup.exe /S
  #    The B7 installer includes and installs the IVSHMEM driver.
  # 4. If you want SSH in the guest again:
  #    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
  #    Start-Service sshd
  #    Set-Service -Name sshd -StartupType Automatic
  #    New-NetFirewallRule -Name sshd -DisplayName "OpenSSH Server" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
  # 5. If the Windows user is an administrator, OpenSSH may ignore
  #    %USERPROFILE%\.ssh\authorized_keys and require the public key in:
  #    $pub = "ssh-ed25519 <your-public-key> <comment>"
  #    Set-Content C:\ProgramData\ssh\administrators_authorized_keys $pub
  #    icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r
  #    icacls C:\ProgramData\ssh\administrators_authorized_keys /grant Administrators:F
  #    icacls C:\ProgramData\ssh\administrators_authorized_keys /grant SYSTEM:F
  #    Restart-Service sshd
  # 6. If you want ${windowsSharePath} mounted in Windows as W::
  #    winget install -e --id WinFsp.WinFsp --accept-source-agreements --accept-package-agreements --disable-interactivity
  #    pnputil /add-driver E:\viofs\w11\amd64\viofs.inf /install
  #    New-Item -ItemType Directory -Force "C:\Program Files\Virtio-Win\VioFS"
  #    Copy-Item E:\viofs\w11\amd64\virtiofs.exe "C:\Program Files\Virtio-Win\VioFS\virtiofs.exe" -Force
  #    sc create VirtioFsSvc binPath= "\"C:\Program Files\Virtio-Win\VioFS\virtiofs.exe\" -t ${windowsShareTag} -m W: -F NTFS" start= auto depend= VirtioFsDrv
  #    sc start VirtioFsSvc
  #
  # One-off operational notes:
  # - After changing VM hardware, remove stale saved state before booting:
  #   virsh --connect qemu:///system managedsave-remove ${vmName}
  # - After changing the virtiofs device or other VM hardware, do a full VM stop/start.
  # - Looking Glass will not replace the remote-display path until the Windows host
  #   app is installed and running inside an interactive Windows session.
  #
  windowsDriversIso =
    pkgs.runCommand "virtio-win-drivers.iso" {
      nativeBuildInputs = [pkgs.xorriso];
    } ''
      mkdir -p iso-root
      cp -r ${pkgs.virtio-win}/. iso-root/
      xorriso -as mkisofs \
        -J -R \
        -V VIRTIO_WIN \
        -o "$out" \
        iso-root
    '';
  windowsNetworkXml = pkgs.writeText "libvirt-${vmName}-network.xml" ''
    <network>
      <name>${vmName}</name>
      <uuid>${networkUuid}</uuid>
      <forward mode='nat'/>
      <bridge name='virbr-win' stp='on' delay='0'/>
      <ip address='192.168.76.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.76.2' end='192.168.76.254'/>
        </dhcp>
      </ip>
    </network>
  '';
  windowsDomainXml = pkgs.writeText "libvirt-${vmName}.xml" ''
    <domain xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0' type='kvm'>
      <name>${vmName}</name>
      <uuid>${vmUuid}</uuid>
      <metadata>
        <description>Declarative Windows 11 VM managed from NixOS.</description>
      </metadata>
      <memory unit='MiB'>${toString memoryMiB}</memory>
      <currentMemory unit='MiB'>${toString memoryMiB}</currentMemory>
      <memoryBacking>
        <source type='memfd'/>
        <access mode='shared'/>
      </memoryBacking>
      <vcpu placement='static'>${toString vcpuCount}</vcpu>
      <cpu mode='host-passthrough' check='none' migratable='on'>
        <topology sockets='1' dies='1' clusters='1' cores='6' threads='2'/>
        <maxphysaddr mode='passthrough' limit='39'/>
      </cpu>
      <os>
        <type arch='x86_64' machine='q35'>hvm</type>
        <loader readonly='yes' secure='yes' type='pflash'>${ovmfCodePath}</loader>
        <nvram template='${ovmfVarsTemplate}'>${windowsNvramPath}</nvram>
        <boot dev='cdrom'/>
        <boot dev='hd'/>
      </os>
      <features>
        <acpi/>
        <apic/>
        <hyperv mode='custom'>
          <relaxed state='on'/>
          <vapic state='on'/>
          <spinlocks state='on' retries='8191'/>
          <vpindex state='on'/>
          <runtime state='on'/>
          <synic state='on'/>
          <stimer state='on'/>
          <reset state='on'/>
          <frequencies state='on'/>
          <reenlightenment state='on'/>
          <tlbflush state='on'/>
          <ipi state='on'/>
          <avic state='off'/>
        </hyperv>
        <kvm>
          <hidden state='off'/>
        </kvm>
        <vmport state='off'/>
        <smm state='on'/>
      </features>
      <clock offset='localtime'>
        <timer name='rtc' tickpolicy='catchup'/>
        <timer name='pit' tickpolicy='delay'/>
        <timer name='hpet' present='no'/>
        <timer name='hypervclock' present='yes'/>
      </clock>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <pm>
        <suspend-to-mem enabled='no'/>
        <suspend-to-disk enabled='no'/>
      </pm>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
          <source file='${windowsDiskPath}'/>
          <target dev='vda' bus='virtio'/>
        </disk>
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='${windowsIsoPath}'/>
          <target dev='sda' bus='sata'/>
          <readonly/>
        </disk>
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='${windowsDriversIso}'/>
          <target dev='sdb' bus='sata'/>
          <readonly/>
        </disk>
        <filesystem type='mount' accessmode='passthrough'>
          <driver type='virtiofs'/>
          <binary path='${pkgs.virtiofsd}/bin/virtiofsd' xattr='on'/>
          <source dir='${windowsSharePath}'/>
          <target dir='${windowsShareTag}'/>
        </filesystem>
        <controller type='usb' model='qemu-xhci' ports='15'/>
        <controller type='pci' model='pcie-root'/>
        <controller type='sata' index='0'/>
        <controller type='virtio-serial' index='0'/>
        <interface type='network'>
          <mac address='52:54:00:76:11:01'/>
          <source network='${vmName}'/>
          <model type='virtio'/>
        </interface>
        <graphics type='spice' autoport='yes' listen='127.0.0.1'>
          <listen type='address' address='127.0.0.1'/>
          <image compression='off'/>
        </graphics>
        <hostdev mode='subsystem' type='pci' managed='yes'>
          <source>
            <address domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
          </source>
          <rom file='${intelIgdRom}'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
        </hostdev>
        <channel type='unix'>
          <target type='virtio' name='org.qemu.guest_agent.0'/>
        </channel>
        <channel type='spicevmc'>
          <target type='virtio' name='com.redhat.spice.0'/>
        </channel>
        <input type='mouse' bus='virtio'/>
        <input type='keyboard' bus='virtio'/>
        <video>
          <model type='vga'/>
        </video>
        <tpm model='tpm-crb'>
          <backend type='emulator' version='2.0'/>
        </tpm>
        <memballoon model='none'/>
        <rng model='virtio'>
          <backend model='random'>/dev/urandom</backend>
        </rng>
      </devices>
      <qemu:override>
        <qemu:device alias='hostdev0'>
          <qemu:frontend>
            <qemu:property name='x-igd-opregion' type='bool' value='true'/>
          </qemu:frontend>
        </qemu:device>
      </qemu:override>
      <qemu:commandline>
        <qemu:arg value='-device'/>
        <qemu:arg value="{&quot;driver&quot;:&quot;ivshmem-plain&quot;,&quot;id&quot;:&quot;shmem0&quot;,&quot;memdev&quot;:&quot;looking-glass&quot;}"/>
        <qemu:arg value='-object'/>
        <qemu:arg value="{&quot;qom-type&quot;:&quot;memory-backend-file&quot;,&quot;id&quot;:&quot;looking-glass&quot;,&quot;mem-path&quot;:&quot;/dev/kvmfr0&quot;,&quot;size&quot;:${toString lookingGlassMemBytes},&quot;share&quot;:true}"/>
      </qemu:commandline>
    </domain>
  '';
in {
  boot.initrd.kernelModules = [
    "vfio"
    "vfio_pci"
    "vfio_iommu_type1"
  ];

  boot.blacklistedKernelModules = [
    "i915"
    "xe"
  ];

  boot.extraModulePackages = [
    config.boot.kernelPackages.kvmfr
  ];

  boot.kernelModules = [
    "kvmfr"
  ];

  boot.extraModprobeConfig = ''
    options kvmfr static_size_mb=${toString lookingGlassMemMiB}
  '';

  boot.kernelParams = [
    "kvm.ignore_msrs=1"
    "intel_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=${intelIgdPciId}"
  ];

  users.users.${userdata.username}.extraGroups = [
    "libvirtd"
    "kvm"
  ];

  environment.systemPackages = with pkgs; [
    looking-glass-client
    virt-manager
  ];

  programs.virt-manager.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
      verbatimConfig = ''
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm",
          "/dev/vfio/vfio", "/dev/kvmfr0"
        ]
      '';
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="kvmfr", OWNER="${userdata.username}", GROUP="kvm", MODE="0660"
  '';

  systemd.tmpfiles.rules = [
    "d ${windowsRoot} 0755 root root -"
    "d ${windowsRoot}/iso 0755 root root -"
  ];

  systemd.services.libvirt-windows-network = {
    description = "Define declarative libvirt network for ${vmName}";
    wantedBy = ["multi-user.target"];
    after = ["libvirtd.service"];
    wants = ["libvirtd.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [
      libvirt
      coreutils
      gnugrep
    ];
    script = ''
      set -euo pipefail

      if ! virsh --connect qemu:///system net-info ${vmName} >/dev/null 2>&1; then
        virsh --connect qemu:///system net-define ${windowsNetworkXml}
      fi

      if ! virsh --connect qemu:///system net-info ${vmName} | grep -q "Active:.*yes"; then
        virsh --connect qemu:///system net-start ${vmName}
      fi

      virsh --connect qemu:///system net-autostart ${vmName}
    '';
  };

  systemd.services.libvirt-windows-storage = {
    description = "Create ${vmName} disk image";
    wantedBy = ["multi-user.target"];
    after = ["libvirtd.service"];
    wants = ["libvirtd.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [
      qemu_kvm
      coreutils
    ];
    script = ''
      set -euo pipefail

      mkdir -p ${windowsRoot}
      if [ ! -f ${windowsDiskPath} ]; then
        qemu-img create -f qcow2 ${windowsDiskPath} ${diskSize}
      fi
    '';
  };

  systemd.services.libvirt-windows-domain = {
    description = "Define declarative ${vmName} libvirt domain";
    wantedBy = ["multi-user.target"];
    after = [
      "libvirtd.service"
      "libvirt-windows-network.service"
      "libvirt-windows-storage.service"
    ];
    wants = [
      "libvirtd.service"
      "libvirt-windows-network.service"
      "libvirt-windows-storage.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [
      libvirt
      coreutils
    ];
    script = ''
      set -euo pipefail

      virsh --connect qemu:///system define ${windowsDomainXml}
      virsh --connect qemu:///system autostart --disable ${vmName} || true
    '';
  };
}
