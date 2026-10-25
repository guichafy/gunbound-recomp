#!/bin/sh
# Harness de qualidade: roda todas as suites headless e consolida o resultado.
# Uso: scripts/check.sh [--quick] [suite ...]
#   --quick   omite test_matches e test_classic_matches (partidas completas)
# Sem suites nomeadas, antes roda --check-only em scripts/*.gd e tests/**/*.gd,
# incluindo as capturas GPU que nao entram no harness.
#   suite     roda apenas as suites informadas (nomes sem tests/ nem .gd)
# GODOT=/caminho/do/Godot sobrepoe o binario padrao do macOS.
# SUITE_TIMEOUT=segundos limita cada suite (padrao 900).
set -u

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT" || exit 2

ALL="test_runner test_scene test_lobby_ui test_lobby_art_hd test_classic_buttons_hd test_refinement test_refinement_scene test_bigfoot test_mage test_mage_scene test_bigfoot_attacks test_bigfoot_attacks_scene test_hd_assets test_mobile_animation test_pilot_projectiles test_roster test_map test_weather test_hud test_aiming test_performance test_items test_items_scene test_shop_items_integration test_avatar_catalog test_avatar_profile test_avatar_shop test_avatar_shop_classic test_avatar_shop_parity test_shop_audit test_shop_wide test_shop_xfs test_xfs_catalog test_shop_test_funds test_xfs_equipment test_xfs_hd_migration test_shop_hd test_avatar_art test_avatar_mount test_avatar_hd test_avatar_continuity test_attributes test_gold_rewards test_mobile_parity test_nak test_battle_rules test_classic_mobiles test_original_mobiles test_mage_client_animation test_classic_flight_parity test_classic_ballistics test_boomer test_classic_assets test_turtle_projectiles test_turtle_t2 test_classic_shot_timing test_classic_shot_timing_scene test_xfs_import test_avatar_effect_source test_classic_asset_manifest test_original_mobile_assets test_asate_effect test_jd_effect test_aduka_effect test_aduka_beam_art test_aduka_thor_assets test_raon_effect test_special_mobiles_integration test_raon_native_source test_asate_satellite_audio test_matches test_classic_matches"
# --quick: todas as suites Godot/Python menos as partidas completas.
QUICK=$(printf '%s\n' $ALL | grep -Ev '^(test_matches|test_classic_matches)$' | tr '\n' ' ')

suites=""
quick=0
named=0
for arg in "$@"; do
	if [ "$arg" = "--quick" ]; then
		quick=1
	else
		suites="$suites $arg"
		named=1
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
if [ "$named" -eq 0 ]; then
	parse_fail=0
	for script in scripts/*.gd tests/*.gd tests/*/*.gd; do
		output=$("$GODOT" --headless --path . --check-only --script "$script" 2>&1)
		if printf '%s\n' "$output" | grep -Eq 'Parse Error|SCRIPT ERROR|Failed to load script'; then
			echo "FAIL parse $script"
			printf '%s\n' "$output" | grep -E 'Parse Error|SCRIPT ERROR' | head -3
			parse_fail=$((parse_fail + 1))
		fi
	done
	if [ "$parse_fail" -eq 0 ]; then
		echo "OK   parse -> todos os scripts e capturas compilam"
	fi
	fail=$((fail + parse_fail))
fi
for suite in $suites; do
	script="tests/$suite.gd"
	log=".tools/check-logs/$suite.log"
	python_suite=0
	if [ -f "tests/$suite.py" ]; then
		python_suite=1
		set -- python3 -m unittest discover -s tests -p "$suite.py" -v
	elif [ -f "$script" ]; then
		set -- "$GODOT" --headless --log-file "$ROOT/.tools/check-logs/$suite-engine.log" --path . --script "$script"
	else
		echo "!! $suite: suite .gd ou .py inexistente"
		fail=$((fail + 1))
		continue
	fi
	# Um SCRIPT ERROR deixa o Godot headless aberto em vez de sair: cada suite
	# tem SUITE_TIMEOUT segundos (padrao 900) e depois conta como falha.
	"$@" >"$log" 2>&1 &
	pid=$!
	waited=0
	while kill -0 "$pid" 2>/dev/null && [ "$waited" -lt "${SUITE_TIMEOUT:-900}" ]; do
		sleep 1
		waited=$((waited + 1))
	done
	if kill -0 "$pid" 2>/dev/null; then
		kill "$pid"
		echo "TIMEOUT: ${SUITE_TIMEOUT:-900} s sem terminar" >>"$log"
	fi
	wait "$pid"
	status=$?
	output=$(cat "$log")
	summary=$(printf '%s\n' "$output" | grep -E 'CHECKS:|MATCHES:|^Ran [1-9][0-9]* tests? in ' | tail -1)
	if [ -z "$summary" ]; then
		summary="(sem resumo; ver $log)"
	fi
	if [ "$python_suite" -eq 1 ] && ! printf '%s\n' "$output" | grep -q '^OK$'; then
		status=1
	fi
	if [ "$summary" = "(sem resumo; ver $log)" ] || [ "$status" -ne 0 ] || printf '%s\n' "$output" | grep -Eq 'FAIL:|SCRIPT ERROR:|^ERROR:|^TIMEOUT:'; then
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
