# Design

このドキュメントは、[auth_quickstart.sh](auth_quickstart.sh) / [quickstart.py](quickstart.py) / [download_file.sh](download_file.sh) / [upload_file.sh](upload_file.sh) / [google_drive_driver.py](google_drive_driver.py) の依存関係と実行フローを、Mermaid 記法で可視化したものです。

## 前提（共通）

- `python3` が利用できること
- 依存パッケージ（`pip`）
  - `google-api-python-client`
  - `google-auth-httplib2`
  - `google-auth-oauthlib`

## 主要ファイル

- `credentials.json`: OAuth クライアント（Desktop app）のクレデンシャル
- `token.json`: 認可後のトークン（アクセス/リフレッシュトークン）

## 依存関係（呼び出し関係が分かる図）

「どのスクリプトがどのスクリプトを呼び出すか」を明確にするため、
スクリプト同士は `classDiagram`、成果物/外部も含める図は subgraph で区切れる `flowchart` で整理します。

### コールグラフ（スクリプト同士のみ）

```mermaid
classDiagram
  direction LR

  class AuthShell
  class RefreshShell
  class DownloadShell
  class UploadShell
  class QuickstartPy
  class DriverPy

  AuthShell : file auth_quickstart.sh
  RefreshShell : file refresh_token.sh
  DownloadShell : file download_file.sh
  UploadShell : file upload_file.sh
  QuickstartPy : file quickstart.py
  DriverPy : file google_drive_driver.py

  AuthShell ..> QuickstartPy : exec
  RefreshShell ..> QuickstartPy : exec
  DownloadShell ..> DriverPy : exec
  UploadShell ..> DriverPy : exec
```

### コールグラフ（成果物/外部も含む）

```mermaid
flowchart LR
  %% ---- 自作（このリポジトリ内） ----
  subgraph INTERNAL[自作スクリプト]
    A[auth_quickstart.sh]
    R[refresh_token.sh]
    D[download_file.sh]
    U[upload_file.sh]
    Q[quickstart.py]
    G[google_drive_driver.py]
  end

  %% ---- 成果物（生成/参照されるファイル） ----
  subgraph ARTIFACTS[成果物]
    C[credentials.json]
    T[token.json]
  end

  %% ---- 外部依存（Pythonライブラリ） ----
  subgraph LIBS[外部依存（Pythonライブラリ）]
    L1[google-auth-oauthlib]
    L2[google-api-python-client]
  end

  %% ---- 外部（サービス/アプリ） ----
  subgraph EXTERNAL[外部（サービス/アプリ）]
    B[Browser]
    OA[Google OAuth]
    DA[Google Drive API v3]
  end

  %% 実行（自作→自作）
  A -->|exec| Q
  R -->|exec| Q
  D -->|exec| G
  U -->|exec| G

  %% 認証（自作↔成果物/外部）
  Q -->|read| C
  Q -->|overwrite| T
  Q -->|import| L1
  Q -->|show authorize URL| B
  B -->|authorize| OA
  Q -->|token exchange| OA

  %% Drive操作（自作↔成果物/外部）
  G -->|read/refresh/write| T
  G -->|import| L2
  G -->|download/upload| DA
```

## シーケンス（認証：token.json 生成）

```mermaid
sequenceDiagram
  autonumber
  participant User as User
  participant Sh as auth_quickstart.sh
  participant Py as quickstart.py
  participant Browser as Browser
  participant GoogleAuth as Google OAuth (Authorize)
  participant Local as Local callback (localhost)
  participant GoogleToken as Google OAuth (Token)
  participant Token as token.json

  User->>Sh: 実行
  Sh->>Sh: pip install/upgrade (依存解決)
  Sh->>Py: OAUTHLIB_INSECURE_TRANSPORT=1 python3 quickstart.py

  Py->>Py: credentials.json を読み込む
  Py->>Browser: 認可URLを表示（ユーザーが開く）
  User->>Browser: URLを開く
  Browser->>GoogleAuth: ログイン/同意
  GoogleAuth-->>Browser: redirect to http://localhost:PORT/?code=...&state=...
  Browser->>Local: GET /?code=...&state=...
  Local-->>Py: code/state を受領

  Py->>GoogleToken: code を token に交換
  GoogleToken-->>Py: access_token/refresh_token
  Py->>Token: token.json を上書き保存
  Py-->>User: 認証完了
```

## シーケンス（ダウンロード）

```mermaid
sequenceDiagram
  autonumber
  participant User as User
  participant Sh as download_file.sh
  participant Py as google_drive_driver.py
  participant Token as token.json
  participant Drive as Google Drive API v3
  participant FS as Local filesystem

  User->>Sh: ./download_file.sh <drive_path_or_id> <output>
  Sh->>Py: python3 google_drive_driver.py download ...
  Py->>Token: token.json 読み込み
  alt access token expired
    Py->>Drive: Refresh (via OAuth)
    Py->>Token: token.json 更新
  end

  alt 入力が「パス」（例: A/B/file.txt）
    Py->>Drive: files.list (フォルダ/ファイル探索)
    Drive-->>Py: fileId
  else 入力が「ID」
    Py->>Py: fileId = 入力
  end

  Py->>Drive: files.get_media(fileId)
  Drive-->>Py: file bytes (chunked)
  Py->>FS: 指定先に保存
  Py-->>User: 完了メッセージ
```

## シーケンス（アップロード）

```mermaid
sequenceDiagram
  autonumber
  participant User as User
  participant Sh as upload_file.sh
  participant Py as google_drive_driver.py
  participant Token as token.json
  participant Drive as Google Drive API v3
  participant FS as Local filesystem

  User->>Sh: ./upload_file.sh <local_file> <drive_folder_path>
  Sh->>Py: python3 google_drive_driver.py upload ...
  Py->>Token: token.json 読み込み
  alt access token expired
    Py->>Drive: Refresh (via OAuth)
    Py->>Token: token.json 更新
  end

  Py->>FS: ローカルファイル存在確認
  Py->>Drive: files.list (フォルダ探索)
  alt フォルダが存在しない
    Py->>Drive: files.create (フォルダ作成)
  end

  Py->>Drive: files.create + Media upload (ファイル作成/アップロード)
  Drive-->>Py: uploaded fileId
  Py-->>User: 完了メッセージ
```

