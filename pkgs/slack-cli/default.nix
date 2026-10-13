{ stdenv, fetchurl, lib }:

let
  version = "4.9.0";

  sources = {
    aarch64-darwin = {
      url = "https://github.com/slackapi/slack-cli/releases/download/v${version}/slack_cli_${version}_macOS_arm64.tar.gz";
      hash = "sha256-CaX7jvZKeUpv8iNO3tGPn6T83yCg6RmerE04hvvff30=";
    };
    x86_64-darwin = {
      url = "https://github.com/slackapi/slack-cli/releases/download/v${version}/slack_cli_${version}_macOS_amd64.tar.gz";
      hash = "sha256-vXcotB98MU9zrqnNFj6nHYeDd7cPYrUiL/UOl7acZmc=";
    };
  };

  src = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "slack-cli";
  inherit version;

  src = fetchurl { inherit (src) url hash; };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    cp bin/slack $out/bin/
    chmod +x $out/bin/slack
  '';

  meta = {
    description = "Official Slack CLI for building and deploying Slack apps";
    homepage = "https://docs.slack.dev/tools/slack-cli/";
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    mainProgram = "slack";
  };
}
