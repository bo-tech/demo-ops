let
  # A site sets these, and the three addresses below.
  network = {
    gateway = "192.0.2.1";
  };

  sshAuthorizedKeys = [
    # "ssh-ed25519 AAAA... user@host"
  ];


  node =
    { index, mac, isLeader, address }:
    {
      inherit index mac isLeader sshAuthorizedKeys;
      network = network // { inherit address; };
    };
in
[
  (node { index = "01"; isLeader = true;  mac = "02:00:00:de:03:01"; address = "192.0.2.21"; })
  (node { index = "02"; isLeader = false; mac = "02:00:00:de:03:02"; address = "192.0.2.22"; })
  (node { index = "03"; isLeader = false; mac = "02:00:00:de:03:03"; address = "192.0.2.23"; })
]
