{
  boot.kernelParams = [
    # Use classic eth0 naming across VM hypervisors (QEMU, UTM) to simplify
    # configuration.
    "net.ifnames=0"
  ];

  networking.hostName = "dev";

  custom.business-operations = {
    enable = true;
    role = "single-node";
    serialConsole = true;
    network = {
      address = "192.0.2.20";
      gateway = "192.0.2.1";
      interface = "ens3";
    };
    sshAuthorizedKeys = [
      "ssh-ed25519 AAAA... user@host"
    ];
  };

  services.getty.autologinUser = "root";

  system.stateVersion = "25.11";
}
