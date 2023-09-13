inputs:

final: prev: with final; {

  cudaPackages = cudaPackages_11_8;
  cudatoolkit = cudaPackages_11_8.cudatoolkit;

  haskell = let
    packageOverrides = lib.composeManyExtensions [
      (prev.haskell.packageOverrides or (_: _: {}))
      (hfinal: hprev: let
        inherit (final.haskell.lib) doJailbreak markUnbroken overrideCabal;
        appendNativeBuildInputs = pkg: list: pkg.overrideAttrs (drv: {
          nativeBuildInputs = (drv.nativeBuildInputs or []) ++ list;
        });
        callCabal2nix' = name: path: arg:
          addCudaEnv
            (appendNativeBuildInputs
              (hfinal.callCabal2nix name path arg) [ libxml2 cudatoolkit ]);
        addCudaEnv = hpkg: overrideCabal hpkg (drv: {
          extraLibraries = (drv.extraLibraries or []) ++ [linuxPackages.nvidia_x11];
          configureFlags = (drv.configureFlags or []) ++ [
            "--extra-lib-dirs=${cudatoolkit.lib}/lib"
            "--extra-include-dirs=${cudatoolkit}/include"
          ];
          preConfigure = (drv.preConfigure or "") + ''
            export CUDA_PATH=${cudatoolkit}
          '';
        });
        in
        {
          Paraiso = callCabal2nix' "Paraiso" ./Paraiso {};
          # typelevel-tensor = doJailbreak (markUnbroken hprev.typelevel-tensor);
          typelevel-tensor = hfinal.callCabal2nix "tyelevel-tensor" inputs.typelevel-tensor {};
          accelerate = hfinal.callCabal2nixWithOptions "accelerate" inputs.accelerate "-fnofib" {};
          accelerate-llvm = (hfinal.callCabal2nix "accelerate-llvm" "${inputs.accelerate-llvm}/accelerate-llvm" {}).overrideAttrs (drv:
            { postUnpack = (drv.postUnpack or "") + ''
                rm -f accelerate-llvm/LICENSE
                cp -f "${inputs.accelerate-llvm}/LICENSE" accelerate-llvm/LICENSE
              '';
              nativeBuildInputs = (drv.nativeBuildInputs or []) ++ [ llvm_15 libxml2 ];
            });
          accelerate-llvm-ptx = overrideCabal ((hfinal.callCabal2nix "accelerate-llvm-ptx" "${inputs.accelerate-llvm}/accelerate-llvm-ptx" {  }).overrideAttrs (drv:
            { postUnpack = (drv.postUnpack or "") + ''
                rm -f accelerate-llvm-ptx/LICENSE accelerate-llvm-ptx/src/Language/Haskell/TH/Extra.hs
                cp -f "${inputs.accelerate-llvm}/LICENSE" accelerate-llvm-ptx/LICENSE
                cp -f "${inputs.accelerate-llvm}/accelerate-llvm/src/Language/Haskell/TH/Extra.hs" accelerate-llvm-ptx/src/Language/Haskell/TH/Extra.hs
              '';
              nativeBuildInputs = drv.nativeBuildInputs ++ [ llvm_15 libxml2 ];
            })) (drv: {
              doCheck = false;
            });
          accelerate-llvm-native = overrideCabal ((hfinal.callCabal2nix "accelerate-llvm-native" "${inputs.accelerate-llvm}/accelerate-llvm-native" {}).overrideAttrs (drv:
            { postUnpack = (drv.postUnpack or "") + ''
                rm -f accelerate-llvm-native/LICENSE accelerate-llvm-native/src/Language/Haskell/TH/Extra.hs
                cp -f "${inputs.accelerate-llvm}/LICENSE" accelerate-llvm-native/LICENSE
                cp -f "${inputs.accelerate-llvm}/accelerate-llvm/src/Language/Haskell/TH/Extra.hs" accelerate-llvm-native/src/Language/Haskell/TH/Extra.hs
              '';
              nativeBuildInputs = drv.nativeBuildInputs ++ [ pkgs.llvm_15 pkgs.libxml2 ];
            })) (drv: {
              doCheck = false;
            });
          llvm-hs = appendNativeBuildInputs (hfinal.callCabal2nix "llvm-hs" "${inputs.llvm-hs}/llvm-hs" {}) [ llvm_15 libxml2 ];
          llvm-hs-pure = hfinal.callCabal2nix "llvm-hs-pure" "${inputs.llvm-hs}/llvm-hs-pure" {};
          cuda = callCabal2nix' "cuda" inputs.cuda {};
          nvvm = hfinal.callCabal2nix "nvvm" inputs.nvvm {};
        })
  ];
  in prev.haskell // { inherit packageOverrides; };

  paraiso-bin = haskell.lib.justStaticExecutables haskellPackages.mldosa;
  paraiso = haskellPackages.Paraiso;

}
