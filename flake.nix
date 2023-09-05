{
  description = "Paraiso";

  inputs = rec {

    haedosa.url = "github:haedosa/flakes";
    nixpkgs.follows = "haedosa/nixpkgs-23-05";
    flake-utils.url = "github:numtide/flake-utils";
    hmatrix.url = "github:haedosa/hmatrix/haedosa";
    hasktorch.url = "github:haedosa/hasktorch?ref=vanilla-nix";
    accelerate.url = "github:AccelerateHS/accelerate";
    accelerate.flake = false;
    accelerate-llvm.url = "github:AccelerateHS/accelerate-llvm";
    accelerate-llvm.flake = false;
    llvm-hs.url = "github:llvm-hs/llvm-hs?ref=llvm-15";
    llvm-hs.flake = false;
    cuda.url = "github:tmcdonell/cuda";
    cuda.flake = false;
    nvvm.url = "github:tmcdonell/nvvm";
    nvvm.flake = false;
    typelevel-tensor.url = "github:haedosa/typelevel-tensor";
    typelevel-tensor.flake = false;

  };

  outputs =
    inputs@{ self, nixpkgs, flake-utils, ... }:
    {
      overlay = nixpkgs.lib.composeManyExtensions
        (with inputs; [ hmatrix.overlay
                        hasktorch.overlay
                        (import ./overlay.nix inputs)
                      ]);
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

        packages = rec {
          default = paraiso;
          inherit (pkgs)
            paraiso
          ;
          inherit (pkgs.haskellPackages)
            accelerate
            accelerate-llvm
            accelerate-llvm-ptx
            accelerate-llvm-native
            llvm-hs
            llvm-hs-pure
            cuda
            libtorch-ffi
          ;
        };

      }
    );

}
