# 概要
学習用のアウトプット、備忘録的なリポジトリ

## 動作環境
os : mac os 14.6</br>
cpu : M3 (aarch64)</br>
開発環境 : vs code</br>
vs code拡張機能</br>
　・Dev Containers
　・C/C++ Extension Pack</br>
dockerを使用

## 動作手順
### docker起動
初回のみビルド</br>
Windowsで動作させる場合,適宜x86_64に修正が必要(aarch64用に作成しているため)
```
$ docker-compose build
```
次回以降
```
$ docker-compose up -d
```
### App build & run.
dockerコンテナの中に入る
```
初回のみ、Dev Containersをインストール
１．vs code のリモートエクスプローラーを開発コンテナーに切り替える
２．study-docker にカーソルを当てて「→」ボタンを押下
```
Appのプロジェクトディレクトリを開く
```
フォルダーを開く、'/home/ubuntu/Shaerd/Applications/XXX'
```
build & run
```
初回のみ、C/C++ Extension Packをインストール
F5押下で、ビルドされデバッグ実行が開始される。
```



