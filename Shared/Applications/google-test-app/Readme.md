# Google Test Sample Application

このプロジェクトは、Google Test (`gtest`) と Google Mock (`gmock`) を使用したサンプルアプリケーションです。

## 必要条件
- C++ ビルド環境
- `pkg-config` がインストールされていること
- `gtest` および `gmock` が利用できること
- RPM を作成する場合: `rpmbuild` が利用できること

補足: `rpm` は「RPMファイルの参照/展開」には使えますが、依存関係を解決しながらインストールするには RPM 系ディストリビューション（`dnf`/`yum`）での検証が確実です。

### 必要なパッケージのインストール
例（Ubuntu）: 以下のコマンドで必要なパッケージをインストールしてください：

```bash
sudo apt update
sudo apt install -y build-essential meson ninja-build pkg-config libgtest-dev libgmock-dev
```

## RPM パッケージ化（事前ビルド成果物を固める）

このディレクトリの `create_rpm.sh` は「事前にビルド済みの成果物/ヘッダ」を、設定ファイルで指定して RPM に固めます。

### 手順（RPM 作成）

1. 事前にビルドして成果物を用意します。

```
$ ./build.sh
```

2. カレントディレクトリに設定ファイル `rpm-package.json` / `rpm-package.yaml` / `rpm-package.yml` のいずれかを用意します。

- サンプル: `rpm-package.json.example` / `rpm-package.yaml.example`
- サンプルをそのまま使う場合は `--config` で指定できます。
- もしくは、サンプルを `rpm-package.yaml` のようにリネームすれば、引数なしで実行できます。

3. `create_rpm.sh` を実行して、指定された成果物を RPM に固めます。

```
$ ./create_rpm.sh

# 例: サンプル設定を指定して実行
$ ./create_rpm.sh --config rpm-package.yaml.example
```

4. 作成された RPM は `./rpmbuild/RPMS/*/*.rpm` に出力されます。

補足: 旧方式（ソースをダウンロードしてビルドする）は `create_rpm_from_source.sh` を使用します。

### 設定ファイル（rpm-package.*）の位置づけ

`rpm-package.(yaml|yml|json)` は「どのファイルを RPM に含め、どこへインストールされるべきか」を宣言するためのファイルです。

- `package`: RPM のメタ情報
  - `name`, `version`, `release`, `summary`, `license`, `description`
  - `url` は任意
  - `arch` は任意（例: `aarch64`, `x86_64`）
- `files`: RPM に含めるファイル一覧
  - 単体ファイル指定: `src`（glob 可） + `dest`
  - 複数ファイル指定: `src`（glob 可） + `dest_dir`
  - ディレクトリ指定: `src_dir` + `dest_dir`（`include` で絞り込み可）
  - `mode` は文字列で指定（例: `"0755"`, `"0644"`）

YAML を使用する場合は PyYAML が必要です（例: `python3 -m pip install pyyaml`）。JSON の場合は不要です。

### RPM の中身確認

RPM ファイルをインストールせずに中身だけ確認できます。

```bash
rpm -qpl ./rpmbuild/RPMS/*/*.rpm
rpm -qpR ./rpmbuild/RPMS/*/*.rpm
```

### RPM のインストール（推奨: RPM 系ディストリビューション）

RPM 系ディストリビューション（Fedora/RHEL/Rocky/Alma 等）では、`dnf` / `yum` を使ってインストールします。

```bash
sudo dnf install -y ./rpmbuild/RPMS/*/*.rpm

# インストールされたファイル一覧
rpm -ql google-test-app
```

### Ubuntu/Debian 系での取り扱い（強制インストール/展開）

Ubuntu/Debian 系では、依存関係解決の都合で `rpm --install` が失敗する場合があります。
どうしても `/usr` に展開して確認したい場合は、自己責任で強制インストールできます。

```bash
sudo rpm -Uvh --nodeps --nosignature ./rpmbuild/RPMS/*/*.rpm
```

または、インストールせずに任意ディレクトリへ展開できます。

```bash
mkdir -p /tmp/rpm-extract && cd /tmp/rpm-extract
rpm2cpio /path/to/package.rpm | cpio -idmu
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
