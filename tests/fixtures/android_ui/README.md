# Android UI observation fixture

`lobby_api36.png` is the unobstructed 1280×800 screenshot produced by the
candidate APK in GitHub Actions run 44098742529 (API36, Linux x86_64 emulator,
PR57 head 09f65e1f). Tesseract does not identify its native raster buttons.

Tests locate controls using the active client PNGs and reject absent,
disabled, darkened and duplicate targets. `.gdignore` excludes this QA image
from Godot imports and application exports.

`options_api36.png` is the 1280×800 Android options screenshot from the local
ARM64/API36 smoke of candidate SHA256 `e174f1dc63e8072a5918330ec981162e9cec8ac9a61eb19399fc11abb573f0cc`.
It exercises the original raster OK, which Tesseract did not read. The template
uses the pixel-identical native fallback validated by ClassicBattleOptionsArt.

`resume_api36.png` is from the same candidate's full UI smoke. Tesseract
returned no text from the full frame, including grayscale and alternate page
segmentation. The observer detects bright panels, thresholds their pixels,
then requires the resume caption and its OCR rectangle before any tap.

`busy_controls_api36.png` and `active_controls_api36.png` preserve the two
backgrounds and OFF/ON captions used to validate contour-derived control OCR.
They come from the same candidate and dedicated API36 emulator. Tests also
move the controls to ensure recognition does not depend on screen positions.
