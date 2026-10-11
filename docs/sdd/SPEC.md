# Especificação — protótipo 0.2.0

Status: implementado; validação funcional pelo usuário pendente de relato.
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
| REQ-07 | Três armas; especial no terceiro turno próprio, uma vez por partida | `combat.gd.WEAPONS`, `match.gd.can_use_special` | Modelos + roteiro manual para apresentação da especial |
| REQ-08 | CPU joga com as mesmas regras; três dificuldades por erro de mira | `match.gd.choose_cpu_shot`, `combat.gd.predict` | Modelos e seis partidas completas |
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

## Fora da entrega

Solicitação posterior ao refinamento: **REQ-19 — integrar assets reais de Bigfoot
e outros mobiles a partir do material disponível do OpenBound**, com animações e
tiros correspondentes. A direção original de REQ-11 permanece descrição do
baseline 0.2, mas foi substituída pelo pedido atual para a próxima integração.
Status e origem do pacote externo em [ORIGINAL_ASSETS.md](ORIGINAL_ASSETS.md).
REQ-19 ainda não implementado no jogo: os sprites ausentes do fork foram recebidos
pelo Drive e estão baixados/validados em `.tools/source-assets/content/`.

Multiplayer, salas privadas, busca de adversários, ranking, contas, reconexão,
2×2 e demais formatos, campanha, monetização e distribuição pública.
O protótipo é gratuito. Mobile vem após desktop; UI/UX, controles, cross-play e
progresso compartilhado serão discutidos nessa etapa, sem decisão antecipada.

## Aceitação e limites

A entrega técnica requer testes passando, aplicativo macOS verificável e
documentação de execução. A aceitação funcional final depende do usuário
percorrer `docs/VALIDACAO.md` e relatar o resultado. Testes não substituem avaliação
de diversão, balanceamento, acessibilidade ou uso real de mouse/teclado.
