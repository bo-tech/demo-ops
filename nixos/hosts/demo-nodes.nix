# The three guests of the multi node demo cluster. flake.nix builds one
# nixosConfiguration per entry, through nixos/profiles/demo-node-microvm.nix.
#
# Node 01 is the leader: it mints the join tokens the other two use.
let
  site = {
    gateway = "192.0.2.1";
    sshAuthorizedKeys = [
      # "ssh-ed25519 AAAA... user@host"
    ];
  };
in
[
  (site // { index = "01"; isLeader = true;  mac = "02:00:00:de:03:01"; address = "192.0.2.21"; })
  (site // { index = "02"; isLeader = false; mac = "02:00:00:de:03:02"; address = "192.0.2.22"; })
  (site // { index = "03"; isLeader = false; mac = "02:00:00:de:03:03"; address = "192.0.2.23"; })
]
