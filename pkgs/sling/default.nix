{ stdenv, fetchurl, lib }:

let
  version = "1.5.20";

  sources = {
    aarch64-darwin = {
      url = "https://github.com/slingdata-io/sling-cli/releases/download/v${version}/sling_darwin_arm64.tar.gz";
      hash = "sha256-BEbRJftyDCHE1RaNpCsHCNIFpZNmBc2gYmI0uX/jXfw=";
    };
    x86_64-darwin = {
      url = "https://github.com/slingdata-io/sling-cli/releases/download/v${version}/sling_darwin_amd64.tar.gz";
      hash = lib.fakeHash;
    };
  };

  src = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "sling";
  inherit version;

  src = fetchurl { inherit (src) url hash; };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    cp sling $out/bin/
    chmod +x $out/bin/sling
  '';

  meta = {
    description = "ELT tool for moving data between databases and files";
    homepage = "https://slingdata.io";
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    mainProgram = "sling";
  };
}
