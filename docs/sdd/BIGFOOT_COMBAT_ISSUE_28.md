# Bigfoot: combate do cliente — issue #28

Base `origin/main` 035d8e172bfdf5a0cf35c2d4683d7d3dbbe3a679, fetch em
11/11/2026. Worktree nativa ee91; branch codex/issue-28-bigfoot-combat.
REQ-04/05/07/08/19/44/45. Execução inline, commit/push/PR/rebase merge
autorizados pelo pedido. Preservar arte, smoothing4×, EPA e assinaturas públicas.

## Matriz de evidência e contrato fechado antes do código

Ghidra12.2/JDK26.0.1 executado em banco exclusivo
`/private/tmp/gunbound-issue28-ghidra`; extratos em
`.tools/bigfoot-native/evidence-{initial,consumers,dispatch}`.
PE x86LE32/base400000, SHA256
4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde.
Bootstrap valida os oito hashes PE/DAT/XFS de `.github/ci-tools.json`;
DAT b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf,
graphics.xfs a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08.

| Contrato | Fonte, unidades e ordem | Classe / integração |
|---|---|---|
| T1 |489580, eventos5/frames3,7,12,17; theta/P: (0,+10),(0,-10),(+1,0),(-1,0)|comprovado; offsets nativos depois de clamp/quantização, sem reclamp|
| T2 |evento6/frames6,10; (0,+15),(+4,+10),(-4,+10); (0,0),(+2,+5),(-2,+5)|comprovado; seis componentes, mesmo tick por trio|
| SS |evento10/frames3,5,7,9,12,15,17,19; repete geometria T1 duas vezes|comprovado; oito componentes sem nova fase temporal|
| inicialização |42bbb0/42de70→41da80; tipo4; bônus3×Attack/divisor e (Dig/2)/divisor, IDIV separado; divisor4/6/8|comprovado por ASM e execuçãoPE; soma à potência/dimensão de cada material|
| DAT |blocos44/57/70: potência86/70/92, dimensão52/40/48, aspecto134/124/126, flags8; três materiais iguais|comprovado; potência não é dano final|
| contato |454dc0 vtable555c34+14→455cc0; SS48de40→55631c+14→455cc0; stride8|comprovado; Bigfoot entra explicitamente no inventário de contato, não por adversário; máscara global já preparada|
| resolução |T1/T2 vtable+18→4572b0; SS+18→48e1d0 e +20→48de60; cratera4e4970→4e4450, dano450eb0→45db20|comprovado; mesmos consumidores Shared/AdukaCombat, elipse estrita e truncamentos separados|
| dano |45db20: raio dimensão/2+10; dx×100/aspect truncado, sqrt, falloff×1000, potência, percent, bônus+Force/2, vulnerabilidade/resistência|comprovado; Shared.amount, HP/shield terminal do treino preservados|
| cratera |4e4450 midpoint, dimensão/2 inteira, largura horizontal truncada antes×2, borda direita exclusiva|comprovado; Shared.crater_spans e terrain.carve_native|
| clima |455cc0 amostra Force/Tornado/Electricity;4572b0/48e1d0 tratam eletricidade e Thor antes do blast, divisor4/6/8|comprovado; reutilizar efeitos nativos compartilhados; calendário/Moon/Eclipse global existente|
| itens |Dual/Dual+ usam emissão comum, PowerUp/Bunge conservam percentuais offline, Thunder conserva anexo atual, Teleport sinalizador comum|adaptações explícitas; não reivindicar ativação de itens do PE|
| geometria do ator |hotspot/apoio/muzzle vigentes e terreno procedural/visuais do treino|ponte declarada; não remodelar mobile nem origem nesta issue|

Fixtures independentes executam MainAction e41da80 reais em Unicorn2.1.4,
45db20 até o valor final (pose/tilt zero controlados) e4e4450 sobre bitmap.
Não executam o clienteWindows inteiro. Nenhum esperado deriva do GDScript.

## Plano executável

1. [x] Ler issue e instruções, preparar entradas verificadas, baseline dirigida,
   Ghidra próprio e fechar matriz/ABI/ASM.
2. [x] Criar gerador `tests/tools/bigfoot_oracle/generate.py` e fixture
   `tests/fixtures/bigfoot_native.json`; verificar hashes e stubs delimitados.
3. [x] Criar `test_bigfoot_native`: emissão/lançamento pós-clamp, inicialização,
   dano final/cratera, contato sem Mage, snapshots e itens. Confirmar RED antigo.
4. [x] `bigfoot_attacks.salvo`: geometria nativa; criar `bigfoot_combat.gd`
   com active/prepare/parameters, potências/dimensões/aspectos/divisores próprios.
   Match prepara no emissor comum e resolve com Shared; habilitar ID2 explícito
   em AdukaWeather e dividir efeitos anexos por4/6/8.
5. [x] Confirmar GREEN; atualizar fixtures antigas somente onde contrato mudou.
   Cobrir ambos sentidos, N−1/N/N+1 EPA, deltas, pausa, Dual/Gold/resultados,
   cópia profunda e igualdade real/previsão. Registrar suite em check.sh e smoke.
6. [x] GPU temporal T1/T2/SS dois sentidos, vento/Force/Tornado/Electricity/Thor,
   pausa e retomada; arte/som preservados, limites de escuta explícitos.
7. [x] Harness integral com Python/modelos/cenas/29partidas, Ruff/diff,
   revisão independente dos cinco focos; TASKS/HANDOFF/MOBILES.
8. [ ] Commit/push feature, PR quatro checks, rebase merge; confirmar issue,
   SHA integrado, mainCI e release automática sem publicação manual.

## Ledger

Baseline dirigido: dez suítes/1179checks/0 falhas, fora do sandbox.
Primeira importação completa demorou; tentativas no sandbox foram rejeitadas
pelo gate de log por erro ambiental de certificados, não regra. Sem override.
Bootstrap usou Python compatível do checkout principal somente como executável;
entradas e logs próprios. `--no-legacy-sound` evita gravar pasta irmã externa.
Unicorn isolado em .tools/oracle-py; JIT exige execução fora do sandbox
(signal132 dentro dele). Ghidra manifests initial/consumers ok=true.


## Resultados locais

- RED final antes do produto:1980checks/998falhas; GREEN inicial1980/0.
- Revisão independente encontrou P2 de truncamento angular sobre apoio
  fracionário: soma theta antes de truncar cruzava zero. Regressão sobre
  colunas reais e mira±0,5 reproduziu2falhas/2569checks; helper interno
  BigfootCombat.launch_velocity_fp recebe theta já inteiro. Corrigido;
  demais mobiles conservam o cálculo de lançamento, agora feito uma vez.
- Oráculo final:72emissões,18inicializações,180danos e18bitmaps de cratera.
  Velocidades derivadas em Python da LUT do próprioPE54c240 e ASM42ccfa..42cd42.
  test_bigfoot_native final2905/0:clamp/quantização/força negativa mínima,
  ambos sentidos, bônus assinados, raster completo, dano, itens/anexos,
  Gold, quatro climas, deltas e mutação de snapshots. EPA permanece intacto.
- Primeira rodada integral exit1:expectativas herdadas em test_mage,
  test_mage_scene, test_shop_items_integration, test_armor_t2 e test_weather_legacy.
  Corrigidas com o contrato nativo:79por bomba contraMage(vulnerabilidade92),
  bônus/item/defesa em passes separados; Armor continua fora do inventário.
  WeatherLegacy conserva68checks do adaptador com consumidorArmorT1 e poder90
  explícito de fixture, pois Bigfoot agora tem contato nativo. As cinco suites
  passaram nas repetições dirigidas; a rodada integral final é registrada abaixo.
- Captura GPU OpenGL/MetalAppleM4Pro:903quadros1920×1080 (3×301), seis painéis
  T1/T2/SS×direção, normal com vento8/−3, tornado e anexosForce/Electricity/Thor
  com vento−8/3. Todos4/6/8impactos por lado e zero shells restantes.
  Pausa45–74:30RGBA e estados do modelo idênticos em cada sequência;
  retomada e término observados. Passo manual1/60s, não benchmarkFPS.
  PNG/MP4/hashes/manifests em docs/bigfoot-native; PNGs integrais em.tools.
- capture_bigfoot_attacks exit0 com perfil isolado:novas imagens em
  .tools/bigfoot-native/legacy-capture; imagens históricas versionadas restauradas.
  capture_mobile_shots ID2 exit0,11stills em docs/mobile-shots/bigfoot-native-*.
- Revisor independente conferiu os90PNGs de pausa por pixels e hashes,
  manifests e stills; P2 corrigido e sem novos achados acionáveis.
- Ruff do gerador e gitdiff--check aprovados. Sem alteração de assets/streams
  de áudio, grupos/ticks EPA ou perfil real. Sem escuta/input/aceite humano,
  clienteWindows inteiro ou publicação manual de pacote. Os gates hospedados
  macOS/Windows validarão os pacotes finais; versão permanece automática.

Harness integral final:exit0/361,706s,357parses,113suítesGodot/54.633checks,
157testesPython/zero skips/falhas e29partidas completas. CoberturaPython62%.
Relatório durável em docs/bigfoot-native/harness.json; logs individuais
em.tools/check-logs. O relatório versionado preserva essa rodada; repetição dirigida posterior
atualizou report.json/import e os logs de três suites, sem invalidar a integral.


### Gate remoto do PR35 — correção de fixture

Primeira execução42981907826,head1b710864:macOS teve somente
`test_mage_scene` com2falhas (pose e escudo). Todos os outros modelos,
156Python e29partidas passaram. A fixture usava match_seed−1 e por isso
às vezes nascia sobThor. Com pulso nativo, o anexo corretamente altera
escudo141/hurt para129/hurt_2. Probe local reproduziu ambos os climas.
A fixture fixaWind antes do pulso isolado; assertivas intactas. BigfootNative
mantém a coberturaThor. Nenhuma regra/asset mudou; revisor aprovou o ajuste.

Repetição dirigida após o ajuste:mage_scene15/0,BigfootNative2905/0,
NativeWeatherRoster2976/0 (5896checks,exit0). Logs em
.tools/check-logs e /private/tmp/issue28-ci-fixture-fix.log.


### Emenda REQ-52: orçamento de partidas na CIWindows

Head e277adaf,run42984907453:macOS completo/export/smoke aprovados;
Windows teve somente test_matches-1-of-4 timeout900, após seeds81 e85
concluídos (grupo estridado81/85/89/93). Python823,797s passou, comparável
à base035d8e17/Python821,347s; grupo da base296,225s. O combate nativo
altera concentração/dano e duração das partidas, sem alterar suas seeds.

Plano antes do código: manter física/assertivas e timeout900; agendar cada
seed/mobile em processo próprio por --match-shard=i/N, usando o seletor
existente, com o mesmo pool limitado a4workers. O guard passa a ser por
partida, sem um seed consumir orçamento dos seguintes. Preservar inventário
exato13+16, logs por caso, falhas e coberturaPython. Regressão deve executar
processos reais com engine-fixture e exigir29resultados unitários antes do
GREEN; depois runner integral real e nova revisão/CI de ambos os pacotes.


### Comparação de custo e estabilidade antes de aceitar a emenda

Atendendo ao acompanhamento da orquestração, o particionamento não foi
usado como prova de performance. Sondas reproduzíveis em tests/tools/bigfoot_profile
compararam a base035d8e17 e o porte no mesmoM4Pro, em sequência e sem outro
harness/encoding; somente wrappers de medição nas cópias isoladas dos scripts.
Resultados completos em docs/bigfoot-native/performance.

| Seed81 / mesmo cenário e RNG | Base | Nativo |
|---|---:|---:|
| tiros/turnos até finished |26|82|
| tempo instrumentado |25,312s|116,760s|
| candidatos de busca |5333|16905|
| candidatos por turno |205,12|206,16|
| tempo médio por previsão |4,713ms|6,855ms|
| busca por turno média / p95 / máxima |0,967/2,233/3,481s|1,414/3,713/4,454s|
| ticks físicos totais (previsão+real) |172161|627470|
| rasterizações nativas / tempo |7293/3,260s|61494/21,960s|
| shell primário explodindo mais de uma vez |nenhum|nenhum|

O fator4,61 de custo vem principalmente de3,15×mais turnos, com o novo
resultado de dispersão/contato/dano. Candidatos por turno mudam apenas0,5%
(arma, limites e refino determinam o número), não há duplicação da grade. Cada previsão executa
em média37,12ticks contra32,28; o consumidor1px/dano/cratera nativo também
custa mais por tick. O algoritmo carve_native não foi alterado; a média por chamada foi0,357ms
contra0,447ms, com dimensões/cargas diferentes (não é um microbenchmark
pareado da função). Há mais chamadas porque Bigfoot passou da cratera adaptada2px para
o consumidor1px, além dos anexos. Não se trocou a física na previsão para
reduzir esse custo. As duas partidas terminam, sem loop de contato ou shell
reexplodindo. No nativo270lançamentos−38misses=232explosões primárias;
43explosões elétricas anexas explicam as275explosões publicadas.

Há aumento real de trabalho e duração das partidas; não alegar paridade de
performance com a adaptação anterior. O novo orçamento é por partida,
com900s intactos, inventário exato e29resultados independentes. A rodada do
runner durante a revisão encontrou captura tardia do denominador da última
família; corrigida com c=shards. Regressão cobre ambasordens reais por
engine-fixture:RED2→GREEN12/0. O run intermediário com13partições inválidas
é explicitamente falho e não valida a emenda final.

Responsividade: o gate test_performance agora mede cenaCPU Mage e Bigfoot,
mesmos limites40ms/frame e12s para buscar/disparar. Rodada local24/0;
Mage0,874ms/frame/873ms até disparo; Bigfoot0,940ms/frame/1872ms. SondaGPU
real1920×1080,Bigfoot+Thor/eletricidade,seed23:3468quadros/5,471s até disparo,
_process p95=0,100ms/máximo0,302ms; render p95=1,911ms/máximo8,872ms;
abrir pausa6,670ms,12quadros com modelo idêntico e retomada aprovada.
Sem vsync; não é metaFPS nem input humano. Essa medição demonstra que o
trabalho permanece no worker e não bloqueia os controles no host observado;
aceite humano e outras máquinas continuam sem medição manual.

Validação final da emenda (fonte corrigida): runner exit0/361,706s,
357parses,113suítesGodot/54.633checks,157Python sem skips e29partidas
unitárias (13seeds+16mobiles), todas aprovadas. CoberturaPython62%.
Gate de cena24/0: Mage0,543ms/frame/887ms; Bigfoot2,393ms/frame/1891ms.
Ruff com a seleção do workflow E9,F63,F7,F82 e git diff --check aprovados.
Um Ruff sem a seleção do projeto encontrou465avisos históricos de estilo;
essa invocação ampliada não é o gate do projeto nem foi usada como GREEN.
