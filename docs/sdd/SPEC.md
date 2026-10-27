# Especificação — Gunbound Recomp 0.20.5

## Transição de partida — REQ-48

O Start da sala abre a tela de loading do cliente por no mínimo 5 segundos
antes da batalha. Ela mostra o mobile já resolvido (Random vira Dragon ou
Knight na hora) e o Miramo Town com o nome de cada piloto no ponto em que
vai nascer. A partida usa esses mesmos mobiles e essas mesmas coordenadas.
Rede e salas maiores continuam fora desta etapa; o temporizador fixo ocupa
o lugar da espera de carregamento multiplayer. Plano: `LOADING_SCREEN.md`.

## Objetivo e escopo de fontes — ADR-132

Reescrever com fidelidade jglim/gunbound-launcher (TestClient) e jglim/gunbound-server,
com suporte multiplataforma e extensões declaradas. Etapa atual: cliente em treino
offline 1×1. Fonte de regra: cliente comprovado; onde faltar prova, adaptação
declarada. OpenBound (Season 2) está fora do escopo; menções nas seções abaixo
descrevem a origem histórica de regras ainda adaptadas, não uma instrução.

## Partículas em voo Mage — REQ-07/08/09/24/44

Substituir a apresentação adaptada deForce/eletricidade nos tirosMage pelos
efeitos comprovados do cliente: amostras físicas, tentativas, posição fixa,
textura, quad, mistura e relógios. Sorteio visual não altera combate/CPU.
Plano e contratos em `MAGE_FLIGHT_SPARKS.md`.

## Revisão Lightning — REQ-04/05/06/07/08/09/19/20/21–26/38–41/44/45

Revisar T1/T2/SS, assets, animação, força, defesa, atributos e interação com
Tempo/clima e seus elementos pelo cliente original. Portar diferenças
comprovadas no passo comum real/previsão, preservando elenco, avatares/HD e
perfil. Escopo, matriz e plano: `LIGHTNING_CLIENT_REVIEW.md`.

## Climas secundários Mage — REQ-04/07/08/09/23/24/25/35/44

Substituir adaptações pelo comportamento comprovado do cliente nas partidas
contendoMage: calendário de sete categorias, vento/colunas, Moon/Eclipse,
elétrico e Thor. Preservar estado independente da previsãoCPU. Matriz,
sequência de implementação e limites em `MAGE_SECONDARY_WEATHER.md`.

## Revisão Mage — REQ-04/05/07/08/09/19/20/44/45

Revisar T1/T2/SS, assets, força, relógios e interação com Tempo/clima, vento
e tornado pelo cliente original, conforme aprendizado da revisão Aduka.
Corrigir divergências comprovadas; preservar montagem/avatares/HD, demais
mobiles e perfil. Plano/matriz: `MAGE_CLIENT_REVIEW.md`.

## Dano e colisão do Aduka — REQ-04/05/07/08/09/19/20/44/45

Portar os consumidores nativos de dano/colisão/Thor e revisar seus assets.
T2 deve emitir três bichos conforme solicitação posterior do usuário; a
divergência com as duas chamadas da build analisada fica explícita. Plano,
matriz e limites em `ADUKA_COMBAT_REA.md`. Preservar montagem aprovada.

## Auditoria Aduka T1/T2/SS e assets — REQ-04/05/07/08/09/19/20/44/45

Revisar a família pelo cliente original, corrigindo emissão, animação,
composição, Thor e sons, principalmente no T2. Manter orientação/encaixe
aprovados (ADR-122/123), demais mobiles/HD e perfil. Matriz, plano e limites
em `ADUKA_AUDIT.md` (ADR-124).

## Piloto centralizado no Aduka — REQ-02/19/20/45

Orientação da ADR-122 aprovada; aproximar o piloto do centro do mobile com
compensação fixa(+8,0) em pixels nativos no ponto de montagem, preservando
altura e deslocamentos animados por quadro. Padrão/equipado, sala/arena/loja
compartilham o encaixe. Plano e evidência: `ADUKA_CENTER.md`, ADR-123.

## Orientação do Aduka na sala — REQ-02/19/20/45

A imagem posterior do usuário substitui a interpretação da ADR-121. No lado A,
o personagem olha para a direita e a traseira/mira do Aduka aponta para a
esquerda. Restaurar o RiderPivot original e orientar o conjunto inteiro na
prévia da sala; lado B espelhado. Na arena, continuar atirando pelas costas
com o desenho vinculado à direção efetiva do tiro. ADR-122.

## Alinhamento visual de SETTINGS — REQ-02/12/19/20

Corrigir os dois T que aparecem acima de SE/INGS, preservando fonte e
acabamento aprovados. Contrato: `SETTINGS_BASELINE.md`.

## Acabamento da palavra SETTINGS — REQ-02/12/19/20

Preservar transparência aprovada e fonte original; eliminar emendas do
contorno e ajustar espaços conforme START. Ver `SETTINGS_WORD_FINISH.md`.

## Alpha e composição dos botões — REQ-02/12/19/20

Remover cenário opaco fora dos cantos arredondados de START/SETTINGS e
refinar as letras de SETTINGS comparando com START, preservando a fonte.
Contrato: `ROOM_BUTTON_ALPHA.md`, posterior à ADR-111.

## Letras completas de SETTINGS — REQ-02/12/19/20

Pedido posterior rejeita a reconstrução daADR-110. Restaurar pixels completos
dos glifos/contornos nativos e lapidar somente fundo/junções. START aprovado
preservado. Contrato: `SETTINGS_ORIGINAL_LETTERS.md`.

## Acabamento de SETTINGS — REQ-02/12/19/20

START aprovado deve permanecer idêntico. SETTINGS conserva as formas nativas,
com fundo transparente, baseline/espaçamento e contorno uniformes, sem emendas
dos recortes. Plano: `SETTINGS_LETTERING_FIX.md`, substitui composição daADR-109.

## SETTINGS e modal clássico — REQ-02/12/19/20

START sem seta; CHANGE substituído porSETTINGS sem seta circular. Modal de
apelido/dificuldade/clima com moldura, cores e controles clássicos, mantendo
rascunho/aceite/cancelamento. Adaptação solicitada: `ROOM_SETTINGS_CLASSIC.md`.

## Acabamento final da sala — REQ-02/12/19/20

Dificuldade aparece ao lado deCPU no card da máquina; números do clima
brancos, sem poços escuros; START usa o botão azul clássico no padrão de
EXIT/CHANGE. Plano: `ROOM_FINAL_POLISH.md`. Demais elementos daADR-107 mantidos.

## Cards e indicadores da sala — REQ-02/12/19/20

Pedido posterior corrige encaixe do mobile na faixa, retira o nome do mobile
dos cards e restaura Ready/placas do mapa com arte nativa. Configurações
exibidas refletem o treino offline existente. Plano: `ROOM_CARD_FIDELITY.md`.
Substitui o contato144 daADR-106; preserva idle, avatar e Random.

## Correções de catálogo, apoio e mapa da sala — REQ-02/12/19/20/36

Ver `ROOM_POLISH.md`: catálogo nativo uniforme, equipamento de1/2slots,
setas encaixadas, mobiles apoiados e somente título/setas laterais nativos.
Sem novos mapas ou alterações de combate/perfil.

## Sala conforme foto — REQ-02/12/19/20/36

Pedido posterior substitui grade8×2 por5×3 e abas por catálogo único.
Quatorze escolhas comuns+Random, que sorteia sóDragon/Knight noStart.
Oito lugares identificadosA/B por arte nativa. VerROOM_REFERENCE_LAYOUT.md.


## Sala clássica e acabamento4× — REQ-02/12/19/20/36

Pedido25/10/2026 autoriza corrigir composição com mapas/retratos/itens
originais e BICUBIC4× conservador. Preservar grade8×2,16mobiles, estados
e hitboxes, perfil/combate/versão. Contrato/plano: ROOM_UI_FIDELITY.md.


## Acabamento restante do lobby — REQ-02/12/19/20

Pedido25/10/2026 autoriza BICUBIC4× no fundo/molduras e insígnias nativas,
com alpha, quadros, layout e hitboxes preservados; fallback original.
Ver LOBBY_ART_HD.md. Não muda perfil, combate ou versão.


## Lobby e patente clássica — REQ-02/10/12/19

Pedido atual substitui a apresentação Rank=level da ADR-096. Patente própria
do cliente Thor, insígnia original e GM20 por padrão no perfil local. Corrigir
contenção do cartão/carteira/chat e rolagem local. Preservar progressão,
avatares, saldos e escopo offline. Contrato/plano: `LOBBY_UI_RANK.md`.

## Suavização dos botões aprovada — REQ-02/12/19/20

O usuário aprovou o EXIT BICUBIC e pediu aplicar a abordagem e adotá-la na
skill. Gerar os42atlas/197estados em4×, suavizando cada quadro isoladamente,
com alpha preservado e sem padding ou mudanças de geometria/estados/hitboxes.
Conservar as fontes e os derivados exatos anteriores. Cores interpoladas são
parte do acabamento aprovado. Plano: `CLASSIC_BUTTONS_SMOOTHING.md`.

## Botões4× integrados — REQ-02/12/19/20

Pedido posterior autoriza usar os atlas4× no lobby e na sala, mantendo o
tamanho visual, alinhamento, estados e áreas de clique vigentes. Apenas os
recortes de textura usam densidade4; layout continua em coordenadas nativas.
Fallback original quando o recurso/catálogo4× estiver inválido ou ausente.
Plano: `CLASSIC_BUTTONS_HD_INTEGRATION.md`. Sem mudança de regras ou versão.

## Skill HD: restauração fiel — REQ-12/19/20

A solicitação atual torna a restauração conservadora o padrão da skill
`gunbound-classic-hd`: fonte visual única, mesma composição/estados/paleta e
alpha, alvo 4× por dimensão quando suportado. Não reconstruir detalhes
ambíguos. Ensaiar com `assets/classic` sem substituir arte ativa. Plano e
critérios em `CLASSIC_HD_RESTORATION_SKILL.md`.

No ensaio posterior do CREATE, o usuário escolheu explicitamente repetição
de pixels. O contrato exige1712×180, mesmos quatro estados, zero margens
acrescidas e nenhum pixel RGBA alterado em relação à ampliação inteira4×.
Entrega separada, sem integração ao jogo.

Pedido seguinte estende a ampliação exata aos demais botões de `assets/classic`:
preservar cores, estados e alinhamento, sem margens extras. Derivados4× em
`assets/hd/classic/buttons_4x`, com originais intactos. O conjunto reúne os41
demais atlas e o CREATE já conferido, sem alterar consumidores do jogo.

## Correções ASate/JD/Aduka/Raon — REQ-04/05/07/08/09/19/44/45

Restaurar comportamentos e animações dos tiros T1/T2/SS dos quatro mobiles
com evidência do cliente clássico. ASate usa guia, Ion e filhos; JD T2 atrai
e SS aplica seu efeito numérico; Aduka T2/SS acionam Thor independentemente
do clima; Raon preserva composição e estados próprios de tiros/minas.
Execução e previsão compartilham efeitos e cópias profundas. Preservar
elenco, avatares, equipamentos e HD aprovado. Plano e limites:
`SPECIAL_MOBILES_CLASSIC_FIX.md` e registros por família.

## Ferramenta do porte — REQ-12/19/44/45

Adotar Ghidra na skill gunbound-client-port, com execução headless direta,
evidência reproduzível e validação da ligação entre ASM/dados e GDScript.
Separar funcionamento do Ghidra12.2 da compatibilidade do conector REA.
Plano: GHIDRA_SKILL_VALIDATION.md. Sem alteração de regra ou arte nesta tarefa.

## Tiros e animações Bigfoot/Mage0.20.4 — REQ-04/07/08/09/19/44/45

Feedback da0.20.3 amplia a restauração para a composição e os estados dos
tiros e poses. Mage T1/T2 devem usar LaserEffect nativo, seções e UV do
cliente; T2 usa onda13px/40°/fases0/180 no passo comum. Timers de ações vêm
da EPA; retirar os overrides genéricos sobre a morte e o rastro Bigfoot.
Preservar avatares e dano. Plano/evidência: MAGE_BIGFOOT_ANIMATION_PORT.md.

## Bigfoot/Mage originais 0.20.3 — REQ-12/19/20/45

Por solicitação atual, Bigfoot e Mage voltam aos sprites originais do cliente,
com o mesmo pipeline do elenco clássico. Conservar derivados HD em disco,
avatares/equipamentos e regras. Esta escolha substitui somente a obrigação
de manter o HD desses dois mobiles na ADR-088. Plano: ORIGINAL_MAGE_BIGFOOT.md.


As seções abaixo são cronológicas: o texto de cada versão fica como histórico
quando uma seção posterior o substitui. A partir de 0.7.0 vale a seção mais nova
de cada requisito (batalha atual: REQ-44/ADR-084/085; Turtle: ADR-086/087).

## Continuidade do porte — REQ-12/19/20/38–41/44/45

Após confirmar o T2 (“Agora funcionou”), o usuário autorizou engenharia
reversa do binário client-side como fonte para ajustar o porte no Godot.
Preservar os 16 mobiles e os avatares/equipamentos atuais, incluindo HD
aprovado; modernização visual será uma etapa posterior solicitada.
Procedimento reutilizável: `skills/gunbound-client-port/SKILL.md` e ADR-088.
Esta consolidação documental não implementa novas famílias nem altera rede,
combate, catálogo ou a versão do aplicativo.

## Turtle T2 0.20.2 — REQ-04/08/19/44/45

A órbita aproximada do T2 foi substituída pelo movimento comprovado no
cliente: duas fases opostas 0/180°, amplitude inicial 1000/100=10 px, avanço 5°
por tick. Nos dez primeiros ticks a amplitude cresce 200 e o avanço 4;
depois diminuem 20 e 1, com piso 0. A onda perpendicular usa heading/LUT
nativos antes da aceleração; seções do rastro usam heading após aceleração,
com meia largura 10 px. Ordem: mover trajetória central→onda/colisão→acelerar→
registrar seção→avançar fase→atualizar amplitude/avanço. O offset não se
acumula na trajetória central. Real e previsão usam o mesmo ponto; renderer
interpola somente cópias e emite dois triângulos explícitos por quad T2,
inclusive nas seções cruzadas. T1 mantém seu raster anterior; T1/SS, avatares,
dano, itens, HUD e carga conservam os contratos existentes. Evidência e
limites em `TURTLE_T2_FIDELITY.md`; não implica combate integral nativo.

## Correção Turtle 0.20.1 — REQ-04/07/19/45

Pedido atual: corrigir as animações de T1, T2 e SS. WaterEffect deve percorrer
as oito colunas completas e compor uma faixa contínua nas curvas, sem alterar
histórico usado por colisão. SS usa `bullet12p` normal/abertura; no tick 44
inicia os 10 ticks de change, emite seis filhos `bullet12c` e remove o pai.
A divisão no ar não aplica dano/cratera. Impactos identificam pai/filho;
o pai normal usa flame123 + ssflame12; pai em change e filhos usam flame123.
Impacto no tick 44 não antecipa a divisão; hold mantém endpoints visuais fixos.
Dano, raio, velocidade e dispersão dos filhos conservam a adaptação atual; não é porte integral
da física especial do Turtle. Plano e evidências: `TURTLE_ANIMATION_FIX.md`.

## Índice vivo de requisitos (0.20.2)

Versão em fonte única: `application/config/version` em `project.godot` (ADR-081).
Este índice resume o requisito vigente e onde ele está; as seções seguintes
guardam o histórico e, em caso de dúvida, vale a seção mais nova indicada aqui.

| ID | Requisito vigente | Documento | Estado |
|---|---|---|---|
| REQ-01 | Engine multiplataforma; entrega executável no Mac | este arquivo, `build_macos.py` | macOS entregue; Windows/Linux/Android/iOS não testados |
| REQ-02 | Treino offline 1×1: apelido, mobile e dificuldade | este arquivo | Vigente; lobby clássico e sala pelo Create (ADR-096); 16 mobiles (REQ-45) |
| REQ-03 | Mira, força e movimento; teclado e extras na tela | HUD_0_10, AIMING_0_12 | Vigente; console original substituído por REQ-27..30 |
| REQ-04 | Balística, colisão e crateras | CLASSIC_BALLISTICS_0_20, BATTLE_FIDELITY_0_20, TURTLE_T2_FIDELITY | Física comum 20 Hz/24.8 e onda Turtle T2 implementadas; colisão/dano continuam adaptações declaradas |
| REQ-05 | Vida, dano, queda e resultado | MOBILE_PARITY, BATTLE_RULES_AUDIT, BATTLE_FIDELITY_0_20 | Vigente; autoria/Gold de minas corrigidos; deriva na queda ADR-077 |
| REQ-06 | Iniciativa por atraso, turno de 30 s, passe | BATTLE_RULES_AUDIT | Vigente; custo por tempo gasto e passe 200 ÷ 7, 5 (REQ-44) |
| REQ-07 | Três tiros; SS aberto no 1º turno, trava de 4 turnos | MOBILE_PARITY, TURTLE_ANIMATION_FIX | Vigente; Turtle divide após abertura, sem impacto aéreo |
| REQ-08 | CPU com as mesmas regras e três dificuldades | PERF_LIMITS_0_11, BATTLE_RULES_AUDIT | Vigente; CPU não se move nem usa itens |
| REQ-09 | Pausa, ajuda, resultado, revanche e menu | HUD_0_10 | Vigente |
| REQ-10 | Perfil local sem duplicar recompensa | AVATAR_SHOP, AVATAR_HD_MIGRATION | Vigente; saldo de teste ADR-080 |
| REQ-11 | Arte original própria | — | Substituído por REQ-19/20 |
| REQ-12 | Código, documentação e app para validar e aprender | QUALITY_REVIEW | Vigente; revisão de qualidade 0.18.6 |
| REQ-13..18 | Refinamento 0.2 (HUD, fila, inclinação, carga, animações, impacto) | REFINEMENT_0_2 | HUD/console substituídos por REQ-27..30; demais vigentes |
| REQ-19 | Mobiles e assets reais | BIGFOOT_0_3, MAGE_0_4, NAK_0_15, REQ-45 | Vigente nos 16 do cliente Thor's Hammer |
| REQ-20 | Derivados HD com aparência clássica | HD_ASSETS_0_6, NAK_HD, HORN_AURA_FIX, BIGFOOT_SMOOTH_4X | Vigente; HD do Nak gerado e pendente de integração; brilho do Great Devil derivado do chifre (ADR-082); Bigfoot original com acabamento4× (ADR-115) |
| REQ-21..26 | Mapa Miramo A, câmera 1: 1, vento 2D, clima, Thor, partícula | MAP_0_8, WEATHER_CAMERA_0_9 | Vigente |
| REQ-27..31 | HUD original e popup de opções | HUD_0_10, BATTLE_FIDELITY_0_20 | Carga 3 s/mínimo nativo (REQ-28); bússola/vento coerentes; Mouse Speed desabilitado |
| REQ-32..33 | CPU sem travar a troca de turno; música original | PERF_LIMITS_0_11 | Vigente; relógio da CPU congelado na busca (ADR-076) |
| REQ-34 | Aiming Mode Drag/Slice | AIMING_0_12 | Vigente; TODO Mouse Speed |
| REQ-35..37 | Itens de batalha, Select Item, arte HD | ITEMS_0_13 | Vigente; custos do `itemdata.dat`; CPU sem itens; Team Teleport sem aliado no 1×1 |
| REQ-38..41 | Loja, composição, atributos e modificadores | AVATAR_SHOP_XFS_0_16, AVATAR_HD_MIGRATION, AVATAR_SHOP_ORIGINAL | Vigente; catálogo XFS com bônus por equipamento; composição e arte originais pela REQ-47 |
| REQ-42 | Paridade Mage/Bigfoot com o C# | MOBILE_PARITY | Vigente, com os ajustes de REQ-44 |
| REQ-43 | Nak (ID 3) com dados do cliente original | NAK_0_15 | Vigente; aura UsingItem ausente (sem arte original) |
| REQ-44 | Regras de batalha: cliente original comprovado, depois C# | BATTLE_RULES_AUDIT, BATTLE_FIDELITY_0_20 | ADR-084 substitui balística/carga/mínimo; demais limites declarados |
| REQ-45 | Os 16 mobiles do cliente, IDs1–3 preservados | BATTLE_FIDELITY_0_20, TURTLE_T2_FIDELITY, BATTLE_MOBILE_FAMILY_PLANS, RAON_CLASSIC_FIX | Boomer, onda Turtle T2, cronologia48 e tiros/minas Raon (ADR-116/117) implementados; demais limites/portes explícitos |
| REQ-46 | Catálogo clássico: os 562 avatares do `avatar.xfs` 280 e o código do servidor | AVATAR_CLASSIC_CATALOG | Vigente; chaves salvas da loja não mudam |
| REQ-47 | Avatar Shop e avatares com os assets originais do cliente | AVATAR_SHOP_ORIGINAL | Vigente (ADR-130); HD de avatares/loja preservado em disco, fora do uso ativo |
| REQ-48 | Start da sala mostra a transição com mapa, spawns e mobile resolvido | LOADING_SCREEN | Vigente (ADR-133); 1×1 local, espera mínima de 5 s |

## Lobby clássico e sala — ADR-096

A entrada é o lobby do `gamelist_back.img` (gelo e torre azul), não o
`gamelistmode.img`. Create abre a sala 1×1 do `ready_back.img`. EXIT do lobby
encerra o jogo; EXIT da sala volta ao lobby. AVATAR abre a loja já existente
e a saída da loja volta à tela que a abriu. Buddy não é colocado. Ranking e
Join ficam desabilitados. Não há rede, contas nem multiplayer.

O cartão mostra o apelido do perfil. Na ADR-096, Rank era `profile.level()`; essa apresentação foi substituída
pela ADR-102: patente atribuída própria, GM20 por padrão. GP continua XP local. O chat é local: uma linha de sistema e o eco
do que o jogador digita, sem nome de servidor. A lista do canal tem só o
jogador. O mapa continua Miramo Town A, com as setas visíveis e desabilitadas.
O botão SOLO aparece como modo vigente. Jewel, Death e Big Bomb não entram
como regra. O palco é 800×600 com escala 4/3, filtro NEAREST, centralizado
na viewport 1280×800. Na sala, o casco do mobile cabe no lugar clássico
(cerca de 67 px na cena); a arena não muda.

## Sala 1×1 — ADR-092 (histórico; alcançada pelo Create)

Histórico da sala, agora aberta pelo Create do lobby (ADR-096). Dois lugares
(piloto e máquina), Miramo Town A no centro, retrato do mobile escolhido e
Iniciar. Iniciar usa o ajuste já gravado.

Configurações da partida reúne apelido, dificuldade e clima. Aceitar grava e
volta à sala; Cancelar restaura o que estava aberto. O casco de 60 px
(ADR-095) ficou na arena. Na sala o casco é 52 px nativos, para o cell mais
largo caber no lugar de 124 px. A grade dos 16 é a única escolha: o clique
aplica no piloto, e o lugar B só muda o modo para a CPU aplicar o clique
seguinte. Sem essa escolha, o pareamento segue o de sempre (1↔2, Nak contra
Mage, os demais contra Mage). O lugar mostra um mobile e, no piloto, o avatar
equipado do perfil. Knight e Aduka usam o quadro 0 do atlas sobre o fundo
do botão, sem o Armor de `b_ready_mobile01`. Itens da sala
ficam nos seis lugares do painel direito, com o catálogo no mesmo painel.
Item de 2 slots cobre os dois lugares com um ícone; item de 1 slot cobre um. Som, rolagem e fundo permanecem no popup de opções do
cliente. Não há troca de mapa.

## Base da batalha 0.20 e validação histórica

[BATTLE_FIDELITY_0_20.md](BATTLE_FIDELITY_0_20.md) consolida implementação,
evidência e limites. REQ-03/04/08/23/28/34/44: passo comum20 Hz/24.8 e LUTs
originais; forçaP1..10*f25 convertida uma vez; Slice3 s, Drag por soltura,
disparo único/cancelável; aceleração capturada no lançamento; CPU/HUD usam
limites e geometria comuns, incluindo extremos de mira. Boomer guarda curva
por shell e SS normal→change36–45→cnormal46, sem contato durante freeze.

REQ-05/06/10/45: mina conserva dono/crédito sem substituir autoria/arma/item
ou delay do tiro vigente; real e previsão avançam minas/filhos no mesmo laço,
com snapshots profundos e recompensa idempotente. Fábrica preserva parâmetros
Lightning e raio. REQ-09/19: EPA/MainAction controlam48timelines, grupos de
som e duração de pose; Dual distingue pose/spawn e pausa congela relógios.
Turtle usa WaterEffect; Dragon reserva o sprite filho ao SS; recursos ausentes
confirmados permanecem silêncio explícito, sem fallback de outro mobile.

Aceite de implementação: fixtures independentes, paridade real/previsão,
modelos/cenas e revisão. Fechamento: harness completo sem ERROR, partidas,
QA GPU/áudio e PCK conforme registro 0.20. Gates de revisão aprovados; rodada
completa final passou (7287 checks Godot, 16 Python, 29 partidas). App assinado e
PCK 160 checks aprovados nas assertivas, com ressalva ambiental de CA.
Recaptura Full HD/escuta pendentes. Pesquisa 48 tiros da tarefa 8
não equivale a porte integral de dano, colisão, tornado ou famílias restantes.

## Histórico da especificação

Status: implementado; validação funcional pelo usuário pendente de relato.
Correção solicitada: estabilidade visual das animações HD de Bigfoot/Mage;
REQ-19/20/12, plano e critérios em `ANIMATION_FIX_0_6_1.md`.
Pedido posterior: piloto coeso e tiros/impactos sem mudanças de silhueta,
salto de fase ou orientação invertida; `PILOT_SHOTS_FIX_0_6_2.md`.
Data: 2026-10-11. Esta especificação consolida as escolhas da conversa e o
comportamento entregue; parâmetros concretos são decisões do protótipo.

## Objetivo e público

Criar um jogo original de artilharia 2D por turnos inspirado em Gunbound,
para jogadores nostálgicos. O usuário trabalha sozinho, conhece JavaScript/
TypeScript, Node.js, Python e Java e quer aprender lendo o resultado final.
Jogar com amigos é o objetivo futuro; a primeira validação é contra a máquina.

## Escopo e critérios

| ID | Requisito / critério de aceitação | Implementação | Evidência |
|---|---|---|---|
| REQ-01 | Engine com suporte a macOS, Windows, Linux, Android e iOS; entrega inicial executável no Mac | Godot 4.7.2, Compatibility; `project.godot`, preset macOS, `build_macos.py` | Aplicativo Universal e assinatura; demais alvos ainda não testados |
| REQ-02 | Iniciar treino offline 1×1; escolher apelido, veículo e dificuldade | Lobby `lobby_screen.gd`, sala `menu_screen.gd` pelo Create; popup da partida; `match.gd.start` | `test_scene.gd` + roteiro manual |
| REQ-03 | Mirar, escolher força e mover com limite por turno; teclado e controles na tela | `game.gd`, `ui.gd`, `match.gd.move_actor` | Modelos, cena/input e roteiro manual |
| REQ-04 | Balística afetada por gravidade/vento, colisão com terreno e veículos, crateras | `combat.gd`, `terrain.gd`, `match.gd` | `test_runner.gd`, partidas completas |
| REQ-05 | Vida, dano por explosão/queda, vitória, derrota e empate | `match.gd`, tela de resultado | Modelos, partidas e cena |
| REQ-06 | Iniciativa por atraso, turno de 30 s, passagem voluntária/automática | `match.gd.schedule`, `pass_turn`, `tick` | Modelos e roteiro manual |
| REQ-07 | Três armas; SS aberto no primeiro turno e travado por quatro turnos próprios depois do uso | `match.gd.can_use_special` | Modelos + roteiro manual para apresentação da especial |
| REQ-08 | CPU joga com as mesmas regras; três dificuldades por erro de mira | `match.gd.choose_cpu_shot/predict_shot`, `combat.gd` | Modelos e dez partidas completas |
| REQ-09 | Pausa congela relógio/voo; ajuda, resultado, revanche e menu navegáveis | `game.gd` | `test_scene.gd` + roteiro manual |
| REQ-10 | Apelido, XP, nível e vitórias locais; recompensa uma vez por resultado | `profile.gd`, `game.gd` | Persistência/corrupção/idempotência e cena |
| REQ-11 | Arte e efeitos originais, sem copiar recursos do Gunbound | `assets/art/`, terreno procedural, `sound.gd` | `docs/ART.md`, capturas visuais |
| REQ-12 | Fonte, documentação e aplicativo permitem validar e aprender | README, guias, fontes, testes e build | Hand-off e roteiro funcional |

## Regras concretas do baseline

- Arena lateral única, 1280×800. Jogador começa (substituído: abertura sorteada, REQ-44); CPU recebe o outro veículo.
- (Histórico: veículos substituídos por Bigfoot/Mage/Nak, REQ-19/43.) Escaravelho: vida 580, movimento 110, atraso adicional 0.
  Carapaça: vida 700, movimento 80, atraso adicional 18.
- Mira local 10–85°, força 15–100%. Movimento de 60 unidades/s limitado pelo orçamento.
  Deslocar vira o veículo; `F` vira parado. A inclinação do apoio afeta a direção
  do disparo; o indicador junto ao canhão mostra o ângulo efetivo no mundo.
- Pulso: dano máximo 145, raio 46, atraso 100, um projétil.
  Impacto: dano máximo 210, raio 62, atraso 155, um projétil.
  Tempestade: dano máximo 105 por projétil, raio 43, atraso 210, três projéteis.
- Vento inteiro entre −30 e +30 por turno (substituído: força 0–34 e ângulo 0–359, REQ-23); gravidade 260 (substituído: 196, REQ-44/ADR-076); integração 120 Hz.
  Dano diminui com a distância, considerando o tamanho do veículo. Queda de mais
  de 70 unidades causa dano (substituído: queda curta não fere, REQ-42/MOBILE_PARITY.md); perder suporte até abaixo da ilha elimina.
- Próximo ator é o de menor disponibilidade acumulada; empate favorece o outro.
  Passar custa 80 + atraso do veículo (substituído: 200 ÷ 7,5, REQ-44). Não existe alternância estrita obrigatória.
- CPU calcula mira e dispara, sem se deslocar. Dificuldade altera o erro da mira,
  sem bônus de vida/dano. A simulação auxilia sua escolha, sem mostrar trajetória
  completa ao jogador; HUD mostra direção inicial e último tiro.
- Vitória 120 XP, derrota 45 XP, empate 70 XP; nível = 1 + piso(XP / 200).
  Apelido até 20 caracteres; vazio vira `Piloto`. Sem conta ou ranking.

## Refinamento 0.2

REQ-13–18 e critérios detalhados estão em [REFINEMENT_0_2.md](REFINEMENT_0_2.md).
Incluem painel azul metálico, força graduada/referência anterior, fila prevista,
bússola, inclinação, carga automática e animações. Aceitação automatizada:
`test_refinement.gd` (28) e `test_refinement_scene.gd` (21), além das suites anteriores.
Os parâmetros de dano/vida/atraso/XP continuam os do baseline.

## Bigfoot e integração original

Solicitação posterior ao refinamento: **REQ-19 — integrar assets reais de Bigfoot
e outros mobiles a partir do material disponível do OpenBound**, com animações e
tiros correspondentes. A direção original de REQ-11 permanece descrição do
baseline 0.2, mas foi substituída pelo pedido atual para a próxima integração.
Status e origem do pacote externo em [ORIGINAL_ASSETS.md](ORIGINAL_ASSETS.md).
REQ-19 parcialmente atendido: Bigfoot selecionável com atlas, piloto padrão,
quadros e projéteis originais na versão 0.3.0. Ver `BIGFOOT_0_3.md`. Vida 1100,
movimento 90. Armas mantêm as regras do protótipo; salvas oficiais e outros
mobiles pendentes. Todos os assets restantes estão em `.tools/source-assets/content/`.

## Paridade Mage/Bigfoot com o C# — REQ-42

REQ-05, REQ-07 e REQ-19. O contrato vigente de escudo, regeneração, SS, dano,
queda, caixa, sinalizador e poses está em [MOBILE_PARITY.md](MOBILE_PARITY.md)
e na skill `skills/gunbound-mobile-port/SKILL.md`. As frases de 0.4 e 0.5 sobre
regen só no turno próprio, SS único e queda linear ficam como histórico.

## Nak 0.15 — REQ-43

Terceiro mobile jogável (ID 3), pedido explícito do usuário. O OpenBound não
implementa o Nak: dados C# (HP, mira, delays, sons, miras, RiderPivot) mais
arte, flipbook, dano e regras de voo do cliente original Thor's Hammer
(jglim/gunbound-launcher), lidos com as notas do GunBound-Decomp — S2 entra no
chão e explode ao emergir, SS atravessa o terreno e só explode em mobile.
Contrato e números em [NAK_0_15.md](NAK_0_15.md), decisão ADR-074. A
restrição "apenas Bigfoot/Mage" deixa de valer para o Nak; demais mobiles
continuam fora. Arte HD do Nak adiada pelo usuário.

## Paridade das regras de batalha — REQ-44

Atualização de24/10/2026: ADR-084 implementada na0.20, com física comum
original, carga3s e força mínima nativa. Os valores C# de balística abaixo
são histórico substituído; agenda/itens/demais regras não alteradas continuam.

Pedido de 20/10/2026: comparar a batalha com o OpenBound C# e com o cliente
original Thor's Hammer (engenharia reversa do GunBound-Decomp e dos `.dat`).
Auditoria e evidências em [BATTLE_RULES_AUDIT.md](BATTLE_RULES_AUDIT.md),
decisão ADR-076. Política: **o original prevalece quando a engenharia reversa
comprova a regra; senão, vale o C#.** Escolhas do usuário aplicadas:

- **REQ-06**: quem abre a partida é sorteado. Cada segundo inteiro gasto no
  turno até o disparo soma ao delay do tiro o valor `[29]` do mobile (10 em
  Mage, Bigfoot e Nak). O turno continua com 30 s. Passar (voluntário ou por
  tempo) custa 200, sem termo de tempo. A prévia de iniciativa usa o tempo ao
  vivo. Empate de iniciativa continua favorecendo o outro, também na fila do
  HUD (`TurnTable.current_order`). A CPU não paga o tempo real da busca, que
  depende da máquina: cada tiro dela cobra um tempo fixo de 2 s
  (`TurnTable.CPU_THINK_SECONDS`), e a mesma seed dá a mesma ordem de turnos.
  Enquanto a busca da CPU roda, o relógio do turno fica parado
  (`Match.cpu_thinking`, 0.18.2): uma busca lenta nunca esgota o tempo nem
  vira passe.
- **REQ-04**: balística do C#. Gravidade 196, velocidade = força × 100 / massa
  (massa 14 nos tiros, 10 no sinalizador), vento × 1,2 por projétil. O piso de
  força 15 e o relógio em tempo real ficam (o C# avança 0,015 s por quadro de
  60 Hz).
- **REQ-43**: delays do Nak do original, 770/920/1320.
- **REQ-42**: Mage com 730 de vida e 30 de regeneração de escudo
  (`characterdata.dat`).
- **REQ-35**: delays dos itens do `itemdata.dat`: Teleport 100, Dual+ 250,
  Energy Up 2 300, Change Wind 150, Bunge Shot 50. Os demais já coincidiam.

Todos os delays seguem na escala ÷ 7,5. Ficam como estavam no Godot: empate
por morte dupla e passe sem travar o SS (o C# trava). As seeds de
`test_matches` mudam de propósito; os novos valores de referência estão no
hand-off.

## Roster clássico 0.19.0 — REQ-45

**Alvo aprovado de fidelidade (ADR-084, REQ-03/04/08/23/28/44/45):**
balística e vento do cliente original comprovados, velocidade/gravidade
por mobile, carga completa em 3 segundos e força mínima nativa, sem piso
arbitrário de 15%. HUD, controles Drag/Slice, CPU e voo real compartilham
os limites e conversões. Disparo único e cancelamento pela pausa continuam.
Critérios: fixtures do cliente, paridade previsão/voo, cenas, modelos e
partidas completas; registrar mudanças intencionais de referência.

Revisão de24/10/2026 implementada na0.20 conforme
[BATTLE_FIDELITY_0_20.md](BATTLE_FIDELITY_0_20.md). O plano original fica
preservado; ADR-084 já substitui balística, carga e mínimo da ADR-076.
As descrições abaixo registram a entrega 0.19.0 e não comprovam paridade
integral com o cliente original.

O `GunBound.gme` carrega 16 registros de `characterdata.dat` (`tank1`…`tank16`).
Mage permanece no ID 1, Bigfoot no 2 e Nak no 3. Os outros entram nos IDs 4–16:
Armor, Trico, Boomer, Raon, Lightning, JD, ASate, Ice, Turtle, Grub, Dragon,
Knight e Aduka. Vida, escudo, regeneração de escudo, mira, delay e o fator
de tempo vêm dessa tabela. O dano e o raio usam a mesma leitura do Nak
(`[44]/[57]/[70]` e metade de `[47]/[60]/[73]`). A arte é o atlas original, sem
HD novo. A CPU dos IDs novos enfrenta o Mage; 1↔2 e Nak→Mage ficam.

Tiros com classe no C#: Armor SS abre aos 2 s; Trico S2 orbita em três e o SS
explode oito vezes; Raon S1 orbita em quatro, S2/SS plantam mina que anda até
90 px e estoura a 90 px; Lightning soma o raio elétrico; Ice S2 tira 5 de
defesa; Turtle S2 são dois projéteis e o SS, depois de 1,5 s, parte em seis.
Boomer, JD, A.Sate, Grub, Knight e o Aduka ainda disparam o projétil
comum com os números da tabela. O SS do Dragon solta cinco filhos. O SS do JD
e os S2/SS do Aduka têm poder 0 nessa tabela. O Aduka atira pelas costas.
Kalsiddon e J.Frog não estão nestes 16 registros.

## Mage 0.4

REQ-19: Carapaça substituído por Mage (índice 1), selecionável e adversário do
Bigfoot. Atlas/piloto, lasers, orbe, efeitos e sons originais preservados. Vida760,
escudo220 regenerando20 por turno próprio; S1/S2/SS e mira15–50° descritos em
[MAGE_0_4.md](MAGE_0_4.md). Regras por ator alimentam CPU, voo, fila e HUD. S2 tem
dois colliders em hélice; SS EMP zera escudos próximos antes do dano. Delays
normalizados ao protótipo. Bigfoot permanece arena60/menu180 e armas atuais.
Gravidade/força/vento e disponibilidade de SS continuam adaptados ao protótipo.
Não reproduz itens, Thor, resistências ou cliente completo de Gunbound
(histórico de 0.4: Thor entrou em REQ-25 e itens em REQ-35; resistências continuam fora).

## Ataques Bigfoot 0.5

REQ-03–08, REQ-09 e REQ-19: T1 tem4 bombas em0/0,2/0,4/0,6s; T2 duas rajadas
de3 bombas em0,2/0,4s com força−4/0/+4; SS8 bombas a cada0,125s. Danos90/70/90
por bomba, raio25, delays770/920/1320÷7,5. Mira18–40° para T1/T2 e23–35° paraSS.
Sprites/Fx/seis sons originais; tudo aguardando seu lançamento, com mesmo avanço
na CPU e voo real. Bigfoot permanece pequeno. Dados/adaptações e plano em
[BIGFOOT_ATTACKS_0_5.md](BIGFOOT_ATTACKS_0_5.md). Substitui as armas genéricas do
Bigfoot de0.3/0.4. Resistências, itens, clima/Thor e regenHP continuam fora.

## Assets HD 0.6

REQ-20 — melhorar a definição dos assets integrados com GPT Images, mantendo a
aparência clássica confirmada pelo usuário. Bigfoot, Mage, piloto, tiros e
explosões recebem derivados separados dos originais, com transparência e
recortes alinhados ao footprint antigo. Apresentação verificada em1920×1080.
Arena60/menu180, combate e sons preservados. Novos atlas usam quadros chave,
com menos imagens distintas que as sequências originais; duração e estados
permanecem. REQ-19/12 relacionados. Plano/limites em [HD_ASSETS_0_6.md](HD_ASSETS_0_6.md).

## Fora da entrega atual

Multiplayer, salas privadas, busca de adversários, ranking, contas, reconexão,
2×2 e demais formatos, campanha, monetização e distribuição pública.
O protótipo é gratuito. Mobile vem após desktop; UI/UX, controles, cross-play e
progresso compartilhado serão discutidos nessa etapa, sem decisão antecipada.

## Aceitação e limites

A entrega técnica requer testes passando, aplicativo macOS verificável e
documentação de execução. A aceitação funcional final depende do usuário
percorrer `docs/VALIDACAO.md` e relatar o resultado. Testes não substituem avaliação
de diversão, balanceamento, acessibilidade ou uso real de mouse/teclado.

## Piloto, tiros e impactos 0.6.2

REQ-19/20/12: piloto completo proporcional com encaixe no assento; cabeça de
cada tiro constante, orientação acompanhando velocidade e chama para trás;
lasers com rastro contínuo e impactos com transição suave, centro fixo e duração
original. REQ-09: pausa congela as camadas. Critérios em PILOT_SHOTS_FIX_0_6_2.md;
103 checks específicos, capturas GPU e revisão. Combate e tamanho dos mobiles
preservados. Aceitação visual pelo usuário pendente.

## Composição 0.6.3 — correção solicitada

REQ-19/20/12: corrigir proporção relativa piloto/carrinho, tamanho de canhão
e rodas e encaixe no assento, no menu e arena. Medidas originais são referência
de composição, PNGs/tiros atuais preservados. Plano em COMPOSITION_FIX_0_6_3.md.

## Perfil do piloto e roster0.6.4 — escopo solicitado

REQ-19/20: perna distante totalmente oculta por perna próxima no piloto HD dos
dois mobiles, mesma proporção/assento e flip. REQ-02/08: somente Bigfoot/Mage
selecionáveis e como adversários; Escaravelho removido do jogo ativo.
Plano SIDE_PILOT_ROSTER_0_6_4.md. Sem novas armas/rede/ranking/mobile.

## Identidade e harness 0.7 — escopo solicitado

REQ-01/12: o projeto passa a se chamar **Gunbound Recomp** — nome do projeto,
nó raiz, bundle `com.local.gunboundrecomp`, assinatura `GREC`, app/ZIP
`builds/Gunbound Recomp.app`/`Gunbound-Recomp-macOS.zip` e executável interno
`GunboundRecomp` (ASCII). Título do menu e rótulos de QA acompanham; versão
0.7.0. Perfil reinicia em `app_userdata/Gunbound Recomp/` por escolha do
usuário, sem migrar nem apagar o arquivo antigo. `scripts/check.sh` consolida
as14suites headless com logs/saída de falha. Regras, roster, arte e áudio
inalterados; documentos históricos mantêm o nome anterior "Brisa de Aço".

## Mapa Miramo Town 0.8 — escopo solicitado

REQ-21: a arena usa o mapa original Miramo Town A do OpenBound (terreno e fundo),
com derivados HD por GPT Images e colisão pelo alpha original. Arena fixa
1280×800, spawns sorteados da lista original (um por metade), crateras com anel
escurecido como no original. REQ-04/05/08/11/12 relacionados. Terreno
procedural permanece como fallback. Plano e critérios em MAP_0_8.md. Clima,
outros mapas, câmera rolante e partícula de chão continuam fora do escopo.

## Câmera, vento, clima e Thor 0.9 — escopo solicitado

REQ-22 câmera rolante 1:1, REQ-23 vento 2D, REQ-24 clima, REQ-25 Thor,
REQ-26 partícula de chão, conforme WEATHER_CAMERA_0_9.md. Substitui a arena
fixa de REQ-21 (mapa e colisão original mantidos). Outros mapas fora do escopo
por decisão do usuário.

## HUD original de batalha 0.10 — escopo solicitado

REQ-27 barra de ação, REQ-28 barras de força/movimento e carga original,
REQ-29 mira original, REQ-30 bússola, relógio, Delayboard, vida, nome e dano,
conforme HUD_0_10.md. Substitui o console de REQ-03 (teclado e controles na
tela continuam) e muda a altura visível do mundo de REQ-22 para 664 px.

## Popup de opções 0.10.1 — escopo solicitado

REQ-31: ESC/Options abre o `PopupGameOptions` original (sprites originais,
layout do C# × 1,6) em vez da pausa própria; aplica volume SFX, velocidade de
rolagem (arrasto da câmera) e fundo on/off; mira, mouse, BGM e skin aparecem
desabilitados. A pausa continua acessível (P e extra "PAUSA" no popup).
Conforme HUD_0_10.md. Altera a parte "Options abre a pausa" de REQ-27.

## Performance e limites 0.11 — escopo solicitado

REQ-32 troca de turno sem travar (busca da CPU fatiada em frames, plano
idêntico), REQ-33 música de batalha original com o slider BGM, e revisão de
REQ-31 com o popup em HD (GPT Images), conforme PERF_LIMITS_0_11.md.

## Modo de mira 0.12 — escopo solicitado

REQ-34: rádio Aiming Mode do popup ativo; Slice (padrão) mantém o Espaço,
Drag liga o tiro por arraste do mouse, conforme AIMING_0_12.md. Mouse Speed
fica desabilitado com TODO; Interface só com a skin Blue.

## Itens de batalha 0.13 — escopo solicitado

REQ-35 itens usáveis no turno (Dual, Dual+, Thunder, Energy Up 1/2, Team
Teleport, Teleport, Blood, Bunge Shot, Power Up, Change Wind) com a lógica,
física e custos de delay do OpenBound. No turno próprio o item sai do slot
na hora, marcado antes ou clicado agora, e a aura UsingItem acompanha o
mobile (ADR-065). REQ-36 limita a carga a 6 slots; na sala clássica a escolha
é o painel direito, não o modal. REQ-37 arte dos itens/Teleport em HD por GPT Images (Codex) e a
aura UsingItem em 4×, conforme ITEMS_0_13.md. CPU sem itens neste corte.

## Shop de avatar — especificação aprovada

Pedido de 2026-10-12: REQ-38 Shop/compra local em Gold/Cash; REQ-39 composição
de cabeça/corpo/óculos/bandeira; REQ-40 distribuição dos oito atributos; REQ-41
modificadores no combate/previsão e Gold. Saldo inicial de teste e atributos
confirmados pelo usuário. Detalhes e adaptações aprovados em AVATAR_SHOP.md.
Implementado no worktree; plano AVATAR_SHOP_PLAN.md e evidências HANDOFF.md.
ItemDelay aguarda integração dos itens; demais modificadores ativos. Relacionados REQ-02/04–10/12/19/20,
REQ-32 (thread) e REQ-35 (dependência ItemDelay).

REQ-39/19: correção0.14.1 do ponto Body/oclusão de chassis (ADR-060,
AVATAR_MOUNT_FIX.md), validada com metadados originais, poses e ambos os sentidos.

REQ-20/39: derivados GPT Images das13peças de avatar, próximos do estilo2.5D
dos mobiles, integrados no menu, loja/inventário e arena. Registro/pivôs, aspecto
e originais preservados, fallback por peça; detalhes/adaptação em AVATAR_HD.md.

REQ-35/40/41: integração à main0.14.3 resolve ItemDelay pendente e compõe os
modificadores de atributos com Power Up/Blood/Bunge sem multiplicação dupla.
Critérios/evidências em INTEGRATION_MAIN_0_14_3.md e HANDOFF.md.

REQ-10/19/20/38/39: correção solicitada0.14.4 exige anatomia HD registrada,
movimento contínuo nas mudanças de pose e ação Vestir no Shop para itens
possuídos, persistida após recarga e usada na batalha. Plano/critério em
AVATAR_SMOOTH_0_14_4.md; experimentar item não possuído continua temporário.

REQ-20/38/39/40: loja0.14.5 segue a primeira foto de referência: grade3×3,
inventário lateral sempre visível e vestível, prévia/saldo compactos, categorias
no rodapé e atributos em painel separado. Critérios em AVATAR_SHOP_CLASSIC_0_14_5.md.

REQ-20/38/39/40: auditoria0.14.6 contra implementação OpenBound; catálogo,
compra/equipamento/atributos e intervalos de interface conferidos, diferenças
corrigidas e assets raster da UI regenerados em HD. Adaptações já aprovadas
preservadas e explicitadas em AVATAR_SHOP_PARITY_0_14_6.md.

REQ-20/38/39: correção0.14.7 preserva os detalhes da moldura sob os preços e
mostra o efeito real de cada peça: cosmético/sem bônus neste catálogo OpenBound.
Pontos de combate permanecem no painel Atributos do piloto. Plano
AVATAR_CARD_FIX_0_14_7.md; sem novos bônus/regras inventados pela referência.

REQ-20/38: correção0.14.8 retira o borrado do fundo dos preços. O centro da
faixa recebe preenchimento vetorial uniforme; moldura, borda branca e rebites
continuam nos recortes HD/nativos. Texto, retrato e regras preservados.

REQ-20/38/39/40: revisão0.14.9 corrige estado de seleção/falhas de vestir,
legendas sobrepostas e cenário deformado. Usuário confirmou abas sobre os
cards e ordem Experimentar/Vestir→Comprar→Presente do C#. Grade3×3 e lista
lateral mantidas. Plano/critério em AVATAR_SHOP_AUDIT_0_14_9.md.

REQ-20/38/39/40: pedido posterior0.15 adota o vídeo GunboundWcLatam como
referência principal de apresentação. Loja16:9/FullHD, grade3×3, avatar sozinho
com alternância para mobile, inventário compacto com destaque do equipado,
cenário claro regenerado e preços nítidos. Contratos transacionais preservados;
critério/plano em AVATAR_SHOP_VIDEO_0_15.md. Substitui coordenadas0.14.5/0.14.9,
sem mudar catálogo/combate ou atribuir bônus às peças.

## Avatar Shop do cliente XFS 0.16

REQ-20/38/39: reproduzir a interface ciano comprovada no cliente de referência
jglim e nos frames store_* de graphics.xfs, com composição FullHD uniforme,
compra/preview/equipamento funcionais e fallback original. Plano e escopo de
dados em AVATAR_SHOP_XFS_0_16.md; substitui a composição do vídeo de0.15.

REQ-38/39/40/41: esclarecimento posterior exige catálogo avatar.xfs completo,
preços/disponibilidade e bônus de ataque/defesa/etc por equipamento. Exibir
modificadores reais nos cards/conjunto e aplicá-los ao snapshot de combate,
preservando progresso/posses antigas. Corrigir sobreposições de imagem/texto.
A restrição anterior a quinze cosméticos fica substituída para o catálogo XFS.

REQ-10/20/39: pedido posterior exige migração HD completa das peças vestidas e
animadas, além das miniaturas. Controle por registro/camada e critérios em
AVATAR_HD_MIGRATION.md. Cobertura real:550avatares vestíveis/629camadas; padrões
vazios/place holders recebem motivo N/A. Regenerar e integrar todos os componentes
reais, preservando registro, identidade, animação contínua e fallback validado.

REQ-10/20/39 aceitos tecnicamente na0.17:550avatares/629camadas vestíveis e
550miniaturas HD, com controle por registro, evidência GPU e auditoria sem
fallback oculto.37lotes, ambos gêneros/mobiles/sentidos, poses e pausa; animação
por masters constantes, sem reconstrução de cada gesto nativo.12N/A explícitos.
Aplicativo exportado e smoke fora do projeto confirmam o mesmo catálogo/render.

REQ-10/20/39 — revisão0.18: luzes de cabeças animadas devem corresponder ao
mesmo estado da cabeça HD (Normal), sem chifres/ornamentos de Staring deslocados.
Auditar os20modelos de cabeça com camada L e preservar fallback coerente.
Pedido atual também autoriza concluir o HD do Nak introduzido no PR1, substituindo
o adiamento anterior. REQ-19/20 e plano NAK_HD.md; regras físicas preservadas.

REQ-10/20/39: validação do Great Devil exige aura pulsante junto ao contorno
do chifre, com ouro/segmentos preservados. Máscara derivada da peça HD, registro
compartilhado e pausa contínua; HORN_AURA_FIX.md.

Correção do aceite0.18.3: o usuário rejeitou a perda perceptível do brilho e
da animação. Preservar a faixa luminosa HD anterior, sua opacidade e pulsação;
corrigir somente a curva/encaixe sobre o chifre. A exigência de máscara atrás
da cabeça fica substituída. Validar a animação no tamanho real da loja.

REQ-38 — pedido de saldo para testar compras: o perfil padrão inicia com
999.999.999 Gold e 999.999.999 Cash. Perfis existentes com carteira válida
recebem esse saldo uma vez ao iniciar o aplicativo atualizado, preservando
progresso/posses/equipamento. Gravar marcador junto à carteira; gastos e
recargas posteriores preservam o saldo salvo. Falha de gravação reverte a
concessão. Não liberar itens indisponíveis nem alterar preços/bônus.

## Catálogo clássico de avatares — REQ-46

Pedido: manter todos os avatares originais do Gunbound clássico e refazer o
catálogo com equivalência máxima a `jglim/gunbound-launcher` e
`jglim/gunbound-server`. Plano e evidência em `AVATAR_CLASSIC_CATALOG.md`.

O `avatar.xfs` versionado é o TestClient do launcher, versão 280, byte a byte.
São 562 registros nos oito DATs (479 compráveis). `ff.dat` tem contagem zero;
`ff00001.img` e `sff00001.img` existem no `graphics.xfs` e não entram na loja.
Nenhum registro é removido e nenhum avatar posterior à versão 280 é inventado.

A identidade de protocolo segue `gameserver.py`: WORD com o id nos 15 bits
baixos e masculino no bit 15; DWORD com o slot no terceiro byte (corpo 0,
cabeça 1, olho 2, bandeira 3). O conjunto equipado são quatro WORDs nessa
ordem. A categoria interna da loja continua cabeça, corpo, óculos, bandeira,
para não mover chaves já salvas. Textos do DAT usam CP949. Preços, bônus e
arte permanecem os do registro original.

## Avatar Shop original — REQ-47

REQ-47 (ADR-130): a loja reproduz a tela do cliente Thor's Hammer 280 com os
frames originais do `graphics.xfs` (fundo, cards, ícones, botões, fonte e
números), nas posições comprovadas pela rotina de desenho do cliente ou
medidas na captura `gb-avatar.png`. Retratos são os `s*.img` do XFS; a prévia
vestida, a sala e a batalha desenham as peças nativas do avatar. Não há busca,
contador, rótulos em português nem prévia de mobile; gênero e atributos ficam
fora do palco 800×600. Compra, vestir, rollback, atributos, bônus e perfil
continuam os da REQ-38..41/46. Matriz e limites em AVATAR_SHOP_ORIGINAL.md.
