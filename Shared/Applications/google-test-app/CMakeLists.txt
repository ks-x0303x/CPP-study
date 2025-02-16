cmake_minimum_required(VERSION 3.10)
project(MyProject)

set(CMAKE_CXX_STANDARD 17)  # C++17を使用

# GoogleTestのビルド設定
add_subdirectory(googletest)
enable_testing()

# テストディレクトリのCMakeLists.txtを追加
add_subdirectory(tests)

# ヘッダーファイルが test/ や include/ にある場合のインクルードディレクトリ設定
 target_include_directories(test_runner PRIVATE ./ tests)