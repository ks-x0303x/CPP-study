#!/bin/bash

# 一時的に `RPMBUILD` のディレクトリを変更
export RPMBUILD="/home/ubuntu/Shared/Applications/google-test-app/rpmbuild"

# 作業ディレクトリを確認
echo "Using RPMBUILD directory: $RPMBUILD"

# `rpmbuild` のディレクトリ構造を作成（必要なら）
# mkdir -p $RPMBUILD/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# `rpmbuild` を実行
rpmbuild -ba --define "_topdir $RPMBUILD" $RPMBUILD/SPECS/googletest.spec

# 完了メッセージ
echo "RPM build completed!"
