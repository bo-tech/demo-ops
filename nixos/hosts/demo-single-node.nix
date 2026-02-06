{...}: let
  sshPubKey = builtins.readFile ../../.secrets/ssh_key.pub;
in {
  networking.hostName = "demo-single-node";

  networking.nameservers = ["10.0.0.1"];
  networking.defaultGateway = "10.0.0.1";
  networking.interfaces.enp0s1.ipv4.addresses = [
    {
      address = "10.0.0.10";
      prefixLength = 24;
    }
  ];

  services.k0s = {
    spec = {
      api.address = "10.0.0.10";
      api.sans = ["10.0.0.10"];
    };
    isLeader = true;
    role = "controller+worker";
  };

  users.users.root.openssh.authorizedKeys.keys = [sshPubKey];

  users.users.admin = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [sshPubKey];
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.11";
}
