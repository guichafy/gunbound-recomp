# Revisão Lightning — cliente Thor's Hammer

REQ-04/05/06/07/08/09/19/20/21–26/38–41/44/45. Pedido27/10/2026:
revisar assets, animação, força, defesa e os elementos/Tempo da batalha pelo
cliente, com reescrita Godot. ID8 (nativo7/tank8), offline1×1; preservar
roster, montagem/avatar/equipamento, originais/HD, perfil e trabalho Mage
simultâneo. Sem versão/exportação/publicação nesta revisão.

## Fonte e método

PE local `.tools/mobile-animation-port/GunBound.gme`, SHA256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`;
graphics.xfs `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`;
characterdata.dat `b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf`.
Ghidra12.2/JDK26 headless direto conforme skill gunbound-client-port.
Base400000, x86LE32, endereços VA. Projeto exclusivo builds/ghidra-lightning;
extratos `.tools/lightning-review/01-dispatch..04-effects`. Cliente Windows
não executado. C# em Workspaces/Gunbound é referência auxiliar somente leitura.

## Matriz inicial e plano antes do código

| Comportamento | Fonte/contrato | Situação inicial |
|---|---|---|
| Emissão |484ff0/MainAction, T1/T2/SS tick1; EPA tank8 | Conferido; 82fire/82blast PCM |
| Voo T1/T2 |4a7050: terreno, stride3(T1)/8(T2), refino1; não chama450e10 | Portado, ignorando corpos durante o voo |
| T1 |482550: coluna vertical, primeiro terreno desde topo;431d90 +43af40 | Portado: terreno original1px, sem varredura por corpos |
| T2 |4a8360: x−y e x+y desdey0, incrementos(+1,+1)/(−1,+1) | Portado: duas diagonais, ordem(+1,+1)/(−1,+1) |
| SS |4837e0→425ac0: distância estrita na origemY−10, alvos por slot | Portado: raio120 estrito; sem blast primário |
| Dano/defesa |41da80→45db20;86 vulnerabilidade base, flags4 | Portado: flags de ataque índice54/67/80, choque separado |
| Força/vento |DAT47/90; física20Hz24.8;4a7050/482550/4a8360 | Portado: ramo tornado nativo; Force+3/+8/+8 |
| Assets/animação |tank8/bullet8n/s/pl/flame81/82/ssflame8, EPA/pivôs/PCM | 524quadros auditados; EPA, PCM, raster e GPU conferidos |

- [x] Fechar parâmetros/unidades/ordem/ABI/ASM dos raios, choque,SS/clima.
- [x] Criar catálogo extraído e oráculos Python independentes; testar diferenças
  com terreno parcial, dois sólidos, corpo atravessado e limites de alcance.
- [x] Implementar `lightning_combat.gd`:prepare/impact/contact; integrar Match
  e clima no passo comum real/previsão, caches pré-aquecidos no principal.
- [x] Conferir assets/pivôs/EPA/sons; portar apresentação dos raios comprovada,
  sem rastro (ADR-120), sem mudar o registro visual aprovado.
- [x] Regressão dirigida, harness completo/29partidas, revisão independente,
  GPU temporal1920×1080/dois sentidos/pausa/retomada e documentos finais.

## Critérios e limites

Contatos não usam interpolação; shell e efeitos têm estado privado copiado
profundamente no snapshot; CPU usa o mesmo algoritmo. Defesa/equipamentos,
SS lock, itensDual/Dual+/Teleport/Thunder, tempo/atraso e clima devem conservar
os contratos comuns onde a ativação nativa ainda não foi portada. Testes usam
perfil isolado. Separar prova estática, captura Godot e aceite do usuário.
Não anunciar paridade integral do cliente a partir de testes verdes.

## Contrato numérico implementado — ADR-127

| Arma | Poder/dimensão/aspecto | Choque/propagação/raio | Voo/impacto |
|---|---|---|---|
| T1 |230/54/134|56+20/70| stride3, só terreno; vertical no primeiro sólido do topo |
| T2 |240/40/143|56+20/70| stride8, só terreno; duas diagonais do topo |
| SS |230/40/143 (dados preservados)|26+20/120| stride8 comum; seleciona inimigo a menos de120px do hotspotY−10 e produz raio vertical/T1 |

SS não usa seu poder/dimensão para inventar um blast no ponto do guia.
`483ff0` chama o virtual `4837e0`; este publica ssflame8 e seleciona os alvos.
Cada strike remoto cria `431d90` com armaT1 (230/54/134), enquanto o choque
conserva26+20 e raio120 doSS. Treino1×1 não inclui joias nem minas doSS;
os laços nativos8/8/64 slots ficam documentados no extrato, sem inventar
esses modos de jogo. T1/T2 não colidem com mobiles; SS conserva o passo comum.

`41da80` mapeia blocos13 a partir de44/57/70: dimensão+3, aspecto+6,
raio elétrico+9, flags+10 (1), choque+11 e secundário+12. Não confundir
70/120 (raio) com bits de ataque. Attack acrescenta3×pontos ao poder;
Dig acrescenta trunc(pontos/2) à dimensão; são campos distintos do choque.
`Shared.amount` aplica queda linear elíptica e passes inteiros, vulnerabilidade
nativa/Defense/tipos/resistências e escudo. Lightning possui vulnerabilidade86,
flags4, HP750, shield300, regen20, força47 (máximo470) e gravidade90.
Os atributos, teto/regen, itens e delay preservam os contratos offline
existentes quando o consumidor específico ainda não foi portado.

`43af40` amostra pontos para cima: vertical passoR; diagonal passo
trunc(R×7/10) nos dois eixos, com X oposto à varredura descendente. Testa pés
nativos (semY−10, sem AABB), raio estrito. Mecânicos(flags8) ampliam apenas
o raio de hit em20% e recebem choque total+trunc(total×8/100):82(T1/T2),49(SS).
Demais recebem76/46, sem multiplicar Attack/Defense. `43bda0` propaga
somente20: fonte comflag1 não propaga; alvo comflag1/2 não recebe cadeia;
distância pelos pés estritamente menor queR original, sem ampliação20%.
`45ea40` consome pendência uma vez e subtrai primeiro do escudo.

T1/SS enfileiram choque antes de criar o blast, T2 depois. `lightning_alive`
conserva a elegibilidade anterior ao blast letal até o flush; isso mantém
propagação20 que pode atingir o atirador antes de resolver a partida. Campos
transientes são privados ao ator e apagados após o flush; snapshots duplicam
profundamente atores/shells. Crédito/Gold só agrega os novos eventos de dano.
O flush ao fim do tick20Hz é a ponte da arquitetura offline; não houve trace
dinâmico Windows do scheduler para alegar identidade integral do frame.

Force é separado do poder, amostrado uma vez/tick nos pontos de contato,
+3 noT1 e+8 noT2/SS, limites20..100. O passe de dano aplica metade do bônus;
choque/chain não herdam Attack/Dig/Force. Tornado conserva velocidade24.8,
limita |vx|mínimo200, reflete duas vezes e libera na terceira saída; vento
retoma no tick seguinte, sem normalização nem impulso/restauração C#.
Aceleração do vento atual é congelada na semente como na física comum.

## Assets, animação e raster

445quadros do mobile e79quadros de tiros/impactos conferidos pixel a pixel
contra oXFS, com janelas/pivôs/EPA intactos. Sem gerar arteIA, suavização nova
ou substituir sprites/avatares aprovados. `Lightning.xtf`256×256 ARGB4444
foi extraído para`Lightning.png`, sem alterar cores, com consumidor dedicado.
SS usa a camada original`bullet8pl` em ADD, orientação quantizada sem flip
vertical; T1/T2 mantêm corpo em alpha. Sem rastro (ADR-120).

`482130` vertical: offsets(−32,−256)/(31,−256)/(31,0)/(−32,0).
`4a6b10` diagonais conservam os offsets inteiros assimétricos e passos256
por tile; não giram um retângulo ideal. UV ocupa1/4 da textura,8tiles,
variantes mudam a cada3ticks; alpha255−24×tick, remoção após10ticks.
Variantes usam RNG local só de apresentação, sem tentar reproduzir o estado
rand global do cliente nem consumir o RNG de combate. Void vertical é
clampado ao fundo do mapa na apresentação conforme436070.

Poses usam durações EPA, sem timers genéricos de morte. A análise dos campos
RiderPivot encontrou11registros inutilizáveis nos20quadros`dead`. Não foram
corrigidos nem reinterpretados. Os consumidores nomeadosAvataTexture1/2
(4c32ce/4c3595) eAvataEffectTexture1/2(4c3ca4/4c3f7b) saltam o desenho se
estadoEPA14=dead; CharacterTexture/CharEffect seguem separados. LightningSprite
desenha só chassis emdestroyed, preservando montagem/equipamento em vida.
A leitura inicial dos laços como4categorias de avatar foi descartada: são
4jogadores por time, com as peças já compostas. A prova é a textura/guarda,
não essa interpretação errada dos slots. Byte/string/state foram reconferidos.

## Verificação e limites

Log de origem, ASM/decomp e metadados em`docs/lightning-review/native-proof.json`;
queries11/manifests em`.tools/lightning-review`. Ghidra12.2/JDK26, PE/XFS/DAT
conferidos; nenhum recurso original sobrescrito. A fonte C# foi lida como
referência auxiliar e permaneceu intacta.

Suítes novas: `test_lightning_native`, `test_lightning_art`,
`test_lightning_assets.py`, `test_lightning_weather`. Oráculos independentes:
441fixtures de queda,1071probes de choque e2000ticks inteiros de tornado;
casos especiais de alcance119/120/121, chain69/70/71, Defense50, golpe letal,
stride3/refino, Force, Dual+, Teleport, regen e delays. Real/previsão conferidos
nos3tiros,2sentidos e ventos horizontais/verticais/tornado. Bridges de
Weakness/Mirror/Electricity/Random/Thor/Ignorance/Protection também conferem
execução e snapshot, sem alegar origem nativa de suas regras. Harness final`./scripts/check.sh`: **25416checksGodot +55testesPython +29partidas/0**,
90suítes, parse aprovado, exit0. Log`.tools/lightning-review/final-harness.log`;
SHA dos arquivos/contagens em`docs/lightning-review/verified-source.json`.
O harness inclui o trabalho Mage simultâneo, preservado. A primeira rodada
sem as novas suítes Lightning passou20590/0+29partidas; ela é histórica e não
substitui a execução final com as quatro suítes novas registradas.

GPU realM4Pro/OpenGL4.1: galeriaT1/T2/SS300quadros e vento/tornado300quadros,
1920×1080/relógio60Hz/física20Hz, dois sentidos, pausa30..59 durante os raios
idêntica e retomada. Poses150quadros/seisposes/dois sentidos/padrão/GreatDevilHD,
pausa60..89 idêntica; recortes da morte são idênticos padrão/equipado.
Sala/arenaMiramo real: primeiro raioT2quadro74; pausa30 idêntica, retomada,
HUD acima do feixe e array/RIDs limpos ao sair. Primeira tentativa restrita
abortou134 antes do primeiro quadro; execuções fora do sandbox concluíram.
Primeiro smoke real detectou dois efeitos retidos no array após sair;
`clear_beams` passou a limpar dados/RIDs, repetição aprovada.
Tempos de captura/escrita são registrados noJSON; vídeo60fps representa
seu relógio e não comprova performance60FPS. Perfil isolado e áudio silenciado.

Revisão independente final semP1/P2 nos caminhos focados, após correções de
sinal, void, stride e ordem letal. Hipótese de imunidade doKnight foi descartada:
+0x24 é índiceEPA14(dead), não IDde mobile. Não alteramos oKnight.
ClienteWindows não executado; escuta/mouse e aceite visual do usuário pendentes.

Calendário/geração dos climas, Weakness/Mirror/Random/Thor/Protection/Ignorance
e ações elétricas anexadas ainda conservam bridges offline/C# identificadas.
A ativação nativa completa de itens, regen/teto, apoio/queda, muzzle e origem
convertida também não são anunciados como paridade integral. Outros ataques
recebidos pelo Lightning mantêm seus resolvedores anteriores; a fórmula
nativa nova se aplica à família Lightning, sem migrar todo o roster por efeito
colateral. SS em modos com joias/multiplayer não faz parte deste treino1×1.
Sem versão/app/export/PCK/ZIP/commit/push nesta revisão.

A importação do editor registrou os erros ambientais conhecidos de CA do
macOS (`get_system_ca_certificates:ret!=noErr`) e gravação deeditor_settings.
Isso não foi tratado como log limpo: estão em`.tools/lightning-review/import.log`.
As execuções headless/GPU finais são verificadas separadamente por exitcode,
resumos e busca deSCRIPT ERROR/ERROR, sem omitir falhas só porque um launcher
saiu0. Não houve overrideTLS novo nem exportação de configuração local.

### Classificação de confiança

| Contrato | Classificação | Prova/limite |
|---|---|---|
| DAT/atlas/EPA/PCM, stride e varreduras, choque/flags/propagação, raster | Comprovado por estática | PE/XFS fixados; fixtures e extratos; não é execução Windows |
| Centro/origem no mundo Godot, flush no tick, RNG de variantes | Derivado/adaptado | Ponte explicitada, testes eGPU Godot |
| Weakness/Mirror/Random/Thor/Protection/Ignorance, itens/teto/regen/apoio | Adaptação preservada | Código existente e regressões real×previsão; sem paridade nativa integral |
| Escuta/input humano, cliente original dinâmico e aceite visual | Pendente | Não alegar validação por captura silenciada |

Um check-only adicional sem`--log-file` encontrou permissão negada em
`user://logs` (rotação do logger), semerro de parse. Repetido comlog explícito
em`.tools/lightning-review`, passou/exit0 e log semERROR/SCRIPT ERROR.
O harness completo já usa logs locais; suas contagens/resultados não mudam.
