#!/usr/bin/env python3
"""Export the Windows x86_64 executable and separate PCK, then add notices."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess

from ci.package_common import copy_notices

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / 'builds' / 'Windows'


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=os.environ.get('GODOT', 'godot'))
    args = parser.parse_args()
    # This dedicated generated directory must never retain stale binaries/PCKs.
    if OUTPUT.exists():
        shutil.rmtree(OUTPUT)
    OUTPUT.mkdir(parents=True)
    executable = OUTPUT / 'GunboundRecomp.exe'
    subprocess.run([args.godot, '--headless', '--path', str(ROOT), '--export-release',
                    'Windows Desktop', str(executable)], cwd=ROOT, check=True)
    for path in (executable, executable.with_suffix('.pck')):
        if not path.is_file() or not path.stat().st_size:
            raise ValueError(f'Exporter did not produce {path.name}')
    copy_notices(ROOT, OUTPUT)
    print('Ready:', executable)


if __name__ == '__main__':
    main()
