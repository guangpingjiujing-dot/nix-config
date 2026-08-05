{ pkgs, ... }:

let
  zenn = pkgs.buildNpmPackage {
    pname = "zenn-cli";
    version = "0.5.2";

    src = ../pkgs/zenn;

    npmDepsHash = "sha256-WSyD+YOCVDf0GdghsfZIMa/YDDaS0nfSxf/Es6rxq5w=";

    dontNpmBuild = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/zenn-cli $out/bin
      cp -r node_modules $out/lib/zenn-cli/
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/zenn \
        --add-flags "$out/lib/zenn-cli/node_modules/zenn-cli/dist/server/zenn.js"
      runHook postInstall
    '';
  };
in

{
  home.packages = [ zenn ];
}