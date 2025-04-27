# meson.build
project('gtest-sample lib', 'cpp',
  default_options : 
  [
    'warning_level=3',
    'cpp_std=c++17'
  ])

# オプション定義
is_gtest = get_option('Is_Gtest')


src = []
include_dirs = []
subdir('Model')
subdir('UseCase')


boost_dep = dependency('boost', version : '>=1.70')

if is_gtest

  test_src = []
  test_include_dirs = []
  subdir('tests')

  # gtest と gmock のライブラリをコンパイラで検索
  gtest_dep = dependency('gtest')
  gmock_dep = dependency('gmock')

  # gtest と gmock のヘッダーファイルを指定
  gtest_include = include_directories('/usr/include')
  gmock_include = include_directories('/usr/include')

  # ヘッダーのディレクトリをまとめて配列に追加
  #test_include_dirs = [gtest_include, gmock_include]

  # テストターゲットを作成
  executable('test_runner',
      src + test_src,
      include_directories: [include_dirs, test_include_dirs, gtest_include, gmock_include],  # ヘッダーファイルのディレクトリを配列で指定
      dependencies: [gtest_dep, gmock_dep, boost_dep],  # 外部ライブラリを依存関係として指定
      cpp_args: ['-pthread']
  )
else
  executable('sample_app',
      ['main.cpp'] + src,
      include_directories: include_dirs,
      #dependencies: [gtest_dep, gmock_dep],  # 外部ライブラリを依存関係として指定
      cpp_args: ['-pthread']
  )
endif




# テスト実行設定
#test('unittests', executable('test_runner'))

