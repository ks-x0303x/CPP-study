#!/bin/bash

# 新方式: 事前ビルド済みの成果物/ヘッダを、カレントの設定ファイルで指定してRPM化
# 設定ファイル: rpm-package.(yaml|yml|json)

set -euo pipefail

# 呼び出し元（App側の symlink）のディレクトリを作業ディレクトリにする。
# これにより、どこから実行しても App 直下の rpm-package.yaml をデフォルトで参照できる。
if [[ "${0}" == */* ]]; then
	PROJECT_DIR="$(cd -P "$(dirname "${0}")" && pwd)"
else
	PROJECT_DIR="$PWD"
fi

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
	DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
	SOURCE="$(readlink "$SOURCE")"
	[[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done

SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

(cd "$PROJECT_DIR" && python3 "$SCRIPT_DIR/rpm_packager.py" "$@")
