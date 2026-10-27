# Clima e Thor: recursos do cliente — REQ-48 / ADR-133

Pedido de27/10/2026: substituir a arte herdada ativa pelos recursos do cliente
GunBound Thor's Hammer, preservando regras, geometria aprovada do Mage e os
adaptadores onde esta build não oferece equivalente. Nenhuma arte foi gerada,
nenhum arquivo original foi apagado e nenhuma fonte OpenBound foi consultada.

## Fonte e reprodução

`TestClient/graphics.xfs` do `jglim/gunbound-launcher`, commit
`2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1`, SHA-256
`a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`.
Consumidores já auditados no PE de SHA-256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`
(Ghidra12.2; evidência anterior de Mage, Lightning e Aduka reutilizada,
sem nova alegação de execução do cliente Windows).

`python3 scripts/import_xfs_weather.py` produz cinco PNGs em
`assets/xfs/weather`, três em `assets/xfs/thor`, o manifesto
`assets/xfs/weather/catalog.json` e `assets/xfs/thor/thor_native.json`.
O importador recusa outro hash do arquivo XFS. Todos os393216pixels das seis
XTFs são ARGB4444 expandido por canal×17; as duas folhas IMG preservam os
112quadros e hotspots. Cada RGBA é comparado à cópia nativa anterior antes
de aceitá-la como fallback. O manifesto registra SHA do recurso XFS, PNG e
RGBA, tamanho, pivôs, consumidor, mistura e lacunas. O catálogo Thor/EPA é
igual ao catálogo nativo previamente aprovado.

## Inventário ativo e confiança

| Consumidor atual | Entrada original / localização | Decisão |
|---|---|---|
| `scripts/weather_art.gd:65`, `scripts/mage_weather_art.gd:12` | `FirewallTexture.xtf`; Force `0x471550` | Cliente, ambas as famílias de calendário |
| mesmos consumidores | `LightningTexture.xtf`; Electric `0x46e020`; dispatcher `0x4508a0` | Cliente; mistura aditiva preservada no nativo e aplicada à textura equivalente no adaptador |
| mesmos consumidores | `TornadoTexture.xtf`; Tornado `0x4ac760` | Cliente, ambas as famílias de calendário |
| `scripts/weather_art.gd:70`, `scripts/thor_native_art.gd:10` | `thor.img`, `thorl.img`, `thor.epa` | Cliente, corpo/luz com registro próprio; EPA20/20/16 preservada no nativo |
| `scripts/weather_art.gd:73`, `scripts/aduka_beam_art.gd:10` | `LaserEffect.xtf`; `0x4c45e4..0x4c46f3` | Cliente; o consumidor comprovado seleciona esta textura |
| `scripts/weather_art.gd:74`, `scripts/lightning_beam_art.gd:9` | `Lightning.xtf`; `0x482130`/`0x4a6b10` | Cliente, quatro tiras64×256; geometria nativa Lightning preservada |
| `scripts/weather_art.gd:75`, `scripts/mage_sparks.gd:65`, `scripts/mage_spark_art.gd:6` | `CrashTexture.xtf`; `0x48dd80`/`0x481ef0`, dispatcher `0x450c20` | Cliente; linhas2/3, oito quadros32²; emissão nativa Mage preservada |
| `scripts/weather_art.gd:87` via `Maps.path` | `pmos.img`, importado pelo grupo Miramo | Cliente;60quadros e pivô(24,24); emissão/rotação herdadas preservadas |
| `scripts/weather_art.gd:68` | Weakness/Mirror/Random: categorias ausentes desta build (`MAGE_SECONDARY_WEATHER.md`) | Arte e comportamento anteriores permanecem como adaptação declarada |
| `scripts/weather_art.gd:77` | Mirror/WindTransition/LightningS1/AdukaS2 herdados | Eventos de som sem equivalente comprovado continuam pendentes; esta migração de arte não arbitra sons |
| `scripts/weather_art.gd:83` | Blast da tabela do Mage T2, `SpawnThorEffect432320` | Som Thor nativo anterior preservado |

Correção do inventário preliminar: `ThorTexture1/2.xtf` existem no arquivo,
mas **não** são as texturas selecionadas pelo consumidor de Thor/Aduka já
comprovado. O registro em `scripts/import_aduka_thor.py` fixa a seleção de
`LaserEffect.xtf`; não foi feita substituição por semelhança de nome.

## Limites entre arte e comportamento

Partidas contendo Mage mantêm os renderers nativos, seus quads/UVs, relógio20Hz,
mistura, bob, EPA e emissão de partículas; somente a localização dos recursos
e a seleção de fallback mudaram. Os PNGs antigos nativos continuam em disco.

Outras combinações conservam calendário, colisão, contato, dano, agenda, larguras,
escala, fade, bob e relógios anteriores. As colunas adaptadas agora usam o
atlas2×4 original; Electricity usa mistura aditiva. Thor adaptado conserva
posição/rotação/escala0,6/15fps com corpo+luz originais e pivôs respectivos.
Raios adaptados conservam largura, duração e cores, com tiras da textura
original e mistura aditiva. Marcas decorativas genéricas mantêm sua emissão,
tremor e tamanho, selecionando linhas2/3 originais de CrashTexture. Esses
consumidores **não** se tornam paridade nativa integral pela troca de PNG.

Passes aditivos novos usam CanvasItems privados com índice negativo para
continuar abaixo do HUD. `clear_beams` limpa esses comandos ao trocar a cena.
As cópias históricas de fallback são exclusivamente os imports já comprovados
do cliente; Force/Electricity/Tornado antigos e ThorLaser/LightningSE não são
fallbacks ativos. `client_weather_assets.gd` valida tipo e dimensão das
texturas carregadas; o metadata Thor valida identidade do arquivo, células,
hotspots e as três sequências EPA antes de usar o primário ou fallback.
Igualdade de pixels/hashes é verificada offline, sem depender da presença de
bytes PNG soltos em um futuro PCK.

## Validação observada

Comando dirigido:

```sh
./scripts/check.sh test_client_weather_assets test_client_weather_source \
  test_mage_weather_art test_mage_spark_art test_mage_sparks test_mage_spark_source \
  test_aduka_native test_aduka_assets test_lightning_art test_lightning_assets \
  test_weather test_map
```

Primeira rodada:12suítes,676checks Godot e20testes Python, zero falhas.
A nova suíte do recurso passou depois a75/0, acrescentando rejeição de hotspot
e EPA adulterados (total dirigido consolidado678checks Godot). Python4/0
confere cada canal das seis XTFs e usa outro decoder IMG para os112quadros
Thor, incluindo registro e regiões vazias. Testa também a recusa de fonte
XFS desconhecida antes de criar saída. As importações PNG são sem perda
(`compress/mode=0`, sem mipmaps).

Captura GPU final:360quadros,4casos,1920×1080, clock60Hz,
Compatibility/OpenGL noAppleM4Pro, exit0/log semERROR.30quadros pausados
idênticos por caso; retomada alterou pixels. As16amostras PNG foram
preservadas; amostras dos quatro casos foram inspecionadas visualmente e
as pausas30/59/retomada75 foram conferidas de
novo emPython por igualdade RGBA. `tests/capture_client_weather_assets.gd`;
resultado final e limites em `docs/client-weather-assets/gpu-validation.json`,
hashes de fontes/amostras em `verified-source.json`. Usa a cena Game real,
perfil isolado, eventos de apresentação controlados e dois sentidos para os
calendários nativo/adaptado. A execução de captura, inspeção visual e
conferência de pausa/retomada são registradas no relatório, sem alegar
medição de60FPS a partir do clock60Hz. Dois ensaios anteriores foram
interrompidos por lentidão de gravação PNG em cada quadro; a rodada final
comparou os360quadros em memória e salvou somente16amostras. Os ensaios
interrompidos não valem como evidência final. A suíte final de75checks e as
suítes MageWeatherArt41/AdukaNative40 foram repetidas após as guardas finais
(156/0). Parse da captura e compilaçãoPython passaram; a primeira tentativa
depy_compile usou cache global sem escrita no sandbox, repetida com cache
local em`.tools`. Não houve escuta, interação com mouse, execução do cliente
Windows, teste de pacote, alteração de versão, commit, push ou exportação.
