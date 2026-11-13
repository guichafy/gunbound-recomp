# Mapas clássicos ausentes — plano de implementação da issue #45

> Para execução futura: usar `superpowers:executing-plans` por etapas, após
> autorização de implementação. As caixas abaixo estão abertas porque esta
> entrega é pesquisa e planejamento, sem alteração do jogo.

**Objetivo:** tornar selecionáveis no treino offline os mapas comprovados
da build Thor's Hammer preservada, conservando Miramo Town A e distinguindo
variantes existentes, metadados sem recursos e adaptações locais.

**Arquitetura proposta:** catálogo por variante com identidade nativa separada
da chave local, recursos validados e configuração de clima/spawn explícita.
Sala resolve um contexto imutável de partida uma vez, compartilhado por
loading e `Match.start`; terreno/CPU continuam no laço físico comum.

**Tecnologia:** Godot 4.7.2/GDScript; leitores Python IMG/XFS/LZHUF já existentes;
Ghidra 12.2/JDK26 e LLVM objdump para evidência, sem dependência nova no jogo.

**Contrato:** [issue #45](https://github.com/guichafy/gunbound-recomp/issues/45),
[SPEC.md](SPEC.md), [DESIGN.md](DESIGN.md), ADR-132/133/134/138/153/158/159.
Pesquisa em 12/11/2026, worktree própria `bb36/DemoGame`, branch
`codex/issue-45-classic-maps-plan`. A integração documental ocupa a posição 3,
depois de #43 e #44 e antes de #46; merge somente após liberação explícita.

## Escopo e decisões de planejamento

- Esta solicitação supera a exclusão anterior de novos mapas somente para
  pesquisa/plano. Não ativa um seletor nem autoriza a implementação futura.
- Só a build Thor's Hammer pinada. Sem consulta a OpenBound, arte HD nova,
  rede/multiplayer, alterações de perfil, IDs dos mobiles ou regras de armas.
- Preservar originais, `.gd.uid`, `.png.import`, arte já aprovada da sala,
  holding de loading de 5 s e Miramo A como padrão, inclusive seus spawns
  legados. Novos spawns serão adaptação offline identificada quando a prova
  do cliente não for suficiente.
- Preferência técnica do plano: implementar os 10 A ausentes em lotes;
  B e Random entram somente quando seus próprios contratos estiverem fechados.
  Não criar um B copiando A só porque o DAT nomeia ambos.
- Recursos faltantes de uma escolha nova impedem Start e conservam a sala;
  não apresentar prévia de um mapa e iniciar silenciosamente o procedural.
  O fallback procedural explícito de fixtures `start(..., "")` permanece.
- A entrega futura deverá reservar os novos números REQ/ADR na main atual,
  antes do código. Esta pesquisa usa critérios locais M45-1..6 para evitar
  colisão de numeração com as entregas paralelas; não são REQs já implementados.

## Fontes e identidade

Fonte primária: [TestClient de jglim/gunbound-launcher](https://github.com/jglim/gunbound-launcher/tree/2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1/TestClient).
Hashes SHA-256:

| Arquivo | Identidade |
|---|---|
| `GunBound.gme` | `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde` |
| `graphics.xfs` | `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08` |
| `stage.dat` | `103c2b488977e1721becf8cb90496f95477302ec24141f94116d5214a3e6cfca` |
| `sound.xfs` | `081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023` |

[Inventário reproduzível](../maps-issue-45/README.md),
[dados completos](../maps-issue-45/inventory.json) e
[spawns auxiliares](../maps-issue-45/server-spawns.json) acompanham o plano.
O inventário contém os 22 nomes não vazios dentre 32 slots, pesos e três
conjuntos de oito ranges de clima por registro. IDs abaixo são índices desse
DAT, não o `openbound_id=20` histórico de `maps.gd` nem IDs dos mobiles.

## Inventário por família/variante

`IMG` contém quadros de terreno/fundo; `LND` contém largura/altura u32 LE e
um byte por pixel. Nos 14 prefixos referenciados que possuem LND, as dimensões
do cabeçalho coincidem com o quadro 0 IMG. A equivalência alpha↔LND de todos
os pixels ainda precisa ser validada na importação; não extrapolar a prova
já existente de Miramo A.

| Família: índice A/B | Prefixo A; mundo / fundo (px) | Partículas A | Situação B no XFS | Música por família |
|---|---|---:|---|---|
| Cave(Random): 0/11 | `cave`; 1800² / 1300² | `pcave`: 62 | `caveb.img/lnd` ausentes; loading 11 existe | fallback `stage1..6` |
| MiramoTown: 1/12 | `mos`; 1800² / 1300² | `pmos`: 60 | `mosb.img/lnd` e loading 12 ausentes | `stage1` |
| Nirvana: 2/13 | `hok`; 1600² / 1200² | `phok`: 64 | `hokb.img` tem terreno 1600² + fundo 1200²; `hokb.lnd`, loading 13 presentes | `stage2` |
| Metropolis: 3/14 | `metro`; 1800² / 1300² | `pmetro`: 54 | `metroB.img/lnd` e loading 14 ausentes | `stage3` |
| SeaOfHero: 4/15 | `candy`; 1600² / 1200² | `pcandy`: 44 | `candyb.img/lnd` e loading 15 ausentes | `stage4` |
| AdiumRoot: 5/16 | `babo`; 1800² / 1300² | `pbabo`: 42 | `babob.img/lnd` e loading 16 ausentes | `stage5` |
| Dragon: 6/17 | `last`; 2000² / 1300² | `plast`: 44 | `lastb.img/lnd` e loading 17 ausentes | `stage6` |
| CozyTower: 7/18 | `brick`; 1800² / 1300² | `pbrick`: 40 | `brickb.img` só terreno 1800²; LND e loading 18 presentes | fallback `stage1..6` |
| DummySlope: 8/19 | `kettle`; 1600² / 1200² | `pkettle`: 44 | `kettleb.img/lnd` e loading 19 ausentes | fallback `stage1..6` |
| StarDust: 9/20 | `star`; 1800² / 1300² | `pstar`: 64 | `starb.img/lnd` e loading 20 ausentes | fallback `stage1..6` |
| MetaMine: 10/21 | `facky`; 1800² / 1300² | `pfacky`: 42 | `fackyb.img` só terreno 1800²; LND e loading 21 presentes | fallback `stage1..6` |

Todos os A possuem IMG, LND e `load_stage00..10.img` (dois quadros 748×209).
Nenhum prefixo B possui `p<prefixoB>.img`. Herança de partículas/fundo não
foi comprovada: é dependência explícita da etapa B, não alias automático.
Há ainda `dragon.lnd` fora dos prefixos do DAT; não se cria mapa jogável
apenas pela existência desse recurso.

UI existente no cliente: `ready_selectmap.img` tem 22 quadros 136×84 e já
está inteiro no atlas da sala; `gameliststage.img` tem 22 quadros 68×18;
`selectmap.img` tem 11 quadros 300×107; `stage.img` tem 13 quadros 208×102.
`loadstage.img` tem 22 quadros 748×228, organizados como pares prévia/máscara
por família no consumidor `0x4430c0`. Não confundir esses pares com 22
variantes A/B nem misturar linhas de máscara 228 com as de loading 209.
As entradas `load_stage11/13/18/21` não provam a disponibilidade da variante
no fluxo nativo: são recursos adicionais, que exigem vínculo por consumidor.

## Matriz de evidência e lacunas

| Comportamento | Fonte/unidade/ordem | Classe e consequência |
|---|---|---|
| Registros/nome/prefixo/clima | `stage.dat`, 484 bytes por registro, loader `0x419d90` | **Comprovado em dados e consumidor**; dois u16 em 256/258 mantidos como `flags`, sem atribuir semântica |
| Arquivos/dimensões/pivôs | TOC XFS, cabeçalhos IMG, LND | **Comprovado em dados**; não é render ou colisão executada |
| Carregamento LND | `0x4e3c50`: acrescenta `.lnd`, aloca máscaras, lê dimensões/bytes; recebe prefixo pelo EAX | **Comprovado estático**; confirmar erro/recurso ausente antes de portar B |
| Prefixo para terreno | ASM `0x43f13e..43f23b`: índice `+0x475c4`, stride `0x7d28`, prefixo `+0x1a1ec8`, chama `0x4e3c50` | **Comprovado no trecho**; ramo/estado B completo ainda não fechado |
| Índice recebido | ASM `0x4d4004..0x4d4038`: lê byte, grava resto por 11 | **Comprovado naquele caminho**; não prova que todo fluxo ignora lado B |
| Nome no loading | `0x4430c0`: quadro `2*índice+1`; x=`spawn_x*748/max(largura,1)`; primeiro u16 não zero até 209; y=linha+18, fallback122 | **Comprovado estático**; clamp x do porte é proteção local; usar máscara da prévia realmente exibida |
| Música | `0x4bb730`, ASM anexado e [ADR-153](CLIENT_MUSIC_SCREENS.md) | **Comprovado estático**: `stage%d` com família; falha sorteia 1..6; resultado conserva faixa |
| Spawns por família/lado | emulador jglim, blob `82a95fc…`; oito faixas/pontos A e oito B por família | **Fonte auxiliar**; y nulo ou explícito, não derivar de `stage.dat` nem alegar sorteio nativo |
| Spawns Miramo atual | `Maps.spawn_points`, `Match.start`, loading | **Adaptação preservada**: lista legada, metade esquerda/direita e busca `y−80` |
| Câmara/parallax | `camera_rig.gd`, `Game.background_region` | **Adaptação atual** conservada inicialmente; fórmula herdada não é prova do cliente |
| Contato/crateras | `terrain.gd`, consumidores nativos e coarse | **Misto**: 1 px nativo e grade2 px continuam distintos; máscaras comuns real/previsão, sem ampliar gate de armas |
| Animações de cenário | arquivos `<prefixo><n>.img`, pivôs e quadros no inventário | **Dados comprovados; comportamento pendente**: consumidores/timing/camadas não provados |
| B sem arquivo/fundo/partícula | inventário acima, paths do loader | **Pendente**; ausência de recurso não prova herança nem bloqueio na UI |

Ghidra: [manifesto final](../maps-issue-45/ghidra/manifest.json) com `ok=true`;
ASM e referências acompanham cada função. Houve três consultas exploratórias
parciais, documentadas no README de evidência, sem alegação de sucesso global.
Não houve execução dinâmica do cliente Windows.

## Delta real do porte e contratos propostos

O porte tem só `Maps.MAPS.miramo_town_a`, `client_stage=1`, paths `mos`, crop
`Rect2i(17,1344,1766,456)`, grid900² e máscara nativa1800². Recursos originais
substituíram os visuais anteriores (ADR-133). O HD antigo continua no disco.

- `scripts/import_xfs_map.py` fixa `mos`, dois quadros, 60 partículas e
  `stage.dat` em path fixo; generalizar sem mudar a saída/hashes de Miramo.
- `scripts/maps.gd` pode catalogar vários mapas, mas `spawn_points` pressupõe
  pontos de ambos os lados. Dados novos exigem validação de domínio/apoio.
- `scripts/terrain.gd` já dimensiona grid e cópias pelo raster. Usa centros
  ímpares em células2 px; `enable_native` carrega alpha1 px antes de crateras.
  Não equiparar esses contratos nem reparar máscara dentro do worker.
- `scripts/menu_screen.gd` fixa `room_maps[1]`, tooltip Miramo, setas inertes
  e indicador de lado sem ação. `classic_room_art.gd`/atlas já possuem arte.
- `scripts/game.gd::begin_loading/start_match` fixa `Maps.DEFAULT` duas vezes;
  contexto deve conter mapa e spawns resolvidos para impedir troca durante loading.
- `scripts/loading_view.gd` fixa PNG Miramo e `MatchLoading.ground_rows()` fixa
  catálogo único; parametrizar os dois juntos, preservando a composição aprovada.
- `scripts/match.gd` carrega `NATIVE_STAGE.miramo_town_a` e aplica ranges/pesos
  somente em `map_id==Maps.DEFAULT`; novos mapas precisam dos registros próprios.
- `scripts/weather_art.gd` já recebe frames/pivô do mapa e deriva a célula como
  `ground_pivot*2`; dimensionar atlas por registro. Headers de `pfacky`38/41
  excedem48×48 em dois pixels numa dimensão quando centrados24; somente
  decode do alpha prova se haveria perda útil. Miramo conserva48/24.
  `scripts/sound.gd` já usa `%11` e fallback, sem playlist nova.
- `flight_snapshot.gd`/`cpu_planner.gd` já copiam terreno/clima; exercitar tamanhos
  novos, apoio em plataformas, buracos, mapas sem solução e descarte de busca.

Critérios contratuais locais, a numerar como REQ na futura implementação:

| Critério | Obrigação | REQs/ADRs relacionados |
|---|---|---|
| M45-1 | Só variante validada pode entrar na lista selecionável; Miramo A padrão | REQ-02/12/19/21/48, ADR-132/133 |
| M45-2 | Arte, máscara, dimensão e offsets originais, sem HD novo | REQ-04/05/08/21/26/48, ADR-133/158 |
| M45-3 | Contexto único sala→loading→batalha; mesma identidade e spawns | REQ-02/12/49, ADR-138 |
| M45-4 | Preset/ranges por registro; faixa por família, inclusive fallback | REQ-23/24/25/33/53, ADR-153/159 |
| M45-5 | Previsão=execução, máscaras privadas e câmera limitada pelo mundo | REQ-04/05/08/22/32/44/52, ADR-057/134/158 |
| M45-6 | Aceite por variante, export sem fontes/ferramentas e perfil isolado | REQ-11/12/19/20/48/52, ADR-132/133 |

## Riscos a cobrir nos testes

1. Um B listado sem recurso não deve iniciar outro mapa; mensagem/Start mantêm coerência.
2. Spawn em plataforma inferior não pode migrar para a plataforma superior;
   ausência de apoio não pode causar laço infinito ou indexação de lista vazia.
3. Máscaras/cache não podem vazar crateras ou clima entre variantes/partidas/worker.
4. Mapa2000² e fundo1200² não podem revelar área externa ou alterar a escala do mundo.
5. Prévia209/228, índice de família/variante e faixa ausente não podem selecionar
   imagem, linha de nome ou música de outro mapa por coincidência de índice.

## Etapas executáveis (ainda não iniciadas)

### 1. Fechar catálogo de recursos e resolver a semântica B

**Arquivos:** evidência em `docs/maps-issue-45/`; complementar este plano;
futuras fixtures `tests/fixtures/classic_maps_native.json` e teste
`tests/test_classic_map_catalog.py`.

**Interface produzida:** manifesto por `stage_index:int`, `family:int`,
`side:int`, `prefix:String`, `available:bool`, referências explícitas para
foreground/LND/background/partícula/prévia e estado de confiança por campo.
Índice do DAT é identidade; aliases, quando comprovados, são campos separados.

- [ ] Escrever primeiro fixtures independentes para 22 registros, 14 pares IMG/LND,
  11 partículas A, 15 arquivos load_stage e ausência dos outros sete.
- [ ] Rastrear no PE a seleção/normalização de lado, o prefixo consumido, falha de
  arquivo e quadro de prévia: partir de `0x4d4004`, `0x43f13e`, `0x4e3c50`,
  refs de `ready_selectmap` em `0x4d6856` e `load_stage%02d` em `0x4d4742`.
  Encontrar prólogos/vtables antes de semear funções; não semear o meio do código.
- [ ] Fechar separadamente B11/12/14/15/16/17/19/20 e fundo/partícula de B13/18/21.
  Conferir também se a UI expõe Cave diretamente ou apenas através de Random.
  Se a build não resolve um recurso, marcar indisponível e manter o item fora
  da lista ativa; registrar pendência por variante, sem fabricar alias.
- [ ] Fechar consumidores de animações de cenário (incluindo `mos1..5`);
  registrar frames/tick/camadas/posição se provados. Suprimir animação sem prova
  exige declarar a limitação visual por mapa; não anunciar porte visual integral.
- [ ] Reservar novos REQs/ADR numéricos na main do momento e ligar M45-1..6.

**Verificação:** `python3 -m unittest discover -s tests -p test_classic_map_catalog.py`;
manifestos Ghidra `ok=true`, PE divergente rejeitado, fixtures idênticas ao regenerar.
Gate: manifesto decide cada um dos 22 registros, ainda que a decisão seja
indisponibilidade explícita; três B existentes não implicam 11 B jogáveis.

### 2. Importação genérica e terreno em escala nativa

**Arquivos:** modificar `scripts/import_xfs_map.py`, `scripts/maps.gd`;
criar assets originais em `assets/xfs/maps/<prefixo>/`, manifesto global
`assets/xfs/maps/catalog.json`, `tests/test_classic_maps.gd` e
`tests/test_import_classic_maps.py`; alterar `terrain.gd` só se o teste exigir.

**Interface:** `Maps.get_map(id:String)->Dictionary` e `path(map,key)->String`
permanecem; adicionar `Maps.available_ids()->Array[String]` e
`Maps.is_available(id:String)->bool`. Dicionários preservam `client_stage`,
`mask`, `crop`, `background`, `particle`, `particle_frames`, `particle_pivot`,
e recebem `stage_index`, `family`, `side` e configuração de prévias/clima.

- [ ] Testar falha por identidade divergente, entrada ausente, IMG/LND com
  dimensões distintas, alpha distinto e manifesto inválido antes de escrever assets.
- [ ] Importar por lista explícita de registros da etapa1; comparar todos os
  pixels alpha>0 com LND!=0, calcular crop como bounding box real, preservar pivôs.
  Se houver divergência real, não descartá-la: fechar consumidor e decidir
  máscara/visual separados em ADR antes de expor esse mapa.
- [ ] Decodificar alpha/pivôs de cada partícula e testar ausência de cortes.
  Se os pixels úteis excederem48×48, escolher célula quadrada par mínima por
  mapa, com pivô no centro: semilado = máximo das extensões absolutas úteis
  sobre o pivô nativo; célula=2×semilado. `pfacky`38/41 são casos obrigatórios.
  Preservar Miramo48/24 e contagens40..64 do manifesto, sem truncar60.
- [ ] Testar grid800²/900²/1000², máscara1px1600²/1800²/2000², crop deslocado,
  limites negativos/exatos/último pixel e `surface_at`/`native_surface_at` sem chão.
- [ ] Comparar PNGs/catalog/hash de Miramo com baseline e conservar os originais.

**Verificação:** unittest do importador + `./scripts/check.sh test_classic_maps
test_map test_native_terrain`. Resultado exigido: zero falhas;
testes novos incluídos no runner segundo seu contrato, sem reduzir inventário.

### 3. Contexto de seleção e spawns offline

**Arquivos:** novo `scripts/map_choice.gd`, testes `tests/test_map_choice.gd`;
modificar `scripts/game.gd`, `scripts/maps.gd`, `scripts/match.gd` e
`scripts/match_loading.gd`. Acrescentar `scripts/map_choice.gd.uid` pelo Godot.

**Interface:** `MapChoice.resolve(id:String,rng:RandomNumberGenerator)->Dictionary`
retorna `{map_id:String, world_width:int, spawns:Array[Vector2]}` ou `{}`.
`Maps.spawn_points` mantém a lista legada Miramo; para novos mapas,
`MapChoice` consome dados de faixas/pontos separados e uma máscara já preparada
na thread principal. `Game` guarda `room_map_id` e `loading_context` em memória;
`Match.start` conserva assinatura e recebe mapa/spawn_override existentes.

- [ ] Testar Miramo inalterado, mapa inválido, duas metades vazias, sem apoio,
  ponto duplicado, y nulo e y explícito para plataforma inferior, com seeds fixas.
- [ ] Importar somente faixas A/B do blob jglim fixado como fonte auxiliar.
  Para novos A, sortear um slot válido por metade e x no intervalo inteiro
  inclusivo, rejeitando posição sem apoio. Validar slots previamente por máscara,
  sem loop de tentativas ilimitado. Essa política esquerda/direita é adaptação1×1.
- [ ] Para B, conservar y explícito como início da sonda na plataforma indicada;
  não aplicar cegamente `y−80`. Fechar a semântica nativa de y recebido antes;
  se faltar prova, usar ponto offline validado e rotular a adaptação no manifesto.
- [ ] Resolver uma vez antes do loading; persistir contexto até Start, sem novo
  sorteio. Start direto usa a mesma resolução; opção inválida bloqueia entrada.
- [ ] Testar loading/cancelamento/volta à sala/novo Start sem contexto obsoleto,
  sem salvar escolha no perfil e sem alterar consumo de RNG de Miramo sem decisão explícita.

**Verificação:** `./scripts/check.sh test_map_choice test_map test_match_loading
test_scene test_roster`; conferir que as duas posições mostradas são as duas
passadas ao modelo, sem tocar perfil real.

### 4. Clima, música e recursos visuais por variante

**Arquivos:** modificar `scripts/import_mage_weather.py`, `scripts/match.gd`,
`scripts/weather_art.gd` se necessário; criar catálogo
`assets/xfs/maps/stages.json`; ampliar `tests/test_music_screens.gd`,
`tests/test_native_weather_roster.gd` e testes de mapas.

**Interface:** catálogo carregado na thread principal por `stage_index`, com
`weights:Array[int]` (sete categorias na ordem já usada por MageWeather) e
`column_ranges` (três listas de oito pares). Retirar só o gate de Miramo;
`MageWeather.setup/copy` e `Sound.battle_music(client_stage)` permanecem.

- [ ] Testar pesos/ranges de cada registro contra fixture DAT independente;
  no modo original nunca herdar pesos de Miramo nem array de dez categorias legado.
- [ ] Preservar `all` como opção local existente, usando dimensões/ranges próprios
  onde o contrato atual exigir; snapshot e RNG têm cópias privadas.
- [ ] Provar `stage1..6` para famílias1..6 e fallback1..6 para0/7/8/9/10;
  lado B não troca família musical, mudo/BGM0 ainda guarda faixa, resultado
  conserva faixa até OK e sala/loading continuam `ready`.
- [ ] Validar partícula/cenário sem contaminar RNG físico; se animações forem
  implementadas, adicionar `scripts/map_art.gd` com relógio só visual e testes
  de pausa/timing baseados exclusivamente na evidência fechada na etapa1.

**Verificação:** `./scripts/check.sh test_classic_maps test_native_weather_roster
test_music_screens test_weather test_performance`; escuta futura registrada por
mapa com áudio habilitado, incluindo fallback. Não basta headless mudo.

### 5. Seleção na sala e loading coerentes

**Arquivos:** modificar `scripts/menu_screen.gd`, `scripts/game.gd`,
`scripts/loading_view.gd`, `scripts/match_loading.gd`,
`scripts/import_loading_screen.py`; ampliar `tests/test_room_ui.gd`,
`tests/test_match_loading.gd`, `tests/test_room_reference.gd`.

**Interface:** `LoadingView.configure(map:Dictionary)->bool` seleciona PNG e
linhas juntos antes de `show_marks`; `MatchLoading.ground_rows(map_id:String)`
retorna linhas do mapa, mantendo argumento padrão Miramo para consumidores atuais.
Setas da sala percorrem `Maps.available_ids()` em ordem de índice nativo;
indicador de lado mostra somente lados habilitados e usa a arte existente.

- [ ] Escrever teste de índice família/variante e bordas anterior/próximo,
  sem habilitar botão Random até fechar sua política e apresentação.
- [ ] Trocar `room_maps[1]` pelo quadro nativo explicitamente mapeado, com
  tooltip/nome coerentes; validar o índice via consumidor, não por coincidência.
  Preservar derivados4×/fallback existentes e os pilotos/equipamentos da sala.
- [ ] Importar prévia/máscara por variante validada. Preferir `load_stageNN`
  para manter o painel aprovado209; se a fonte exige `loadstage`228, definir
  recorte/conversão como adaptação e testar coordenadas, nunca reusar linhas209.
- [ ] Testar nomes em x0/largura−1, coluna vazia, título e clip da moldura;
  não mostrar B sobre imagem A sem vínculo explícito no manifesto.
- [ ] Testar falta/corrupção de recurso e cancelamento sem iniciar fallback
  silencioso; seleção em memória retorna intacta após resultado/QUIT.

**Verificação:** `./scripts/check.sh test_room_ui test_room_reference
test_room_polish test_match_loading test_scene test_result_screen
test_music_screens`. Captura GPU da mesma identidade na sala/loading/arena.

### 6. Ativar mapas em lotes e validar cada variante

**Arquivos:** catálogo `scripts/maps.gd`, `tests/test_map_matches.gd`,
`tests/capture_classic_maps.gd`, resultados em `docs/classic-maps/`;
registrar suíte no runner sem remover as 29 partidas existentes.

**Dependências:** etapas1–5. Cada lote é revisável/testável antes do seguinte:

| Lote | Variantes propostas | Foco adicional de aceite |
|---|---|---|
| A1 | Nirvana2, SeaOfHero4, DummySlope8 | mundo1600²/fundo1200²; ilhas/bordas/plataformas |
| A2 | Metropolis3, AdiumRoot5, CozyTower7, StarDust9, MetaMine10 | mundo1800²; vazios entre estruturas; partículas40/42/54/64 |
| A3 | Dragon6, Cave0 | mundo2000² no Dragon; Cave e política Random separados |
| B1 | Nirvana13, CozyTower18, MetaMine21 | máscaras diferentes; fundo/partícula resolvidos pela etapa1; plataforma inferior |
| B2 | Cave11, Miramo12, Metro14, Sea15, Adium16, Dragon17, Dummy19, Star20 | somente aliases/fluxos provados; caso contrário indisponibilidade explícita |

- [ ] Para **cada linha A/B individual**, verificar hashes e dimensions/crop,
  duas posições com apoio, preview/máscara/nome/cenário/música próprios e
  flag de disponibilidade. B não herda o aceite do respectivo A.
- [ ] Em cada variante habilitada, executar duas seeds de partida1×1 até resultado,
  alternando lado e famílias de contato; preservar as29 partidas de regressão.
  Acrescentar ao menos um disparo de cada uma das48 armas por mapa em smoke
  dirigido (não48 partidas), com cópia privada nativa/coarse antes e após cratera.
- [ ] Comparar real/previsão no mesmo estado para contato, posição/vida final,
  terreno, minas, calendário/Thor e RNG; cobrir Nak subterrâneo/SS, Grub rebote,
  minas Raon e teleporte em plataformas, além de queda no vazio.
- [ ] Testar câmeras nas quatro bordas, pan, follow de projétil/impacto, zoom
  inalterado, Background Off e fundos1200/1300; orçamento de CPU sem novos
  carregamentos no worker e sem alterar timeout para esconder regressões.
- [ ] Capturar por variante: sala/loading/arena em1920×1080, tiro/cratera/queda,
  pausa30 quadros idênticos e retomada; inspecionar recorte/alpha/cenário.
- [ ] Se Random for incluído, resolver uma vez somente entre variantes habilitadas,
  declarar probabilidades offline (não importar a chance Cave do emulador como
  regra nativa), testar conjunto/seed e mostrar o mapa já resolvido no loading.

**Verificação:** `./scripts/check.sh test_classic_maps test_map_choice
test_map_matches` por lote, seguido de `./scripts/check.sh` integral ao concluir
alterações de combate/terreno. Gate por variante: zero falhas/logs de erro,
real=previsão, arte inspecionada; limitação visual ou dinâmica explicitada.

### 7. Exportação e aceite final da futura implementação

**Arquivos:** `export_presets.cfg`, `scripts/ci/smoke.gd`/
`combat_smoke.gd` e `scripts/ci/package.py` se necessário;
`SPEC/DESIGN/DECISIONS/TASKS/HANDOFF`, `docs/JOGAR.md`.

- [ ] Testar que presets incluem catálogos/PNGs/áudio necessários e excluem
  PE/XFS fontes, pesquisa Ghidra, overrides de certificado e dependências locais.
- [ ] Executar harness completo com modelos/cenas,29 partidas antigas e novas
  partidas por variante; registrar inventário efetivo, duração, logs e limites.
- [ ] Se aplicativo for solicitado, reexportar com `scripts/build_macos.py`,
  conferir assinatura/PCK isolado e smoke sala→cada variante→resultado→sala;
  checks Windows conforme CI. Não anunciar validação Android/iOS sem executá-la.
- [ ] Obter aceite visual/input/escuta por mapa; execução estática/PNG não é
  paridade dinâmica do cliente inteiro. Publicação/release exige autorização própria.

## Critério de conclusão desta pesquisa

Pesquisa entregue quando inventário, fontes/hashes, diferenças do porte,
dependências, contratos/testes e lacunas B estão registrados e revisados.
Isso **não** marca as etapas de implementação como concluídas. Nenhum novo
mapa, arte, pacote ou mudança de perfil faz parte da issue de planejamento.

Na retomada, partir da main após #43/#44, conferir IDs REQ/ADR e consumidores
atuais, atualizar este plano e executar etapa1 antes de expor variantes.
