{ ... }:
{
  # GUIアプリ(launchd経由で起動されるアプリ)向けの環境変数。
  # GUIアプリはシェルの環境変数を継承しないため、launchctl setenv 相当を
  # nix-darwin で宣言的に設定する。
  launchd.user.envVariables = {
    # Orca IDE の内蔵SSHトランスポートはリモートホストで exec に失敗し
    # 「Could not detect the remote platform: Unable to exec」となるため、
    # システムの ssh(/usr/bin/ssh)経由に強制して回避する。
    ORCA_SSH_FORCE_SYSTEM_TRANSPORT = "1";
  };
}
