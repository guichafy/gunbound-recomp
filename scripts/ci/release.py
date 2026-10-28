#!/usr/bin/env python3
"""Conventional versions from a pinned bootstrap or the latest ancestor release."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
HEADER = re.compile(r'^[a-z]+(?:\([^\r\n()]+\))?(!)?: .+')
VERSION = re.compile(r'^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$')


def next_version(base, messages):
    if not VERSION.fullmatch(base):
        raise ValueError(f'Invalid base version: {base}')
    bump = 0
    for message in messages:
        subject = message.splitlines()[0] if message else ''
        match = HEADER.fullmatch(subject)
        if not match:
            raise ValueError(f'Expected Conventional Commit: {subject}')
        level = 3 if match[1] or re.search(r'^BREAKING[ -]CHANGE: .+', message, re.M) else 2 if subject.startswith('feat:') or subject.startswith('feat(') else 1
        bump = max(bump, level)
    major, minor, patch = map(int, base.removeprefix('v').split('.'))
    if bump == 3:
        return f'{major + 1}.0.0'
    if bump == 2:
        return f'{major}.{minor + 1}.0'
    return f'{major}.{minor}.{patch + bool(bump)}'


def git(root, *arguments):
    return subprocess.check_output(['git', '-C', str(root), *arguments], text=True).strip()


def plan(root, config, pr_title=None):
    if pr_title:
        next_version('0.0.0', [pr_title])
    sha = git(root, 'rev-parse', 'HEAD')
    floor = tuple(map(int, config['baseline_version'].split('.')))
    tags = [tag for tag in git(root, 'tag', '--merged', 'HEAD').splitlines()
            if VERSION.fullmatch(tag) and tag.startswith('v')
            and tuple(map(int, tag[1:].split('.'))) >= floor]
    exact = [tag for tag in tags if git(root, 'rev-list', '-n', '1', tag) == sha]
    if len(exact) > 1:
        raise ValueError('Multiple release tags for the same SHA')
    if exact:
        return {'version': exact[0][1:], 'tag': exact[0], 'sha': sha}
    if tags:
        base = max(tags, key=lambda tag: tuple(map(int, tag[1:].split('.'))))
        version = base[1:]
    else:
        base, version = config['baseline_sha'], config['baseline_version']
    subprocess.run(['git', '-C', str(root), 'merge-base', '--is-ancestor', base, sha], check=True)
    commits = git(root, 'rev-list', '--reverse', '--no-merges', f'{base}..{sha}').splitlines()
    # Rebase and merge preserves commit messages; the title alone cannot prove
    # that main will accept this history or predict its release version.
    messages = [git(root, 'show', '-s', '--format=%B', commit) for commit in commits]
    if not messages:
        raise ValueError('No new commits to release')
    version = next_version(version, messages)
    return {'version': version, 'tag': f'v{version}', 'sha': sha}


def apply_version(project, version):
    if not VERSION.fullmatch(version) or version.startswith('v'):
        raise ValueError('Expected numeric SemVer')
    content = project.read_text(encoding='utf-8')
    section = False
    lines = content.splitlines(keepends=True)
    count = 0
    for index, line in enumerate(lines):
        if line.startswith('['):
            section = line.strip() == '[application]'
        elif section and line.startswith('config/version='):
            lines[index] = f'config/version="{version}"\n'
            count += 1
    if count != 1:
        raise ValueError('Expected one application/config/version')
    project.write_text(''.join(lines), encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply')
    parser.add_argument('--title')
    parser.add_argument('--pr-title')
    args = parser.parse_args()
    if args.apply:
        apply_version(ROOT / 'project.godot', args.apply)
        return
    if args.title:
        next_version('0.0.0', [args.title])
        return
    result = plan(ROOT, json.loads((ROOT / '.github/release.json').read_text()), args.pr_title)
    (ROOT / '.tools').mkdir(exist_ok=True)
    (ROOT / '.tools/release.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))
    if os.environ.get('GITHUB_OUTPUT'):
        with open(os.environ['GITHUB_OUTPUT'], 'a', encoding='utf-8') as output:
            for key, value in result.items():
                output.write(f'{key}={value}\n')


if __name__ == '__main__':
    main()
