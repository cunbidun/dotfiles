# Test VM Bootstrap

A QEMU/KVM VM for testing the 2-stage NixOS bootstrap flow without touching real hardware.

## Prerequisites

- NixOS minimal ISO downloaded to `/var/lib/libvirt/images/nixos-minimal.iso`
- 1Password agent running (`~/.1password/agent.sock`)
- KVM available (`/dev/kvm`)

Download the ISO if missing:

```bash
sudo curl -L "https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso" \
  -o /var/lib/libvirt/images/nixos-minimal.iso
```

## Stage 1: Fresh install

### 1. Create disk and boot installer

```bash
qemu-img create -f qcow2 ~/tmp/test-vm.qcow2 40G

qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 4 \
  -drive file=~/tmp/test-vm.qcow2,if=virtio,format=qcow2 \
  -cdrom /var/lib/libvirt/images/nixos-minimal.iso -boot d \
  -netdev "user,id=net0,hostfwd=tcp::2222-:22" \
  -device virtio-net-pci,netdev=net0 \
  -display none \
  -monitor unix:/tmp/qemu-mon.sock,server,nowait \
  -cpu host -daemonize -pidfile /tmp/test-vm.pid
```

### 2. Inject SSH key into installer

Wait for the installer to boot (TCP port open), then inject via QEMU monitor.
Start a local HTTP server to serve the setup script:

```bash
python3 -m http.server 9999 --directory ~/dotfiles/scripts/vm-setup &
```

Create `~/dotfiles/scripts/vm-setup/setup.sh`:

```bash
#!/bin/sh
set -e
mkdir -p /root/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYi6b9Qaa6hF5PXkaTinS131ESVKDkQTOWCcvD8JmZ3' \
  > /root/.ssh/authorized_keys
chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys
SSHD=$(readlink -f "$(which sshd)")
grep -v 'PerSourcePenalties' /etc/ssh/sshd_config > /tmp/sshd_fixed.conf
echo 'PerSourcePenalties no' >> /tmp/sshd_fixed.conf
"$SSHD" -t -f /tmp/sshd_fixed.conf
systemctl stop sshd && sleep 1
"$SSHD" -f /tmp/sshd_fixed.conf
echo "done"
```

Wait for TCP port, then inject:

```bash
until nc -z -w2 localhost 2222; do sleep 2; done
sleep 12  # wait for auto-login shell

python3 -c "
import socket, time
KEY_MAP = {' ':'spc','\n':'ret','/':'slash','.':'dot',':':'shift-semicolon',
  '|':'shift-backslash','-':'minus','_':'shift-minus','=':'equal','>':'shift-dot',
  '&':'shift-7','\"':'shift-apostrophe',\"'\":'apostrophe',
  '(':'shift-9',')':'shift-0','\$':'shift-4'}
def t(sock, s):
  for ch in s:
    key = KEY_MAP.get(ch, f'shift-{ch.lower()}' if ch.isupper() else ch)
    sock.sendall(f'sendkey {key}\n'.encode()); time.sleep(0.09)
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect('/tmp/qemu-mon.sock'); s.recv(4096)
t(s, 'curl -s 10.0.2.2:9999/setup.sh | sudo sh\n')
s.close()
"
```

### 3. Deploy with nixos-anywhere

```bash
sleep 8  # wait for setup.sh to complete and sshd to restart

SSH_AUTH_SOCK=~/.1password/agent.sock \
nix run github:nix-community/nixos-anywhere -- \
  --flake .#test-vm \
  --generate-hardware-config nixos-generate-config ./nix/hosts/test-vm/hardware-configuration.nix \
  --ssh-option "StrictHostKeyChecking=no" \
  --ssh-option "UserKnownHostsFile=/dev/null" \
  -p 2222 root@localhost
```

Expected: sops will fail with `cannot read keyfile '/var/lib/sops-nix/keys.txt'` — this is normal for stage 1.

### 4. Boot installed system

```bash
pkill -f "test-vm.qcow2"  # kill installer VM

qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 4 \
  -drive file=~/tmp/test-vm.qcow2,if=virtio,format=qcow2 \
  -netdev "user,id=net0,hostfwd=tcp::2222-:22" \
  -device virtio-net-pci,netdev=net0 \
  -display none \
  -monitor unix:/tmp/qemu-mon.sock,server,nowait \
  -cpu host -daemonize -pidfile /tmp/test-vm.pid
```

Verify:

```bash
SSH_AUTH_SOCK=~/.1password/agent.sock ssh \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -p 2222 cunbidun@localhost \
  'hostname && systemctl --failed'
```

Expected: `hostname=test-vm`, 0 failed units.

---

## Stage 2: Place age key (secrets bootstrap)

SSH into the VM as root and place the age key from 1Password:

```bash
SSH_AUTH_SOCK=~/.1password/agent.sock \
  op read "op://Private/SOPS Age Key/private key" | \
  SSH_AUTH_SOCK=~/.1password/agent.sock ssh \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -p 2222 root@localhost \
    'install -d -m 700 /var/lib/sops-nix && cat > /var/lib/sops-nix/keys.txt && chmod 600 /var/lib/sops-nix/keys.txt'
```

Then reapply so sops can decrypt:

```bash
nix run .#switch -- test-vm
```

Verify secrets are decrypted:

```bash
SSH_AUTH_SOCK=~/.1password/agent.sock ssh \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -p 2222 cunbidun@localhost \
  'ls /run/secrets/'
```

---

## Iterating on config

After the initial install, rebuild from local dotfiles without pushing to git:

```bash
nix run .#switch -- test-vm
```

This builds locally and deploys to the VM over SSH.

## Teardown

```bash
pkill -f "test-vm.qcow2"
rm ~/tmp/test-vm.qcow2
```
