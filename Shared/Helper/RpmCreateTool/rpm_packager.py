#!/usr/bin/env python3

from __future__ import annotations

import argparse
import dataclasses
import datetime as _dt
import glob
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Any, Iterable


@dataclasses.dataclass(frozen=True)
class PackageMeta:
    name: str
    version: str
    release: str
    summary: str
    license: str
    url: str | None
    description: str
    build_arch: str | None


@dataclasses.dataclass(frozen=True)
class InstallItem:
    source_on_disk: Path
    stage_relpath: Path
    dest_path: str
    mode: str


def _load_config(config_path: Path) -> dict[str, Any]:
    suffixes = [s.lower() for s in config_path.suffixes]
    # Allow .yaml.example / .json.example for sample configs
    if len(suffixes) >= 2 and suffixes[-1] == ".example":
        suffix = suffixes[-2]
    else:
        suffix = config_path.suffix.lower()
    if suffix in {".json"}:
        return json.loads(config_path.read_text(encoding="utf-8"))

    if suffix in {".yaml", ".yml"}:
        try:
            import yaml  # type: ignore
        except Exception as exc:  # pragma: no cover
            raise RuntimeError(
                "YAML を使うには PyYAML が必要です。\n"
                "例: python3 -m pip install pyyaml"
            ) from exc
        return yaml.safe_load(config_path.read_text(encoding="utf-8"))

    raise RuntimeError(f"Unsupported config extension: {config_path.name}")


def _require_dict(obj: Any, where: str) -> dict[str, Any]:
    if not isinstance(obj, dict):
        raise RuntimeError(f"{where} must be an object")
    return obj


def _require_str(obj: Any, where: str) -> str:
    if not isinstance(obj, str) or not obj.strip():
        raise RuntimeError(f"{where} must be a non-empty string")
    return obj


def _optional_str(obj: Any) -> str | None:
    if obj is None:
        return None
    if not isinstance(obj, str):
        raise RuntimeError("value must be a string")
    value = obj.strip()
    return value if value else None


def _parse_meta(cfg: dict[str, Any]) -> PackageMeta:
    pkg = _require_dict(cfg.get("package"), "package")
    name = _require_str(pkg.get("name"), "package.name")
    version = _require_str(pkg.get("version"), "package.version")
    release = _require_str(pkg.get("release"), "package.release")
    summary = _require_str(pkg.get("summary"), "package.summary")
    license_ = _require_str(pkg.get("license"), "package.license")
    url = _optional_str(pkg.get("url"))
    description = _optional_str(pkg.get("description")) or summary
    build_arch = _optional_str(pkg.get("arch"))
    return PackageMeta(
        name=name,
        version=version,
        release=release,
        summary=summary,
        license=license_,
        url=url,
        description=description,
        build_arch=build_arch,
    )


def _iter_src_files_from_dir(src_dir: Path, include_glob: str) -> Iterable[Path]:
    # include_glob is evaluated relative to src_dir
    pattern = str(src_dir / include_glob)
    for p in sorted(Path(x) for x in glob.glob(pattern, recursive=True)):
        if p.is_file():
            yield p


def _expand_install_items(project_dir: Path, cfg: dict[str, Any]) -> list[InstallItem]:
    raw_items = cfg.get("files")
    if not isinstance(raw_items, list) or not raw_items:
        raise RuntimeError("files must be a non-empty array")

    items: list[InstallItem] = []
    for idx, raw in enumerate(raw_items, start=1):
        if not isinstance(raw, dict):
            raise RuntimeError(f"files[{idx}] must be an object")

        mode = str(raw.get("mode") or "0644")
        if not mode.isdigit() or len(mode) not in {3, 4}:
            raise RuntimeError(f"files[{idx}].mode must be like 0644")

        if "src_dir" in raw:
            src_dir = (project_dir / _require_str(raw.get("src_dir"), f"files[{idx}].src_dir")).resolve()
            if not src_dir.exists() or not src_dir.is_dir():
                raise RuntimeError(f"files[{idx}].src_dir not found: {src_dir}")

            dest_dir = _require_str(raw.get("dest_dir"), f"files[{idx}].dest_dir")
            if not dest_dir.startswith("/"):
                raise RuntimeError(f"files[{idx}].dest_dir must start with '/'")

            include_glob = str(raw.get("include") or "**/*")
            stage_base = Path(f"dir_{idx}")

            for f in _iter_src_files_from_dir(src_dir, include_glob):
                rel = f.relative_to(src_dir)
                stage_rel = stage_base / rel
                dest = (dest_dir.rstrip("/") + "/" + rel.as_posix()).replace("//", "/")
                items.append(
                    InstallItem(
                        source_on_disk=f,
                        stage_relpath=stage_rel,
                        dest_path=dest,
                        mode=mode,
                    )
                )
            continue

        src = _optional_str(raw.get("src"))
        if not src:
            raise RuntimeError(f"files[{idx}] must have either src or src_dir")

        dest = _optional_str(raw.get("dest"))
        dest_dir = _optional_str(raw.get("dest_dir"))

        matches = sorted(Path(x) for x in glob.glob(str((project_dir / src)), recursive=True))
        matches = [m.resolve() for m in matches if m.is_file()]
        if not matches:
            raise RuntimeError(f"files[{idx}].src matched no files: {src}")

        if dest and dest_dir:
            raise RuntimeError(f"files[{idx}] cannot set both dest and dest_dir")

        if dest:
            if len(matches) != 1:
                raise RuntimeError(f"files[{idx}].dest requires exactly 1 matched file")
            if not dest.startswith("/"):
                raise RuntimeError(f"files[{idx}].dest must start with '/'")
            stage_rel = Path(f"file_{idx}") / matches[0].name
            items.append(
                InstallItem(
                    source_on_disk=matches[0],
                    stage_relpath=stage_rel,
                    dest_path=dest,
                    mode=mode,
                )
            )
            continue

        if dest_dir:
            if not dest_dir.startswith("/"):
                raise RuntimeError(f"files[{idx}].dest_dir must start with '/'")
            stage_base = Path(f"glob_{idx}")
            for f in matches:
                stage_rel = stage_base / f.name
                dest_path = (dest_dir.rstrip("/") + "/" + f.name).replace("//", "/")
                items.append(
                    InstallItem(
                        source_on_disk=f,
                        stage_relpath=stage_rel,
                        dest_path=dest_path,
                        mode=mode,
                    )
                )
            continue

        raise RuntimeError(f"files[{idx}] must set dest or dest_dir")

    if not items:
        raise RuntimeError("No installable files resolved from files[]")

    # Validate destination paths
    for it in items:
        if not it.dest_path.startswith("/"):
            raise RuntimeError(f"dest must start with '/': {it.dest_path}")

    return items


def _write_spec(
    spec_path: Path,
    meta: PackageMeta,
    items: list[InstallItem],
    build_date: str,
) -> None:
    lines: list[str] = []
    lines.append(f"Name:           {meta.name}")
    lines.append(f"Version:        {meta.version}")
    lines.append(f"Release:        {meta.release}")
    lines.append(f"Summary:        {meta.summary}")
    lines.append("")
    lines.append(f"License:        {meta.license}")
    if meta.url:
        lines.append(f"URL:            {meta.url}")
    if meta.build_arch:
        lines.append(f"BuildArch:      {meta.build_arch}")
    lines.append("")
    lines.append("%description")
    lines.append(meta.description)
    lines.append("")
    lines.append("%prep")
    lines.append("")
    lines.append("%build")
    lines.append("")
    lines.append("%install")
    lines.append("rm -rf %{buildroot}")

    for it in items:
        src = f"%{{_sourcedir}}/stage/{it.stage_relpath.as_posix()}"
        dst = f"%{{buildroot}}{it.dest_path}"
        lines.append(f"install -D -m {it.mode} \"{src}\" \"{dst}\"")

    lines.append("")
    lines.append("%files")
    for it in items:
        lines.append(it.dest_path)

    lines.append("")
    lines.append("%changelog")
    lines.append(f"* {build_date} Packager <packager@example.com> - {meta.version}-{meta.release}")
    lines.append("- Built from prebuilt artifacts")

    spec_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _ensure_clean_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def _copy_stage(stage_dir: Path, items: list[InstallItem]) -> None:
    for it in items:
        dst = stage_dir / it.stage_relpath
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(it.source_on_disk, dst)


def _run_rpmbuild(topdir: Path, spec_path: Path) -> None:
    cmd = [
        "rpmbuild",
        "-bb",
        str(spec_path),
        "--define",
        f"_topdir {topdir}",
    ]
    subprocess.run(cmd, check=True)


def _find_default_config(cwd: Path) -> Path | None:
    candidates = [
        cwd / "rpm-package.yaml",
        cwd / "rpm-package.yml",
        cwd / "rpm-package.json",
    ]
    for c in candidates:
        if c.exists() and c.is_file():
            return c
    return None


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Package prebuilt artifacts into an RPM, using rpm-package.(yaml|yml|json) in current directory.",
    )
    parser.add_argument(
        "config_positional",
        nargs="?",
        default=None,
        help="Path to config (positional; optional).",
    )
    parser.add_argument(
        "--config",
        type=str,
        default=None,
        dest="config_option",
        help="Path to config (default: ./rpm-package.yaml|yml|json)",
    )
    parser.add_argument(
        "--no-rpmbuild",
        action="store_true",
        help="Do not invoke rpmbuild (only stage files and generate spec).",
    )
    args = parser.parse_args(argv)

    project_dir = Path.cwd()

    if args.config_positional and args.config_option:
        raise RuntimeError("Specify config only once (either positional CONFIG or --config)")

    config_arg = args.config_option or args.config_positional
    config_path = Path(config_arg).resolve() if config_arg else _find_default_config(project_dir)
    if not config_path:
        raise RuntimeError(
            "Config file not found. Put one of these in current directory:\n"
            "- rpm-package.yaml\n- rpm-package.yml\n- rpm-package.json"
        )

    cfg = _load_config(config_path)
    cfg = _require_dict(cfg, "config")

    meta = _parse_meta(cfg)
    items = _expand_install_items(project_dir, cfg)

    topdir = project_dir / "rpmbuild"
    stage_dir = topdir / "SOURCES" / "stage"
    specs_dir = topdir / "SPECS"

    _ensure_clean_dir(topdir)
    for d in ["BUILD", "BUILDROOT", "RPMS", "SOURCES", "SPECS", "SRPMS"]:
        (topdir / d).mkdir(parents=True, exist_ok=True)

    stage_dir.mkdir(parents=True, exist_ok=True)
    _copy_stage(stage_dir, items)

    build_date = _dt.datetime.now().strftime("%a %b %d %Y")
    spec_path = specs_dir / f"{meta.name}.spec"
    _write_spec(spec_path, meta, items, build_date)

    print(f"Config:   {config_path}")
    print(f"Topdir:   {topdir}")
    print(f"Spec:     {spec_path}")
    print(f"Staged:   {len(items)} file(s)")

    if args.no_rpmbuild:
        print("Skip:    rpmbuild (requested via --no-rpmbuild)")
        return 0

    _run_rpmbuild(topdir, spec_path)
    print("RPM build completed.")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        raise
