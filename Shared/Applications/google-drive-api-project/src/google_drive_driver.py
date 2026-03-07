import argparse
import fnmatch
import glob
import re
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload, MediaIoBaseDownload


# quickstart.py とスコープを揃える（アップロード/ダウンロード用途）
SCOPES = ["https://www.googleapis.com/auth/drive"]

_FILE_ID_RE = re.compile(r"^[A-Za-z0-9_-]{20,}$")
_GLOB_META_CHARS = set("*?[")


def _get_config_dir() -> Path:
    """Locate config directory.

    Prefer `/usr/local/config` only when it actually contains `token.json`.
    This avoids surprising failures when the directory exists but the config
    files live next to the scripts.
    """

    container_dir = Path("/usr/local/config")
    if container_dir.is_dir() and (container_dir / "token.json").exists():
        return container_dir
    return Path(__file__).resolve().parent


def _load_credentials(config_dir: Path) -> Credentials:
    token_path = config_dir / "token.json"
    if not token_path.exists():
        raise FileNotFoundError(
            "token.json が見つかりません。\n"
            f"期待パス: {token_path}\n"
            "先に quickstart.py を実行して token.json を生成してください。"
        )

    creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)
    if creds and creds.expired and creds.refresh_token:
        creds.refresh(Request())
        token_path.write_text(creds.to_json(), encoding="utf-8")
    return creds


def _service():
    config_dir = _get_config_dir()
    creds = _load_credentials(config_dir)
    return build("drive", "v3", credentials=creds)


def _escape_query_value(value: str) -> str:
    # Drive query uses single quotes; escape backslash first.
    return value.replace("\\", "\\\\").replace("'", "\\'")


def _has_glob_magic(value: str) -> bool:
    return any(ch in value for ch in _GLOB_META_CHARS)


def _looks_like_file_id(value: str) -> bool:
    return bool(_FILE_ID_RE.match(value))


def _find_files_in_root_by_name(service, name: str):
    q = " and ".join(
        [
            "'root' in parents",
            "trashed=false",
            f"name='{_escape_query_value(name)}'",
        ]
    )
    resp = service.files().list(q=q, fields="files(id,name,mimeType,modifiedTime,size)").execute()
    return resp.get("files", [])


def _find_child(service, parent_id: str, name: str, mime_type: str | None):
    q_parts = [
        f"'{parent_id}' in parents",
        "trashed=false",
        f"name='{_escape_query_value(name)}'",
    ]
    if mime_type is not None:
        q_parts.append(f"mimeType='{mime_type}'")

    resp = service.files().list(q=" and ".join(q_parts), fields="files(id,name,mimeType)").execute()
    files = resp.get("files", [])
    return files[0] if files else None


def _list_children(service, parent_id: str, name_contains: str | None):
    q_parts = [f"'{parent_id}' in parents", "trashed=false"]
    if name_contains:
        q_parts.append(f"name contains '{_escape_query_value(name_contains)}'")

    files: list[dict] = []
    page_token = None
    while True:
        resp = (
            service.files()
            .list(
                q=" and ".join(q_parts),
                fields="nextPageToken, files(id,name,mimeType,modifiedTime,size)",
                pageSize=1000,
                pageToken=page_token,
            )
            .execute()
        )
        files.extend(resp.get("files", []))
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return files


def _resolve_folder_id(service, folder_path: str, create: bool) -> str:
    folder_path = folder_path.strip("/")
    if folder_path == "":
        return "root"

    parent_id = "root"
    for part in [p for p in folder_path.split("/") if p]:
        folder = _find_child(service, parent_id, part, "application/vnd.google-apps.folder")
        if not folder:
            if not create:
                raise FileNotFoundError(f"Folder not found: {folder_path}")
            meta = {
                "name": part,
                "mimeType": "application/vnd.google-apps.folder",
                "parents": [parent_id],
            }
            folder = service.files().create(body=meta, fields="id").execute()
        parent_id = folder["id"]
    return parent_id


def _resolve_file_id(service, file_path_or_id: str) -> str:
    # "a/b/c.txt" のような Drive パスを優先的に扱う。
    # "/" が無い場合は、まず「IDっぽいか」を判定し、IDっぽくなければ root 直下のファイル名解決を試す。
    if "/" not in file_path_or_id:
        if _looks_like_file_id(file_path_or_id):
            return file_path_or_id

        candidates = _find_files_in_root_by_name(service, file_path_or_id)
        # フォルダは download できないので除外
        candidates = [c for c in candidates if c.get("mimeType") != "application/vnd.google-apps.folder"]
        if len(candidates) == 1:
            return candidates[0]["id"]
        if len(candidates) > 1:
            shown = "\n".join(
                [
                    f"- {c.get('name')} (id={c.get('id')}, modifiedTime={c.get('modifiedTime')})"
                    for c in candidates[:10]
                ]
            )
            raise ValueError(
                "Multiple files matched in Drive root. Specify a Drive path (Folder/file) or an explicit file ID.\n"
                f"name={file_path_or_id}\n{shown}"
            )

        raise FileNotFoundError(
            "File not found in Drive root. Specify a Drive path like 'Folder/file.txt' or use the file ID.\n"
            f"name={file_path_or_id}"
        )

    drive_path = file_path_or_id.strip("/")
    parts = [p for p in drive_path.split("/") if p]
    if not parts:
        raise ValueError("Invalid file path")

    file_name = parts[-1]
    folder_path = "/".join(parts[:-1])
    parent_id = _resolve_folder_id(service, folder_path, create=False)

    f = _find_child(service, parent_id, file_name, None)
    if not f:
        raise FileNotFoundError(f"File not found: {file_path_or_id}")
    if f.get("mimeType") == "application/vnd.google-apps.folder":
        raise IsADirectoryError(f"Path refers to a folder (cannot download a folder): {file_path_or_id}")
    return f["id"]


def _resolve_output_path(src_file_path_or_id: str, output_path: str) -> Path:
    out = Path(output_path).expanduser().resolve()
    if out.is_dir():
        out = out / Path(src_file_path_or_id).name
    out.parent.mkdir(parents=True, exist_ok=True)
    return out


def _download_one(service, file_id: str, out: Path) -> None:
    req = service.files().get_media(fileId=file_id)
    with open(out, "wb") as fh:
        downloader = MediaIoBaseDownload(fh, req)
        done = False
        while not done:
            _, done = downloader.next_chunk()


def _download_many(service, items: list[dict], output_path: str) -> None:
    out_base = Path(output_path).expanduser().resolve()
    if out_base.exists() and out_base.is_file():
        raise ValueError(
            "Output path must be a directory when downloading multiple files. "
            f"output={out_base}"
        )
    out_base.mkdir(parents=True, exist_ok=True)

    for item in items:
        name = item.get("name") or item.get("id")
        out = out_base / name
        _download_one(service, item["id"], out)
        print(f"Downloaded: {name} ({item['id']}) -> {out}")


def _resolve_drive_glob(service, drive_path_glob: str) -> list[dict]:
    """Resolve Drive-side glob for file names.

    Supports glob only in the last path component (file name), e.g.:
    - test.*
    - Folder/*.txt
    """

    drive_path_glob = drive_path_glob.strip("/")
    if drive_path_glob == "":
        raise ValueError("Invalid file path")

    if "/" in drive_path_glob:
        folder_path, name_glob = drive_path_glob.rsplit("/", 1)
        if _has_glob_magic(folder_path):
            raise ValueError("Wildcards in folder path are not supported.")
        parent_id = _resolve_folder_id(service, folder_path, create=False)
    else:
        name_glob = drive_path_glob
        parent_id = "root"

    prefix = ""
    for ch in name_glob:
        if ch in _GLOB_META_CHARS:
            break
        prefix += ch

    candidates = _list_children(service, parent_id, prefix or None)

    matched = [c for c in candidates if fnmatch.fnmatchcase(c.get("name", ""), name_glob)]
    # フォルダは download できないので除外
    matched = [m for m in matched if m.get("mimeType") != "application/vnd.google-apps.folder"]

    return matched


def download_file(src_file_path_or_id: str, output_path: str) -> None:
    service = _service()
    try:
        if _has_glob_magic(src_file_path_or_id):
            items = _resolve_drive_glob(service, src_file_path_or_id)
            if not items:
                raise FileNotFoundError(f"No files matched: {src_file_path_or_id}")
            if len(items) == 1:
                name = items[0].get("name") or src_file_path_or_id
                out = _resolve_output_path(name, output_path)
                _download_one(service, items[0]["id"], out)
                print(f"Downloaded: {name} ({items[0]['id']}) -> {out}")
                return

            _download_many(service, items, output_path)
            return

        file_id = _resolve_file_id(service, src_file_path_or_id)
        out = _resolve_output_path(src_file_path_or_id, output_path)
        _download_one(service, file_id, out)
    except Exception as exc:
        # fileId として失敗した場合に、ありがちな誤用（ファイル名を渡した）をガイドする
        if (
            hasattr(exc, "resp")
            and getattr(getattr(exc, "resp", None), "status", None) == 404
            and "/" not in src_file_path_or_id
            and not _looks_like_file_id(src_file_path_or_id)
        ):
            raise FileNotFoundError(
                "File not found. If you passed a file name, specify a Drive path like 'Folder/test.txt' or use the file ID.\n"
                f"input={src_file_path_or_id}"
            ) from exc
        raise

    print(f"Downloaded: {src_file_path_or_id} -> {out}")


def upload_file(local_file_path: str, target_folder: str) -> None:
    service = _service()
    parent_id = _resolve_folder_id(service, target_folder, create=True)

    def upload_one(local: Path) -> None:
        media = MediaFileUpload(str(local), resumable=True)
        meta = {"name": local.name, "parents": [parent_id]}
        created = service.files().create(body=meta, media_body=media, fields="id").execute()
        print(f"Uploaded: {local} -> {target_folder} (id={created['id']})")

    if _has_glob_magic(local_file_path):
        pattern = str(Path(local_file_path).expanduser())
        matches = [Path(p) for p in glob.glob(pattern)]
        matches = [p for p in matches if p.is_file()]
        if not matches:
            raise FileNotFoundError(f"Local files not found (glob): {pattern}")
        for p in sorted({m.resolve() for m in matches}):
            upload_one(p)
        return

    local = Path(local_file_path).expanduser().resolve()
    if not local.exists():
        raise FileNotFoundError(f"Local file not found: {local}")
    if not local.is_file():
        raise FileNotFoundError(f"Local file not found: {local}")
    upload_one(local)


def main():
    parser = argparse.ArgumentParser(description="Upload or download files to/from Google Drive.")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    upload_parser = subparsers.add_parser("upload", help="Upload a file to Google Drive")
    upload_parser.add_argument("-f", "--file", required=True, help="Path to the file to upload")
    upload_parser.add_argument("-t", "--target", required=True, help="Target folder path on Google Drive")

    download_parser = subparsers.add_parser("download", help="Download a file from Google Drive")
    download_parser.add_argument("-f", "--file", required=True, help="Path or ID of the file on Google Drive")
    download_parser.add_argument("-o", "--output", required=True, help="Output path to save the downloaded file")

    args = parser.parse_args()
    if args.command == "upload":
        upload_file(args.file, args.target)
    elif args.command == "download":
        download_file(args.file, args.output)
    else:
        parser.print_help()
        raise SystemExit(1)


if __name__ == "__main__":
    main()