# Google Test Sample Application

このプロジェクトは、Google Test (`gtest`) と Google Mock (`gmock`) を使用したサンプルアプリケーションです。

目的:

- `Model` / `UseCase` のようなシンプルな層分け
- テスト実行バイナリ（`test_runner`）の作成と実行

## ディレクトリ構成（抜粋）

- `Model/`: ドメインモデル（例: `*.hpp`）
- `UseCase/`: ユースケース層（例: `*.hpp` / `*.cpp`）
- `tests/`: テストコード
- `build/`: ビルド成果物

## ビルド

```bash
./build.sh
```

## 実行

```bash
./build/test_runner
```
