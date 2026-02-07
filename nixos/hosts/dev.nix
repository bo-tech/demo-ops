{sshPubKey, ...}: {
  networking.hostName = "dev";
  networking.useDHCP = true;

  services.k0s = {
    spec = {
      api.address = "192.168.65.7";
      api.sans = ["192.168.65.7"];
    };
    controller.isLeader = true;
    role = "controller+worker";
  };

  users.users.root.openssh.authorizedKeys.keys = [sshPubKey];

  users.users.admin = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [sshPubKey];
  };

  services.getty.autologinUser = "root";

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.11";
}
