# JEWEL — cristais JD, Lightning SS e gatilho Raon

13/11/2026. Mesmo PE pinado emCONTRACT.md. Ghidra12.2/JDK26, bancoexclusivo
`/tmp/gb-jewel-impl-lifecycle`. q16..q19 têm run/manifest.ok=true. AnáliseASM,
não execuçãoWindows; testesGodot não comprovam trace dinâmico nativo.

## JD

`4644e0` T2 varre atores,64minas e depois8entidadescategoria186a6. O último
laço começa464f80. UsaPOSx/y originais, sem Y−10, distância estrita ao quadrado
do raio base do efeito (`+33c8`): T2=60, SS=68. Não aplica a ampliação de raio
dos atores aos jewels. Campo de inclinação`+af0` é produzido por4785f0 pela
LUTnativa e vale0 durante drop, sem projeção por direção/facing.

T2 só continua com `abs(center.x-jewel.x)>2` (`465193..465219`). Se slope<=80
(global794e48, default80 em40da6e), liga flagwork e acumula emjewel+15ac:
`debt += (100-slope)*2`. Só move comdebt>100. Divide truncadamente por100,
movepara centro e guardaresto. Não copia autoria nem adiciona dano.
O ramo é distinto dos atores, cuja fórmula é200−3*slope.

SS `48f300` tem laçoJewels490140..49074f. Dentro do raio, **antes** do gate de
inclinação (`4904c8..4904df`), escreve dono em`+d14` e somaJD[82]=14 direto no
acumulador`+8c8` (`490361..4903a1`), semAttack/Defense ou fator de mobile.
Emitepopup negativo na posiçãoY−contador*15 (`+aec` incrementa), mas não
chama vtablepose nesse ramo. Depois acumula a mesma fórmula2*(100−slope),
repulsando. Centro.x<jewel.x somaX, caso contrário subtraiX: **igualX vai
para esquerda** (`49056b..4905a6`). Rejeitar por slope81 não impede os14,
mas dano sozinho não liga flagwork. SS e T2 compartilham odebt+15ac do jewel.

APIpura `JewelAux.jd_step(effect,entities)->bool`: aplicaumtick, retorna
flagwork adicional, sem avançar contador/age/TTLdoefeito. O chamador deve
**OR com trabalho dos atores/minas antes de decidir retenção**. A avaliação
nativa do tempo é posterior aoefeito: counters<=18(T2)/<=20(SS), máximo20/22
chamadas quando há trabalho. Não chamar uma vezporator ouporprojétil.
Integração/terreno/scheduler são responsabilidade doMatch, fora destearquivo.

## Lightning SS

`4837e0` tem laços8atores/8Jewels/64minas. Segundo laço chama425c90 em483b0c.
`425c90` procura categoria186a6/slot; testa `(jewel.x-impact.x)^2 +
(jewel.y-impact.y)^2 < radius^2` diretamente (425e1e..425e53). Difere do
helper425ac0de atores que fazY−10. Sem owner/teamfilter noJewels. O laço
seleciona emslots0..7, não ordem de entrada noarray.

Para cadajewel selecionado, usa seuX e varre a primeira superfície desdeY0,
chama436070 para raio vertical,43af40com parâmetroschoqueSS, e431d90com
armaT1(tipo7,weapon0). Não há blastSS primário local nem dano diretoinventado
pelo helper. Doisjewels no mesmoX geram duas chamadas nativas.

API `lightning_targets(entities,impact,radius=120)->Array[Vector2i]` retorna
POSpor slotsem alterar entidades. Integrar usando `ray(model,projectile,pos,0,0)`
existente emLightningCombat, após atores e antes deminas se estas foremportadas.
Os120 vêm dofieldraioSSdo catálogo, parâmetro explícito naAPI.

## Raon minas

Ambos AnimateMine498b60 e AnimateSuperMine4921e0 têm laço de8Jewels após
atores. Proximidade usaPOSmine vsPOSjewel sem offsets dehitbox, distância
estrita emradiusfield8([66]/[79]); chama vtablemine+20 para detonar.
Normal:49940b..4995d6; super:492b46..492cd4. Não há filtro de autor/time/drop
no ramoJewels. Manter os gates devida/estado e settledoMineexistentes antes
do novo teste, sem alterar explosão/composição de dano.

API `mine_touching(entities,mine_position,radius=8)->bool` só lêentidades.
O scheduler pode ORcomdetecção deatores e usar o caminho existente deexplosão.
Minas que ainda estão noestado deespera continuam sob a política do chamador.

## Testes e limites

`tests/test_jewel_aux.gd`: REDpor módulo ausente e depois por função demina
ausente, GREEN24checks0. Cobre raio60/68/120/8 estrito, centrosemY−10, slots,
declive50comresíduo100, 81 bloqueado, −20semfacing, SSdamageantesdogate,
igualXesquerda,22chamadasSS=308/44px, dropminetrigger, remoçãoecópialeitura.
Esperadosnuméricos derivados deASM emaux-fixtures.json; não são oráculoPE
executável. Não modificar Match/Game/JewelRules ou módulos de combate de
outros agentes nestaentrega.
