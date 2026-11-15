# Android v1 — release readiness review

> Follow-up: the API24 P1 below was fixed and independently re-reviewed. No P1/P2 remains in that source delta; signing/publication prerequisites remain open in issue56.

Read-only review, 2026-11-15. Initial source HEAD 49fdeaa9, fetched main 7d1e66d4. During review root reconciled the same source bytes onto branch codex/android-v1 based on origin/main; product behavior was not re-reviewed. Root will fix the API24 finding separately. No host Godot/AVD or remote mutation was run by this reviewer.

## P1 — API24 smoke uses unavailable package/logcat options

`scripts/ci/android_ui_smoke.py:315–321` invokes `cmd package list packages -U` and then `logcat --uid=<uid>`. The always-executed minimum-API job `.github/workflows/desktop.yml:254–268` runs this same helper on Android 7/API24. In AOSP android-7.0.0_r1 PackageManagerShellCommand.runListPackages, -U is absent and hits Unknown option; logcat long_options also lacks uid. Thus API24 smoke fails even if this APK works, preventing the Android job from passing in PR/main. Replace both with API24-compatible observation and add regression coverage. Root notified before source edits.

Primary evidence:

- [API24 PackageManagerShellCommand](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-7.0.0_r1/services/core/java/com/android/server/pm/PackageManagerShellCommand.java), runListPackages lines501–545.
- [API24 logcat](https://raw.githubusercontent.com/aosp-mirror/platform_system_core/android-7.0.0_r1/logcat/logcat.cpp), option table547–575; --pid supported, --uid absent.
- [API24 package dump](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-7.0.0_r1/services/core/java/com/android/server/pm/Settings.java), exact package block4055–4066 contains userId=appId.
- [API24 UID log format](https://raw.githubusercontent.com/aosp-mirror/platform_system_core/android-7.0.0_r1/liblog/logprint.c), UID1277–1294/threadtime1332–1339. logcat -d -v threadtime -v uid can be parsed locally to preserve every app PID across relaunch. Confirm default Android user0 when treating appId as full UID.

## Confirmed operational gates, intentional in approved design

Root confirmed names-only repository inspection returns no secrets and no vars. `.github/workflows/desktop.yml:232–245` signs on every main push irrespective of the publication flag and asserts a persistent key is present; `scripts/ci/android_package.py:52–65` also requires all signing inputs/fingerprint. Main therefore fails the Android job until authorized signing provisioning. This is fail-closed behavior explicitly documented in ANDROID_V1_DESIGN.md D6 and PLAN T5/T7, not an implementation divergence. It must remain visible before the user merges. No provisioning was authorized.

`.github/workflows/desktop.yml:339–342` replaces the existing desktop publisher condition with ANDROID_PUBLICATION_ENABLED=true and depends on Android/physical acceptance. With current absent vars, all new automatic releases, including desktop ZIP releases, are skipped. This is also explicit in the approved design; preserve/document this consequence in the blocking distribution issue rather than silently weakening gates. Desktop test/package jobs still run and upload their artifacts.

## Review limits and remaining validation

No additional concrete P1/P2 issue was identified in inspected Linux bootstrap/export/acceptance/publisher source. This is not execution evidence for the Linux emulator/toolchain. Local evidence is macOS ARM64/API36, ephemeral .ci APKs; min API24, Linux/x86_64, persistent-key updates and physical ARM64 remain unproved. User acceptance of the macOS emulator does not satisfy the physical exact-APK publication gate. Existing 98 CI tests and 3370 directed GDScript checks plus prior 103 matches were read from the ledger, not repeated by this reviewer.

## Reviewed file digests at report time

```json
{
  ".github/workflows/desktop.yml": "62ab27837a3d8cbea3be075346fcfe78296b0cdde2b911d11df90ad38bfa81be",
  "scripts/ci/android_ui_smoke.py": "b42c4dec77c8c10a6e1e1ef621b124e3662d12effe5d2bd8d849dfb7843fcc42",
  "scripts/ci/android_package.py": "592d00bd0ec149853f48eae2c751b2c544b075a1d2f4ccb7517ec67b926f7956",
  "scripts/ci/android_tools.py": "1d306774848fb2227e6c6515cf38287055f99c0991fd7d606999e122c2b4f460",
  "scripts/ci/publish.py": "bd85896f556f9d35cf1c34cb1c98e2fdbe02526b5ada6a36549eeee3712b53b2",
  "scripts/ci/android_acceptance.py": "405c47758c53a9db2e7a93132f525bf0b8184897d87867bf292dc6a0caf15f3c",
  "export_presets.cfg": "a249d7eaa6a41d7f4169aaacc3ee4029678153362a97f2b02e13d9cf1fd03a39"
}
```

## Follow-up disposition — API24 correction

The reviewer read the exact-package/default-user0/UID-format implementation and independently ran the UI smoke Python suite:20 tests,0 failures (1.875s). Both final and diagnostic use the helper. The P1 is resolved in source; actual API24 CI execution is still pending. Intentional signing/publication gates are tracked in issue56, not waived.
