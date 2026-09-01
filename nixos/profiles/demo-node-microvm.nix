# No argument carries a default: a host file that omits one must fail
# to evaluate rather than deploy a stand-in value.
{
  index,
  mac,
  isLeader,
  network,
  sshAuthorizedKeys,
}:

{
  imports = [ ./demo-microvm.nix ];

  networking.hostName = "demo-node-${index}-microvm";

  business-operations = {
    enable = true;
    role = "controller+worker";
    cluster.isLeader = isLeader;
    cluster.multipleControllers = true;
    serialConsole = true;
    inherit network sshAuthorizedKeys;
  };

  services.getty.autologinUser = "root";

  systemd.network.links."10-eth0" = {
    matchConfig.MACAddress = mac;
    linkConfig.Name = "eth0";
  };

  microvm.interfaces = [ {
    type = "bridge";
    id = "vm-node-${index}";
    bridge = "br0";
    mac = mac;
  } ];
}
