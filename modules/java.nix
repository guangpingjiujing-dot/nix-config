{ pkgs, ... }:

{
  # Java 実行環境（JDK）
  # PySpark 4.x は JVM 上で動くため Java 17 以上が必須。
  # Spark 4 がサポートするのは Java 17 / 21 なので LTS の 21 を採用する。
  home.packages = [ pkgs.jdk21 ];

  # PySpark やビルドツールは java コマンドではなく JAVA_HOME を見るものが多いため明示する
  home.sessionVariables = {
    JAVA_HOME = pkgs.jdk21.home;
  };
}
