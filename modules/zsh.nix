{ ... }:

{
  programs.zsh = {
    enable = true;

    # キーマップを emacs モードに固定する
    # デフォルトでは $EDITOR に "vi" が含まれると vi モードになるため、
    # programs.neovim.defaultEditor = true（EDITOR=nvim）を設定すると
    # zsh が自動で vi モードに切り替わり Ctrl+F などが使えなくなる
    defaultKeymap = "emacs";

    # ディレクトリ名だけで cd できるようにする（例: ~/project → cd ~/project が不要）
    autocd = true;

    # コマンド入力中にシンタックスハイライトを表示する
    # 例: 存在するコマンドは緑、存在しないコマンドは赤
    syntaxHighlighting.enable = true;

    # 過去のコマンド履歴をグレーでサジェストしてくれる
    # →キーで補完、Ctrl+Fで一語補完
    autosuggestion.enable = true;

    # エイリアス（コマンドの短縮形）
    shellAliases = {
      # macOSのlsはBSD版のため -G でカラー表示になる
      ls = "ls -laG";   # デフォルトで詳細表示＋隠しファイル表示
      ll = "ls -lhG";   # 詳細表示
      la = "ls -lahG";  # 隠しファイルも含めた詳細表示
      vim = "nvim";
    };

    initContent = ''
      eval "$(pyenv init -)"
    '';

    # コマンド履歴の設定
    history = {
      size = 10000;       # メモリ上に保持する件数
      save = 10000;       # ファイルに保存する件数
      ignoreDups = true;  # 同じコマンドの連続実行は1件だけ残す
      ignoreSpace = true; # スペース始まりのコマンドは履歴に残さない
      share = true;       # 複数ターミナル間で履歴を共有する
    };
  };

  # Starship: Rust製の高速プロンプト
  # git状態・ディレクトリ・言語バージョンなどをカラフルに表示してくれる
  # 多くの開発者が使用しているデファクトスタンダードなプロンプト
  programs.starship = {
    enable = true;
    settings = {
      # コマンドの前に空行を入れて見やすくする
      add_newline = true;

      directory = {
        # デフォルトではgitリポジトリのルート名だけ表示されるが、
        # falseにすることでホームからのパスを表示するようになる
        truncate_to_repo = false;

        # 親ディレクトリを何文字に省略するか（fish shellスタイル）
        # 1にすると ~/.c/nix-config のように各ディレクトリが1文字になる
        fish_style_pwd_dir_length = 1;
      };

      python = {
        # venvがアクティブなときだけ表示する（蛇の絵文字・バージョンは出さない）
        # ''${...} は Nix 文字列内で ${ をエスケープする書き方
        format = ''\(''${virtualenv}\) '';
        # VIRTUAL_ENV がセットされていれば（＝venvがactive）、
        # Pythonファイルがないディレクトリでも常に表示する
        detect_env_vars = [ "VIRTUAL_ENV" ];
      };

      # git の変更状態をシンボル＋ファイル数で表示する
      # !3+2 のように各状態が何ファイルあるか分かるようにする
      git_status = {
        modified  = ''!''${count}'';
        staged    = ''+''${count}'';
        deleted   = ''✘''${count}'';
        renamed   = ''»''${count}'';
        untracked = ''?''${count}'';
        stashed   = ''\$''${count}'';
        ahead     = ''⇡''${count}'';
        behind    = ''⇣''${count}'';
        diverged  = ''⇕⇡''${ahead_count}⇣''${behind_count}'';
      };

      # pyproject.toml / package.json などのバージョン表示を非表示にする
      package.disabled = true;
    };
  };
}
