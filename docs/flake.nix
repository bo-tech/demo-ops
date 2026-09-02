{
  description = "demo-ops documentation build using sphinx-builder";

  inputs = {
    sphinx-builder.url = "git+https://codeberg.org/johbo/sphinx-builder.git";
    nixpkgs.follows = "sphinx-builder/nixpkgs";
    flake-utils.follows = "sphinx-builder/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      sphinx-builder,
    }:
    flake-utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ]
      (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          builder = sphinx-builder.packages.${system};
          src = pkgs.lib.cleanSource ./..;
          projectSlug = "demo-ops";
          docName = "${projectSlug}-docs";

          # Sphinx renders the year of SOURCE_DATE_EPOCH as the copyright
          # year, so the last commit's date advances it on its own.
          sourceDateEpoch = toString self.lastModified;

          # stdenv defaults the epoch to 1980, which renders as the
          # copyright year without failing. Not `preBuild`: a `buildPhase`
          # attribute replaces the function that runs the hooks.
          refuseAPlaceholderEpoch = ''
            year=$(date -u -d "@$SOURCE_DATE_EPOCH" +%Y)
            if [ "$year" -lt 2000 ]; then
              echo "SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH renders the copyright year as $year" >&2
              exit 1
            fi
          '';

          makeRunner = pkgs.writeShellApplication {
            name = "docs-make";
            runtimeInputs = [ builder.full-sphinx-env ];
            text = ''
              set -euo pipefail
              exec make "$@"
            '';
          };
          makeApp = flake-utils.lib.mkApp { drv = makeRunner; } // {
            meta.description = "Run make in the documentation environment";
          };
        in
        {
          formatter = pkgs.nixfmt-tree;

          packages.html = pkgs.stdenv.mkDerivation {
            name = docName;
            inherit src;
            SOURCE_DATE_EPOCH = sourceDateEpoch;
            nativeBuildInputs = [
              builder.full-sphinx-env
            ];

            buildPhase = ''
              ${refuseAPlaceholderEpoch}
              pushd docs
              make html SPHINXOPTS="-W"
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
            SOURCE_DATE_EPOCH = sourceDateEpoch;
            nativeBuildInputs = [
              builder.full-sphinx-env
            ];

            buildPhase = ''
              ${refuseAPlaceholderEpoch}
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

          apps.default = makeApp;
          apps.make = makeApp;
          apps.watch = sphinx-builder.apps.${system}.watch;
        }
      );
}
