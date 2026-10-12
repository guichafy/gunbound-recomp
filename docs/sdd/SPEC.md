# Especificação — Gunbound Recomp 0.7.0

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
| REQ-02 | Iniciar treino offline 1×1; escolher apelido, veículo e dificuldade | Menu de `game.gd`; `match.gd.start` | `test_scene.gd` + roteiro manual |
| REQ-03 | Mirar, escolher força e mover com limite por turno; teclado e controles na tela | `game.gd`, `ui.gd`, `match.gd.move_actor` | Modelos, cena/input e roteiro manual |
| REQ-04 | Balística afetada por gravidade/vento, colisão com terreno e veículos, crateras | `combat.gd`, `terrain.gd`, `match.gd` | `test_runner.gd`, partidas completas |
| REQ-05 | Vida, dano por explosão/queda, vitória, derrota e empate | `match.gd`, tela de resultado | Modelos, partidas e cena |
| REQ-06 | Iniciativa por atraso, turno de 30 s, passagem voluntária/automática | `match.gd.schedule`, `pass_turn`, `tick` | Modelos e roteiro manual |
| REQ-07 | Três armas; especial no terceiro turno próprio, uma vez por partida | `match.gd.weapon_rules/can_use_special` | Modelos + roteiro manual para apresentação da especial |
| REQ-08 | CPU joga com as mesmas regras; três dificuldades por erro de mira | `match.gd.choose_cpu_shot/predict_shot`, `combat.gd` | Modelos e dez partidas completas |
| REQ-09 | Pausa congela relógio/voo; ajuda, resultado, revanche e menu navegáveis | `game.gd` | `test_scene.gd` + roteiro manual |
| REQ-10 | Apelido, XP, nível e vitórias locais; recompensa uma vez por resultado | `profile.gd`, `game.gd` | Persistência/corrupção/idempotência e cena |
| REQ-11 | Arte e efeitos originais, sem copiar recursos do Gunbound | `assets/art/`, terreno procedural, `sound.gd` | `docs/ART.md`, capturas visuais |
| REQ-12 | Fonte, documentação e aplicativo permitem validar e aprender | README, guias, fontes, testes e build | Hand-off e roteiro funcional |

## Regras concretas do baseline

- Arena lateral única, 1280×800. Jogador começa; CPU recebe o outro veículo.
- Escaravelho: vida 580, movimento 110, atraso adicional 0.
  Carapaça: vida 700, movimento 80, atraso adicional 18.
- Mira local 10–85°, força 15–100%. Movimento de 60 unidades/s limitado pelo orçamento.
  Deslocar vira o veículo; `F` vira parado. A inclinação do apoio afeta a direção
  do disparo; o indicador junto ao canhão mostra o ângulo efetivo no mundo.
- Pulso: dano máximo 145, raio 46, atraso 100, um projétil.
  Impacto: dano máximo 210, raio 62, atraso 155, um projétil.
  Tempestade: dano máximo 105 por projétil, raio 43, atraso 210, três projéteis.
- Vento inteiro entre −30 e +30 por turno; gravidade 260; integração 120 Hz.
  Dano diminui com a distância, considerando o tamanho do veículo. Queda de mais
  de 70 unidades causa dano; perder suporte até abaixo da ilha elimina.
- Próximo ator é o de menor disponibilidade acumulada; empate favorece o outro.
  Passar custa 80 + atraso do veículo. Não existe alternância estrita obrigatória.
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

## Mage 0.4

REQ-19: Carapaça substituído por Mage (índice 1), selecionável e adversário do
Bigfoot. Atlas/piloto, lasers, orbe, efeitos e sons originais preservados. Vida760,
escudo220 regenerando20 por turno próprio; S1/S2/SS e mira15–50° descritos em
[MAGE_0_4.md](MAGE_0_4.md). Regras por ator alimentam CPU, voo, fila e HUD. S2 tem
dois colliders em hélice; SS EMP zera escudos próximos antes do dano. Delays
normalizados ao protótipo. Bigfoot permanece arena60/menu180 e armas atuais.
Gravidade/força/vento e disponibilidade de SS continuam adaptados ao protótipo.
Não reproduz itens, Thor, resistências ou cliente completo de Gunbound.

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
física e custos de delay do OpenBound; REQ-36 seleção de 6 slots pelo
`PopupSelectItem` original no menu; REQ-37 arte dos itens/Teleport em HD por
GPT Images (Codex), conforme ITEMS_0_13.md. CPU sem itens neste corte.

## Shop de avatar — proposta em revisão

Pedido de 2026-10-12: REQ-38 Shop/compra local em Gold/Cash; REQ-39 composição
de cabeça/corpo/óculos/bandeira; REQ-40 distribuição dos oito atributos; REQ-41
modificadores no combate/previsão e Gold. Saldo inicial de teste e atributos
confirmados pelo usuário. Detalhes e adaptações propostas em AVATAR_SHOP.md.
Não implementado; requisitos em revisão. Relacionados REQ-02/04–10/12/19/20,
REQ-32 (thread) e REQ-35 (dependência ItemDelay).
