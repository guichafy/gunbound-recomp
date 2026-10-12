# Performance da batalha e revisão dos limites 0.11 — especificação e plano

## Pedido

"Devemos implementar e rever os limites. Exemplo: item popup precisa ser gerado
no Codex com GPT Image a versão Full HD. Além disso, entre as trocas de turno
estou percebendo problemas de performance ou travamento de frame (vamos
melhorar a performance da batalha)." (2026-10-11, após a 0.10.1.)

## Diagnóstico medido (antes)

`choose_cpu_shot` avalia a grade completa de ângulo × força (≈105–150
previsões de ~3 ms cada, no laço de voo comum) **num único frame** quando o
turno da CPU começa. Medido no app com renderização Metal (M4 Pro): picos de
**90–100 ms** em `aim1` durante a partida e até **200–314 ms** em medições
isoladas; demais frames ≈ 0,35 ms de `_process`. Crateras custam ~2 ms com a
GPU (atualização da textura HD 2560×661), sem pico relevante. O pico de
~50 ms no primeiro frame é carregamento de texturas, não troca de turno.

## Requisitos

- **REQ-32 — Troca de turno sem travar.** A busca da mira da CPU roda numa
  thread do `WorkerThreadPool` sobre um retrato do estado tirado no início do
  turno da CPU (máscara de colisão, atores, vento, clima). Em três passos:
  `begin_cpu_plan` (vira para o alvo, sorteia a arma, tira o retrato),
  `search_cpu_plan` (só a grade, sem RNG nem estado vivo) e
  `finish_cpu_plan` (sorteia os erros de mira na thread principal). Grade,
  sorteios e erros são os mesmos: o plano é idêntico ao da busca única
  (`choose_cpu_shot` continua como wrapper, usado pelos testes de modelo e
  pelas partidas completas). A apresentação não muda: `cpu_plan` só é
  preenchido quando a busca termina e a espera inicial (1,1 s) vence; depois
  a pose de carga dura 0,75 s como antes. Recomeçar, voltar ao menu, nova
  troca de turno ou sair da cena esperam a thread terminar e descartam a
  busca. Diferença visível: a CPU vira para o alvo no início do turno, não
  após 1,1 s.

  Primeira tentativa (descartada): fatiar a busca em frames com orçamento de
  5 ms. Eliminava os picos, mas a CPU passava a disparar em ~3,3 s em vez de
  ~1,9 s, porque a grade inteira leva ~0,5 s de CPU.
- **REQ-33 — Música de batalha original (BGM).** A batalha toca as 12 faixas
  `Audio/Music/LevelScene/Theme*` do OpenBound (`SongParameter.LevelScene`):
  uma faixa aleatória ao iniciar a partida e outra aleatória quando ela
  termina (`AudioHandler.PlayRandomSong`), parando no menu. Volume pelo
  slider BGM do popup (0 silencia; padrão 50), gravado com as demais opções;
  o "Som" da pausa silencia música e efeitos. Testes e áudio mudo nunca
  tocam música. Sem música no menu (o menu deste jogo não corresponde às
  telas de sala/servidor do original).
- **REQ-31 (revisão) — Popup em HD.** Fundo, Accept (4 estados) e
  RadioButton do popup ganham derivados GPT Images 3× (Codex `image_gen`,
  folha `options` em `build_hud_hd.py`, alfa original); Bar, BarFrame e o
  ponteiro são ampliados direto. O popup usa o HD quando presente e cai no
  original sem ele; as regiões de quadro escalam pela densidade da textura.

## Limites revistos

| Limite 0.10.1 | Decisão 0.11 |
|---|---|
| Popup sem HD | Implementado (REQ-31 revisão) |
| BGM sem música | Implementado (REQ-33) |
| Travamento na troca de turno | Corrigido (REQ-32) |
| Aiming Mode Drag/Slice | Mantido: não há implementação no OpenBound (desativado no C#) nem mira por mouse aqui |
| Mouse Speed | Mantido: controla o cursor do sistema, que o jogo não altera |
| Interface (skins) | Mantido: o pacote só tem a skin Blue em `Interface/InGame/HUD/` |
| Fonte Consolas | Mantido: proprietária e fora do pacote; usa a monoespaçada do sistema |
| Popup pausa o treino | Mantido por decisão (treino offline) |

## Fases

A. Especificação, folha `options` no pipeline HD e geração no Codex (fundo).
B. Busca da CPU em thread (match.gd/game.gd), teste de equivalência, medição.
C. BGM: cópia das faixas com SHA, player de música, slider ativo.
D. Integração do HD do popup, testes, capturas, docs, reexportação do app.

## Resultado medido (depois)

Roteiro local `.tools/profile_live.gd` (não versionado; `VEHICLE=1|2`), 60 FPS
no app com Metal, M4 Pro, seis turnos da CPU por cenário:

| Cenário | Pior frame no turno da CPU (antes → depois) | Disparo da CPU após o início do turno (antes → depois) |
|---|---|---|
| Jogador Bigfoot × CPU Mage | 160–185 ms → 17,7 ms | 1,88–1,90 s → 1,83–1,87 s |
| Jogador Mage × CPU Bigfoot (salvas, SS incluído) | 336–484 ms → 17,8 ms | 2,05–2,20 s → 1,83–1,87 s |

17–18 ms é o frame normal a 60 FPS. Partidas seeds 81–90 idênticas
(56/12/13/15/19/10/8/12/9/15 tiros). test_performance cobre a equivalência
direta = em passos = em thread com CPU Mage e CPU Bigfoot (T1, T2 e SS). O
pico de ~45 ms no primeiro frame da partida (carga de texturas) continua e
não é troca de turno. Máquinas mais lentas terão números diferentes.
