#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

REQ_PKGS=(
  google-api-python-client
  google-auth-httplib2
  google-auth-oauthlib
)

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 が見つかりません。"
  exit 1
fi

echo "[1/3] 依存パッケージをインストール/更新します..."
python3 -m pip install --upgrade "${REQ_PKGS[@]}"

if [[ ! -f "./credentials.json" ]]; then
  echo
  echo "Error: カレントディレクトリに credentials.json がありません。"
  echo "Google Cloud Console で OAuth クライアント(デスクトップアプリ)を作成し、credentials.json をここに配置してください。"
  echo
  echo "手順:"
  echo "https://developers.google.com/workspace/drive/api/quickstart/python?hl=ja#authorize_credentials_for_a_desktop_application"
  echo
  exit 2
fi

if [[ ! -f "./quickstart.py" ]]; then
  echo "Error: quickstart.py が見つかりません。"
  exit 3
fi

echo "[2/3] quickstart.py を実行します..."
echo "      (ローカル開発用途のため OAUTHLIB_INSECURE_TRANSPORT=1 を設定)"
echo

OAUTHLIB_INSECURE_TRANSPORT=1 python3 ./quickstart.py

echo
echo "[3/3] 完了"