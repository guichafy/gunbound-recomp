# GunBound client reference assets

The original shop frames and avatar data were extracted from the public
`TestClient/graphics.xfs` and `TestClient/avatar.xfs` files in
https://github.com/jglim/gunbound-launcher at commit
`2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1` (XFS version 280).
GunBound artwork belongs to its respective rights holders; the emulator's
source license does not grant ownership of the game's art.

The displayed client layout was checked against `Other/gb-avatar.png` from
https://github.com/jglim/gunbound-server at commit
`46af0e758643563666723efecd7a32a3debb939a`.

`shop/catalog.json` records source frame dimensions, pivots, and SHA-256 for
every decoded PNG. `reference/` retains the small original avatar archive,
its eight DAT files and the extracted records; `.gdignore` excludes that
reference data from the game package. `avatars/catalog.json` is the active
562-record XFS catalog (479 buyable), with registered base/effect layers and
native shop portraits. Legacy C# identities remain available for saved items.

The new reader and IMG decoder are tooling, not a server/client protocol
implementation. Compressed-block checksums have not been reverse engineered;
structural bounds, preserved fixture bytes and decoded-frame hashes are checked.

`jewel/` contains the original Thor's Hammer jewel bodies, additive lights,
EPA timelines, Jflame impacts, room control and score glyphs, extracted from
that same `graphics.xfs` (SHA-256
`a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`).
`jewel/catalog.json` preserves source entry hashes, pivots and frame counts;
`jewel/combat.json` records the material triples from the pinned client DAT.
Reproduce with `scripts/import_jewel_assets.py` and `scripts/import_jewel_combat.py`.
