import argparse
import os
import re
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload, MediaIoBaseDownload


# quickstart.py とスコープを揃える（アップロード/ダウンロード用途）
SCOPES = ["https://www.googleapis.com/auth/drive"]

_FILE_ID_RE = re.compile(r"^[A-Za-z0-9_-]{20,}$")


def _get_config_dir() -> Path:
    container_dir = Path("/usr/local/config")
    if container_dir.is_dir():
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
    return value.replace("'", "\\'")


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

        # root 直下に見つからない場合は「ID」として扱う（ユーザーが短いIDを渡した可能性を残す）
        return file_path_or_id

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
    return f["id"]


def _resolve_output_path(src_file_path_or_id: str, output_path: str) -> Path:
    out = Path(output_path).expanduser().resolve()
    if out.is_dir():
        out = out / Path(src_file_path_or_id).name
    out.parent.mkdir(parents=True, exist_ok=True)
    return out


def download_file(src_file_path_or_id: str, output_path: str) -> None:
    service = _service()
    file_id = _resolve_file_id(service, src_file_path_or_id)
    out = _resolve_output_path(src_file_path_or_id, output_path)

    req = service.files().get_media(fileId=file_id)
    try:
        with open(out, "wb") as fh:
            downloader = MediaIoBaseDownload(fh, req)
            done = False
            while not done:
                _, done = downloader.next_chunk()
    except Exception as exc:
        # fileId として失敗した場合に、ありがちな誤用（ファイル名を渡した）をガイドする
        if (
            isinstance(exc, Exception)
            and hasattr(exc, "resp")
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
    local = Path(local_file_path).expanduser().resolve()
    if not local.exists():
        raise FileNotFoundError(f"Local file not found: {local}")

    parent_id = _resolve_folder_id(service, target_folder, create=True)
    media = MediaFileUpload(str(local), resumable=True)
    meta = {"name": local.name, "parents": [parent_id]}
    created = service.files().create(body=meta, media_body=media, fields="id").execute()
    print(f"Uploaded: {local} -> {target_folder} (id={created['id']})")


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