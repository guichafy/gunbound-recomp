"""Shared desktop export contracts; no dependency on the local tool installation."""
from pathlib import Path

NOTICES = {
    'docs/GODOT_LICENSE.txt': 'GODOT_LICENSE.txt',
    'docs/GODOT_COPYRIGHT.txt': 'GODOT_COPYRIGHT.txt',
    'assets/openbound/OPENBOUND_CODE_LICENSE.GPL': 'OPENBOUND_CODE_LICENSE.GPL',
    'assets/openbound/ATTRIBUTION.md': 'OPENBOUND_ATTRIBUTION.md',
    'assets/xfs/ATTRIBUTION.md': 'XFS_ATTRIBUTION.md',
}


def project_version(root: Path) -> str:
    section = ''
    for source in (root / 'project.godot').read_text(encoding='utf-8').splitlines():
        line = source.strip()
        if line.startswith('['):
            section = line
        elif section == '[application]' and line.startswith('config/version='):
            return line.split('=', 1)[1].strip().strip('"')
    raise ValueError('project.godot has no application/config/version')


def copy_notices(root: Path, destination: Path) -> None:
    import shutil
    destination.mkdir(parents=True, exist_ok=True)
    for relative, name in NOTICES.items():
        source = root / relative
        if not source.is_file():
            raise ValueError(f'Missing required distribution notice: {relative}')
        shutil.copy2(source, destination / name)
