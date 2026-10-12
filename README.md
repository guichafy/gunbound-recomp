# Gunbound Recomp

Protótipo de artilharia 2D por turnos, inspirado na experiência de Gunbound. Versão **0.10.0**: treino **1×1 contra o computador no macOS**, feito em **Godot 4.7.2 + GDScript**, no mapa Miramo Town do OpenBound com câmera rolante, vento 2D, clima/Thor, o HUD de batalha original do OpenBound (remasterizado em HD) e Bigfoot/Mage com derivados HD do GPT Images.

## Jogar

Abra **`builds/Gunbound Recomp.app`**. O aplicativo é independente: não precisa abrir o editor. Escolha seu apelido, veículo e dificuldade, depois clique em **Iniciar treino**.

Também é possível importar `project.godot` no Godot 4.7.2 e pressionar **F6** na cena `scenes/main.tscn`, ou **F5** para executar o projeto.

| Controle | Ação |
|---|---|
| A/D ou ←/→ | Mover e virar, consumindo o orçamento do turno (barra de movimento) |
| W/S ou ↑/↓ | Mira: 1° por toque; segurar repete cada vez mais rápido |
| Espaço, segurar e soltar | A barra de força enche de 0 a 100 em 2 s; soltar dispara, cheia dispara sozinha |
| Tab ou 1/2/3 | Trocar o tiro S1 / S2 / SS (botões da barra) |
| F8 ou botão PASS | Passar o turno |
| Esc ou botão ESC | Opções (popup original: SFX, rolagem, fundo) |
| P ou PAUSA no popup | Pausa (recomeçar, menu, ajuda) |
| Modo Drag (ESC → Aiming Mode) | Segurar o botão esquerdo no mapa e arrastar → define a força; soltar dispara. Botão direito olha o mapa |

A batalha toca os temas originais do OpenBound (volume no BGM do popup).
| F | Virar parado |
| H | Ajuda |

O HUD é o do OpenBound: barra de ação com botões S1/S2/SS, ângulo atual e LAST, barra de força com marcador do tiro anterior e um seletor arrastável (só referência), barra de movimento, previsão de clima, Delayboard (ordem e atraso), bússola, relógio do turno, mira com a faixa legal do mobile, barra de vida, nome e contador de dano. Botões pequenos acima da barra (← → F ●) permitem jogar só com mouse/toque; o ● segura para carregar. Ver [HUD_0_10.md](docs/sdd/HUD_0_10.md).

## Regras deste protótipo

- Mage: **760 de vida, 220 de escudo, 90 de movimento**; mira15–50°. Regenera20 de escudo por turno próprio, até220+vida perdida. Laser150; duplo laser200 por componente em hélice; EMP200 que zera escudos próximos. Cratera25, delays100/120/173,33. Enfrenta Bigfoot como CPU.
- Bigfoot: **1100 de vida e 90 de movimento**; seleção inicial. Derivados HD com originais preservados; T1 quatro bombas sequenciais, T2 duas rajadas de três, SS oito bombas sequenciais. Danos90/70/90 por bomba, raio25, mira18–40° (SS23–35°). Efeitos HD e áudio originais.
- O dano diminui com a distância da explosão. Quedas grandes também causam dano; cair da ilha elimina o veículo.
- Vento muda a cada turno. Gravidade e vento afetam todos os disparos.
- O ator com menor disponibilidade acumulada joga primeiro. Um disparo leve pode permitir agir novamente antes de um adversário com muito atraso.
- Cada decisão tem 30 segundos. Esgotar o tempo passa o turno. Pausa congela relógio, projéteis e animações; cancela uma carga em andamento sem disparar.
- Vitória: 120 XP. Derrota: 45 XP. Empate: 70 XP. A cada 200 XP, aumenta um nível. A recompensa é concedida uma vez por partida concluída.
- Mage usa dados do fork com balística/delays adaptados à arena. Detalhes e limites em [MAGE_0_4.md](docs/sdd/MAGE_0_4.md). Bigfoot usa o emitter original com as adaptações em [BIGFOOT_ATTACKS_0_5.md](docs/sdd/BIGFOOT_ATTACKS_0_5.md).

## Conteúdo entregue

Arena destrutível, dois veículos, três armas, três dificuldades de mira, vida/dano/queda, fila de atraso, efeitos visuais e sonoros, pausa, ajuda, resultado, revanche e perfil local. HUD de batalha original do OpenBound (HD), bússola, inclinação, mira com faixa legal, carga de 0 a 100 e animações de repouso, movimento, recuo, dano e destruição. Explosões com clarão, detritos e fumaça. As dificuldades mudam o erro de mira da máquina; não alteram vida/dano. A máquina usa a mesma física e conversão de inclinação do disparo real.

Apelido, XP, nível e vitórias ficam em `~/Library/Application Support/Godot/app_userdata/Gunbound Recomp/profile.json`. Os testes usam arquivos separados e não alteram esse progresso.

## Para aprender com o resultado

Leia [docs/APRENDIZADO.md](docs/APRENDIZADO.md), depois abra os arquivos nessa ordem: `scripts/terrain.gd`, `scripts/combat.gd`, `scripts/match.gd`, `scripts/profile.gd` e `scripts/game.gd`.

O design e o plano estão em `docs/superpowers/`. O roteiro de validação funcional está em [docs/VALIDACAO.md](docs/VALIDACAO.md). Os prompts e a origem das imagens estão em [docs/ART.md](docs/ART.md).

## Contexto para próximas sessões (SDD)

Comece por [docs/sdd/HANDOFF.md](docs/sdd/HANDOFF.md). O [índice SDD](docs/sdd/README.md) reúne requisitos, arquitetura, decisões e tarefas rastreáveis. [AGENTS.md](AGENTS.md) orienta a retomada por agentes. Código, arte e documentação são versionados; builds, templates e cache são locais. Uma cópia obtida pelo Git precisa importar os recursos e preparar `.tools/`, conforme o hand-off.

## Executar testes

```sh
mkdir -p .tools
./scripts/check.sh          # roda todas as suites e consolida o resultado
./scripts/check.sh --quick  # sem as dez partidas completas
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_runner.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_refinement.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_refinement_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_bigfoot.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_mage.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_mage_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_bigfoot_attacks.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_bigfoot_attacks_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_hd_assets.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_mobile_animation.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_pilot_projectiles.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_roster.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_matches.gd
```

`test_runner` cobre regras e persistência; `test_scene` percorre a cena real; as duas suites `test_refinement*` cobrem encostas, fila, carga e animação; `test_matches` simula dez partidas completas. Modelos e cenas somam251verificações. Total atual com HD/animação/piloto/roster:825verificações e dez partidas, incluindo Bigfoot/Mage. Bigfoot tem56 checks de ataques e14 de cena adicionais. Mage tem36 checks de combate/atlas e15 de cena; a salva prevê crateras em cópia isolada do modelo. `tests/capture.gd` renderiza capturas de QA, incluindo carga; a tela de resultado usa uma condição controlada, sem escrever no perfil do jogador.

## Exportar novamente

Somente Mage e Bigfoot estão disponíveis, tanto na seleção quanto como CPU. O especial de cada um desbloqueia no terceiro turno próprio e pode ser usado uma vez por partida.

O preset `macOS` usa o modelo oficial em `.tools/macos.zip`, baixado da release Godot 4.7.2. Ele gera um aplicativo Universal (Apple Silicon e Intel), assinado ad-hoc para teste local:

O template e o aplicativo não entram no Git. Para reconstruir em outro checkout, siga a preparação em [docs/sdd/HANDOFF.md](docs/sdd/HANDOFF.md).

```sh
python3 scripts/build_macos.py
```

Este build foi feito para validação local, sem publicação ou notarização Apple. Somente macOS foi validado. A engine mantém suporte aos demais alvos acordados; builds Windows/Linux e adaptação mobile são etapas posteriores.

O script exporta pelo Godot, normaliza os nomes internos do executável/pacote para `GunboundRecomp` (ASCII, sem espaço), assina e verifica o aplicativo, e gera um ZIP. Essa normalização corrigiu um selo inválido observado no exportador ao usar nomes internos com acento.

## Roadmap

Multiplayer online, salas privadas, busca automática, ranking, reconexão e 2×2+. Mobile após desktop: adaptar UI/UX e discutir cross-play e progresso compartilhado. Nada disso faz parte desta entrega offline.

## Limitações conhecidas

Um mapa original do OpenBound (Miramo Town A em escala nativa com câmera rolante, terreno HD via GPT Images e colisão pelo alpha original), vento 2D, clima (Força, Fraqueza, Espelho, Tornado, Elétrico, Aleatório, Proteção), satélite Thor, partículas de chão e dois veículos; sem campanha, contas, ranking ou multiplayer. A IA calcula o disparo, mas não desloca seu veículo. O terreno tem resolução de colisão de dois pixels e fragmentos flutuantes permanecem no lugar; somente os veículos caem. Bigfoot e Mage usam peças HD constantes articuladas, animação contínua e piloto preso ao assento; os atlas originais ficam disponíveis como fallback. Balanceamento provisório. A pesquisa dos vídeos/OpenBound está em [docs/sdd/GUNBOUND_REFERENCES.md](docs/sdd/GUNBOUND_REFERENCES.md); sprites originais Bigfoot/Mage e piloto foram incorporados, com proveniência em `assets/openbound/ATTRIBUTION.md`; demais mobiles e regras completas Gunbound continuam pendentes.

## Assets HD 0.6

Bigfoot, Mage, piloto, tiros e explosões redesenhados com GPT Images integrado.
[Amostra Full HD](docs/hd/bigfoot-menu.png), [salva SS](docs/hd/bigfoot-ss.png),
[MageEMP](docs/hd/mage-ss-impact.png). Originais preservados; menos quadros chave
por ciclo, duração/estados e combate inalterados. Plano/limites em
[HD_ASSETS_0_6.md](docs/sdd/HD_ASSETS_0_6.md); prompts em
[GENERATION.json](assets/hd/GENERATION.json).439checks+10partidas, zero falhas.

```sh
python3 scripts/catalog_hd_assets.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_hd_assets.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_hd_assets.gd
```

## Correção de animações 0.6.1

Peças Bigfoot/Mage redesenhadas com GPT Images e animadas com pivôs fixos.
Rodas acompanham deslocamento; suspensão, carga, recuo, dano e morte são
contínuos. O piloto conserva proporções e acompanha o corpo; auras não
redimensionam o carro. [Prévia animada](docs/animation/animation.gif),
[vídeo](docs/animation/animation.mp4), [plano/validação](docs/sdd/ANIMATION_FIX_0_6_1.md).

## Personagem e tiros 0.6.2

Piloto completo com encaixe no assento, tiros com forma constante, chamas para
trás, lasers com rastro contínuo e impactos suavizados. Física, dano e salvas
preservados. [Piloto em encostas](docs/projectiles/pilot-poses.png),
[prévia dos tiros](docs/projectiles/shots.gif),
[plano/validação](docs/sdd/PILOT_SHOTS_FIX_0_6_2.md).783checks sem falhas.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_hd_assets.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_mobile_animation.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_pilot_projectiles.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_pilot_projectiles.gd
```

## Composição corrigida 0.6.3

Piloto, rodas e arma recalibrados pela proporção original, com novo encaixe no
assento e peças sem esticar. Menu e arena usam o mesmo conjunto. Compare
[original e HD em encostas](docs/composition/comparison.png) ou veja a
[prévia animada](docs/composition/composition.gif). Tiros0.6.2 preservados.
Plano em [COMPOSITION_FIX_0_6_3.md](docs/sdd/COMPOSITION_FIX_0_6_3.md).

## Piloto em perfil e roster0.6.4

Perna distante oculta no novo mestre GPT Images, preservando a proporção e o
assento. Apenas Bigfoot/Mage no menu e nas partidas; Escaravelho removido.
Fontes históricas preservadas, assets Escaravelho/Carapaça excluídos do pacote.
[Prévia dos dois mobiles](docs/occlusion/pilot-mobiles.png),
[animação](docs/occlusion/pilot.gif),
[plano/evidência](docs/sdd/SIDE_PILOT_ROSTER_0_6_4.md).825checks e10partidas sem falhas.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_roster.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_side_pilot.gd
```

## Identidade 0.7.0

O projeto passa a se chamar **Gunbound Recomp**: nome do projeto, menu,
`Gunbound Recomp.app`, `Gunbound-Recomp-macOS.zip`, bundle
`com.local.gunboundrecomp` e executável interno `GunboundRecomp`. O progresso
recomeça em `app_userdata/Gunbound Recomp/` — o perfil antigo não foi migrado
nem apagado. `scripts/check.sh` consolidou o harness de testes. Regras, roster,
arte e áudio são os mesmos de0.6.4.

## Shop de avatar 0.14.0

No menu, abra **Shop de avatar**. Cabeça, corpo, óculos e bandeira usam o
catálogo e os preços do OpenBound. Experimente sem equipar; compre com Gold ou
Cash; na aba Inventário, clique para equipar. Masculino/feminino mantêm seus
conjuntos, com acessórios unissex compartilhados.

O perfil recebe uma única vez 1.000 de cada moeda para teste. Os oito atributos
liberam 10 pontos por avanço do nível local (teto 180, máximo 50 por atributo);
confirme para aplicar na próxima partida. O combate e a CPU usam os mesmos
modificadores. Gold da partida e bônus de Popularity seguem o fluxo C#; XP
continua separado. ItemDelay tem fórmula, mas depende da integração dos itens.

[Especificação](docs/sdd/AVATAR_SHOP.md), [capturas](docs/avatar-shop/inventory.png).
Arte dos avatares/interface original; nenhum derivado GPT novo foi gerado.

### Avatares HD0.14.2

As13peças visíveis agora têm derivados GPT Images no mesmo acabamento2.5D dos
mobiles. Retratos e piloto usam a mesma arte, com encaixe preservado.
[Inventário HD](docs/avatar-shop/inventory.png) · [Conjuntos](docs/avatar-shop/hd-roster.png).
Originais mantidos para referência/fallback; prompts em assets/hd/avatars/GENERATION.json.
