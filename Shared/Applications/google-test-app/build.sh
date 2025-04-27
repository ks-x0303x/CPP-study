#!/bin/bash

# ヘルプメッセージ
function show_help() {
    echo "Usage: ./build.sh [FEATURE_FLAG] [BUILD_TYPE]"
    echo ""
    echo "Arguments:"
    echo "  FEATURE_FLAG   Specify 'gtest' to enable GTest feature (default: none)."
    echo "                 If not specified, the application will be built without GTest."
    echo "  BUILD_TYPE     Specify the build type: 'debug', 'release', or leave empty for default."
    echo ""
    echo "Examples:"
    echo "  ./build.sh gtest debug    # Enable GTest feature and build in debug mode."
    echo "  ./build.sh debug          # Build the application in debug mode without GTest."
    echo "  ./build.sh release        # Build the application in release mode without GTest."
    echo "  ./build.sh                # Default build of the application without GTest."
    echo "  ./build.sh --help         # Show this help message."
    echo "  ./build.sh -h             # Show this help message."
    exit 0
}

# ヘルプオプションの処理
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_help
fi

# ビルドディレクトリを削除
rm -rf build/

# 引数を変数に格納
feature_flag=${1:-none}  # 第1引数: 機能フラグ（デフォルトは none）
build_type=$2            # 第2引数: ビルドタイプ（例: debug, release）

# 第1引数がビルドタイプの場合に対応（gtest を省略した場合）
if [ "$feature_flag" == "debug" ] || [ "$feature_flag" == "release" ]; then
    build_type=$feature_flag
    feature_flag="none"  # デフォルトで通常アプリケーションのビルド
fi

# ビルドタイプオプションを設定（デフォルトは指定しない）
build_type_option=""
if [ -n "$build_type" ]; then
    build_type_option="--buildtype=$build_type"
    echo "Build type specified: $build_type"
else
    echo "No build type specified. Using default."
fi

# GTest 機能フラグに応じて Meson をセットアップ
if [ "$feature_flag" == "gtest" ]; then
    echo "Setting up Meson with Is_Gtest feature enabled..."
    meson setup build -DIs_Gtest=true $build_type_option
else
    echo "Setting up Meson for the application build..."
    meson setup build $build_type_option
fi

# ビルドディレクトリに移動してビルドを実行
cd build/
ninja