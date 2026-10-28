# Matriz dos 48 tiros — pesquisa estática de 24/10/2026

REQ-44/45. Pesquisa da tarefa8; não é alegação de paridade implementada. Nenhum algoritmo novo foi implementado. A identidade vigente é type13 Dragon, type14 Knight, type15 Aduka; nomes antigos do decomp não definem identidade. IDs Godot preservados.

## Fontes e precisão

Binário original somente lido: `GunBound.gme`, SHA-256 `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`. `characterdata.dat` local foi descompactado novamente e suas 16×83 células coincidem com o JSON recuperado. Evidência nova: `.tools/battle-execution/shots-research/` (manifesto, 135 extratos ASM do binário, fontes auxiliares decomp, dados e slots JSON). Decomp fixado em `colemancda/GunBound-Decomp@c23ec4fa03ab3ad0318c4514ab2b9083a4dbf636`, usado como índice; nomes de Shot1/Shot2 não substituem `(type,kind,idx)`.

A = despacho/quantidade/slots/dados demonstrados estaticamente e comportamento sem lacuna relevante nesta linha; B = despacho/quantidade/slots/dados demonstrados, com fórmula/ciclo especial ainda parcial. Confiança B não autoriza copiar literalmente um raw port Ghidra: há argumentos/registradores descartados. Não houve execução do cliente nem validação dinâmica contra ele.

`SpawnPrimaryShot`=0x42bbb0 (S1/S2), `SpawnSuperShot`=0x42de70 (SS). `@n` é quadro da animação MainAction, NÃO milissegundo ou tick de física. `count` é metadado +0x3f94; só chamadores/loops estabelecem número de emissões. Os 16 MainAction e seus endereços estão abaixo.

`P/R/F; X/Y` registra os campos brutos [poder, raio, fator da cratera; extraA, extraB] da arma: S1[44..56], S2[57..69], SS[70..82]. As três variantes de poder/raio/fator são iguais nestes dados. P não é dano final garantido: bônus, resistência, distância, estágios e filhos entram depois. R não deve ser confundido com o raio circular em pixels do Godot; a rotina original de dano usa R/2+10 em seu gate. Zero é dado de estágio, nunca prova de ausência de dano na cadeia.

Todos os tiros partem da física original escolhida na ADR-084; `g=[40]` por type, vento ax/ay comum dos spawners. Exceções de voo/objetos e filhos têm de preservar os estados próprios. Nenhum fator C# de vento deve ser inserido nesta matriz como se fosse original.

## MainAction e chamadores

| Type / ID / mobile | MainAction | Chamadas diretas ao spawn (VA; S1/S2/SS conforme eventos5/6/10) |
|---|---|---|
| 0 / 4 / Armor | 0x44e920 | 0x44eac5, 0x44ec23, 0x44eed2 |
| 1 / 1 / Mage | 0x488ac0 | 0x488c60, 0x488dce, 0x488edd, 0x48918d |
| 2 / 3 / Nak | 0x48d1f0 | 0x48d395, 0x48d4f3, 0x48d7a2 |
| 3 / 5 / Trico | 0x4b31f0 | 0x4b3390, 0x4b34fe, 0x4b3619, 0x4b372b, 0x4b39db |
| 4 / 2 / Bigfoot | 0x489580 | 0x489769, 0x489907, 0x489a9c, 0x489c31, 0x489dbb, 0x489f1d, 0x48a0a1, 0x48a2a6, 0x48a419, 0x48a59a, 0x48a86b, 0x48a9d6, 0x48ab38, 0x48ac9a, 0x48ae14, 0x48af8e, 0x48b0f0, 0x48b252 |
| 5 / 6 / Boomer | 0x4542a0 | 0x454447, 0x4545b4, 0x45470e, 0x454868, 0x4549c5, 0x454c76 |
| 6 / 7 / Raon | 0x49c120 | 0x49c2dc, 0x49c3fc, 0x49c50d, 0x49c6ab, 0x49c7fc, 0x49caf6 |
| 7 / 8 / Lightning | 0x484ff0 | 0x485195, 0x4852f3, 0x4855a2 |
| 8 / 9 / JD | 0x466890 | 0x466a30, 0x466bb3, 0x466e6f |
| 9 / 10 / ASate | 0x47f2d0 | 0x47f475, 0x47f5d3, 0x47f8a9 |
| 10 / 11 / Ice | 0x475e40 | 0x475fe5, 0x476143, 0x4763f2 |
| 11 / 12 / Turtle | 0x4aed30 | 0x4aeed0, 0x4af03e, 0x4af14d, 0x4af3ff |
| 12 / 13 / Grub | 0x471fd0 | 0x472195, 0x472367, 0x4724af, 0x47260f, 0x472788, 0x472903, 0x472a4b, 0x472bab, 0x472d27, 0x473021 |
| 13 / 14 / Dragon | 0x46d070 | 0x46d23e, 0x46d40d, 0x46d5d8, 0x46d7a3, 0x46d971, 0x46db1c |
| 14 / 15 / Knight | 0x47ab90 | 0x47ad35, 0x47ae93, 0x47b011 |
| 15 / 16 / Aduka | 0x466fd0 | 0x467175, 0x4672e1, 0x467491, 0x467702, 0x467886, 0x467979 |

## Matriz

Cada chave da coluna Classe resolve os endereços `Animate/Simulate/tick/Explode` na tabela seguinte. MainAction acima + spawner comum + classe abaixo formam a cadeia rastreável de cada uma das 48 linhas. Trico S2 usa também Projectile para idx2; Raon S1 usa Projectile para idx0.

| Type / mobile | Arma | Emissões iniciais / tempo | Classe | P/R/F; X/Y; g | Filhos / regra / pendência | Conf. |
|---|---|---|---|---|---|---|---|
| 0 Armor | S1 | 1 @2 | Projectile | 210/68/144; 0/0; 98 | Dano/cratera comuns. | A |
| 0 Armor | S2 | 1 @14; 2 impactos | Shot2_Bullet1 | 236/56/134; 0/0; 98 | Mesmo objeto atravessa a primeira cratera; flag +0x3f9c, 2º impacto encerra. Poder/raio ×7/10 após 1º. | A |
| 0 Armor | SS | 1 @14 | SuperShot_Bullet1 | 280/70/134; 200/120; 98 | Transformação e aumento de poder/raio; fechar estado/animação antes de alterar. | B |
| 1 Mage | S1 | 1 @1 | MageS1 | 200/66/143; 0/0; 90 | Rastro helicoidal visual; algoritmo de dano existente. | B |
| 1 Mage | S2 | 2 @1 | Shot2_Bullet2 | 186/54/134; 0/0; 90 | Par de lasers com fase 0/180; validar geom. contra original. | B |
| 1 Mage | SS | 1 @1 | SuperShot_Bullet2 | 380/60/130; 150/0; 90 | EMP: ExplodeSuperShot_Bullet2; efeito de escudo exige cadeia própria. | B |
| 2 Nak | S1 | 1 @1 | Projectile | 200/60/144; 0/0; 98 | Balístico comum. | B |
| 2 Nak | S2 | 1 @1 | Shot2_Bullet3 | 350/70/134; 0/0; 98 | Burrow: SimulateShot2_Bullet3/tick próprio; atravessa terreno até saída. | B |
| 2 Nak | SS | 1 @1 | SuperShot_Bullet3 | 360/70/100; 0/0; 98 | Ghost: ignora terreno; collide mobile; Explode próprio. | B |
| 3 Trico | S1 | 1 @12 | Projectile | 200/70/144; 0/0; 98 | Balístico comum. | A |
| 3 Trico | S2 | 3 @6 | PrimaryShot_Bullet4 | 150/48/134; 0/0; 98 | idx0/1 orbitam; idx2 é Projectile comum. Não tratar os três como iguais. | B |
| 3 Trico | SS | 1 @6 | SuperShot_Bullet4 | 256/120/120; 76/0; 98 | Tick próprio e Explode próprio; detalhes numéricos pendentes. | B |
| 4 Bigfoot | S1 | 4 @3,7,12,17 | Projectile | 86/52/134; 0/0; 98 | Rajada de quatro por quadro de animação. | A |
| 4 Bigfoot | S2 | 6 @6,10 (3+3) | Projectile | 70/40/124; 0/0; 98 | Duas rajadas de três. | A |
| 4 Bigfoot | SS | 8 @3,5,7,9,12,15,17,19 | BigfootSS | 92/48/126; 0/0; 98 | Oito chamadas SS reais, não dedução de count. | A |
| 5 Boomer | S1 | 1 @8 | Boomer | 254/48/124; 50/0; 98 | Curva conforme sinal de ax versus vx; k=[53]=50. | A |
| 5 Boomer | S2 | 4 @8,10,12,14 | Boomer | 118/42/114; 0/0; 98 | Mesma curva; quatro emissões temporizadas. | A |
| 5 Boomer | SS | 1 @8 | SuperShot_Bullet6 | 350/46/120; 200/120; 98 | Curva; contador 36 ticks → change → cnormal; poder×2 e raio×1,2. | A |
| 6 Raon | S1 | 3 @11 | Shot2_Bullet7 | 90/54/130; 0/0; 98 | idx0 comum; idx2/3 oscilam com fase 0/180 (ADR-116). | A |
| 6 Raon | S2 | 2 @11 | Shot1_Bullet7 | 200/42/122; 90/26; 98 | 2 minas no impacto: SpawnMine 0x4375f0. Força P+15/P−15 no mesmo ângulo; bala só colide com terreno (ADR-116). | B |
| 6 Raon | SS | 1 @11 | SuperShot_Bullet7 | 400/42/130; 90/26; 98 | 1 supermina: SpawnSuperMine 0x437870; força P+15, só terreno, direção vx>0 (ADR-116). | B |
| 7 Lightning | S1 | 1 @1 | Shot1_Bullet8 | 230/54/134; 56/20; 90 | Feixe de colisão próprio após impacto; não reduzir ao sprite. | B |
| 7 Lightning | S2 | 1 @1 | Shot2_Bullet8 | 240/40/143; 56/20; 90 | Feixes diagonais: consultar simulador e tick, não count de spawn. | B |
| 7 Lightning | SS | 1 @1 | SuperShot_Bullet8 | 230/40/143; 26/20; 90 | ExplodeSuperShot_Bullet8; composição/varredura a fechar. | B |
| 8 JD | S1 | 1 @1 | Shot1_Bullet9_16 | 180/64/144; 45/15; 98 | Dano/cratera e efeito no impacto; classe compartilhada com Aduka S1. | B |
| 8 JD | S2 | 1 @1 | Shot2_Bullet9 | 240/54/124; 60/0; 98 | Dano inicial + SpawnCrystalShot 0x437b40; atração em Animate 0x465470→0x4644e0. | B |
| 8 JD | SS | 1 @1 | SuperShot_Bullet9 | 0/30/124; 68/14; 98 | Poder base zero; SpawnSuperCrystalShot 0x437d90→Animate 0x490780→0x48f300; efeitos numéricos/movimento próprios. | B |
| 9 ASate | S1 | 1 guia @1 | PrimaryShot_Bullet10 | 190/54/144; 0/0; 98 | Guia aciona Ion; Ion emite 1 filho SpawnShot_Type9 0x42f4b0. | B |
| 9 ASate | S2 | 1 guia @1 | PrimaryShot_Bullet10 | 160/46/134; 0/0; 98 | Guia aciona Ion; 3 filhos em frames1/3/5, ângulo central±1. | B |
| 9 ASate | SS | 1 guia @1 | SuperShot_Bullet10 | 140/44/134; 0/0; 98 | Guia aciona Ion SS; laço observado 1..3 em 2 passagens =6 filhos. Count=8 não prova oito. | B |
| 10 Ice | S1 | 1 @13 | Projectile | 220/66/144; 0/0; 98 | Balístico comum. | A |
| 10 Ice | S2 | 1 @4 | Shot2_Bullet11 | 310/56/124; 0/0; 98 | Tick/Simulate próprios; campo de redução não pode ser descartado. | B |
| 10 Ice | SS | 1 @8 | SuperShot_Bullet11 | 350/60/124; 130/0; 98 | ExplodeSuperShot_Bullet11; campo/status não é dano comum apenas. | B |
| 11 Turtle | S1 | 1 @6 | Shot1_Bullet12 | 230/56/134; 0/0; 98 | Ribbon/Animate próprio; não escolher só a bala base por hash. | B |
| 11 Turtle | S2 | 2 @6 | Shot2_Bullet12 | 224/46/114; 0/0; 98 | Dois componentes fase0/180; tick próprio. | B |
| 11 Turtle | SS | 1 @6 | SuperShot_Bullet12 | 300/46/120; 70/60; 98 | Contador44→change; depois FUN0x432850(...,6) cria6 filhos e termina o pai. Geometria/dano dos filhos pendentes. | B |
| 12 Grub | S1 | 1 @2 | Projectile | 190/50/144; 0/0; 98 | Balístico comum. | A |
| 12 Grub | S2 | 4 @2 em cada ramo angular | Shot2_Bullet13 | 94/38/120; 0/1800; 98 | Ricochete; contador44 e normalização de velocidade. Limites de energia/contato pendentes. | B |
| 12 Grub | SS | 1 @2 | SuperShot_Bullet13 | 26/36/100; 0/1600; 98 | Colisão SimulateSuperShot_Bullet13 não consulta mobiles. Contador40 após contato; ricochetes/dano repetido pendentes. | B |
| 13 Dragon | S1 | 1 @4 | PrimaryShot_Bullet14 | 290/58/136; 0/0; 90 | Simulate próprio solta faíscas; tick balístico comum. | B |
| 13 Dragon | S2 | 4 @1,6,11,16 | PrimaryShot_Bullet14 | 200/54/130; 0/0; 90 | 4 emissões nos frames1/6/11/16; mesmo simulador de faíscas. | B |
| 13 Dragon | SS | 1 @4 | SuperShot_Bullet14 | 160/54/130; 30/200; 90 | Explode0x46ca60 emite 5 filhos; θ=(45−[81])×2+i×[81], força[82]. | B |
| 14 Knight | S1 | 1 guia @1 | PrimaryShot_Bullet15 | 136/48/110; 0/0; 98 | Guia aciona KnightIon; frame2 emite 3 filhos ângulos central,±4. | B |
| 14 Knight | S2 | 1 guia @7 | PrimaryShot_Bullet15 | 128/40/120; 0/0; 98 | Guia aciona KnightIon; frame2 emite 5 filhos central,±2,±4. | B |
| 14 Knight | SS | 1 guia @1 | SuperShot_Bullet15 | 126/40/120; 0/0; 98 | Guia aciona KnightIon SS; laço i<8 emite 8 filhos com parâmetro i×2. | B |
| 15 Aduka | S1 | 1 @1 | Shot1_Bullet9_16 | 152/64/120; 40/20; 94 | Classe compartilhada com JD S1; dano base não nulo. | B |
| 15 Aduka | S2 | 2 @2,6 | Shot2_Bullet16 | 0/0/0; 0/0; 94 | Cada impacto chama FUN0x4398e0(...,1), forçando Thor fora do gate de clima; feixe/blast com dados próprios. | B |
| 15 Aduka | SS | 3 @2,6,10 | SuperShot_Bullet16 | 0/0/0; 0/0; 94 | 3 impactos; Explode0x4685b0 chama FUN0x4398e0(...,1); dano de Thor independente de poder base zero. | B |

## Slots originais por classe

`tick` é o slot6 chamado Detonate no decomp; não equivale a Explode. `Animate` pode implementar toda a regra e nunca chamar o tick comum (cristais, satélites). `—` significa classe sem slot8, não ausência de efeito.

| Classe | Vtable | Animate (slot2) | Simulate (slot5) | tick/Detonate (slot6) | Explode (slot8) |
|---|---|---|---|---|---|
| ASateChild | 0x556468 | 0x49cc70 | 0x455cc0 | 0x49d270 | — |
| ASateIon | 0x556110 | 0x480310 | 0x455cc0 | 0x4572b0 | — |
| BigfootSS | 0x55631c | 0x48f1c0 | 0x455cc0 | 0x48e1d0 | 0x48de60 |
| Boomer | 0x555bd0 | 0x452bf0 | 0x455cc0 | 0x4513b0 | — |
| Crystal | 0x555cf4 | 0x465470 | 0x455cc0 | 0x4572b0 | — |
| KnightChild | 0x556008 | 0x47ab00 | 0x455cc0 | 0x4572b0 | — |
| KnightIon | 0x556078 | 0x47ca40 | 0x455cc0 | 0x4572b0 | — |
| MageS1 | 0x5560d0 | 0x47ebc0 | 0x455cc0 | 0x4572b0 | — |
| PrimaryShot_Bullet10 | 0x556160 | 0x48f1c0 | 0x455cc0 | 0x481320 | — |
| PrimaryShot_Bullet14 | 0x555ea8 | 0x48f1c0 | 0x46fb20 | 0x4572b0 | — |
| PrimaryShot_Bullet15 | 0x556058 | 0x48f1c0 | 0x455cc0 | 0x47b2f0 | — |
| PrimaryShot_Bullet4 | 0x5564d0 | 0x4a4610 | 0x455cc0 | 0x4a2ce0 | — |
| Projectile | 0x555c34 | 0x48f1c0 | 0x455cc0 | 0x4572b0 | — |
| Shot1_Bullet12 | 0x556680 | 0x4b2aa0 | 0x455cc0 | 0x4b1810 | — |
| Shot1_Bullet7 | 0x555aa4 | 0x48f1c0 | 0x49aeb0 | 0x44c950 | — |
| Shot1_Bullet8 | 0x5561a8 | 0x48f1c0 | 0x4a7050 | 0x482550 | — |
| Shot1_Bullet9_16 | 0x555e88 | 0x48f1c0 | 0x455cc0 | 0x46e5a0 | — |
| Shot2_Bullet1 | 0x555dac | 0x48f1c0 | 0x455cc0 | 0x4688b0 | — |
| Shot2_Bullet11 | 0x555f38 | 0x48f1c0 | 0x4731b0 | 0x474650 | — |
| Shot2_Bullet12 | 0x556660 | 0x4b1050 | 0x455cc0 | 0x4af7a0 | — |
| Shot2_Bullet13 | 0x55649c | 0x4a1690 | 0x49e650 | 0x49fd40 | — |
| Shot2_Bullet16 | 0x5565ac | 0x48f1c0 | 0x455cc0 | 0x4aafd0 | — |
| Shot2_Bullet2 | 0x5564f0 | 0x4a6200 | 0x455cc0 | 0x4a4950 | — |
| Shot2_Bullet3 | 0x5563a8 | 0x48f1c0 | 0x493390 | 0x494910 | — |
| Shot2_Bullet7 | 0x5563d0 | 0x497730 | 0x455cc0 | 0x495e80 | — |
| Shot2_Bullet8 | 0x556524 | 0x48f1c0 | 0x4a7050 | 0x4a8360 | — |
| Shot2_Bullet9 | 0x555d14 | 0x48f1c0 | 0x49aeb0 | 0x465500 | — |
| SuperCrystal | 0x556340 | 0x490780 | 0x455cc0 | 0x4572b0 | — |
| SuperShot_Bullet1 | 0x555ac4 | 0x48f1c0 | 0x455cc0 | 0x44d9b0 | 0x48de60 |
| SuperShot_Bullet10 | 0x555b18 | 0x48f1c0 | 0x455cc0 | 0x44f050 | 0x44fc90 |
| SuperShot_Bullet11 | 0x555f58 | 0x48f1c0 | 0x455cc0 | 0x483ff0 | 0x4759b0 |
| SuperShot_Bullet12 | 0x55661c | 0x48f1c0 | 0x455cc0 | 0x4ae3a0 | 0x48de60 |
| SuperShot_Bullet13 | 0x55620c | 0x488780 | 0x4857f0 | 0x486ea0 | 0x48de60 |
| SuperShot_Bullet14 | 0x555e30 | 0x48f1c0 | 0x455cc0 | 0x48e1d0 | 0x46ca60 |
| SuperShot_Bullet15 | 0x556098 | 0x48f1c0 | 0x455cc0 | 0x47de50 | 0x48de60 |
| SuperShot_Bullet16 | 0x555d74 | 0x48f1c0 | 0x455cc0 | 0x467a70 | 0x4685b0 |
| SuperShot_Bullet2 | 0x5562c8 | 0x48f1c0 | 0x455cc0 | 0x483ff0 | 0x48d8e0 |
| SuperShot_Bullet3 | 0x556284 | 0x48d110 | 0x48b7f0 | 0x48e1d0 | 0x48b420 |
| SuperShot_Bullet4 | 0x5565f8 | 0x4ae0f0 | 0x455cc0 | 0x4ad3b0 | 0x4ad230 |
| SuperShot_Bullet6 | 0x555bf0 | 0x453f30 | 0x455cc0 | 0x452cc0 | 0x48de60 |
| SuperShot_Bullet7 | 0x556424 | 0x48f1c0 | 0x49aeb0 | 0x499ef0 | 0x49c050 |
| SuperShot_Bullet8 | 0x5561c8 | 0x48f1c0 | 0x455cc0 | 0x483ff0 | 0x4837e0 |
| SuperShot_Bullet9 | 0x556360 | 0x48f1c0 | 0x49aeb0 | 0x490820 | 0x491b10 |
| ThorRay | 0x55658c | 0x4aacb0 | 0x455cc0 | 0x4572b0 | — |

## Arte e áudio rastreáveis

Sons conferidos nas tabelas PE 0x56d1d0/0x56d210/0x56d250 (fire) e 0x56d290/0x56d310 (blast). Strings abaixo omitem somente o sufixo `.xes`. Arte: o spawn primário consulta `bullet{type+1}n/s`; SS consulta `bullet{type+1}p`. Mage e Turtle têm ribbons em Animate e Dragon primário usa emissor de faíscas no Simulate: a textura isolada não é a composição completa. Impactos usam `flame{type+1}_{1/2/3}`; spawners de filhos também definem arte/impacto próprios. Os quadros extraídos estão no inventário recuperado `arte-audio/tank_epa.json` e `fire_frames_decomp.json`; conversão a segundos só após confirmar relógio EPA.

| Type / mobile | Fire S1 / S2 / SS | Blast S1 / S2 / SS |
|---|---|---|
| 0 Armor | 11fire / 12fire / 12fire | 11blast / 12blast / 12blast |
| 1 Mage | 21fire / 21fire / 21fire | 22blast / 22blast / 22blast |
| 2 Nak | 31fire / 32fire / 32fire | 31blast / 32blast / 31blast |
| 3 Trico | 42fire / 42fire / 42fire | 42blast / 42blast / 42blast |
| 4 Bigfoot | 51fire / 52fire / 51fire | 51blast / 52blast / 51blast |
| 5 Boomer | 62fire / 62fire / 62fire | 62blast / 62blast / 62blast |
| 6 Raon | 71fire / 72fire / 72fire | 71blast / 72blast / 72blast |
| 7 Lightning | 82fire / 82fire / 82fire | 82blast / 82blast / 82blast |
| 8 JD | 91fire / 91fire / 91fire | 91blast / 92blast / 92blast |
| 9 ASate | 102fire / 102fire / 102fire | 101blast / 101blast / 101blast |
| 10 Ice | 111fire / 111fire / 111fire | 111blast / 112blast / 112blast |
| 11 Turtle | 121fire / 121fire / 121fire | 121blast / 121blast / 121blast |
| 12 Grub | 131fire / 131fire / 131fire | 132blast / 132blast / 11blast |
| 13 Dragon | 141fire / 141fire / 141fire | 142blast / 142blast / 142blast |
| 14 Knight | 151fire / 151fire / 151fire | 151blast / 151blast / 151blast |
| 15 Aduka | 161fire / 162fire / 162fire | 91blast / 22blast / 23blast |

## Conclusões e limites que mudam o plano

### Armor S2 e Raon S1

Armor S2: MainAction0x44e920 evento6/frame14 faz uma única chamada em 0x44ec23; count=2. Slot6 0x4688b0: primeira colisão aplica cratera/dano, conserva objeto, reduz os seis campos poder/raio por 7/10 e marca +0x3f9c; segunda colisão termina. Isso concorda estruturalmente com C# `Armor.cs:38–45` (um ArmorProjectile2) e `ArmorProjectile.cs` (`primaryExplosion`). Retira-se a inferência antiga de dois projéteis.

Raon S1: MainAction0x49c120/frame11 faz três chamadas reais em 0x49c2dc/0x49c3fc/0x49c50d. O spawner deixa idx0 comum e idx1/2 com classe de oscilação. C# `RaonLauncherProjectile.cs:33–38` cria quatro: conflito real, original prevalece; corrigir para três somente em tarefa própria com testes.

### ASate e Knight: tiro guia versus dano

ASate: guia PrimaryBullet10 0x481320 / SS0x44f050 acompanha objeto classe0x186a5 (Ion); ao colidir chama 0x47fad0 ou 0x47fee0. `SpawnLaserIon`0x437f70 instala vtable0x556110. `Animate`0x480310 move Ion e, conforme estado1/2/SS, emite 1 / 3 / 6 filhos pelo spawner0x42f4b0. SS tem ff3=1..3, reinicia uma vez e termina na segunda passagem; count8 do filho não é prova de oito. Os filhos usam vtable0x556468/tick0x49d270 e `FUN0x41da80(type9,kind,isSS)`; os poderes190/160/140 pertencem ao caminho que ainda passa pelos ajustes do spawner. Contrato ainda parcial: arredondamento, sinal/escala de ângulos, delays e estados da animação do Ion devem ser fixados por fixtures ASM antes do porte.

Knight: guia PrimaryBullet15 0x47b2f0 / SS0x47de50 aciona Ion classe própria via 0x47c040 / 0x47c3f0. `SpawnKnightIon`0x438100, vtable0x556078/Animate0x47ca40. S1 gera3 e S2 gera5 no frame2; SS gera8 no laço i<8. Filhos0x4305c0 têm tipo14, não os dados do type13. A geometria completa e parâmetro i×2 do SS ficam como gate de pesquisa.

### JD: cristal é comportamento em Animate

S2 impacta com sua regra e chama SpawnCrystalShot0x437b40, que instala vtable0x555cf4: Animate0x465470 chama 0x4644e0 e altera posições de atores/objetos próximos; raio de influência vem de extraA[68]=60, vida útil também considera +0x3fcc≤18. SS chama SpawnSuperCrystalShot0x437d90 e instala vtable0x556340: Animate0x490780 chama0x48f300, limitado por constante20 e contador. Este lê extraA[81]=68, escreve estados numéricos/posições e chama SpawnDamagePopup; poder0 do SS não encerra a análise. O tick0x4572b0 comum na vtable não demonstra que o cristal cai: seu Animate especializado não delega simplesmente àquele tick. A afirmação anterior do HANDOFF0.19 é insuficiente e deve ser substituída após a implementação.

Gate: fechar as células de HP/escudo e o termo global ctx+0x15406c lido por 0x48f300, os sinais da atração, imunidades e a interação com minas. Não inventar dano, impulso ou queda para substituir essa cadeia.

### Aduka: poder zero e Thor

S2 tick0x4aafd0 chama0x4398e0 em0x4ab292; SS Explode0x4685b0 faz o mesmo em0x468611. Parâmetro final1 força ramo que os tiros comuns só usam com contador climático4. Helper procura Thor classe0x186aa e cria efeito/raio0x186a9 (vtable0x55658c), chama0x432320 e lê tabelas próprias0x4ac400/0x4ac4d0 indexadas pelo nível; blast usa0x4ac260/0x4ac330. Animate do raio0x4aacb0 só envelhece até20 e remove: dano não nasce do tick comum listado na vtable. Logo não é lícito manter Aduka sem dano por P=0, nem reutilizar arbitrariamente dano de S1. Gate: fechar tabelas, criação/nível/XP do Thor e como SS muda penetração/efeito nos três impactos. A cadeia comprovada já remove a ambiguidade do zero; o valor final ainda é pesquisa.

### Grub e demais especiais

Grub S2: quatro chamadas por ramo angular em MainAction0x471fd0/frame2; contador +0x3f9c e ricochete no tick0x49fd40. Finalização usa44 e condições de contato; não traduzir como TTL de44 ticks desde o lançamento. SS usa Simulate0x4857f0, sem teste de mobile, e tick0x486ea0 com contador40 após contato. Fórmula da velocidade tangencial, energia de cada ricochete e dano repetido ainda não fechada. **Fechada em 28/10/2026 (issue #8): ver `GRUB_CLIENT_FIX.md`** — normal em `0x4a1740`, módulo constante `[69]/[82]` após cada ricochete, dano repetido do SS por `Animate` `0x488780`.

Dragon: S1/S2 Simulate0x46fb20 (tick comum) adiciona faíscas via0x436fd0. SS Explode0x46ca60 gera exatamente5 filhos pelo laço i<5; extras30/200 dão ângulos30,60,90,120,150 e força200 antes das conversões originais. `SpawnShot_Type13`0x4388e0 inicializa filho e copia dados do estágio; dano/raio final de cada filho ainda precisa conferir ajustes, não presumir160×5.

Trico, Lightning, Ice e Turtle: a matriz fecha despacho, número de objetos iniciais, dados e slots. Confronto estrutural C# serve de referência auxiliar; não foi fechado contrato numérico de todos os especiais. Próxima pesquisa precisa confirmar cada loop de colisão/transformação e produzir fixtures por tick antes de qualquer troca. Preservar Mage/Bigfoot HD aprovados.

## Confronto estrutural C#

Fonte somente lida: `/Users/guichafy/Workspaces/Gunbound/OpenBound/GameComponents/Pawn/Unit{,Projectiles}/`. Não confundir estes números com teste dinâmico de dano.

| Família | C# consultado | Original | Resultado |
|---|---|---|---|
| Armor | Armor.cs:38–45; ArmorProjectile.cs:61–121, primaryExplosion | 1 S2, 2 fases de impacto | Concorda estruturalmente; corrigir relatório antigo de 2 objetos. |
| Raon | RaonLauncherProjectile.cs:33–44 | S1=3, S2=2 | C# S1=4 diverge; original prevalece. |
| Trico | TricoProjectile.cs:30–35 | S2=3, idx2 comum e duas órbitas | Quantidade concorda; forma/tempo ainda exigem fixtures originais. |
| Lightning | Lightning.cs:49–56; LightningProjectile.cs:98–111 | Um pai por arma, regras de feixe em Simulate/tick/Explode | C# S2 cria4 eletricidades após impacto; validar caminho original antes de portar constantes. |
| Ice | Ice.cs:47–54; IceProjectile.cs:84–111 | Um pai por arma; S2 e SS têm rotina própria | C# tem redução de defesa em OnDealDamage e condição de teto; não é prova de equivalência de células originais. |
| Turtle | TurtleProjectile.cs:32–48,225–261 | S2=2; SS contador44, change, spawner0x432850 com6 | Quantidades concordam; tempo C# e conversões dos filhos não comprovam os originais. |
| Dragon | DragonProjectile.cs:29–36,144–161 | S2=4; SS=5 filhos | Quantidades concordam; não copiar spread/força/dano C# sem comparar. |
| Knight | KnightProjectile.cs:66–71,90,103,144–151 | Filhos S1/S2/SS=3/5/8 | C#=3/5/7; SS diverge. |
| JD/ASate/Grub/Aduka | Não existem classes equivalentes neste fork C# | Classes e dados originais acima | Não preencher lacunas com classes de outro type. |

## Perguntas ao usuário

Nenhuma decisão de produto é necessária para continuar a pesquisa estática. As pendências acima são lacunas técnicas verificáveis no binário e nas tabelas; não devem virar pedidos de escolha arbitrária de dano. Só consultar o usuário se a pesquisa exaurir as fontes e exigir um substituto de recurso realmente ausente ou se restar evidência original contraditória. Os planos por família estão em BATTLE_MOBILE_FAMILY_PLANS.md.
