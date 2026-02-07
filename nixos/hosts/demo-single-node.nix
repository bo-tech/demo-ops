{sshPubKey, ...}: {
  networking.hostName = "demo-single-node";

  networking.nameservers = ["192.0.2.1"];
  networking.defaultGateway = "192.0.2.1";
  networking.interfaces.enp0s1.ipv4.addresses = [
    {
      address = "192.0.2.10";
      prefixLength = 24;
    }
  ];

  services.k0s = {
    spec.api.address = "192.0.2.10";
    controller.isLeader = true;
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
