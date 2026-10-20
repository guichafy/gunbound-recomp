# Paridade Mage/Bigfoot com o OpenBound

Pedido: corrigir escudo, regeneração, SS, dano, queda, colisão e detalhes
esquecidos, comparando com o C# em `Unit/Mage.cs`, `Unit/Bigfoot.cs`,
`Mobile.cs`, `Projectile.cs`, `MageProjectile.cs` e `MobileMetadata.cs`.
REQ-05, REQ-07, REQ-19 e REQ-42. ADR-066.

## Regras que passam a valer

- `Regenerate()` roda em todos os mobiles vivos ou não no início de cada turno.
  Mage soma 20 de escudo por turno de qualquer um, com o atributo Regeneração,
  teto `escudo base + vida máxima − vida atual` medido antes da cura de vida.
- Vida de Mage e Bigfoot não regenera no turno (`HealthRegeneration` 0).
  Proteção cura 35, também com Regeneração, e não devolve escudo.
- SS abre no primeiro turno (`SSLockRemainingTurns` 0). O uso soma 4
  (`SSCooldownTimer + 1`). Cada turno próprio seguinte desce 1. Item continua
  travando o SS naquele turno.
- Dano = `int(base × raio / max(distância ao centro da caixa, 1))` se a
  distância até a caixa for menor que o raio. Ataque e defesa multiplicam só
  essa parcela. O EMP soma o escudo atual quando a distância até a caixa é
  menor que 100; essa soma não entra no multiplicador.
- A constante `ProjectileMageSSBaseDamage` 300 não é a do construtor. O SS
  usa 200 e raio 25.
- Queda curta não tira vida. Sair do chão (vazio ou abaixo do mapa) mata.
  Enquanto cai, o vento empurra no eixo X como `Movement.ApplyGravity`.
- Caixas: Mage 38×33, Bigfoot 46×40, deslocamento (0, 10). Apoio no chão:
  Mage 30, Bigfoot 25. A barra de vida usa vida base + escudo base.
- Sinalizador: Mage 0 s, Bigfoot 0,4 s.
- Bigfoot solta fumaça abaixo de 30% da vida. Poses de segundo dano, choque,
  queda e parede usam os quadros do `MobileFlipbook.cs`.
- Arquétipo de ataque e os cinco números do radar não entram no dano. O C#
  só usa o arquétipo de armadura para o bônus biônico de cura. Mage e Bigfoot
  não são biônicos.

A skill `skills/gunbound-mobile-port/SKILL.md` guarda o roteiro para o
próximo mobile.
