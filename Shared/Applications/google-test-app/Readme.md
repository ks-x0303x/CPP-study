# Google Test Sample Application

このプロジェクトは、Google Test (`gtest`) と Google Mock (`gmock`) を使用したサンプルアプリケーションです。

## 必要条件
- Ubuntu 環境
- `pkg-config` がインストールされていること
- `gtest` および `gmock` がシステムにインストールされていること

### 必要なパッケージのインストール
以下のコマンドで必要なパッケージをインストールしてください：

```bash
sudo apt update
sudo apt install -y build-essential meson ninja-build pkg-config libgtest-dev libgmock-dev
```

### RPM パッケージの作成とインストール

1. `create_rpm.sh` スクリプトを使用して、Google Test (`gtest`) を RPM パッケージ化します。

```
$ create_rpm.sh
```

2. 作成された RPM パッケージをインストールします。
```
$ rpm --install ./rpmbuild/RPMS/aarch64/googletest-1.14.0-1.aarch64.rpm
```

### ビルド
```
$ ./build.sh
```

### 実行
```
$ ./build/test_runner
```

### 環境変数の設定（必要な場合）
pkg-config が正しく動作しない場合、以下のコマンドで環境変数 PKG_CONFIG_PATH を設定してください：

```
export PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH
```
