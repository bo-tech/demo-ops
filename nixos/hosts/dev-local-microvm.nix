{ lib, ... }:

let
  mac = "02:00:00:de:03:01";
in
{
  imports = [ ../profiles/demo-microvm.nix ];

  networking.hostName = "dev-local-microvm";

  business-operations = {
    enable = true;
    role = "single-node";
    serialConsole = true;
    # The address lies in the workstation's guest bridge, and the
    # gateway is the workstation itself.
    network = {
      address = "192.0.2.21";
      gateway = "192.0.2.1";
      nameservers = [ "192.0.2.2" ];
    };
    sshAuthorizedKeys = [
      # "ssh-ed25519 AAAA... user@host"
    ];
  };

  services.getty.autologinUser = "root";

  microvm.mem = lib.mkForce 8192;

  systemd.network.links."10-eth0" = {
    matchConfig.MACAddress = mac;
    linkConfig.Name = "eth0";
  };

  microvm.interfaces = [ {
    type = "bridge";
    id = "vm-dev-local";
    bridge = "br0";
    mac = mac;
  } ];
}
