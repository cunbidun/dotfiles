{
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
  windowsRoot = "/var/lib/libvirt/windows";
  windowsIsoPath = "${windowsRoot}/iso/windows11.iso";
  windowsDiskPath = "${windowsRoot}/${vmName}.qcow2";
  windowsNvramPath = "${windowsRoot}/${vmName}-VARS.fd";
  ovmfCodePath = "/run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd";
  ovmfVarsTemplate = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.fd";
  # Host-side libvirt state is declarative below, but a fresh Windows reinstall
  # still needs these guest-side steps:
  #
  # 1. During Windows setup, load VirtIO drivers from the attached VIRTIO_WIN ISO:
  #    - storage: E:\viostor\w11\amd64
  #    - network: E:\NetKVM\w11\amd64
  #
  # 2. After first boot, install SPICE guest tools in Windows and reboot.
  #
  # 3. Install the newer QXL display driver from the VirtIO ISO and reboot:
  #    pnputil /add-driver E:\qxldod\w10\amd64\qxldod.inf /install
  #
  # 4. If you want SSH again after reinstall:
  #    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
  #    Start-Service sshd
  #    Set-Service -Name sshd -StartupType Automatic
  #    New-NetFirewallRule -Name sshd -DisplayName "OpenSSH Server" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
  #
  # 5. If the Windows user is an administrator, OpenSSH may ignore
  #    %USERPROFILE%\.ssh\authorized_keys and require the public key in:
  #    C:\ProgramData\ssh\administrators_authorized_keys
  windowsDriversIso = pkgs.runCommand "virtio-win-drivers.iso" {
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
    <domain type='kvm'>
      <name>${vmName}</name>
      <uuid>${vmUuid}</uuid>
      <metadata>
        <description>Declarative Windows 11 VM managed from NixOS.</description>
      </metadata>
      <memory unit='MiB'>${toString memoryMiB}</memory>
      <currentMemory unit='MiB'>${toString memoryMiB}</currentMemory>
      <vcpu placement='static'>${toString vcpuCount}</vcpu>
      <cpu mode='host-passthrough' check='none' migratable='on'>
        <topology sockets='1' dies='1' clusters='1' cores='6' threads='2'/>
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
        <controller type='usb' model='qemu-xhci' ports='15'/>
        <controller type='pci' model='pcie-root'/>
        <controller type='pci' model='pcie-root-port'/>
        <controller type='sata' index='0'/>
        <controller type='virtio-serial' index='0'/>
        <controller type='scsi' model='virtio-scsi'/>
        <interface type='network'>
          <mac address='52:54:00:76:11:01'/>
          <source network='${vmName}'/>
          <model type='virtio'/>
        </interface>
        <serial type='pty'>
          <target type='isa-serial' port='0'/>
        </serial>
        <console type='pty'>
          <target type='serial' port='0'/>
        </console>
        <channel type='unix'>
          <target type='virtio' name='org.qemu.guest_agent.0'/>
        </channel>
        <channel type='spicevmc'>
          <target type='virtio' name='com.redhat.spice.0'/>
        </channel>
        <input type='tablet' bus='usb'/>
        <input type='mouse' bus='ps2'/>
        <input type='keyboard' bus='ps2'/>
        <tpm model='tpm-crb'>
          <backend type='emulator' version='2.0'/>
        </tpm>
        <graphics type='spice' autoport='yes' listen='127.0.0.1'>
          <listen type='address' address='127.0.0.1'/>
          <image compression='off'/>
          <gl enable='no'/>
        </graphics>
        <video>
          <model type='qxl' ram='262144' vram='131072' vgamem='65536' heads='1' primary='yes'/>
        </video>
        <sound model='ich9'/>
        <audio id='1' type='spice'/>
        <redirdev bus='usb' type='spicevmc'/>
        <redirdev bus='usb' type='spicevmc'/>
        <memballoon model='virtio'/>
        <rng model='virtio'>
          <backend model='random'>/dev/urandom</backend>
        </rng>
      </devices>
    </domain>
  '';
in {
  boot.kernelParams = [
    "kvm.ignore_msrs=1"
  ];

  users.users.${userdata.username}.extraGroups = [
    "libvirtd"
    "kvm"
  ];

  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    swtpm
  ];

  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };

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
