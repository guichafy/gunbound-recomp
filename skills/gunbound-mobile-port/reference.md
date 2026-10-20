# Referência do porte

Fontes: `MobileMetadata.BuildMobileMetadata`, `Mobile.Regenerate`, `Projectile.CalculateDamage`, `MageProjectile3`, `Movement.ApplyGravity`, `MobileFlipbook` e a classe do mobile.

## Campos do catálogo

| C# | Chave em `mobiles.gd` |
|---|---|
| `baseHealth` | `hp` |
| `baseShield` / `ShieldRegeneration` | `shield` / `shield_regen` |
| `HealthRegeneration` | `hp_regen` (0 em aço e escudo; 10 nos biônicos) |
| `HealthRegenerationProtection` | `protection` (35 ou 70) |
| `CollisionBox` retângulo e offset | `box`, `box_offset` |
| `Movement.CollisionOffset` | `stance` (altura do apoio) |
| `Movement.MaximumStepsPerTurn` | `move` |
| `TeleportationBeaconInteractionTime` | `beacon_delay` |
| `MobileArmorArchetype.Bionic` | `bionic` |
| `smokeParticleEmitter` no construtor | `smoke` |
| `AimPresets` / `DelayPresets` | `aim_limits` / `delay` da arma ÷ 7,5 |

`GetDelay` devolve só o atraso do tiro (S1, S2 ou SS), não a soma com `Base`.

## Regeneração

No C#, todo mobile recebe `Regenerate()` quando um turno é concedido, não só quem joga.

```
vida = min(vida + int((1 + Regeneração/100) * hp_regen), vida_máxima)
teto = escudo_base + vida_máxima - vida_antes_desta_cura
escudo = min(escudo + int((1 + Regeneração/100) * shield_regen), teto)
```

Proteção chama `Regenerate(true)`: usa `protection` no lugar de `hp_regen` e soma 0 de escudo, mas ainda aplica o teto. A barra desenha `vida_base + escudo_base`, não o teto dinâmico.

## Dano

Gate: distância do impacto até a caixa `< raio`. O parâmetro `radius` de `GetDistance` não é subtraído; a função devolve a distância até o retângulo.

```
dano = int(base * raio / max(distância_ao_centro, 1))
dano = int(dano * (1 + (ataque - defesa) / 100))
```

O piso de 1 px evita a divisão por zero do C# quando o impacto coincide com o centro. Perto do centro o dano passa da base. Isso é o comportamento da fonte.

EMP do Mage (`MageProjectile3`): se a distância até a caixa é `< 100`, o dano é o cálculo acima (0 fora do raio 25) mais o escudo atual. O escudo somado não passa por ataque/defesa. O construtor usa dano 200 e raio 25. A constante `ProjectileMageSSBaseDamage` 300 não é usada.

## SS

`SSLockRemainingTurns` nasce 0, então o primeiro turno já atira. O uso soma `SSCooldownTimer + 1` (4). `ReduceSSCooldown` roda no `GrantTurn` daquele mobile e não desce abaixo de 0. Um item chama `DisableSS` naquele turno.

## Queda e sinalizador

Queda com chão embaixo não tira vida nem escudo. Fora do mapa é morte (`CausaMortis.Bungee`). No ar, `wind / 45` acumula até mover 1 px em X.

O sinalizador usa `TeleportationBeaconInteractionTime` como `SpawnTime`. Mage 0, Bigfoot 0,4 s.

## O que não portar como regra de dano

Os números Attack/Defence/Delay/Energy/Mobility e os arquétipos Laser/Fire/Hit só alimentam o radar da seleção. `CalculateDamage` usa ataque e defesa do jogador, não do mobile. Não crie uma tabela de resistências que o C# não aplica.

`Mobile.Heal` soma a cura sem teto e pode passar da vida máxima. Este projeto limita à vida máxima. Mantenha o limite.

Mage e Bigfoot compartilham massa 14 e influência de vento 1,2. A balística absoluta do protótipo (gravidade 260, vento × 1,3) continua a adaptação comum; não a reescreva ao adicionar um mobile, a menos que a massa ou o vento daquele tiro sejam outros.

## Mobile ausente no fork

Se o C# não tiver a classe/folha (caso do Nak), use o cliente original Thor's
Hammer em `.tools/gunbound-client/` lido por `scripts/gunbound_xfs.py`
(`tankN.img/.epa`, `bulletN*`, `flameN*`, `characterdata.dat`; índice = tipo + 1)
e as notas do GunBound-Decomp. Exemplo completo: `scripts/import_nak_assets.py`
e `docs/sdd/NAK_0_15.md`. Na dúvida sobre essa fonte, pergunte ao usuário.
