# 開発フロー

## ビルド環境
Docker コンテナ上で開発をします。

```
run_docker.sh
```

## ビルド

基本方針: 各アプリケーションはそれぞれのディレクトリでビルドします。

1. 対象アプリのディレクトリへ移動します。

例:

- `Shared/Applications/google-test-app`

2. ビルドスクリプトを実行します。

```bash
./build.sh
```

補足:

- 生成物の出力先はアプリごとに異なります（例: `build/` 配下）。
- アプリ固有のビルド要件は、各アプリの `Readme.md` を参照してください。

## RPM作成

RPM作成は「事前にビルド済みの成果物/ヘッダ」を、設定ファイルで指定してRPMに固めます。
RPM作成ツール本体は `Shared/Helper/RpmCreateTool` に置き、各アプリ側は `create_rpm.sh` をシンボリックリンクして利用します。

### 手順

1. 対象アプリのディレクトリへ移動します。

例:

- `Shared/Applications/google-test-app`

2. 事前にビルドして成果物を用意します。

```bash
./build.sh
```

3. 設定ファイル `rpm-package.json` / `rpm-package.yaml` / `rpm-package.yml` のいずれかを用意します。

- `src` や `src_dir` は「アプリのカレントディレクトリ」からの相対パスとして解釈されます
- サンプルがある場合は `*.example` をコピー/リネームして作成します

4. RPM作成を実行します。

```bash
./create_rpm.sh

# 例: 設定ファイルを明示する場合
./create_rpm.sh --config rpm-package.yaml

# 例: rpmbuild は呼ばず、ステージングとspec生成だけ行う（確認用）
./create_rpm.sh --no-rpmbuild --config rpm-package.json
```

5. 生成されたRPMを確認します。

- 出力先: `./rpmbuild/RPMS/*/*.rpm`

```bash
rpm -qpl ./rpmbuild/RPMS/*/*.rpm
rpm -qpR ./rpmbuild/RPMS/*/*.rpm
```