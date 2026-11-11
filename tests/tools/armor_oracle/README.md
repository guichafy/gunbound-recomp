# Armor T2 oracle

`generate.py` executes the pinned Thor's Hammer PE functions in Unicorn2.1.4;
no GDScript is imported. It reuses only the generic PE loader/CPU harness in
`../grub_oracle/emu.py`. Required: verified local PE, Python + Unicorn, and
fresh Ghidra extracts in `.tools/armor-t2/evidence-*` (RET sizes checked by
`pop`). Reproduce with `python tests/tools/armor_oracle/generate.py` after
running the four queries recorded in `docs/armor-t2/evidence.json`.

The real4688b0 tick executes both impact branches, signed protected arithmetic,
phase/removal and acceleration. Its contact producer is controlled at ticks1/4;
crater/damage/registry/presentation/audio functions are recorded no-op stubs.
Separate cases execute real455cc0 +458920/458a00 with a1px terrain bitmap and
mobile-box stub; force/tornado/electricity/render hooks return0. These verify
scan order, overscan and fixed-point writeback, including both directions.

Fixture `tests/fixtures/armor_t2_native.json` is deterministic. This is isolated
function emulation, not execution of the complete original Windows game.
