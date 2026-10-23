extends SceneTree
## Base of the headless suites (scripts/check.sh): counts checks, reports
## failures and prints the "<LABEL> CHECKS: n | FAILURES: m" line the harness reads.

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

## Subclasses implement the scenario here (it may await frames).
func run() -> void:
	pass

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func exit_code() -> int:
	return 0 if failures == 0 else 1

func report(label: String) -> void:
	print(label, ": ", checks, " | FAILURES: ", failures)

## Prints the summary and leaves with 1 on any failure.
func finish(label: String) -> void:
	report(label)
	quit(exit_code())
