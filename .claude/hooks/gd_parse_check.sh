#!/bin/sh
# PostToolUse: compila o .gd recém-editado com --check-only e devolve o erro
# de parse ao Claude (exit 2). Outros arquivos passam direto.
file=$(jq -r '.tool_input.file_path // empty')
case "$file" in
	*.gd) ;;
	*) exit 0 ;;
esac
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
[ -x "$GODOT" ] || exit 0
[ -f "$file" ] || exit 0
output=$("$GODOT" --headless --path "$CLAUDE_PROJECT_DIR" --check-only --script "$file" 2>&1)
if printf '%s\n' "$output" | grep -Eq 'Parse Error|SCRIPT ERROR|Failed to load script'; then
	echo "Godot --check-only falhou em $file:" >&2
	printf '%s\n' "$output" | grep -EA1 'Parse Error|SCRIPT ERROR' | head -8 >&2
	exit 2
fi
exit 0
