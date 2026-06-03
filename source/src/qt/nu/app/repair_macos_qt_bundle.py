#!/usr/bin/env python3
"""Repair and verify Qt framework deployment in the macOS Nu app bundle.

Homebrew's modular Qt 6 layout can leave macdeployqt with unresolved @rpath
references for some Qt Quick frameworks. This pass keeps macdeployqt as the
primary deployer, then fills in missing Qt frameworks and rewrites bundled
Mach-O references so the app is self-contained before it reaches distribution
staging.
"""

from __future__ import annotations

import contextlib
import os
import re
import shutil
import stat
import subprocess
import sys
from pathlib import Path

QT_FRAMEWORK_RE = re.compile(r"(Qt[^/\s]+\.framework)/Versions/([^/\s]+)/([^/\s]+)$")
MACHO_MAGICS = {
    b"\xfe\xed\xfa\xce",
    b"\xce\xfa\xed\xfe",
    b"\xfe\xed\xfa\xcf",
    b"\xcf\xfa\xed\xfe",
    b"\xca\xfe\xba\xbe",
    b"\xbe\xba\xfe\xca",
    b"\xca\xfe\xba\xbf",
    b"\xbf\xba\xfe\xca",
}


def run(args: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, check=check, capture_output=True, text=True)


def is_macho(path: Path) -> bool:
    try:
        with path.open("rb") as handle:
            return handle.read(4) in MACHO_MAGICS
    except OSError:
        return False


def macho_files(contents_dir: Path) -> list[Path]:
    files: list[Path] = []
    for root, dirs, names in os.walk(contents_dir):
        root_path = Path(root)
        if any(part.endswith(".framework") for part in root_path.parts):
            dirs[:] = [name for name in dirs if name not in {"Headers", "Modules", "Resources"}]
        for name in names:
            path = root_path / name
            if is_macho(path):
                files.append(path)
    return files


def otool_deps(path: Path) -> list[str]:
    result = run(["otool", "-L", str(path)])
    deps: list[str] = []
    for line in result.stdout.splitlines()[1:]:
        line = line.strip()
        if not line:
            continue
        deps.append(line.split(" ", 1)[0])
    return deps


def qt_framework_from_dep(dep: str) -> tuple[str, str] | None:
    match = QT_FRAMEWORK_RE.search(dep)
    if not match:
        return None
    framework, _version, library = match.groups()
    return framework, library


def flat_dylib_name(dep: str) -> str | None:
    if ".framework/" in dep:
        return None
    if dep.startswith("/usr/lib/") or dep.startswith("/System/"):
        return None
    name = dep.rsplit("/", 1)[-1]
    if not name.endswith(".dylib"):
        return None
    return name


def candidate_roots(qt_root: Path) -> list[Path]:
    roots = [
        qt_root / "lib",
        qt_root / "opt" / "qt" / "lib",
        qt_root / "opt" / "qtbase" / "lib",
        qt_root / "opt" / "qtdeclarative" / "lib",
        qt_root / "opt" / "qtsvg" / "lib",
        qt_root / "opt" / "qttools" / "lib",
        Path("/opt/homebrew/lib"),
        Path("/opt/homebrew/opt/qt/lib"),
        Path("/opt/homebrew/opt/qtbase/lib"),
        Path("/opt/homebrew/opt/qtdeclarative/lib"),
        Path("/opt/homebrew/opt/qtsvg/lib"),
        Path("/opt/homebrew/opt/qttools/lib"),
    ]
    roots.extend(sorted(Path("/opt/homebrew/opt").glob("qt*/lib")))
    seen: set[Path] = set()
    unique: list[Path] = []
    for root in roots:
        try:
            resolved = root.resolve()
        except OSError:
            resolved = root
        if resolved not in seen:
            unique.append(root)
            seen.add(resolved)
    return unique


def source_framework_for(framework: str, dep: str, roots: list[Path]) -> Path | None:
    if dep.startswith("/"):
        marker = f"/{framework}/"
        if marker in dep:
            source = Path(dep.split(marker, 1)[0]) / framework
            if source.exists():
                return source

    for root in roots:
        source = root / framework
        if source.exists():
            return source
    return None


def source_flat_dylib_for(dep: str, macho: Path, roots: list[Path]) -> Path | None:
    name = flat_dylib_name(dep)
    if name is None:
        return None
    if dep.startswith("/"):
        source = Path(dep)
        if source.exists():
            return source
    if dep.startswith("@loader_path/"):
        source = macho.parent / dep[len("@loader_path/") :]
        if source.exists():
            return source
    for root in roots:
        source = root / name
        if source.exists():
            return source
    return None


def chmod_writable(path: Path) -> None:
    try:
        mode = path.stat().st_mode
        path.chmod(mode | stat.S_IWUSR)
    except OSError:
        pass


def add_rpath(path: Path, rpath: str) -> None:
    result = run(["otool", "-l", str(path)], check=False)
    if rpath in result.stdout:
        return
    chmod_writable(path)
    run(["install_name_tool", "-add_rpath", rpath, str(path)], check=False)


def remove_suffix(value: str, suffix: str) -> str:
    if value.endswith(suffix):
        return value[: -len(suffix)]
    return value


def bundled_framework_identity(path: Path) -> tuple[str, str] | None:
    for part in path.parts:
        if part.startswith("Qt") and part.endswith(".framework"):
            framework = part
            library = remove_suffix(framework, ".framework")
            if path.name == library:
                return framework, library
    return None


def bundled_flat_dylib_identity(path: Path, contents_dir: Path) -> str | None:
    try:
        if path.parent != contents_dir / "Frameworks":
            return None
    except OSError:
        return None
    if not path.name.endswith(".dylib"):
        return None
    return f"@executable_path/../Frameworks/{path.name}"


def path_is_relative_to(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def executable_frameworks_prefix(macho: Path, contents_dir: Path) -> str:
    backend_bin_dir = contents_dir / "Resources" / "nu" / "bin"
    if path_is_relative_to(macho, backend_bin_dir):
        return "@executable_path/../../../Frameworks"
    return "@executable_path/../Frameworks"


def framework_install_name(macho: Path, contents_dir: Path, framework: str, library: str) -> str:
    return f"{executable_frameworks_prefix(macho, contents_dir)}/{framework}/Versions/A/{library}"


def flat_dylib_install_name(macho: Path, contents_dir: Path, name: str) -> str:
    return f"{executable_frameworks_prefix(macho, contents_dir)}/{name}"


def framework_local_flat_dylib(dep: str, macho: Path, contents_dir: Path) -> str | None:
    if not dep.startswith("@loader_path/") or "/" in dep[len("@loader_path/") :]:
        return None
    if ".framework/Versions/" not in str(macho):
        return None
    library = dep.rsplit("/", 1)[-1]
    if not library.endswith(".dylib"):
        return None
    if not (contents_dir / "Frameworks" / library).exists():
        return None
    return flat_dylib_install_name(macho, contents_dir, library)


def copy_framework(source: Path, target: Path) -> None:
    if target.exists():
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(source, target, symlinks=True)


def copy_flat_dylib(source: Path, target: Path) -> None:
    if target.exists():
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target, follow_symlinks=True)
    chmod_writable(target)


def ensure_frameworks(app_bundle: Path, qt_root: Path) -> None:
    contents_dir = app_bundle / "Contents"
    frameworks_dir = contents_dir / "Frameworks"
    frameworks_dir.mkdir(parents=True, exist_ok=True)
    roots = candidate_roots(qt_root)

    for _ in range(10):
        copied = False
        for macho in macho_files(contents_dir):
            for dep in otool_deps(macho):
                info = qt_framework_from_dep(dep)
                if not info:
                    continue
                framework, _library = info
                target = frameworks_dir / framework
                if target.exists():
                    continue
                source = source_framework_for(framework, dep, roots)
                if source is None:
                    raise RuntimeError(f"Unable to locate Qt framework {framework} required by {macho}")
                copy_framework(source, target)
                copied = True
        if not copied:
            return

    raise RuntimeError("Qt framework dependency copy did not converge")


def ensure_flat_dylibs(app_bundle: Path, qt_root: Path) -> None:
    contents_dir = app_bundle / "Contents"
    frameworks_dir = contents_dir / "Frameworks"
    frameworks_dir.mkdir(parents=True, exist_ok=True)
    roots = candidate_roots(qt_root)

    for _ in range(10):
        copied = False
        for macho in macho_files(contents_dir):
            for dep in otool_deps(macho):
                name = flat_dylib_name(dep)
                if name is None:
                    continue
                target = frameworks_dir / name
                if target.exists():
                    continue
                source = source_flat_dylib_for(dep, macho, roots)
                if source is None:
                    continue
                copy_flat_dylib(source, target)
                copied = True
        if not copied:
            return

    raise RuntimeError("Flat dylib dependency copy did not converge")


def normalize_qt_deps(app_bundle: Path) -> None:
    contents_dir = app_bundle / "Contents"
    for macho in macho_files(contents_dir):
        identity = bundled_framework_identity(macho)
        if identity:
            framework, library = identity
            framework_id = f"@executable_path/../Frameworks/{framework}/Versions/A/{library}"
            chmod_writable(macho)
            run(["install_name_tool", "-id", framework_id, str(macho)], check=False)
        else:
            flat_id = bundled_flat_dylib_identity(macho, contents_dir)
            if flat_id:
                chmod_writable(macho)
                run(["install_name_tool", "-id", flat_id, str(macho)], check=False)

        add_rpath(macho, "@executable_path/../Frameworks")
        if ".framework/Versions/" in str(macho):
            add_rpath(macho, "@loader_path/../../../")

        for dep in otool_deps(macho):
            desired: str | None
            info = qt_framework_from_dep(dep)
            if info:
                framework, library = info
                desired = framework_install_name(macho, contents_dir, framework, library)
            else:
                desired = framework_local_flat_dylib(dep, macho, contents_dir)
                if desired is None:
                    name = flat_dylib_name(dep)
                    if name is not None and (contents_dir / "Frameworks" / name).exists():
                        desired = flat_dylib_install_name(macho, contents_dir, name)
                if desired is None:
                    continue
            if dep == desired:
                continue
            chmod_writable(macho)
            run(["install_name_tool", "-change", dep, desired, str(macho)], check=False)


def prune_non_runtime_framework_files(app_bundle: Path) -> None:
    frameworks_dir = app_bundle / "Contents" / "Frameworks"
    if not frameworks_dir.exists():
        return

    for headers_dir in frameworks_dir.glob("Qt*.framework/Versions/*/Headers"):
        shutil.rmtree(headers_dir, ignore_errors=True)

    for headers_link in frameworks_dir.glob("Qt*.framework/Headers"):
        try:
            if headers_link.is_symlink() or headers_link.exists():
                headers_link.unlink()
        except OSError:
            pass

    for prl_file in frameworks_dir.glob("Qt*.framework/Versions/*/Resources/*.prl"):
        with contextlib.suppress(OSError):
            prl_file.unlink()


def validate_bundle(app_bundle: Path) -> None:
    contents_dir = app_bundle / "Contents"
    missing: list[str] = []
    unresolved: list[str] = []

    for macho in macho_files(contents_dir):
        for dep in otool_deps(macho):
            info = qt_framework_from_dep(dep)
            if info:
                framework, library = info
                bundled = contents_dir / "Frameworks" / framework / "Versions" / "A" / library
                if not bundled.exists():
                    missing.append(f"{macho}: {dep}")
                if dep.startswith("/opt/homebrew/") or dep.startswith("@rpath/"):
                    unresolved.append(f"{macho}: {dep}")
                continue
            if dep.startswith("@loader_path/") and ".framework/Versions/" in str(macho):
                library = dep.rsplit("/", 1)[-1]
                if (contents_dir / "Frameworks" / library).exists():
                    unresolved.append(f"{macho}: {dep}")
                continue
            name = flat_dylib_name(dep)
            if name is not None:
                bundled = contents_dir / "Frameworks" / name
                desired = flat_dylib_install_name(macho, contents_dir, name)
                if not bundled.exists() and (dep.startswith("/opt/homebrew/") or dep.startswith("@rpath/")):
                    missing.append(f"{macho}: {dep}")
                elif (
                    bundled.exists()
                    and dep != desired
                    and (
                        dep.startswith("/opt/homebrew/") or dep.startswith("@rpath/") or dep.startswith("@loader_path/")
                    )
                ):
                    unresolved.append(f"{macho}: {dep}")

    if missing or unresolved:
        details = []
        if missing:
            details.append("Missing bundled Qt framework references:")
            details.extend(f"  {item}" for item in missing[:40])
        if unresolved:
            details.append("Unresolved Qt install names:")
            details.extend(f"  {item}" for item in unresolved[:40])
        raise RuntimeError("\n".join(details))


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: repair_macos_qt_bundle.py <qt-root> <app-bundle>", file=sys.stderr)
        return 2

    qt_root = Path(sys.argv[1]).resolve()
    app_bundle = Path(sys.argv[2]).resolve()
    if not (app_bundle / "Contents" / "MacOS").exists():
        print(f"not a macOS app bundle: {app_bundle}", file=sys.stderr)
        return 2

    prune_non_runtime_framework_files(app_bundle)
    ensure_frameworks(app_bundle, qt_root)
    ensure_flat_dylibs(app_bundle, qt_root)
    prune_non_runtime_framework_files(app_bundle)
    normalize_qt_deps(app_bundle)
    prune_non_runtime_framework_files(app_bundle)
    validate_bundle(app_bundle)
    print(f"Verified bundled Qt frameworks for {app_bundle}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
