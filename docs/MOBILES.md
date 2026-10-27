# Mobiles

Os 16 mobiles do cliente estão no elenco jogável desde a 0.19 (ADR-083), com arte original e
a balística comum da 0.20. Esta tabela diz até onde cada um foi portado a partir do cliente.
As classes de evidência estão explicadas em [PORTE.md](PORTE.md).

| ID | Mobile | Estado | Registro |
|---|---|---|---|
| 1 | Mage | Revisado pelo cliente: T1/T2/SS, força, climas secundários e partículas em voo. Aguarda aceite | [MAGE_CLIENT_REVIEW](sdd/MAGE_CLIENT_REVIEW.md), [MAGE_SECONDARY_WEATHER](sdd/MAGE_SECONDARY_WEATHER.md), [MAGE_FLIGHT_SPARKS](sdd/MAGE_FLIGHT_SPARKS.md) |
| 2 | Bigfoot | Arte original, suavizada 4×. Ataques herdados (adaptação), com porte parcial de animações na 0.20.4 sem resultados registrados. Falta a revisão de combate pelo cliente | [ORIGINAL_MAGE_BIGFOOT](sdd/ORIGINAL_MAGE_BIGFOOT.md), [BIGFOOT_ATTACKS_0_5](sdd/BIGFOOT_ATTACKS_0_5.md), [BIGFOOT_SMOOTH_4X](sdd/BIGFOOT_SMOOTH_4X.md) |
| 3 | Nak | Arte, dano e voo com dados do cliente. Falta a revisão completa | [NAK_0_15](sdd/NAK_0_15.md) |
| 4 | Armor | Balística comum. Falta o S2 com dois impactos | [BATTLE_MOBILE_FAMILY_PLANS §1](sdd/BATTLE_MOBILE_FAMILY_PLANS.md) |
| 5 | Trico | Balística comum. Falta o S2 de três componentes | [BATTLE_MOBILE_FAMILY_PLANS §1](sdd/BATTLE_MOBILE_FAMILY_PLANS.md) |
| 6 | Boomer | Curva, S2 temporizado e SS com congelamento do cliente (0.20). Falta a revisão completa | [CLASSIC_BALLISTICS_0_20](sdd/CLASSIC_BALLISTICS_0_20.md) |
| 7 | Raon | T1/T2/SS, minas e rastro do T1 portados. Restam detalhes do plantio e do contato das minas | [RAON_CLASSIC_FIX](sdd/RAON_CLASSIC_FIX.md) |
| 8 | Lightning | Revisado pelo cliente: T1/T2/SS, dano, Force e tornado. Aguarda aceite | [LIGHTNING_CLIENT_REVIEW](sdd/LIGHTNING_CLIENT_REVIEW.md) |
| 9 | JD | Cristal de atração no T2 e efeito numérico no SS. Falta a captura GPU | [JD_CLASSIC_FIX](sdd/JD_CLASSIC_FIX.md) |
| 10 | ASate | Guia, Ion e 1/3/6 filhos. Falta a captura GPU | [ASATE_CLASSIC_FIX](sdd/ASATE_CLASSIC_FIX.md) |
| 11 | Ice | Balística comum. Falta o campo do S2/SS | [BATTLE_MOBILE_FAMILY_PLANS §6](sdd/BATTLE_MOBILE_FAMILY_PLANS.md) |
| 12 | Turtle | T1/T2 com a onda original (T2 aceito). Dano e física dos filhos do SS adaptados | [TURTLE_T2_FIDELITY](sdd/TURTLE_T2_FIDELITY.md), [TURTLE_ANIMATION_FIX](sdd/TURTLE_ANIMATION_FIX.md) |
| 13 | Grub | Balística comum. Faltam os ricochetes | [BATTLE_MOBILE_FAMILY_PLANS §5](sdd/BATTLE_MOBILE_FAMILY_PLANS.md) |
| 14 | Dragon | Balística comum. Faltam a cadência do S2 e os filhos do SS | [BATTLE_MOBILE_FAMILY_PLANS §1](sdd/BATTLE_MOBILE_FAMILY_PLANS.md) |
| 15 | Knight | Balística comum. Faltam os satélites do SS | [BATTLE_MOBILE_FAMILY_PLANS §2](sdd/BATTLE_MOBILE_FAMILY_PLANS.md) |
| 16 | Aduka | Revisado pelo cliente: T1/T2/SS, Thor, dano, colisão e tornado. O T2 mostra três criaturas a pedido do usuário. Aguarda aceite | [ADUKA_AUDIT](sdd/ADUKA_AUDIT.md), [ADUKA_COMBAT_REA](sdd/ADUKA_COMBAT_REA.md) |

Os IDs são fixos e não devem mudar. O ID 0 (Escaravelho) foi retirado e não volta.

## Limites comuns

Dano, colisão, apoio e parede comuns, itens e climas fora das partidas com Mage continuam
adaptados nos mobiles que ainda não foram revisados. Nenhum mobile tem paridade integral
alegada. A execução dinâmica do cliente original no Windows ainda não foi feita.

## Portar um mobile

Use a skill [gunbound-client-port](../skills/gunbound-client-port/SKILL.md). Os
pré-requisitos e o aceite de cada família estão em
[BATTLE_MOBILE_FAMILY_PLANS](sdd/BATTLE_MOBILE_FAMILY_PLANS.md).
