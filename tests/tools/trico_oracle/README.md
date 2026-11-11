# Trico PE oracle

Run from the repository root with Python, Pillow and Unicorn2.1.4 installed:

```sh
python tests/tools/trico_oracle/generate.py
```

`bootstrap.py --client-source … --skip-godot --no-legacy-sound` prepares the
pinned PE/DAT. The generator explicitly sets `emu.PE` to that verified copy;
PE and DAT hash mismatches stop execution before producing a fixture.
Unicorn's local JIT requires executable memory (a restricted sandbox may
reject this). No whole-client process, network or Godot code is executed.

- T2: protected cells are initialized at the isolated boundary established by
  constructor4a2a70/factory42bbb0; execute Animate4a4610 → tick4a2ce0. Native
  contact invocation is recorded without collision. Radius/phase updates,
  sine LUT, x87 conversion, carrier publication, acceleration and bounds run
  as PE instructions. Common idx2 executes vtable555c34/48f1c0/4872b0.
- Contacts: execute455cc0 and refiners on a controlled1px flat floor, no
  mobiles/weather. Read the Boolean from AL; EAX upper bits are unspecified.
  Both contacts and absence of contacts are covered.
- SS: execute4ad230 →4ae0f0/4acd10 through removal21. Record431d90 before
  renderer/network/damage. Replay flag suppresses only flame allocation.
- Initializer: decode the pinned DAT directly and execute41da80 for type3;
  width3198 is100 for T2 and50 for SS, not its blast dimension120.

Fixture: `tests/fixtures/trico_native.json`. Units are signed24.8 for motion,
integer pixels for contacts/SS, uint32 for SS seed; one row per native tick.
Ghidra identity, VAs, bridge limits and port tests are documented in
`docs/sdd/TRICO_SPECIALS_ISSUE_30.md` and `docs/trico-native/`.
