# meson.build
project('boost_example', 'cpp',
  default_options : ['warning_level=3'])

# Boostライブラリを依存関係として追加
boost_dep = dependency('boost', version : '>=1.70')

# Boostライブラリが見つからなかった場合、エラーを出す
if not boost_dep.found()
  error('Boost library not found. Please install Boost.')
endif

# Boostライブラリを使用してコンパイル
executable('boost_example', 'main.cpp', dependencies: boost_dep)
