{ pkgs, ... }:

let
  vercel = pkgs.buildNpmPackage {
    pname = "vercel";
    version = "54.5.0";

    src = ../pkgs/vercel;

    npmDepsHash = "sha256-XrldPzgt4beNLwQ7AXxDjWlpftVGnmgDhqDU5nw/VMM=";

    dontNpmBuild = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib $out/bin
      cp -r node_modules $out/lib/
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/vercel \
        --add-flags "$out/lib/node_modules/vercel/dist/vc.js"
      runHook postInstall
    '';
  };
in

{
  home.packages = [ vercel ];
}