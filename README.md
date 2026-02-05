個人用nixパッケージ管理リポジトリ

nix-darwin インストールコマンド
```shell
$ sudo nix run nix-darwin -- switch --flake .#mac-config
```

home-manager インストールコマンド
```shell
$  nix run nixpkgs#home-manager -- switch --flake .#myHomeConfig --show-trace
```

nixの容量削減
```shell
$ nix-store --gc
```
