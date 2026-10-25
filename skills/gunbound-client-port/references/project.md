# Gunbound Recomp / DemoGame

Resolver caminhos a partir da raiz do checkout, nunca de um usuário fixo.
Ler `docs/sdd/HANDOFF.md`, `SPEC.md`, `DESIGN.md`, `TASKS.md` e decisões
vigentes. O projeto é treino offline 1×1; versão em `project.godot`.

## Preservação e fontes

Preservar IDs: 1 Mage, 2 Bigfoot, 3 Nak, 4 Armor, 5 Trico, 6 Boomer, 7 Raon,
8 Lightning, 9 JD, 10 ASate, 11 Ice, 12 Turtle, 13 Grub, 14 Dragon,
15 Knight, 16 Aduka. Não reintroduzir ID 0. Preservar catálogo, equipamentos,
perfil, avatares e HD aprovados. REA do cliente está autorizada para informar
os portes; modernização visual fica para etapa posterior solicitada.

Reusar `.tools/gunbound-client/` e os caminhos de referência no AGENTS atual;
não pedir novamente ZIP/link já disponível. OpenBound C# fica na pasta
adicional Gunbound, somente leitura. Repositórios jglim são fontes auxiliares
identificadas em reverse-engineering.md.

Consultar `BATTLE_SHOT_MATRIX.md`, `BATTLE_ASSET_MATRIX.md` e
`BATTLE_MOBILE_FAMILY_PLANS.md`. Elenco completo e pesquisa de 48 tiros não
significam especiais, dano, colisão ou tornado integralmente nativos.
Fontes do exemplo: `TURTLE_ANIMATION_FIX.md`/ADR-086 e
`TURTLE_T2_FIDELITY.md`/ADR-087 em docs/sdd. Aceite local não aprova outras famílias.

## Integração (caminhos em scripts/)

| Arquivo | Papel |
|---|---|
| `match.gd` | Regras, turno, dano, resultado e passo real/previsão |
| `classic_ballistics.gd`, `classic_flight.gd`, `turtle_flight.gd`, `boomer_flight.gd` | Aritmética, tick e estado especial |
| `shell_state.gd`, `flight_snapshot.gd`, `cpu_planner.gd` | Fábrica, cópia fechada e busca isolada |
| `classic_shot_timing.gd` | EPA, pose, emissão e grupos de som |
| `game.gd`, `classic_projectile_art.gd`, `battle_art.gd` | Apresentação e interpolação de cópias |
| `mobile_looks.gd`, `mobile_rig.gd`, `avatar_art.gd` | Estilo aprovado, rig e equipamento |
| `gunbound_xfs.py` e importadores | Extração/catálogo; preservar originais/metadados |

Usar muzzle/shot_velocity compartilhados para mira/CPU. Novos campos de regra
entram em ShellState/FlightSnapshot. Worker não lê estado vivo, arquivos ou
recursos. Preservar `.gd.uid`/`.png.import` e assets originais.

## Verificação

Preparar `.tools/` e importar checkout novo. Conferir o contrato atual de
`scripts/check.sh`; `--quick` omite partidas. Combate exige modelos e partidas
completas; navegação/input exige cena. Reusar suites Turtle/Boomer/timing/
ballistics sem copiar seus resultados como oráculo novo. Capturas ficam em
tests/capture_*.gd e docs; perfil de teste é isolado.

Se entregar app, executar `python3 scripts/build_macos.py` conforme handoff,
conferir assinatura e probe isolado do PCK. Mudança documental não exige
reexportar nem citar contagens antigas como testes recém-executados.
