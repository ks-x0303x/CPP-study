## 目的（最小構成）
GitHub Actions で、Docker Hub 上の開発用イメージ（x64/amd64）を使って
リポジトリ内のアプリがビルドできることを CI の green 条件にします。

最小構成では、`google-test-app` を「gtest 有効でビルド → テスト実行」まで確認します。

## 使う Docker イメージ
- Docker Hub: `ksx0303x/ubuntu-env:latest`

補足:
- GitHub-hosted runner（`ubuntu-latest`）は通常 amd64 のため、`docker pull` は amd64 イメージを取得します。

## Workflow（最小）
- ファイル: `.github/workflows/ci.yml`
- トリガー: `push` / `pull_request`
- やること:
	- `actions/checkout` でソース取得
	- `docker pull ksx0303x/ubuntu-env:latest`
	- コンテナ内で `Shared/Applications/google-test-app/build.sh gtest` を実行
	- 続けて `meson test -C build` を実行

### コンテナ実行時のマウント
Workflow では、docker-compose と同じパス構成になるように以下をマウントします。

- `./Shared` → `/home/ubuntu/Shared`
- `./config` → `/usr/local/config`

## 拡張（次の一手）
最小CIが安定してから、段階的に増やすのがおすすめです。

例:
- `google-test-app` もビルドする（まずはビルドのみ、次にテスト実行へ）
- ビルド対象を matrix 化して、アプリごとに job/step を分ける
- `workflow_dispatch` を追加して手動実行できるようにする

## 注意（機密情報）
`config/credentials.json` や `config/token.json` は機密情報になり得ます。
CI では基本的に不要なので、Git にコミットしない運用にしてください。
