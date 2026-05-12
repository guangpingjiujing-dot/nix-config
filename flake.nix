{
  description = "kouheisakai's nix configuration";

  inputs = {
    # パッケージのソース
    # nixos-unstableは最新パッケージが揃っているブランチ
    # 安定性を優先する場合は "github:NixOS/nixpkgs/nixos-24.11" のようにリリースブランチを指定する
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager: ユーザーのパッケージ・dotfilesをNixで管理するツール
    home-manager = {
      url = "github:nix-community/home-manager";
      # nixpkgsのバージョンをhome-managerと揃えることで、
      # 同じパッケージが2つのソースから重複して取得されるのを防ぐ
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # マシン固有の設定（ユーザー名・ホームディレクトリ・アーキテクチャ）
      # クローン後に local.nix を自分の環境に合わせて編集する（README 参照）。
      local = import ./local.nix;

      pkgs = import nixpkgs {
        system = local.system;
        # unfreeライセンスのパッケージ（claude-codeなど）を許可する
        config.allowUnfree = true;
      };
    in
    {
      # home-managerの設定エントリーポイント
      # キーのユーザー名は local.nix の username と一致する
      homeConfigurations."${local.username}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # マシン固有の値を各モジュールへ渡す
        extraSpecialArgs = { inherit (local) username homeDirectory gitName gitEmail; };

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
