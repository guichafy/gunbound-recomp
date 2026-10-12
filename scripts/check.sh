#!/bin/sh
# Harness de qualidade: roda todas as suites headless e consolida o resultado.
# Uso: scripts/check.sh [--quick] [suite ...]
#   --quick   omite test_matches (dez partidas completas, ~30s)
#   suite     roda apenas as suites informadas (nomes sem tests/ nem .gd)
# GODOT=/caminho/do/Godot sobrepoe o binario padrao do macOS.
set -u

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT" || exit 2

ALL="test_runner test_scene test_refinement test_refinement_scene test_bigfoot test_mage test_mage_scene test_bigfoot_attacks test_bigfoot_attacks_scene test_hd_assets test_mobile_animation test_pilot_projectiles test_roster test_map test_weather test_hud test_aiming test_performance test_items test_items_scene test_shop_items_integration test_avatar_catalog test_avatar_profile test_avatar_shop test_avatar_art test_avatar_mount test_avatar_hd test_attributes test_gold_rewards test_matches"
QUICK="test_runner test_scene test_refinement test_refinement_scene test_bigfoot test_mage test_mage_scene test_bigfoot_attacks test_bigfoot_attacks_scene test_hd_assets test_mobile_animation test_pilot_projectiles test_roster test_map test_weather test_hud test_aiming test_performance test_items test_items_scene test_shop_items_integration test_avatar_catalog test_avatar_profile test_avatar_shop test_avatar_art test_avatar_mount test_avatar_hd test_attributes test_gold_rewards"

suites=""
quick=0
for arg in "$@"; do
	if [ "$arg" = "--quick" ]; then
		quick=1
	else
		suites="$suites $arg"
	fi
done
if [ -z "$suites" ]; then
	suites=$QUICK
	[ "$quick" -eq 0 ] && suites=$ALL
fi

if [ ! -x "$GODOT" ]; then
	echo "Godot nao encontrado em $GODOT (defina GODOT=...)" >&2
	exit 2
fi
mkdir -p .tools/check-logs

fail=0
total_checks=0
for suite in $suites; do
	script="tests/$suite.gd"
	if [ ! -f "$script" ]; then
		echo "!! $suite: tests/$suite.gd inexistente"
		fail=$((fail + 1))
		continue
	fi
	log=".tools/check-logs/$suite.log"
	output=$("$GODOT" --headless --path . --script "$script" 2>&1)
	status=$?
	printf '%s\n' "$output" >"$log"
	summary=$(printf '%s\n' "$output" | grep -E 'CHECKS:|MATCHES:' | tail -1)
	if [ -z "$summary" ]; then
		summary="(sem resumo; ver $log)"
	fi
	if [ "$summary" = "(sem resumo; ver $log)" ] || [ "$status" -ne 0 ] || printf '%s\n' "$output" | grep -Eq 'FAIL:|SCRIPT ERROR:|^ERROR:'; then
		echo "FAIL $suite -> $summary"
		fail=$((fail + 1))
	else
		echo "OK   $suite -> $summary"
	fi
	case $summary in
		*CHECKS:*) n=$(printf '%s\n' "$summary" | sed -n 's/.*CHECKS: *\([0-9][0-9]*\).*/\1/p'); total_checks=$((total_checks + n)) ;;
	esac
done

echo "----------------------------------------"
if [ "$fail" -eq 0 ]; then
	echo "CHECK HARNESS: todas as suites passaram ($total_checks checks)"
else
	echo "CHECK HARNESS: $fail suite(s) com falha; logs em .tools/check-logs/"
fi
exit "$fail"
