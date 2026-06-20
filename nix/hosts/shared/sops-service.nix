{ config, pkgs, ... }:
{
  systemd.services.sops-nix = {
    description = "sops-nix activation";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "sops-nix-system" config.system.activationScripts.setupSecrets.text;
    };
  };
}
