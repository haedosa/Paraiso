{ pkgs }: with pkgs; let

  ghcid-bin = haskellPackages.ghcid.bin;

  mk-ghcid-command = { name, target }:
  runCommand name { buildInputs = [ makeWrapper ]; } ''
    makeWrapper "${ghcid-bin}/bin/ghcid" \
                $out/bin/${name} \
                --add-flags \
                "--command='cabal repl ${target}' \
                --test 'Main.main'"
  '';

  ghcid-test-paraiso = mk-ghcid-command { name = "ghcid-test-paraiso"; target = "Paraiso:runtests"; };

in haskellPackages.shellFor {
  withHoogle = true;
  packages = p: with p; [
    Paraiso
  ];
  buildInputs =
    (with haskellPackages;
    [ haskell-language-server
      ghcid
      threadscope
    ]) ++
    [
      ghcid-bin
      ghcid-test-paraiso
      cabal-install
    ];
}
