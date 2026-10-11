# Brisa de Aço

Protótipo original de artilharia 2D por turnos, inspirado na experiência de Gunbound. Versão **0.2.0**: treino **1×1 contra o computador no macOS**, feito em **Godot 4.7.2 + GDScript**, com painel clássico, mira em encostas e animações de combate.

## Jogar

Abra **`builds/Brisa de Aco.app`**. O aplicativo é independente: não precisa abrir o editor. Escolha seu apelido, veículo e dificuldade, depois clique em **Iniciar treino**.

Também é possível importar `project.godot` no Godot 4.7.2 e pressionar **F6** na cena `scenes/main.tscn`, ou **F5** para executar o projeto.

| Controle | Ação |
|---|---|
| A/D ou ←/→ | Mover e virar, consumindo o orçamento do turno |
| W/S ou ↑/↓ | Ajustar a mira relativa à inclinação do veículo |
| Espaço, segurar e soltar | Carregar e disparar; a 100%, dispara automaticamente |
| Botão Disparar / Enter | Disparar com a força selecionada |
| 1/2/3 | Pulso / Impacto / Tempestade (botão SS) |
| F | Virar parado |
| Esc | Pausar / continuar |
| H ou ? | Ajuda |

Os controles na tela oferecem as mesmas ações. A barra graduada registra a força anterior. A mira circular mostra a direção inicial e seu ângulo efetivo no mundo, sem prever a trajetória completa. O controle inferior mostra o ângulo relativo ao veículo; em uma encosta os dois valores podem ser diferentes.

A fila lateral mostra quem está ativo e a ordem prevista depois da arma escolhida. Enquanto a CPU escolhe a arma, ela aguarda essa escolha para calcular a previsão. O painel muda para o canto superior se uma queda colocar a vida do veículo atrás dele.

## Regras deste protótipo

- Escaravelho: **580 de vida, 110 de movimento**, recuperação mais rápida.
- Carapaça: **700 de vida, 80 de movimento**, 18 unidades adicionais de atraso.
- Pulso: 145 de dano máximo, cratera de 46 unidades, atraso 100.
- Impacto: 210 de dano máximo, cratera de 62 unidades, atraso 155.
- Tempestade: três projéteis, até 105 de dano por projétil, atraso 210. Desbloqueia no terceiro turno próprio e só pode ser usada uma vez por partida.
- O dano diminui com a distância da explosão. Quedas grandes também causam dano; cair da ilha elimina o veículo.
- Vento muda a cada turno. Gravidade e vento afetam todos os disparos.
- O ator com menor disponibilidade acumulada joga primeiro. Um disparo leve pode permitir agir novamente antes de um adversário com muito atraso.
- Cada decisão tem 30 segundos. Esgotar o tempo passa o turno. Pausa congela relógio, projéteis e animações; cancela uma carga em andamento sem disparar.
- Vitória: 120 XP. Derrota: 45 XP. Empate: 70 XP. A cada 200 XP, aumenta um nível. A recompensa é concedida uma vez por partida concluída.
- Os números são valores originais para validação e balanceamento, não uma reprodução exata dos dados do Gunbound.

## Conteúdo entregue

Arena destrutível, dois veículos, três armas, três dificuldades de mira, vida/dano/queda, fila de atraso, efeitos visuais e sonoros, pausa, ajuda, resultado, revanche e perfil local. HUD azul metálico, bússola, inclinação, mira graduada, carga monotônica e animações de repouso, movimento, recuo, dano e destruição. Explosões com clarão, detritos e fumaça. As dificuldades mudam o erro de mira da máquina; não alteram vida/dano. A máquina usa a mesma física e conversão de inclinação do disparo real.

Apelido, XP, nível e vitórias ficam em `~/Library/Application Support/Godot/app_userdata/Brisa de Aço/profile.json`. Os testes usam arquivos separados e não alteram esse progresso.

## Para aprender com o resultado

Leia [docs/APRENDIZADO.md](docs/APRENDIZADO.md), depois abra os arquivos nessa ordem: `scripts/terrain.gd`, `scripts/combat.gd`, `scripts/match.gd`, `scripts/profile.gd` e `scripts/game.gd`.

O design e o plano estão em `docs/superpowers/`. O roteiro de validação funcional está em [docs/VALIDACAO.md](docs/VALIDACAO.md). Os prompts e a origem das imagens estão em [docs/ART.md](docs/ART.md).

## Contexto para próximas sessões (SDD)

Comece por [docs/sdd/HANDOFF.md](docs/sdd/HANDOFF.md). O [índice SDD](docs/sdd/README.md) reúne requisitos, arquitetura, decisões e tarefas rastreáveis. [AGENTS.md](AGENTS.md) orienta a retomada por agentes. Código, arte e documentação são versionados; builds, templates e cache são locais. Uma cópia obtida pelo Git precisa importar os recursos e preparar `.tools/`, conforme o hand-off.

## Executar testes

```sh
mkdir -p .tools
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_runner.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_refinement.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_refinement_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_matches.gd
```

`test_runner` cobre regras e persistência; `test_scene` percorre a cena real; as duas suites `test_refinement*` cobrem encostas, fila, carga e animação; `test_matches` simula seis partidas completas. Total atual: 102 verificações e seis partidas. `tests/capture.gd` renderiza capturas de QA, incluindo carga; a tela de resultado usa uma condição controlada, sem escrever no perfil do jogador.

## Exportar novamente

O preset `macOS` usa o modelo oficial em `.tools/macos.zip`, baixado da release Godot 4.7.2. Ele gera um aplicativo Universal (Apple Silicon e Intel), assinado ad-hoc para teste local:

O template e o aplicativo não entram no Git. Para reconstruir em outro checkout, siga a preparação em [docs/sdd/HANDOFF.md](docs/sdd/HANDOFF.md).

```sh
python3 scripts/build_macos.py
```

Este build foi feito para validação local, sem publicação ou notarização Apple. Somente macOS foi validado. A engine mantém suporte aos demais alvos acordados; builds Windows/Linux e adaptação mobile são etapas posteriores.

O script exporta pelo Godot, normaliza os nomes internos do executável/pacote para `BrisaDeAco` (mantendo o título visível com acento), assina e verifica o aplicativo, e gera um ZIP. Essa normalização corrigiu um selo inválido observado no exportador ao usar o nome com acento.

## Roadmap

Multiplayer online, salas privadas, busca automática, ranking, reconexão e 2×2+. Mobile após desktop: adaptar UI/UX e discutir cross-play e progresso compartilhado. Nada disso faz parte desta entrega offline.

## Limitações conhecidas

Um mapa e dois veículos; sem campanha, contas, ranking ou multiplayer. A IA calcula o disparo, mas não desloca seu veículo. O terreno tem resolução de colisão de dois pixels e fragmentos flutuantes permanecem no lugar; somente os veículos caem. Animações usam transformações, rodas/canhão e efeitos por código sobre PNGs originais, sem spritesheets oficiais. Câmera fixa e balanceamento provisório. A pesquisa dos vídeos/OpenBound está em [docs/sdd/GUNBOUND_REFERENCES.md](docs/sdd/GUNBOUND_REFERENCES.md); nenhum código ou asset do fork foi incorporado.
