import json
import os.path
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# If modifying these scopes, delete token.json.
# download/upload にも使うため Drive フルスコープに揃える。
SCOPES = ["https://www.googleapis.com/auth/drive"]


def _get_config_dir() -> Path:
  """Return config dir.

  - Container default: /usr/local/config (mounted from ./config)
  - Fallback: this script directory
  """
  container_dir = Path("/usr/local/config")
  if container_dir.is_dir() and (
    (container_dir / "credentials.json").exists() or (container_dir / "token.json").exists()
  ):
    return container_dir
  return Path(__file__).resolve().parent


def _validate_credentials_json(credentials_path: Path) -> None:
  """Validate minimal structure of credentials.json without printing secrets."""
  try:
    raw = credentials_path.read_text(encoding="utf-8")
    data = json.loads(raw)
  except Exception as exc:
    raise ValueError(f"credentials.json の JSON 形式が不正です: {credentials_path}") from exc

  if isinstance(data, dict) and "installed" in data:
    cfg = data.get("installed") or {}
    kind = "installed"
  elif isinstance(data, dict) and "web" in data:
    cfg = data.get("web") or {}
    kind = "web"
  else:
    raise ValueError(
      "credentials.json の形式が想定外です。Google Cloud Console で OAuth クライアント(Desktop app)の JSON を再ダウンロードしてください。\n"
      f"path: {credentials_path}"
    )

  required = ["client_id", "auth_uri", "token_uri"]
  missing = [k for k in required if not cfg.get(k)]
  if missing:
    raise ValueError(
      "credentials.json に必須フィールドがありません。OAuth クライアント(Desktop app)の JSON をそのまま配置してください。\n"
      f"type: {kind}\nmissing: {', '.join(missing)}\npath: {credentials_path}"
    )


def _receive_auth_code(bind_host: str, bind_port: int):
  """
  bind_host: コンテナ内で待受するアドレス(0.0.0.0推奨)
  戻り: (code, full_path_query) 例: (xxxxx, "/?state=...&code=...&scope=...")
  """
  done = threading.Event()
  result = {"code": None, "path": None, "error": None}

  class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
      parsed = urlparse(self.path)
      qs = parse_qs(parsed.query)

      if "error" in qs:
        result["error"] = qs.get("error", [""])[0]
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"Authorization failed. You may close this tab.")
        done.set()
        return

      if "code" in qs:
        result["code"] = qs.get("code", [""])[0]
        result["path"] = self.path
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"Authorization finished. You may close this tab.")
        done.set()
        return

      # code/error が無いリクエスト（favicon など）は無視して待ち続ける
      self.send_response(200)
      self.send_header("Content-Type", "text/html; charset=utf-8")
      self.end_headers()
      self.wfile.write(b"Waiting for OAuth redirect...")

    def log_message(self, format, *args):
      # アクセスログを抑制
      return

  httpd = HTTPServer((bind_host, bind_port), Handler)
  t = threading.Thread(target=httpd.serve_forever, daemon=True)
  t.start()

  # 最大 5 分待つ
  if not done.wait(timeout=300):
    httpd.shutdown()
    raise TimeoutError("Timed out waiting for OAuth redirect.")

  httpd.shutdown()

  if result["error"]:
    raise RuntimeError(f"OAuth error: {result['error']}")
  if not result["code"] or not result["path"]:
    raise RuntimeError("No authorization code received.")

  return result["code"], result["path"]


def main():
  creds = None

  config_dir = _get_config_dir()
  token_path = config_dir / "token.json"
  credentials_path = config_dir / "credentials.json"

  if not credentials_path.exists():
    raise FileNotFoundError(
      "credentials.json が見つかりません。\n"
      f"期待パス: {credentials_path}\n"
      "Google Cloud Console で OAuth クライアント(Desktop app)を作成し、credentials.json を配置してください。\n"
      "https://developers.google.com/workspace/drive/api/quickstart/python?hl=ja#authorize_credentials_for_a_desktop_application\n"
    )

  _validate_credentials_json(credentials_path)

  if token_path.exists():
    creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)

  if not creds or not creds.valid:
    if creds and creds.expired and creds.refresh_token:
      creds.refresh(Request())
    else:
      flow = InstalledAppFlow.from_client_secrets_file(str(credentials_path), SCOPES)

      # 既に別スコープで認可済みの場合、トークン応答の scope が「要求したスコープの上位集合」になることがある。
      # oauthlib が 이를 mismatch として例外化するのを避ける。
      os.environ.setdefault("OAUTHLIB_RELAX_TOKEN_SCOPE", "1")

      # 重要: redirect_uri は localhost にする（0.0.0.0 は Google が拒否）
      redirect_port = 8080
      flow.redirect_uri = f"http://localhost:{redirect_port}/"

      auth_url, _ = flow.authorization_url(
        access_type="offline",
        prompt="consent",
      )

      print("Open this URL in your browser:")
      print(auth_url)
      print(f"Waiting for redirect on 0.0.0.0:{redirect_port} ...")

      # コンテナ側は 0.0.0.0 で待受（docker の port 公開でホスト->コンテナに届く）
      _code, _path = _receive_auth_code("0.0.0.0", redirect_port)

      # fetch_token は redirect_uri と整合する必要があるので localhost で組み立てる
      try:
        flow.fetch_token(authorization_response=f"http://localhost:{redirect_port}{_path}")
      except Exception as exc:
        # よくある: token 交換で invalid_client(Unauthorized)
        # -> credentials.json の client_secret が違う/欠けている/別クライアントの JSON を置いている等
        if exc.__class__.__name__ == "InvalidClientError":
          raise RuntimeError(
            "OAuth トークン交換に失敗しました: invalid_client (Unauthorized)\n"
            "- /usr/local/config/credentials.json が正しい OAuth クライアント(Desktop app)の JSON か確認してください\n"
            "- Cloud Console で OAuth クライアントを再作成/再ダウンロードした場合は、最新の credentials.json に差し替えてください\n"
            "- credentials.json を差し替えた後、必要なら token.json を削除して再実行してください\n"
            f"credentials: {credentials_path}"
          ) from exc
        raise
      creds = flow.credentials

    token_path.write_text(creds.to_json(), encoding="utf-8")

  try:
    service = build("drive", "v3", credentials=creds)
    results = (
      service.files()
      .list(pageSize=10, fields="nextPageToken, files(id, name)")
      .execute()
    )
    items = results.get("files", [])

    if not items:
      print("No files found.")
      return

    print("Files:")
    for item in items:
      print(f"{item['name']} ({item['id']})")

  except HttpError as error:
    print(f"An error occurred: {error}")


if __name__ == "__main__":
  main()