#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 が見つかりません。"
  exit 1
fi

CONFIG_DIR="/usr/local/config"
if [[ ! -d "$CONFIG_DIR" ]]; then
  # コンテナ外など /usr/local/config が無い場合はスクリプト配置先を使う
  CONFIG_DIR="$SCRIPT_DIR"
fi

if [[ ! -w "$CONFIG_DIR" ]]; then
  echo "Error: CONFIG_DIR に書き込めません: $CONFIG_DIR"
  echo "docker-compose の volumes 設定（./config:/usr/local/config）を確認してください。"
  exit 1
fi

echo "[1/3] 依存パッケージをインストール/更新します..."
python3 -m pip install --upgrade \
  google-api-python-client \
  google-auth-httplib2 \
  google-auth-oauthlib

echo "[2/3] credentials.json を確認します..."

# 優先: このディレクトリに credentials.json があれば /usr/local/config に強制上書きコピー
if [[ -f "$SCRIPT_DIR/credentials.json" && "$CONFIG_DIR" == "/usr/local/config" ]]; then
  echo "- $SCRIPT_DIR/credentials.json を $CONFIG_DIR/credentials.json に強制コピーします"
  cp -f "$SCRIPT_DIR/credentials.json" "$CONFIG_DIR/credentials.json"
fi

if [[ ! -f "$CONFIG_DIR/credentials.json" ]]; then
  echo
  echo "Error: credentials.json が見つかりません。"
  echo "期待パス: $CONFIG_DIR/credentials.json"
  echo
  echo "以下の手順に従って OAuth クライアント(デスクトップアプリ)を作成し、credentials.json を配置してください:"
  echo "https://developers.google.com/workspace/drive/api/quickstart/python?hl=ja#authorize_credentials_for_a_desktop_application"
  echo
  exit 2
fi

echo "[3/3] quickstart.py を実行して token.json を生成/上書きします..."

echo "- credentials: $CONFIG_DIR/credentials.json"
echo "- token:       $CONFIG_DIR/token.json"
echo

env OAUTHLIB_INSECURE_TRANSPORT=1 python3 ./quickstart.py
