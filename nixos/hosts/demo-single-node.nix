{
  boot.kernelParams = [
    # Use classic eth0 naming across VM hypervisors (QEMU, UTM) to simplify
    # configuration.
    "net.ifnames=0"
  ];

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

  services.getty.autologinUser = "root";

  system.stateVersion = "25.11";
}
