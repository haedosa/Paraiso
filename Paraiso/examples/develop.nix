{ pkgs }: with pkgs; let

in mkShell {
  buildInputs =
    (with haskellPackages;
    [ ghcid
      (ghcWithPackages (p: [p.Paraiso ]))
    ]) ++
    [
      cabal-install
      cudatoolkit
    ];
  LD_LIBRARY_PATH = lib.makeLibraryPath [
    linuxPackages.nvidia_x11
  ];
  CUDA_PATH="${cudatoolkit}";

}
