#!/bin/sh
# PreToolUse: bloqueia Edit/Write em arquivos que o AGENTS.md manda preservar.
file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -n "$file" ] || exit 0
case "$file" in
	*.gd.uid|*.png.import)
		reason="metadados do Godot (.gd.uid/.png.import) devem ser preservados" ;;
	*/override.cfg|override.cfg)
		reason="override.cfg é local (certificados) e não pode ser editado nem exportado" ;;
	/Users/guichafy/Workspaces/Gunbound/*)
		reason="referência C# (OpenBound) é somente leitura sem solicitação explícita" ;;
	*) exit 0 ;;
esac
echo "Bloqueado: $file — $reason. Peça autorização ao usuário se for intencional." >&2
exit 2
