{
  description = "kouheisakai's nix configuration";

  inputs = {
    # パッケージのソース
    # nixos-unstableは最新パッケージが揃っているブランチ
    # 安定性を優先する場合は "github:NixOS/nixpkgs/nixos-24.11" のようにリリースブランチを指定する
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # claude-code だけ別ソースから最新版を取る
    # メインの nixpkgs pin は他パッケージの互換性のため据え置きたいが、
    # claude-code は活発に更新されるので新しいバージョンが欲しい。
    # 現行 nixos-unstable は 26.11 で x86_64-darwin サポートを打ち切ったため、
    # hunk (flake-parts で全システム評価) の巻き添えで使えない。
    # nixos-25.11 なら x86_64-darwin サポートを維持しつつ新しめの claude-code を提供している。
    nixpkgs-claude.url = "github:NixOS/nixpkgs/nixos-25.11";

    # home-manager: ユーザーのパッケージ・dotfilesをNixで管理するツール
    home-manager = {
      url = "github:nix-community/home-manager";
      # nixpkgsのバージョンをhome-managerと揃えることで、
      # 同じパッケージが2つのソースから重複して取得されるのを防ぐ
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hunk: レビュー志向のターミナル diff ビューア（nixpkgs に無いため公式 flake を利用）
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-claude, home-manager, hunk, ... }:
    let
      # マシン固有の設定（ユーザー名・ホームディレクトリ・アーキテクチャ）
      # クローン後に local.nix を自分の環境に合わせて編集する（README 参照）。
      local = import ./local.nix;

      # claude-code を新しい nixpkgs から取得するための評価
      pkgsClaude = import nixpkgs-claude {
        system = local.system;
        config.allowUnfree = true;
      };

      pkgs = import nixpkgs {
        system = local.system;
        # unfreeライセンスのパッケージ（claude-codeなど）を許可する
        config.allowUnfree = true;
        overlays = [
          (final: prev: {
            sling = prev.callPackage ./pkgs/sling { };
            hunk = hunk.packages.${local.system}.default;
            claude-code = pkgsClaude.claude-code;
          })
        ];
      };
    in
    {
      # home-managerの設定エントリーポイント
      # キーのユーザー名は local.nix の username と一致する
      homeConfigurations."${local.username}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # マシン固有の値を各モジュールへ渡す
        extraSpecialArgs = { inherit (local) username homeDirectory gitName gitEmail slackToken; };

        # 読み込む設定ファイル
        # home.nixがルートで、そこから各モジュールをimportする
        modules = [ ./home.nix ];
      };

      # `nix run .#home-manager -- switch --flake .` で使えるようにする
      apps.${local.system}.home-manager = {
        type = "app";
        program = "${home-manager.packages.${local.system}.home-manager}/bin/home-manager";
      };
    };
}
