{
  description = "demo-ops documentation build using sphinx-builder";

  inputs = {
    sphinx-builder.url = "github:bo-tech/sphinx-builder";
    nixpkgs.follows = "sphinx-builder/nixpkgs";
    flake-utils.follows = "sphinx-builder/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, sphinx-builder }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        builder = sphinx-builder.packages.${system};
        src = pkgs.lib.cleanSource ./..;
        projectSlug = "demo-ops";
        docName = "${projectSlug}-docs";

        makeRunner = pkgs.writeShellApplication {
          name = "docs-make";
          runtimeInputs = [ builder.full-sphinx-env ];
          text = ''
            set -euo pipefail
            exec make "$@"
          '';
        };
      in
      {
        packages.html = pkgs.stdenv.mkDerivation {
          name = docName;
          inherit src;
          nativeBuildInputs = [
            builder.full-sphinx-env
          ];

          buildPhase = ''
            pushd docs
            make html
            popd
          '';

          installPhase = ''
            pushd docs
            mkdir -p "$out/share/doc/$name"
            cp -r _build/html "$out/share/doc/$name"

            mkdir -p "$out/nix-support"
            echo "doc manual $out/share/doc/$name/html index.html" \
              >> "$out/nix-support/hydra-build-products"
            popd
          '';
        };

        packages.pdf = pkgs.stdenv.mkDerivation {
          name = "${docName}-pdf";
          inherit src;
          nativeBuildInputs = [
            builder.full-sphinx-env
          ];

          buildPhase = ''
            pushd docs
            export TEXMFVAR="$TMPDIR/texmf-var"
            export TEXMFCONFIG="$TMPDIR/texmf-config"
            export TEXMFHOME="$TMPDIR/texmf-home"
            make latexpdf
            popd
          '';

          installPhase = ''
            pushd docs
            mkdir -p "$out/share/doc/$name"
            cp _build/latex/*.pdf "$out/share/doc/$name"/

            mkdir -p "$out/nix-support"
            for f in "$out"/share/doc/$name/*.pdf; do
              echo "doc manual $f" >> "$out/nix-support/hydra-build-products"
            done
            popd
          '';
        };

        devShells.default = pkgs.mkShell {
          packages = [
            builder.full-sphinx-env
          ];
        };

        apps.default = flake-utils.lib.mkApp { drv = makeRunner; };
        apps.make = flake-utils.lib.mkApp { drv = makeRunner; };
      });
}
