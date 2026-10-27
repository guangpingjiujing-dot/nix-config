{
  lib,
  stdenvNoCC,
  fetchurl,
  versionCheckHook,
}:

let
  version = "1.4.7";
  buildId = "5900205422411776";
  wholeVersion = "${version}-${buildId}";

  sources = {
    aarch64-darwin = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-AZLJkw/I7M3ceu2Wpq/ekV8p7jgMgba2qDXmjk8ZUFFNmKWWqH+6ubHYe6JJIeKTJ68GS6yM7Qu4c+eCQ4Jt6Q==";
    };
    x86_64-darwin = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-l0+RBjsvXwHIlXMwTwHvsnMZrBIoofBuG46DUJsHb9y3fNUrSItyJVSqCkQ6K4rd7eXa/711pB+dUexdEIoS0Q==";
    };
    aarch64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-ap+g32MAYzQEVx9m7HkkCYzHCp8jrFXDZZE5u8vdLqUwH+Hvco1MBk+sZRBOoUordEIfMgqC5bzyGMSCtY46Fg==";
    };
    x86_64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-vtp2BYdYn1gnsLUWw+wsW9XNLpHrDiUzgHuh6ZCifc1jrvAZHgt2+2D+qw0W6qghD7eYQsNN1ICeJX4XEu3RUg==";
    };
  };

  src = sources.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "antigravity-cli";
  inherit version;

  src = fetchurl { inherit (src) url hash; };

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 antigravity $out/bin/agy
    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Google Antigravity CLI (agy)";
    homepage = "https://antigravity.google";
    changelog = "https://antigravity.google/changelog";
    license = lib.licenses.unfree;
    platforms = lib.attrNames sources;
    mainProgram = "agy";
  };
}
