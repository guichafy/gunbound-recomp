# Design implementado

## Componentes e responsabilidades

| Arquivo | Responsabilidade |
|---|---|
| `scenes/main.tscn`, `scripts/game.gd` | Cena, menu/HUD, input, pausa, overlays, desenho, efeitos, CPU e recompensa |
| `scripts/ui.gd` | Construção e estilo de controles |
| `scripts/battle_art.gd` | Estado visual separado, interpolação, rodas/canhão, recuo, dano, destruição, explosão e bússola |
| `scripts/bigfoot_sprite.gd` | Atlas Bigfoot, FPS/ciclos, piloto e offsets por quadro, projéteis, nearest por CanvasTexture |
| `scripts/terrain.gd` | Máscara sólida 640×400, células de 2 px, textura, superfície, crateras e raycast DDA |
| `scripts/combat.gd` | Parâmetros das armas, integração, colisão, dano e previsão de trajetória |
| `scripts/match.gd` | Atores, RNG, projéteis, fases, movimento, disponibilidade, CPU e resultado |
| `scripts/profile.gd` | JSON local, saneamento, recompensa e gravação temporária seguida de rename |
| `scripts/sound.gd` | Efeitos PCM originais sintetizados em memória |
| `scripts/build_macos.py` | Exportação, nomes internos ASCII, assinatura ad-hoc, verificação e ZIP |

Os modelos herdam `RefCounted`; apresentação usa `Node2D`/controles Godot.
Não há backend, servidor, banco externo, serviço de conta ou dependência npm.

## Fluxo de partida

`menu → aim → flight → settle → aim`, até `finished`.

- `start`: gera arena, cria dois atores, limpa filas/projéteis/especial e inicia
  o jogador em `aim` com vento, orçamento e 30 segundos novos.
- `aim`: aceita deslocamento e um disparo válido; timeout/passar agenda novo ator.
- `flight`: usa acumulador com passo `1/120 s`; varre todo o segmento entre posições.
- `settle`: espera 0,55 s, acomoda veículos, aplica quedas e decide o resultado
  antes de agendar a próxima ação.
- `finished`: elimina projéteis, emite resultado; a apresentação concede XP uma
  vez e abre as ações de revanche/menu. Ajuda fechada nessa fase restaura resultado.
- Pausa pertence à apresentação, que deixa de avançar a partida e o trabalho da
  CPU. `screen`/overlay da view e `phase` do modelo são estados distintos.

## Contratos e invariantes

`MatchModel` expõe atores, projéteis, fase e uma fila `events`. A view consome os
eventos `turn`, `pass`, `fire`, `explosion`, `damage`, `fall`, `finished` para
som, partículas, texto e resultado. View não calcula dano nem ordena turnos.

`Combat.advance` integra aceleração constante: `a=(vento×1,5, 260)`,
`p'=p+vΔt+aΔt²/2`, `v'=v+aΔt`. Previsão e voo real usam esse integrador e
`trace_segment`: primeiro impacto entre máscara sólida e círculos dos veículos.
O atirador é ignorado somente durante os primeiros 0,15 s em ambos os caminhos.

Na versão 0.2, `MatchModel.body_rotation(index)` estima apoios x±18 a partir da
máscara, descarta apoios distantes e limita a inclinação a ±30°.
`shot_velocity(index, angle, power, weapon)` gira a direção local antes de lançar.
`cannon_pivot` gira o offset do canhão; `muzzle` usa a mesma direção. CPU, view e
voo consomem essa geometria. A mira local pode diferir do ângulo no mundo.

`initiative_preview(weapon)` retorna duas entradas `{actor, ready, delay}`,
incluindo custo do veículo e desempate idêntico ao scheduler, sem alterar estado.
Durante voo/resolução considera a arma do tiro; a view aguarda escolha da CPU
antes de exibir previsão. Vida/identificação são protegidas de sobreposição pelo
reposicionamento do painel da fila.

`BattleArt` guarda apenas poses/tempos; atualiza com o delta de apresentação,
consome eventos e nunca escreve no modelo. A pausa impede seu avanço e cancela
carga. Força sobe 65 pontos/s e dispara a 100% uma vez; botão/Enter mantêm tiro direto.
Os estilos metálicos são gradientes em memória, compartilhados por cor/contorno.

Em 0.3, Bigfoot tem índice 2; CPU usa Carapaça como adversário. `BattleArt` guarda
`pose_age` e reinicia o relógio ao trocar de pose/arma de carga. Recuo usa a arma
registrada em `last_shots`, para não trocar SS por S1 após um turno curto.
Corpo e piloto usam quadros originais, sem rodas/canhão artificiais adicionais.
JSON do piloto mantém arquivo intacto e normaliza sua vírgula final em memória.
O preset inclui esse JSON; o pacote inclui avisos/licença de referência.

Terreno desenhado e colisão derivam da mesma máscara. Explosão altera a máscara,
depois atualiza sua textura. Fragmentos não desabam; veículos perdem suporte e caem.
Os atrasos `ready`/`clock` representam disponibilidade lógica, não segundos reais.

Perfil padrão: `user://profile.json`, versão JSON 1, campos `nickname`, `xp`,
`wins`, `matches`, `awarded`. Nível é derivado. `awarded` retém os últimos 64 IDs
para impedir recompensa repetida recente; não é um histórico ilimitado nem
proteção antifraude. Não renomear `config/name` sem planejar migração do caminho.

## Arte, execução e distribuição

Três PNGs gerados com GPT Images. As regiões dos sprites são selecionadas pela
view; arquivos originais permanecem intactos. Cenário, veículos e canhões são
combinados com terreno e efeitos por código. Fontes são do sistema, com fallback.

Build macOS Universal arm64/x86_64 usa `.tools/macos.zip`. Nome exibido contém
acento; executável/PCK internos usam `BrisaDeAco` para evitar falha de assinatura
observada. Build ad-hoc local sem notarização; só macOS foi testado.
App exportado incorpora a fonte no momento da exportação e exige novo build
após alterações. Caches, templates e binários não entram no Git.

Não há garantia de determinismo entre plataformas nem protocolo de rede definido.
RNG com seed explícita permite cenários repetíveis nos testes atuais.

## Integração Mage 0.4

`mobile_sprite.gd` concentra leitura/recorte/filtragem dos atlas e piloto;
`bigfoot_sprite.gd` e `mage_sprite.gd` fornecem dados/tiros próprios. Mage substitui
Carapaça no índice1. Modelo consulta `weapon_rules`, `aim_limits` e
`projectile_parameters` por ator; view e CPU consomem essas regras. Deslocamento
helicoidal passa por `Combat.sample_position`; `hit_pos` é posição física real
do componente, independente da interpolação visual do veículo.

Escudo integra o estado do modelo, absorve explosões antes de HP e regenera no
turno próprio até220+HPperdido. EMP zera escudo próximo antes da explosão. HUD
mostra barra azul/valor e usa os limites de mira. Eventos carregam veículo de
origem para escolher Fx/áudio mesmo após mudança de turno. Carga da CPU acompanha
plano/arma; recuo usa `last_shots`. Morte Mage completa25quadros antes do resultado.
Detalhes de fonte/adaptações em `MAGE_0_4.md`, avisos/hashes em `assets/openbound/`.

Para salvas, `predict_shot` executa `advance_projectiles` num modelo temporário
com atores duplicados e `Terrain.collision_copy`. Crateras e morte afetam os
componentes restantes na mesma ordem do voo real. A cópia manipula só máscara,
sem imagens/GPU, e não altera recursos ou eventos do modelo vivo.

## Ataques Bigfoot 0.5

`bigfoot_attacks.gd` guarda o perfil e a função `salvo(weapon)` do emitter.
`weapon_rules` escolhe perfil Bigfoot; `aim_limits(index, weapon)` fornece limite
por tiro. `shot_velocity` limita a mira base e depois aplica dispersão espelhada,
e acrescenta força após limitar entrada (T2 aceita componentes11–104%).
Todas as bombas Bigfoot compartilham a origem `muzzle(index, angle, weapon)`.

Projéteis guardam `spawn_at` e `launched`; `flight_elapsed` conta tempo de salva.
Passo fixo lança bombas elegíveis e integra somente o trecho posterior ao spawn.
`age` mede voo, sem contar espera. Bombas pendentes mantêm o voo vivo e não são
desenhadas; `projectile_launch` emite áudio original de cada lançamento.
Pausa não avança relógio da salva. Reinício limpa tempo e projéteis.

CPU executa a salva em cópia de modelo/máscara/atores até12s após último spawn.
Ordem/crateras/dano idênticos ao voo real. Mira do HUD muda por arma; atualização
de limites do slider bloqueia sinais para o thumb antigo não sobrescrever mira.
BigfootSprite desenha Fx originais e áudio de impacto consultando veículo de
origem do evento, mesmo após mudança de turno. Escaravelho e Mage mantêm seus
perfis e formatos anteriores; fonte/adaptações em BIGFOOT_ATTACKS_0_5.

## Derivados HD 0.6

`hd_sheet.gd` renderiza derivados GPT Images com filtragem linear. Metadados de
`assets/hd/atlas_regions.json` guardam grade/dimensões e recortes sem ruído de
alpha≤8/255. Leitura usa números normalizados em int: JSON do Godot retorna
floats, cuja igualdade de Array não corresponde aos arrays de inteiros.
Dimensões/grade devem coincidir com a textura; sem catálogo válido, usa recorte
por alpha da engine. Sem textura/quadro, o consumidor renderiza original.

`mobile_sprite.gd.hd_frame` converte os índices originais para4 quadros por
estado. Aliases BigfootSS-carga/recuoT2 e Mage-recuos preservam a organização
existente; baixa saúde escurece o derivado. O estado/FPS/tempo continua vindo do
mesmo frame_index/BattleArt. A área opaca do quadro original determina destino,
preservando pivô/chão e offsets do piloto, com metadados/imagens cacheados.
Menus usam a imagem maior heroes; arena usa atlas. Tiros/Fx mantêm contagem,
rotação, posição real e duração antiga, selecionando quadros HD proporcionais.
Modelo de combate, terreno e perfil não foram modificados.

`capture_hd_assets.gd` renderiza framebuffer1920×1080 com cena original1280×800
escalada uniformemente1,35 e margem96px de cada lado. O stretch de Window
excluía barras laterais e retornava1728×1080; a captura corrige somente o setup
de QA, sem alterar resolução lógica ou exportação do jogo. Perfis são isolados.
