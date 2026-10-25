---
name: check
description: Escolhe e roda as suítes do harness (scripts/check.sh) pertinentes ao diff atual, seguindo as regras de validação do AGENTS.md. Use antes de concluir uma mudança ou quando o usuário pedir para validar/testar.
argument-hint: "[--full | --quick | suite ...]"
---

# Validação do Gunbound Recomp

Argumentos: `$ARGUMENTS`

- `--full`: rode `./scripts/check.sh` (parse + todas as suítes + 29 partidas). Pule a seleção.
- `--quick`: rode `./scripts/check.sh --quick`. Pule a seleção.
- Nomes de suíte: rode `./scripts/check.sh <suítes>` exatamente como informado.
- Sem argumentos: selecione pelo diff, como abaixo.

## Seleção pelo diff

1. Liste as mudanças: `git status --short` e `git diff --name-only HEAD`.
2. Mapeie para suítes (nomes em `ALL` de `scripts/check.sh`; confira que existem):
   - Regras de combate (`match.gd`, `damage.gd`, `turn_table.gd`, `mobiles.gd`,
     `classic_ballistics.gd`, `*_flight.gd`, `cpu_planner.gd`, `items.gd`,
     `item_effects.gd`, `weather*.gd`): **obrigatório** testes de modelo
     (`test_runner`, `test_battle_rules`, suítes do mobile/sistema tocado) **e**
     partidas completas `test_matches test_classic_matches`.
   - Navegação/input/cena (`game.gd`, `menu_screen.gd`, `lobby_screen.gd`,
     `aim_control.gd`, `camera_rig.gd`, `item_bar.gd`, `*_popup.gd`, `avatar_shop.gd`):
     **obrigatório** testes de cena (`test_scene`, `test_items_scene`, `test_roster`,
     e `*_scene`/`test_shop_*` correspondentes).
   - Arte/animação de um mobile: a suíte do mobile (`test_<mobile>`, `test_classic_mobiles`,
     `test_original_mobiles`, `test_mobile_animation`).
   - Para o resto, procure em `tests/` (`grep -l <script_alterado> tests/*.gd`) as suítes que
     carregam o arquivo alterado.
   - Mudanças só em `docs/`: não rode nada; diga isso.
3. Diga ao usuário quais suítes vai rodar e por quê (uma linha por grupo), depois rode
   `./scripts/check.sh <suítes>`. Partidas completas são longas: rode em background se
   houver outro trabalho a fazer.
4. Se `.tools/` não estiver preparado ou o projeto não estiver importado, avise (ver HANDOFF).

## Relato

- Copie a linha final do harness e o total de checks (formato do HANDOFF:
  "N checks Godot + M Python + P partidas").
- Para cada FAIL, mostre o trecho relevante de `.tools/check-logs/<suite>.log`.
- Diga explicitamente o que **não** foi rodado (ex.: partidas omitidas, capturas GPU,
  validação visual/escuta) — não alegue validação completa sem `--full`.
