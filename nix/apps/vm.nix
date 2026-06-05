{ pkgs, lib }:
let
  vmStart = pkgs.writeShellApplication {
    name = "vm-start";
    runtimeInputs = with pkgs; [ qemu netcat-openbsd git procps ];
    text = ''
      DISK="$HOME/tmp/test-vm.qcow2"
      MON_SOCK="/tmp/qemu-mon.sock"
      SSH_PORT=2222

      [ -f "$DISK" ] && { echo "ERROR: $DISK exists. Run 'nix run .#vm-destroy' first."; exit 1; }

      ISO=$(nix build "$(git rev-parse --show-toplevel)#minimal-iso" --no-link --print-out-paths)/iso/*.iso
      mkdir -p "$HOME/tmp"
      qemu-img create -f qcow2 "$DISK" 40G

      qemu-system-x86_64 \
        -enable-kvm -m 4096 -smp 4 \
        -drive "file=$DISK,if=virtio,format=qcow2" \
        -cdrom "$ISO" -boot d \
        -netdev "user,id=net0,hostfwd=tcp::$SSH_PORT-:22" \
        -device virtio-net-pci,netdev=net0 \
        -display none \
        -monitor "unix:$MON_SOCK,server,nowait" \
        -cpu host -daemonize -pidfile /tmp/test-vm.pid

      until nc -z -w2 localhost "$SSH_PORT"; do sleep 2; done
      echo "Installer up — ssh -p $SSH_PORT root@localhost  |  nix run .#vm-deploy"
    '';
  };

  vmDeploy = pkgs.writeShellApplication {
    name = "vm-deploy";
    runtimeInputs = with pkgs; [ qemu netcat-openbsd git procps ];
    text = ''
      REPO=$(git rev-parse --show-toplevel)
      DISK="$HOME/tmp/test-vm.qcow2"
      MON_SOCK="/tmp/qemu-mon.sock"
      PID_FILE="/tmp/test-vm.pid"
      SSH_PORT=2222

      if ! nc -z -w2 localhost "$SSH_PORT" 2>/dev/null; then
        echo "ERROR: no VM reachable on port $SSH_PORT. Run 'nix run .#vm-start' first."
        exit 1
      fi

      echo "Running nixos-anywhere..."
      SSH_AUTH_SOCK="$HOME/.1password/agent.sock" \
      nix run github:nix-community/nixos-anywhere -- \
        --flake "$REPO#test-vm" \
        --generate-hardware-config nixos-generate-config \
          "$REPO/nix/hosts/test-vm/hardware-configuration.nix" \
        --ssh-option "StrictHostKeyChecking=no" \
        --ssh-option "UserKnownHostsFile=/dev/null" \
        -p "$SSH_PORT" root@localhost

      echo "Rebooting into installed system..."
      pkill -f "test-vm.qcow2" || true
      rm -f "$MON_SOCK"
      sleep 2

      qemu-system-x86_64 \
        -enable-kvm -m 4096 -smp 4 \
        -drive "file=$DISK,if=virtio,format=qcow2" \
        -netdev "user,id=net0,hostfwd=tcp::$SSH_PORT-:22" \
        -device virtio-net-pci,netdev=net0 \
        -display none \
        -monitor "unix:$MON_SOCK,server,nowait" \
        -cpu host -daemonize -pidfile "$PID_FILE"

      echo "Waiting for installed system to boot..."
      until nc -z -w2 localhost "$SSH_PORT"; do sleep 2; done

      echo ""
      echo "Stage 1 complete. Next: place the age key then run: nix run .#switch -- test-vm"
    '';
  };

  vmDestroy = pkgs.writeShellApplication {
    name = "vm-destroy";
    runtimeInputs = with pkgs; [ procps ];
    text = ''
      DISK="$HOME/tmp/test-vm.qcow2"
      PID_FILE="/tmp/test-vm.pid"
      MON_SOCK="/tmp/qemu-mon.sock"

      if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
          echo "Stopping VM (pid $PID)..."
          kill "$PID"
        fi
        rm -f "$PID_FILE"
      fi

      pkill -f "test-vm.qcow2" 2>/dev/null || true
      rm -f "$MON_SOCK"

      if [ -f "$DISK" ]; then
        echo "Removing $DISK..."
        rm -f "$DISK"
      fi

      echo "Done."
    '';
  };
in {
  vm-start  = { type = "app"; program = "${vmStart}/bin/vm-start"; };
  vm-deploy = { type = "app"; program = "${vmDeploy}/bin/vm-deploy"; };
  vm-destroy = { type = "app"; program = "${vmDestroy}/bin/vm-destroy"; };
}
