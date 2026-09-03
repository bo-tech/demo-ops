# demo-ops

Example deployment showing how to consume
[business-operations](https://codeberg.org/business-operations/business-operations).

This repository defines a minimal k0s cluster, on a single node or on
three, covering NixOS deployment and cluster bootstrap with Cilium and
OpenEBS.

- Documentation: <https://business-operations.codeberg.page/demo-ops/>
- Source code: <https://codeberg.org/business-operations/demo-ops>


## Status - Experimental

This is an early example. Its application layer covers cert-manager,
LLDAP and Authelia rather than the platform's full set.

See the [getting started guide](https://business-operations.codeberg.page/demo-ops/getting-started.html)
for deployment instructions.


## Contact

Reach me via [`@jbornhold:matrix.org`](https://matrix.to/#/@jbornhold:matrix.org)
or [`@johbo@mastodon.social`](https://mastodon.social/@johbo).


## License

MIT, see [`LICENSES/MIT.txt`](LICENSES/MIT.txt). The repository follows
[REUSE](https://reuse.software/), so `reuse lint` states the licensing of
every file.
