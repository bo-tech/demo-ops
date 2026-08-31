let
  mac = "02:00:00:de:01:01";
in
{
  imports = [ ../profiles/demo-microvm.nix ];

  networking.hostName = "demo-single-node-microvm";

  business-operations = {
    enable = true;
    role = "single-node";
    serialConsole = true;
    network = {
      address = "192.0.2.20";
      gateway = "192.0.2.1";
    };
    sshAuthorizedKeys = [
      # "ssh-ed25519 AAAA... user@host"
    ];
  };

  services.getty.autologinUser = "root";

  systemd.network.links."10-eth0" = {
    matchConfig.MACAddress = mac;
    linkConfig.Name = "eth0";
  };

  microvm.interfaces = [ {
    type = "bridge";
    id = "vm-demo-01";
    bridge = "br0";
    mac = mac;
  } ];
}
