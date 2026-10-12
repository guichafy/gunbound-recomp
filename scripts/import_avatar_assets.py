"""Copy the four source avatar categories and original Shop UI without editing pixels."""
import argparse, hashlib, json, re, shutil
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--source', type=Path, default=Path.home() / 'Workspaces/Gunbound')
    source = ap.parse_args().source
    base = source / 'OpenBound-Assets/Game Assets'
    metadata = source / 'Openbound Network Object Library/DatabaseSeed/AvatarMetadata.json'
    rows = json.loads(re.sub(r'//[^\n]*', '', metadata.read_text(encoding='utf-8-sig')))
    manifest, entries = [], []
    def copy(src, dst):
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)
        digest = hashlib.sha256(src.read_bytes()).hexdigest()
        assert hashlib.sha256(dst.read_bytes()).hexdigest() == digest
        manifest.append({'source': str(src.relative_to(source)), 'file': str(dst.relative_to(ROOT)), 'sha256': digest})
    for r in rows:
        if r['AvatarCategory'] > 3:
            continue
        gender = ['Male', 'Female', 'Unissex'][r['Gender']]
        category = ['Hat', 'Body', 'Goggles', 'Flag'][r['AvatarCategory']]
        stem = Path(gender) / category / (r['Name'] + '.png')
        atlas = ROOT / 'assets/openbound/avatars' / stem
        portrait = ROOT / 'assets/openbound/avatars' / gender / 'Portrait' / category / (r['Name'] + '.png')
        empty = r['ID'] == 0 and r['AvatarCategory'] in (2, 3)
        if not empty:
            copy(base / 'Graphics/Avatar' / stem, atlas)
        copy(base / 'Graphics/Avatar' / gender / 'Portrait' / category / (r['Name'] + '.png'), portrait)
        entries.append({'key': f"{r['Gender']}:{r['AvatarCategory']}:{r['ID']}", 'gender': r['Gender'], 'category': r['AvatarCategory'], 'id': r['ID'], 'name': r['Name'], 'date': r['Date'], 'gold_price': r.get('GoldPrice', 0), 'cash_price': r.get('CashPrice', 0), 'pivot': [r.get('PivotX', 0), r.get('PivotY', 0)], 'frame_size': [r['FrameDimensionX'], r['FrameDimensionY']], 'atlas': '' if empty else 'res://' + str(atlas.relative_to(ROOT)), 'portrait': 'res://' + str(portrait.relative_to(ROOT))})
    paths = ['Interface/InGame/Scene/AvatarShop', 'Interface/AnimatedButtons/AvatarShop', 'Interface/StaticButtons/AvatarShop', 'Interface/Popup/Blue/Avatar', 'Interface/Spritefont/AvatarShop', 'Interface/StaticButtons/Popup', 'Interface/AnimatedButtons/General']
    for path in paths:
        for src in sorted((base / path).rglob('*.png')):
            copy(src, ROOT / 'assets/openbound/shop' / src.relative_to(base / 'Interface'))
    out = ROOT / 'assets/openbound/avatars'
    (out / 'catalog.json').write_text(json.dumps(entries, indent=2))
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2))
    print(f'{len(entries)} avatars, {len(manifest)} original files copied')
if __name__ == '__main__':
    main()
