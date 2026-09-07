{ pkgs, ... }:

let
  # zvec-grep (zg): ripgrep / BM25 / ベクトル検索を統合したローカル検索 CLI
  # nixpkgs に無いため npm パッケージ @zvec/zvec-grep を buildNpmPackage で導入する
  zvec-grep = pkgs.buildNpmPackage {
    pname = "zvec-grep";
    version = "0.2.1";

    src = ../pkgs/zvec-grep;

    npmDepsHash = "sha256-PeB+juWoqcMMpwfWBWRliyGKMdBptCwnUdTL13yotJs=";

    # 依存の postinstall（onnxruntime-node 等）はビルド中にネットワークへ出るため無効化する。
    # ripgrep / node-llama-cpp / zvec のネイティブバイナリは
    # プラットフォーム別 npm パッケージ（@vscode/ripgrep-darwin-arm64 など）で配布されるため
    # スクリプトを実行しなくても揃う。
    npmFlags = [ "--ignore-scripts" ];
    dontNpmBuild = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/zvec-grep $out/bin
      cp -r node_modules $out/lib/zvec-grep/
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/zg \
        --add-flags "$out/lib/zvec-grep/node_modules/@zvec/zvec-grep/dist/cli/index.js"
      runHook postInstall
    '';
  };
in

{
  home.packages = [ zvec-grep ];
}
