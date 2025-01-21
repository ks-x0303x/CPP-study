# meson.build
project('Hydoromic lib', 'cpp',
  default_options : ['warning_level=3'])

subdir('Hypodermic')
# Hypodermic-dep = dependency('Hypodermic')

# main.c をビルド
executable(
  'main',                                                   # 実行ファイル名
  'main.cpp',                                               # ソースファイル
  dependencies: declare_dependency(
    include_directories: include_directories('Hypodermic')  # ヘッダーファイルを参照 プロジェクトのディレクトリ直下を参照する場合
    # dependencies: Hypodermic-dep                          # /usr/local/include/Hydoromic がインストールされている場合はこの書き方でも良い
  )
)