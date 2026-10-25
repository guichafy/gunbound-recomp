---
name: release
description: Fecha uma entrega do Gunbound Recomp — versão, harness completo, export macOS assinado, ZIP, smoke do PCK e atualização de TASKS/HANDOFF.
disable-model-invocation: true
argument-hint: "[nova-versão]"
---

# Entrega do app macOS

Versão pedida: `$ARGUMENTS` (vazio = manter a atual).

Não publique, não faça push e não crie tag/release remota: isso exige pedido separado.

1. **Versão.** A única fonte é `application/config/version` em `project.godot`. Se uma
   nova versão foi informada, atualize só ali e mostre o valor antigo e o novo.
2. **Harness completo.** Rode `./scripts/check.sh` (sem `--quick`: parse + suítes + 29
   partidas). Se algo falhar, pare e relate; não exporte sobre falhas.
3. **Override fora do pacote.** Confirme que `override.cfg` não entra no export
   (`export_presets.cfg` exclude/include) — ele é local e contém caminhos de certificado.
4. **Export.** `python3 scripts/build_macos.py`. O script exporta, renomeia o executável,
   ajusta o Info.plist, assina ad hoc e roda `codesign --verify --deep --strict`.
   Confira e reporte a saída do verify e o ZIP gerado em `builds/`.
5. **Smoke do PCK.** Rode o probe/captura `*_pck*.gd` pertinente em `tests/` contra o pacote
   exportado (ver o comando no HANDOFF da entrega mais recente). Reporte checks/falhas/exit
   e confirme que `override.cfg` não está no ROOT/PCK. Separe erros ambientais (CA,
   editor_settings) de falhas reais, explicitamente.
6. **Documentos.** Atualize `docs/sdd/TASKS.md` e `docs/sdd/HANDOFF.md` com os números
   observados (checks Godot + Python + partidas, PCK n/0, versão do app/ZIP) e as
   pendências/limites (aceite visual, escuta/mouse, capturas não feitas). Se houve decisão
   nova, registre em `DECISIONS.md` sem apagar histórico. Atualize a seção "caminho atual"
   do `AGENTS.md` se o estado mudou.
7. **Resumo.** Versão, resultado do harness, assinatura, PCK, o que ficou sem validar.
   Não commite a menos que o usuário peça.
