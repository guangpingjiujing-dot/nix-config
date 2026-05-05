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
      # 使用するシステムアーキテクチャ
      # Apple Silicon Mac → "aarch64-darwin"
      # Intel Mac         → "x86_64-darwin"
      system = "aarch64-darwin";

      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # home-managerの設定エントリーポイント
      # キーのユーザー名はシステムのユーザー名と一致させる必要がある
      homeConfigurations."kouheisakai" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # 読み込む設定ファイル
        # home.nixがルートで、そこから各モジュールをimportする
        modules = [ ./home.nix ];
      };
    };
}
