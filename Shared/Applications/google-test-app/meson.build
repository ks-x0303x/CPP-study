# meson.build
project('gtest-sample lib', 'cpp',
  default_options : 
  [
    'warning_level=3',
    'cpp_std=c++11'
  ])


# gtest と gmock のライブラリをコンパイラで検索
gtest_dep = dependency('gtest')
gmock_dep = dependency('gmock')

# gtest と gmock のヘッダーファイルを指定
gtest_include = include_directories('/usr/include')
gmock_include = include_directories('/usr/include')

# ヘッダーのディレクトリをまとめて配列に追加
include_dirs = [gtest_include, gmock_include]

src = 'main.cpp'

# テストターゲットを作成
executable('test_runner',
    src,  # テストコードのエントリポイント
    include_directories: include_dirs,  # ヘッダーファイルのディレクトリを配列で指定
    dependencies: [gtest_dep, gmock_dep],  # 外部ライブラリを依存関係として指定
    cpp_args: ['-pthread']
)

# テスト実行設定
#test('unittests', executable('test_runner'))

