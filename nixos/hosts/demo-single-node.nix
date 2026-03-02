{
  networking.hostName = "demo-single-node";

  custom.business-operations = {
    enable = true;
    role = "single-node";
    network = {
      address = "192.0.2.10";
      gateway = "192.0.2.1";
      interface = "enp0s1";
    };
    sshAuthorizedKeys = [
      "ssh-ed25519 AAAA... user@host"
    ];
  };

  system.stateVersion = "25.11";
}
