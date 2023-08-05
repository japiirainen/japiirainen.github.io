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
      agda-stdlib = ps: (ps.standard-library.overrideAttrs (_: {
        version = "2.0";
        src = pkgs.fetchFromGitHub {
          repo = "agda-stdlib";
          owner = "agda";
          rev = "177dc9e983606b653a3c6af2ae2162bbc87882ad";
          sha256 = "sha256-ovnhL5otoaACpqHZnk/ucivwtEfBQtGRu4/xw4+Ws+c=";
        };
      }));
      agda = pkgs.agda.withPackages (ps: [ (agda-stdlib ps) ]);
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
          ]) ++
          [ agda ];

        shellHook = with pkgs;
          ''
            ${ghc}/bin/ghc --version
            ${cabal-install}/bin/cabal --version
          '';
      };
    });
}
