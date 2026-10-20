---
name: gunbound-mobile-port
description: Porta um mobile do OpenBound em C# para o Godot deste projeto (escudo, regeneração, SS, dano, caixa, queda, sinalizador e poses). Use ao migrar um mobile, comparar Mage/Bigfoot com o C#, ou quando o pedido citar OpenBound, MobileMetadata, escudo, regeneração ou SS.
---

# Porte de mobile OpenBound para Godot

Leia o C# do mobile e o catálogo em `scripts/mobiles.gd`. Não invente resistências: o dano do C# não usa arquétipo de ataque nem os cinco números do radar. Detalhes e armadilhas em [reference.md](reference.md).

## Checklist

Copie e marque:

```
- [ ] Identidade: ID estável, HP base, escudo base, movimento, mira S1/S2/SS, delays ÷ 7,5
- [ ] BuildMobileMetadata: hp_regen, protection, shield, shield_regen
- [ ] Caixa (largura, altura, offset) e stance (Movement.CollisionOffset)
- [ ] Armas: dano, raio, massa e vento só se diferirem de 14 e 1,2; conferir o construtor, não a constante vizinha
- [ ] SS: trava compartilhada (abre em 0, uso soma 4, turno próprio desce 1)
- [ ] Regenerate em todos os mobiles a cada turno; teto do escudo antes da cura de vida
- [ ] Dano inverso e gate pela caixa; EMP soma o escudo atual depois de ataque/defesa
- [ ] Queda curta sem dano; vazio mata; vento empurra no ar
- [ ] TeleportationBeaconInteractionTime no spawn do sinalizador
- [ ] Poses do MobileFlipbook e fumaça só se o C# cria smokeParticleEmitter
- [ ] Bionic: +3% no Energy Up e regen de vida/proteção próprios
- [ ] Teste de modelo com o número do C#, mais a suíte de combate
```

## Onde entra no projeto

- Dados do mobile: `scripts/mobiles.gd` (ou um arquivo irmão, como `bigfoot_attacks.gd`).
- Dano e caixa: `scripts/combat.gd` e `scripts/damage.gd`. Não duplique a fórmula no mobile.
- Turno, SS, queda e sinalizador: `scripts/match.gd` já chama o catálogo. Um campo novo de voo também entra em `flight_snapshot.gd`.
- Quadros: o sprite do mobile. O rig HD só anima; o índice do atlas continua vindo do flipbook.

## Validação

Rode `./scripts/check.sh test_mobile_parity test_mage test_bigfoot_attacks`. Mudança de dano ou colisão também pede `test_runner`, `test_items`, `test_attributes` e as partidas de `test_matches`.
