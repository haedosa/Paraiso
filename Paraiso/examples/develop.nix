{ pkgs }: with pkgs; let

in mkShell {
  buildInputs =
    (with haskellPackages;
    [ ghcid
      (ghcWithPackages (p: [p.Paraiso ]))
    ]) ++
    [
      cabal-install
    ];
}
