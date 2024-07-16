{
  description = "BlbleRunner flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (sys: f nixpkgs.legacyPackages.${sys});
    in
    rec {
      packages = forAllSystems (pkgs: {
        default = pkgs.callPackage ./. { };
      });
      devShells = forAllSystems (pkgs: {
        default =
          pkgs.mkShell {
            nativeBuildInputs = with pkgs; [ rustc cargo gcc rustfmt clippy ];
            RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          };
      });
    };
}
