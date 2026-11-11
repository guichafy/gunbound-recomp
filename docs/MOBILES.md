# Mobiles

ADR-165 / issue #32: Armor, Bigfoot, Trico, JD, ASate e Ice agora compõem
corpo alfa → luz aditiva nos consumidores comprovados do cliente. Folhas
somente luz entram uma vez. Armas sem luz, EPA, pivôs, suavização4× e regras
continuam preservados. Inventário e limites em
[PROJECTILE_LIGHT_ISSUE_32](sdd/PROJECTILE_LIGHT_ISSUE_32.md).

Os 16 mobiles do cliente estão no elenco jogável desde a 0.19 (ADR-083), com arte original e
a balística comum da 0.20. Esta tabela diz até onde cada um foi portado a partir do cliente.
As classes de evidência estão explicadas em [PORTE.md](PORTE.md).

ADR-159 / issue #26: calendário, pesos/ranges de Miramo, vento/colunas,
Moon/Eclipse e ciclo global do Thor são compartilhados pelos 16 mobiles,
independentemente do adversário. Isso não amplia o estado de fidelidade dos
anexos ou do contato particular de cada tiro listado abaixo. Contrato e
limites em [NATIVE_WEATHER_ISSUE_26](sdd/NATIVE_WEATHER_ISSUE_26.md).

| ID | Mobile | Estado | Registro |
|---|---|---|---|
| 1 | Mage | Revisado pelo cliente: T1/T2/SS, força, climas secundários e partículas em voo. Aguarda aceite | [MAGE_CLIENT_REVIEW](sdd/MAGE_CLIENT_REVIEW.md), [MAGE_SECONDARY_WEATHER](sdd/MAGE_SECONDARY_WEATHER.md), [MAGE_FLIGHT_SPARKS](sdd/MAGE_FLIGHT_SPARKS.md) |
| 2 | Bigfoot | Dispersão pós-quantização, bônus4/6/8, contato455cc0, dano/cratera e anexos revistos pelo cliente (ADR-161). EPA, arte e suavização4× preservados. Hotspot/muzzle e itens offline são pontes declaradas; aceite humano pendente | [BIGFOOT_COMBAT_ISSUE_28](sdd/BIGFOOT_COMBAT_ISSUE_28.md), [BIGFOOT_SMOOTH_4X](sdd/BIGFOOT_SMOOTH_4X.md) |
| 3 | Nak | Arte, dano e voo com dados do cliente. Luz dos tiros T1/T2 aditiva sobre o corpo como no cliente (ADR-154). Falta a revisão completa | [NAK_0_15](sdd/NAK_0_15.md), [SHOTS_NAK_DRAGON_KNIGHT](sdd/SHOTS_NAK_DRAGON_KNIGHT.md) |
| 4 | Armor | T2 com único shell, dois impactos e seis campos×7/10 (ADR-160/issue27). Dano/cratera/itens seguem pontes declaradas; T1/SS preservados | [ARMOR_T2_ISSUE_27](sdd/ARMOR_T2_ISSUE_27.md) |
| 5 | Trico | T2: dois componentes com centro/LUT/fase/raio/contato nativos e idx2 comum; SS sem blast inicial, oito ações2..16 e fim21 (ADR-163/issue30). Dano/cratera/itens/clima particular e muzzle seguem pontes declaradas | [TRICO_SPECIALS_ISSUE_30](sdd/TRICO_SPECIALS_ISSUE_30.md) |
| 6 | Boomer | Curva, S2 temporizado, SS com congelamento e dano/cratera delimitados pelo cliente (ADR-142). Varredura, tornado e orientação (ADR-143), Lightning/Thor (ADR-144), minas e camadas do SS (ADR-145), vento na queda (ADR-146), boca fixa, poses e áudio (ADR-147); registro do apoio, pose ao vento apoiado e aceite visual/sonoro pendentes | [CLASSIC_BALLISTICS_0_20](sdd/CLASSIC_BALLISTICS_0_20.md) |
| 7 | Raon | T1/T2/SS, minas e rastro do T1 portados; sondagem enterrada1px fechada na issue#31/ADR-164. Movimento/agenda/dano das minas ainda têm pontes declaradas | [RAON_CLASSIC_FIX](sdd/RAON_CLASSIC_FIX.md) |
| 8 | Lightning | Revisado pelo cliente: T1/T2/SS, dano, Force e tornado. Aguarda aceite | [LIGHTNING_CLIENT_REVIEW](sdd/LIGHTNING_CLIENT_REVIEW.md) |
| 9 | JD | Cristal de atração no T2 e efeito numérico no SS. Falta a captura GPU | [JD_CLASSIC_FIX](sdd/JD_CLASSIC_FIX.md) |
| 10 | ASate | Guia, Ion e 1/3/6 filhos. Falta a captura GPU | [ASATE_CLASSIC_FIX](sdd/ASATE_CLASSIC_FIX.md) |
| 11 | Ice | T2/SS com campos nativos de vulnerabilidade: T2 terceiro campo+5 até50 antes do escudo; SS quatrocampos+5 até20 em área130. PoseEPA própria, sem expiração dos campos; contato/itens e bases restantes delimitados. ADR-162, issue#29. Aguarda aceite visual humano | [ICE_EFFECTS_ISSUE_29](sdd/ICE_EFFECTS_ISSUE_29.md) |
| 12 | Turtle | T1/T2 com a onda original (T2 aceito). Dano e física dos filhos do SS adaptados | [TURTLE_T2_FIDELITY](sdd/TURTLE_T2_FIDELITY.md), [TURTLE_ANIMATION_FIX](sdd/TURTLE_ANIMATION_FIX.md) |
| 13 | Grub | Revisado pelo cliente: T1 no contato 0x455cc0, T2 (4 corpos)/SS com ricochete, dano repetido do SS, linha type 12, caixa 28×24 e Lua 8%. Sem cura por turno. A boca do tiro segue o muzzle genérico | [GRUB_CLIENT_FIX](sdd/GRUB_CLIENT_FIX.md) |
| 14 | Dragon | Pelo cliente: S1/SS P+10, S2 quatro corpos (θ±1, P±10) em 1/6/11/16, rastro de faíscas `CrashTexture` e cinco filhos do SS no semicírculo de 200 px (ADR-154). Contato comum. Aguarda aceite | [SHOTS_NAK_DRAGON_KNIGHT](sdd/SHOTS_NAK_DRAGON_KNIGHT.md) |
| 15 | Knight | Pelo cliente: guia → Ion → leques convergentes de 3/5 filhos e chuva de 8 no SS, filhos 6144/768 sem gravidade (ADR-154). Altura −400 do Ion e contato comum adaptados. Aguarda aceite | [SHOTS_NAK_DRAGON_KNIGHT](sdd/SHOTS_NAK_DRAGON_KNIGHT.md) |
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
