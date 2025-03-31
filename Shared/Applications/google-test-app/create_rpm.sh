#!/bin/bash

# 一時的に `RPMBUILD` のディレクトリを変更
export RPMBUILD="$(pwd)/rpmbuild"

# 設定値
PACKAGE_NAME="googletest"
VERSION="1.14.0"
RELEASE="1"
LICENSE="BSD"
URL="https://github.com/google/googletest"
SOURCE="googletest-${VERSION}.tar.gz"
SUMMARY="Test framework by google."

BUILD_DATE=$(date "+%a %b %d %Y")
CURENT_NAME=$(basename "$PWD")

SOURCE_NAME="$PACKAGE_NAME-$VERSION"
SOURCE_TARBALL="$SOURCE_NAME.tar.gz"
DOWNLOAD_URL="https://github.com/google/googletest/archive/refs/tags/v$VERSION.tar.gz"


# 作業ディレクトリを確認
echo "Using RPMBUILD directory: $RPMBUILD"

rm -rd $RPMBUILD
# `rpmbuild` のディレクトリ構造を作成（必要なら）
mkdir -p $RPMBUILD/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cp -rf ./rpm.spec ${RPMBUILD}/SPECS/${CURENT_NAME}.spec

# === ソースコードのダウンロード ===
echo "Downloading $PACKAGE_NAME version $VERSION..."
wget -O "${RPMBUILD}/SOURCES/${SOURCE_TARBALL}" "$DOWNLOAD_URL"
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to download $DOWNLOAD_URL"
  exit 1
fi

# === RPM のビルド準備 ===
echo "Preparing RPM build environment..."
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# `rpmbuild` を実行
rpmbuild -ba $RPMBUILD/SPECS/${CURENT_NAME}.spec \
    --define "_topdir $RPMBUILD" \
    --define "_build_date ${BUILD_DATE}" \
    --define "_name ${PACKAGE_NAME}" \
    --define "_version ${VERSION}" \
    --define "_release ${RELEASE}" \
    --define "_license ${LICENSE}" \
    --define "_url ${URL}" \
    --define "_source ${SOURCE}" \
    --define "_summary ${SUMMARY}"


# 完了メッセージ
echo "RPM build completed!"
