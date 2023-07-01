{
  description = "Haskell development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs
    , flake-utils
    , ...
    }:

    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.default = pkgs.mkShell {
        packages =
          (with pkgs; [
            ghc
            haskell-language-server
            just
            zlib
            icu
          ]) ++
          (with pkgs.haskellPackages; [
            ghcid
            cabal-install
            containers
            fourmolu
          ]);

        shellHook = with pkgs;
          ''
            ${ghc}/bin/ghc --version
            ${cabal-install}/bin/cabal --version
          '';
      };
    });
}
