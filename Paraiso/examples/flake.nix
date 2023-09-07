{
  description = "Paraiso Examples";

  inputs = rec {

    paraiso.url = "github:haedosa/Paraiso";
    flake-utils.follows = "paraiso/flake-utils";
    nixpkgs.follows = "paraiso/nixpkgs";

  };

  outputs =
    inputs@{ self, nixpkgs, flake-utils, ... }:
    {
      overlay = nixpkgs.lib.composeManyExtensions
        (with inputs; [ paraiso.overlay ]);
    } // flake-utils.lib.eachDefaultSystem (system:

      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = [
            self.overlay
          ];
        };

      in
      {
        inherit pkgs;

        devShells.default = import ./develop.nix { inherit pkgs; };

        packages = {
          default = pkgs.paraiso;
          inherit (pkgs) paraiso;
        };

      }
    );

}
