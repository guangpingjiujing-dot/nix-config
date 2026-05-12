# local.nix のテンプレート（参照用）
# クローン後は local.nix を直接編集して自分の環境に合わせる。
{
  # macOS のユーザー名（`whoami` で確認できる）
  username = "yourname";

  # ホームディレクトリのパス
  homeDirectory = "/Users/yourname";

  # CPU アーキテクチャ
  # Apple Silicon (M1/M2/M3/M4) → "aarch64-darwin"
  # Intel Mac                    → "x86_64-darwin"
  system = "aarch64-darwin";

  # Git の個人情報
  gitName = "Your Name";
  gitEmail = "your@email.com";
}