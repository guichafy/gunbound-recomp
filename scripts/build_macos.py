#!/usr/bin/env python3
"""Export, normalize internal executable names, sign locally and package macOS."""
import argparse
import plistlib
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "builds" / "Brisa de Aco.app"
GODOT = Path("/Applications/Godot.app/Contents/MacOS/Godot")


def run(*arguments: str) -> None:
    subprocess.run(arguments, cwd=ROOT, check=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-export", action="store_true")
    args = parser.parse_args()
    APP.parent.mkdir(exist_ok=True)
    if not args.skip_export:
        run(str(GODOT), "--headless", "--path", str(ROOT), "--export-release", "macOS", str(APP))
    contents = APP / "Contents"
    plist_path = contents / "Info.plist"
    with plist_path.open("rb") as source:
        info = plistlib.load(source)
    original = info["CFBundleExecutable"]
    internal = "BrisaDeAco"
    if original != internal:
        (contents / "MacOS" / original).rename(contents / "MacOS" / internal)
        (contents / "Resources" / (original + ".pck")).rename(contents / "Resources" / (internal + ".pck"))
    info["CFBundleExecutable"] = internal
    info["CFBundleDisplayName"] = "Brisa de Aço"
    with plist_path.open("wb") as target:
        plistlib.dump(info, target)
    for name in ["GODOT_LICENSE.txt", "GODOT_COPYRIGHT.txt"]:
        source = ROOT / "docs" / name
        if source.exists():
            shutil.copy2(source, contents / "Resources" / name)
    # Normalize executable metadata before sealing resources. This avoids the
    # observed accented-filename resource mismatch in the native signer.
    run("codesign", "--force", "--sign", "-", "--timestamp=none", str(contents / "MacOS" / internal))
    run("codesign", "--force", "--sign", "-", "--timestamp=none", str(APP))
    run("codesign", "--verify", "--deep", "--strict", "--verbose=2", str(APP))
    run("ditto", "-c", "-k", "--keepParent", str(APP), str(APP.parent / "Brisa-de-Aco-macOS.zip"))
    print("Ready:", APP)


if __name__ == "__main__":
    main()
