{ pkgs, ... }:

let
  qiita = pkgs.buildNpmPackage {
    pname = "qiita-cli";
    version = "1.9.1";

    src = ../pkgs/qiita;

    npmDepsHash = "sha256-3kUhZnP/0kHrPlER+RatNuztXoPml++0tZixll1TGvo=";

    dontNpmBuild = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/qiita-cli $out/bin
      cp -r node_modules $out/lib/qiita-cli/
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/qiita \
        --add-flags "$out/lib/qiita-cli/node_modules/@qiita/qiita-cli/dist/main.js"
      runHook postInstall
    '';
  };
in

{
  home.packages = [ qiita ];
}