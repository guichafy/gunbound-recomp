# Desenvolvimento

## Preparar e verificar

Na raiz do projeto, com o Godot 4.7.2 instalado:

```bash
mkdir -p .tools
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
```

```bash
./scripts/check.sh
```

`check.sh` compila todos os scripts e capturas e roda todas as suítes, incluindo as 29
partidas (13 seeds e os 16 mobiles). `--quick` omite as duas suítes de partidas. Mudanças
em regras de combate exigem os testes de modelos e as partidas completas. Mudanças de
navegação ou input exigem os testes de cena. A skill `check` escolhe as suítes pertinentes
ao diff.

`.godot/`, `.tools/` e `builds/` são locais e ficam fora do Git. Um checkout novo precisa
importar o projeto antes dos testes. Os testes usam um perfil isolado, nunca o real.

## Exportar o aplicativo

```bash
python3 scripts/build_macos.py
```

O template é o `macos.zip` oficial do Godot 4.7.2, em `.tools/macos.zip`. O script exporta,
normaliza o executável para `GunboundRecomp`, assina e gera o ZIP. Rodar o projeto no
editor não atualiza o `.app` já exportado. Confira a assinatura depois de cada exportação.

## Mapa do código

| Onde | O quê |
|---|---|
| `scripts/match.gd` | Turno, dano e resultado. Única autoridade da partida |
| `scripts/game.gd` | Cena: apresenta estado e eventos, sem decidir regra |
| `scripts/mobiles.gd`, `mobile_looks.gd` | Regras por mobile e apresentação por mobile |
| `scripts/classic_ballistics.gd` | Passo balístico do cliente, 20 Hz e ponto fixo 24.8 |
| `scripts/flight_snapshot.gd` | Estado copiado pela previsão da CPU |
| `scripts/*_effect.gd`, `*_combat.gd` | Efeitos e combate próprios das famílias portadas |
| `scripts/lobby_screen.gd`, `menu_screen.gd` | Lobby e sala clássicos |
| `scripts/avatar_shop.gd`, `classic_shop_art.gd` | Avatar Shop sobre os quadros originais |
| `assets/openbound/`, `assets/xfs/` | Assets originais do OpenBound e do cliente |
| `assets/hd/` | Derivados HD e 4×, preservados mesmo quando fora do uso ativo |
| `tests/` | Suítes (`test_*.gd`) e capturas GPU (`capture_*.gd`) |
| `skills/` | Skills de porte do cliente, de mobile e de arte clássica HD |

Uma leitura guiada do código está em [APRENDIZADO.md](APRENDIZADO.md). A arquitetura e os
invariantes estão em [DESIGN.md](sdd/DESIGN.md). A origem da arte está em [ART.md](ART.md).

## Trabalho orientado por especificação

Antes de mudar comportamento, identifique os `REQ-*` afetados em [SPEC.md](sdd/SPEC.md).
Registre decisões em [DECISIONS.md](sdd/DECISIONS.md) e atualize [TASKS.md](sdd/TASKS.md)
e [HANDOFF.md](sdd/HANDOFF.md) ao concluir. A organização completa está em
[sdd/README.md](sdd/README.md).
