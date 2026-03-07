# google drive APIs helper

Google Drive API を使うための補助ツールです。

Google OAuth 認可を通して `token.json`（アクセストークン/リフレッシュトークン）を生成し、そのトークンで Drive のダウンロード/アップロードを行います。

## シナリオ別の操作

### 1) 初回セットアップ（credentials.json を用意する）

1. Google Cloud Console で OAuth クライアント（デスクトップアプリ）を作成し、`credentials.json` を取得します。
	- 手順: https://developers.google.com/workspace/drive/api/quickstart/python?hl=ja#authorize_credentials_for_a_desktop_application
2. 取得した `credentials.json` を、この README と同じディレクトリ（`auth_quickstart.sh` がある場所）に配置します。

### 2) 認証（token.json を生成/更新する）

以下を実行します。

```bash
./auth_quickstart.sh
```

- `auth_quickstart.sh` は依存をインストールし、`quickstart.py` を実行して `token.json` を生成します。
- `token.json` は **生成時に強制上書き**されます。

### 3) token.json を作り直したい（強制再認証）

スコープ変更やアカウント変更などでトークンを作り直したい場合:

```bash
rm -f token.json
./auth_quickstart.sh
```

上記で削除できない場合は、前回生成された `token.json` を削除してから再実行してください。

### 4) ファイルをダウンロードする

```bash
./download_file.sh 'Test/hoge/huga/test.txt' ./
```

- `token.json` が無い場合は、先に `./auth_quickstart.sh` を実行してください。

### 5) ファイルをアップロードする

```bash
./upload_file.sh ./local.txt 'BackupFolder/SubFolder'
```

- 指定したフォルダパスが存在しない場合は作成します。

## よくあるエラーと対策

### `webbrowser.Error: could not locate runnable browser`

実行環境にブラウザが無いだけなので問題ありません。
`quickstart.py` は認可 URL を表示するので **Mac 側のブラウザで URL を開いて**ください。

### `oauthlib... InsecureTransportError: OAuth 2 MUST utilize https.`

ローカル開発用途（`http://localhost`）で発生することがあります。
`auth_quickstart.sh` は `OAUTHLIB_INSECURE_TRANSPORT=1` を設定して実行します。

### `OSError: [Errno 98] Address already in use`

`8080` を既に別プロセスが使用しています。
不要なプロセスを止めるか、OAuth 用ポートを変更してください。

## セキュリティ注意

- `credentials.json` には `client_secret` が含まれます。Git にコミットしないでください。
- `token.json` も個人の認証情報です。Git にコミットしないでください。
- 誤って外部に公開した場合は、Google Cloud Console 側で OAuth クライアントのシークレットをローテーションしてください。
