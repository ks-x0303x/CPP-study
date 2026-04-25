#!/bin/bash

# 新方式: 事前ビルド済みの成果物/ヘッダを、カレントの設定ファイルで指定してRPM化
# 設定ファイル: rpm-package.(yaml|yml|json)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 "$SCRIPT_DIR/tools/rpm_packager.py" "$@"
