# 概要
学習用のアウトプット、備忘録的なリポジトリ

## 動作環境
Docker を使った C/C++ 開発環境。

- ホストCPU: `arm64` / `amd64` のどちらでも動作（Docker が自動で適切なアーキのイメージをビルド/実行）
- 目的: コンテナ内で `aarch64` / `x86_64` のクロスコンパイルができること

## 動作手順（イメージを使う人向け）
Docker Hub からイメージを取得して、コンテナを起動します。

このリポジトリ直下で実行します。

1) イメージを pull
```
$ ./pull_docker.sh
# or
$ ./pull_docker.sh 1.0
```

2) コンテナ起動（使い捨て起動）
```
$ ./run_docker.sh
```

3) 終了（compose のリソースを落とす）
```
$ ./exit_docker.sh
```

補足:
- `pull_docker.sh` は pull 後にローカルへ `ubuntu-env:latest` としてタグ付けします（以降 `run_docker.sh` は常に `ubuntu-env:latest` を使用）。

## 動作手順（イメージを作る人向け）
基本的に利用者は不要です（イメージ作成・配布をする人向け）。

このリポジトリ直下で実行します。

### ローカルビルド
```
$ ./build_docker.sh
```

### Docker Hub へ multi-arch push
同じタグで `linux/amd64` と `linux/arm64` を配布したい場合は、buildx で manifest を push します。

事前に `docker login` を済ませておいてください。

```
$ ./push_docker.sh 1.0 --install-binfmt
```

補足:
- `push_docker.sh` は `docker buildx build --push` を使うため、ローカルに `ksx0303x/ubuntu-env:1.0` のタグは残りません（`docker images` に出なくても正常です）。必要なら `./pull_docker.sh 1.0` で取り直してください。

補足:
- ホストが片方のCPUでも、クロスビルドを行うには環境側で QEMU/binfmt が必要なことがあります。
  - 必要なら `--install-binfmt` を付けて実行できます（Docker が privileged を許可している場合のみ）。

補足: スクリプトは内部で `docker compose` / `docker buildx` を呼びます。

## クロスコンパイル
コンテナ内で以下のコンパイラが利用できます（pull/run どちらで起動しても同じです）。

- ネイティブ: `gcc` / `g++`
- aarch64 向け: `aarch64-linux-gnu-gcc` / `aarch64-linux-gnu-g++`
- x86_64 向け: `x86_64-linux-gnu-gcc` / `x86_64-linux-gnu-g++`

例（単発コンパイル）
```
$ aarch64-linux-gnu-g++ main.cpp -o app_arm64
$ x86_64-linux-gnu-g++ main.cpp -o app_amd64
$ file app_arm64 app_amd64
```

例（CMake）
```
$ cmake -S . -B build-aarch64 \
	-DCMAKE_TOOLCHAIN_FILE=/usr/local/config/toolchains/cmake-aarch64-linux-gnu.cmake
$ cmake --build build-aarch64
```

例（Meson）
```
$ meson setup build-aarch64 --cross-file /usr/local/config/toolchains/meson-aarch64-linux-gnu.ini
$ meson compile -C build-aarch64
```

注意: 追加ライブラリ（例: Boost）を「クロス先アーキ向け」にリンクする場合は、クロス用のライブラリ/PKG_CONFIG 設定が別途必要になることがあります。

## App build & run.
dockerコンテナの中に入る
```
初回のみ、Dev Containersをインストール
１．vs code のリモートエクスプローラーを開発コンテナーに切り替える
２．study-docker にカーソルを当てて「→」ボタンを押下
```
Appのプロジェクトディレクトリを開く
```
フォルダーを開く、'/home/ubuntu/Shared/Applications/XXX'
```
build & run
```
初回のみ、C/C++ Extension Packをインストール
F5押下で、ビルドされデバッグ実行が開始される。
```



