# Hand-off — Gunbound Recomp 0.20.5

## Bigfoot com acabamento4× — ADR-104

Pedido: aplicar ao Bigfoot a suavização BICUBIC4× aprovada nos botões/lobby.
Nove folhas de `bigfoot/original` (corpo, tiros, luzes, Flame1–3) em
`assets/hd/classic/mobiles_smooth_4x/bigfoot`, por quadro, alpha nearest.
`MobileLooks` liga só no Bigfoot (`smooth`); `ClassicSprite` valida catálogo
(`mobile_smooth_art.gd`) e multiplica apenas recortes de origem. Destino, pivô,
contato, avatar, regras e demais mobiles nativos; folha inválida volta ao nativo.

`test_bigfoot_smooth` 70/0; regressões dirigidas 1196/0 + 1772/0; 21 Python.
GPU1920×1080/60Hz: galeria 210 quadros com pausa idêntica e sala/arena reais
em escala de uso (nativo×4×, movimento). PCK isolado 30/0/exit0. Atlas4×
custa 172 MB descomprimido. Sem app novo, versão ou commit. Aceite visual pendente.
Registro/limites: `BIGFOOT_SMOOTH_4X.md`; evidência em `docs/bigfoot-smooth-4x`.

## Lobby com acabamento4× completo — ADR-103

Correção chat/GM versionada em5732568. Fundo, molduras chat/canal,
preenchimento e50insígnias agora usam BICUBIC4× conservador/alpha nearest.
SeisPNGs em assets/hd/classic/lobby_smooth_4x; fontes/botões prévios intactos.
Tamanho visual/posições/áreas de clique nativos; fallback validado.
Sala permaneceRGBAidêntica. Sem alteração de perfil/combate/versão.

1045checks Godot/0 e21testes Python, revisão independente776/0,54células
conferidas. GPU1920×1080 padrão/stress, PCK223/0/exit0 semoverride/TLSlocal.
CA/editor_settings ambientais detalhados em LOBBY_ART_HD.md. Commit local
autorizado, sem push/app novo. Aceite visual do usuário e mouse físico/escuta
permanecem separados. Capturas/hashes: docs/lobby-art-hd.


## Lobby corrigido e patente GM — ADR-102

Rank deixou de ser level(): perfil novo e legado sem patente recebem GM20,
Administrador do Sistema. Campo rank version4 persiste separado do XP/level;
saldos, avatares e atributos preservados. REA/Hopper confirmou o WORD+4 do
cliente e atlas rank1/rank2, GMquadro24; GM27OpenBound não é a convençãoThor.
GP continua sendo XP local; nenhuma ladder ou tabela competitiva foi criada.

Cartão tem campos separados/contidos, insígnias originais no cartão/canal;
chat recebe Enter, texto literal,64mensagens e roda do mouse. Entrada usa
estilo transparente dentro da faixa. Filtros usam posições nativas; tag de
versão cabe na lateral. Catálogo/extrator de patentes separados, sem substituir
botõesHD/fundos aprovados. Registro/evidência: `LOBBY_UI_RANK.md`.

Validação **1086checks Godot/0**,96/0 repetidos pelo revisor,50quadrosXFS
conferidos. GPU real1920×1080, padrãoGM e stress em `docs/lobby-rank`.
PCK isolado109/0/exit0 com CAambiental e semoverride/TLSlocal. Import/export
registram CA/editor_settings ambientais. Sem execução do cliente original,
sem perfil real nos testes, sem versão/app/publicação. Commit local solicitado em25/10/2026; nova
verificação dirigida735checks/0 antes do versionamento. Aceite visual
manual e eventual aplicativo atualizado ainda separados.

## Versionamento local — 25/10/2026

Por solicitação do usuário, alterações pendentes da sessão anterior reunidas
para commit local: restauração/suavização dos botões, integração, evidências,
testes e skills, incluindo a cópia Codex de `gunbound-client-port` (9 arquivos
idênticos à skill já versionada). Verificação repetida nesta sessão:
`test_classic_buttons_hd test_scene test_items_scene test_roster test_shop_wide`
com **778 checks/0 falhas**, **21 testes Python** da skill HD aprovados e
`git diff --check` sem problemas. Sem push, mudança de versão ou nova exportação;
os limites de inspeção visual/manual e do aplicativo abaixo permanecem.

## Suavização aprovada aplicada — ADR-101

O usuário aprovou o EXIT bicúbico e autorizou aplicação ao lote e adoção na
skill. `ClassicChrome` agora usa `assets/hd/classic/buttons_smooth_4x`:
42atlas/197estados, BICUBIC por quadro e alpha nativo preservado. EXIT
idêntico à prévia aprovada;180arquivos de fontes/exatos anteriores intactos.
Geometria, estados, cliques e fallback permanecem. As cores são interpoladas.

Validação atual: **778checks Godot +21testes Python**, sem falhas. GPU real
1920×1080: layout/hitboxes iguais, mudançasRGBA restritas aos botões. PCK
isolado92/0/exit0 confirma atlas, JSONs, hash do EXIT e ausência de override/TLS
local. Revisão independente aprovada; CA/editor_settings ambientais no registro.

Skill instalada sincronizada:14arquivos idênticos, estrutura/links e21testes
aprovados. Modo exato permanece disponível; verificador não sobrescreve
imagens/relatórios. Registro: `CLASSIC_BUTTONS_SMOOTHING.md`; capturas em
`docs/classic-buttons-smoothing`. Sem app novo/versão/publicação; aplicativo
previamente exportado não foi atualizado. Inspeção visual integral pelo
usuário e escuta/mouse manual permanecem separados das verificações automáticas.

## EXIT — prévia de suavização conservadora

Pedido atual: avaliar melhoria de nitidez antes de um lote. Duas restaurações
IA do estado normal alteraram detalhes/margens e foram rejeitadas para
produção. O usuário aceitou testar suavização algorítmica conservadora.

`docs/exit-restoration-preview/exit-4x-bicubic.png`:1712×180, quatro estados
processados separadamente com BICUBIC, alinhamento/alpha preservados e sem
margens novas. As cores são interpoladas; não é repetição exata de pixels.
Dimensões/grade/alpha aprovados, comparação antes/depois e quatro estados
conferidos. Fonte e atlas ativo intactos. Registro em
`CLASSIC_HD_RESTORATION_SKILL.md` e `docs/exit-restoration-preview/reference.json`.
Aceite visual, eventual integração e lote aguardam decisão do usuário.

## Botões4× integrados no lobby/sala — ADR-100

`ClassicChrome` usa os atlas4× validados, mantendo geometria/estados no
manifest nativo. Apenas recortes de textura mudam de densidade; mínimos,
posições, filtro, stretch e hitboxes ficam iguais. Fallback nativo para HD
ausente/inválido. Os dois JSONs foram incluídos no preset de exportação.

Suítes dirigidas: **735checks/0falhas**, incluindo nova544/0, cliques reais
da viewport e fallback. GPU final1920×1080: lobby/sala RGBA idênticos ao usar
texturas nativas ou4× na mesma cena congelada. PCK isolado91/0/exit0 confirma
42atlas e os dois JSONs, sem override/TLS local. Revisão independente aprovada.
PNG/JSON em `docs/classic-buttons-integration`; registro e limites em
`CLASSIC_BUTTONS_HD_INTEGRATION.md`.

GPU restrita abortou em registro gráfico/fontes; captura fora do sandbox
funcionou. CA/editor_settings ambientais explícitos no registro.95arquivos
de origem e42PNGsHD intactos por hash. Sem nova versão/app; app já exportado
não foi atualizado. Aceite visual/escuta/mouse manual pendentes.

## Todos os botões clássicos4× — derivados exatos

Pedido seguinte aplicado aos41atlas restantes de `assets/classic`. Conjunto
em `assets/hd/classic/buttons_4x`:42PNGs incluindo o CREATE já conferido,
197estados, catálogo com dimensões/ordem/regiões/hashes e registro original.
Checker exato aprovado em42/42; comparação independente de8087792pixels RGBA
sem divergências ou novas cores/margens.95arquivos de origem intactos por
hash antes/depois. Inspeção de amostras START/canal1/Friends/Dragon.

ZIP42PNGs+catálogo em `docs/classic-hd-restoration/classic-buttons-4x.zip`,
CRC e hashes conferidos. Relatórios em `reports/buttons-4x` nessa pasta.
Registro: `CLASSIC_HD_RESTORATION_SKILL.md`. Derivados ainda não conectados
ao runtime; nenhum build, versão ou código alterado nesta etapa.

## CREATE4× — ampliação exata na skill HD

Pedido posterior e escolha explícita do usuário por repetição de pixels.
Saída `docs/classic-hd-restoration/output/create-4x.png`:1712×180RGBA opaco,
quatro estados de428×180, sem margens novas. Checker exato e enumeração
independente conferem308160pixels, zero divergências e mesmas648cores.
PNG inspecionado. É ampliação pixelada4×, sem alegar novos detalhes por IA.

Skill ganhou helper de repetição e `--exact-pixels` no checker;15testes
aprovados no repositório e na instalação sincronizada;11arquivos idênticos,
estrutura/links válidos e revisão independente aprovada. A nova tentativa
IA2164×726 também foi rejeitada e preservada.
Registro: `CLASSIC_HD_RESTORATION_SKILL.md`. Fonte, runtime e build preservados.
Aceite visual do usuário e eventual integração permanecem separados.

## Skill gunbound-classic-hd — restauração fiel (ADR-099)

Pedido atual atualiza a skill, sem trocar arte ativa. Prompt completo do usuário,
fonte visual única, preservação de geometria/paleta/alpha/quadros e alvo4×
substituem o padrão de acabamento2.5D. Rig/efeitos aprovados continuam acessíveis
no seu escopo. Registro: `CLASSIC_HD_RESTORATION_SKILL.md`.

Três gerações reais com `assets/classic` foram rejeitadas: lobby1448×1086
(alvo3200×2400, alpha/aparência alterados), CREATE2170×725 (alvo1712×180)
e Mage2048×768 (alvo1260×188); atlas ganharam padding/aspecto errado.
Brutos, prompts e JSONs/hash em `docs/classic-hd-restoration`. Nenhum foi aplicado.
Checker read-only:9testes aprovados; estrutura válida e cinco cenários de
comportamento revisados independentemente. Sem validação Godot/GPU nova nem build.
Cópia instalada sincronizada com backup;9testes também aprovados na instalação,
estrutura/links válidos e arquivos idênticos. Aceite de arte futura continua pendente.

## Sala — ícone do Dragon

`b_ready_mobile14` do cliente é o Aduka, o mobile que vem depois do Grub.
A grade entregava esse botão ao Dragon (ID 14). O Dragon passa a usar o
quadro 0 do atlas `tank14` (`b_ready_mobile_dragon`); o Aduka (ID 16) fica
com o botão original 14. Sem mudança de ID, de combate ou de versão.

## Sala — Knight, Aduka e item de 2 slots

O ícone de Knight e de Aduka colava o quadro 0 do atlas por cima do botão
inteiro de `b_ready_mobile01`, que já traz o Armor. O recorte do spritesheet
é um só mobile; o lugar A/B também desenha um atlas e um avatar, o mesmo
caminho dos outros clássicos, sem empilhar casco, arma e piloto. O fundo do
botão agora perde o Armor antes da colagem. Item de 2 slots é um retângulo
só (os dois lugares e o vão); item de 1 slot continua em um. Clique na peça
remove o item inteiro. Catálogo, gravação e o limite de 6 slots permanecem.
CPU sem itens. Sem rede, sem commit, sem reexportar e sem mudar a versão.

Suítes: `scripts/check.sh test_items_scene test_scene test_roster`.
Resultado: **154 checks, 0 falhas** (itens 47, cena 27, roster 80).
Aceite visual da sala ainda depende do olhar do usuário. O cliente original
não foi executado. Sem captura nova.

## Sala — grade, lugares e avatar — ADR-096

A grade 8×2 é a única escolha de mobile. Cada ícone cabe na própria célula
do poço (36×28, passo 41×40); o PNG de 63×47 não invade o vizinho. O clique
aplica no piloto. O lugar B só muda o modo (“Escolhendo: máquina”) e o
próximo clique da mesma grade vale para a CPU. O modal de mobile saiu; o
popup de CHANGE permanece.

Os lugares A e B desenham o mobile num nó acima do fundo e atrás dos nomes.
O piloto usa o avatar equipado do perfil, no mesmo encaixe da arena. A CPU
fica com o piloto padrão, sem as peças do perfil. O casco na sala é 52 px
nativos para o cell mais largo caber nos 124 px do lugar. Sem rede, sem
commit, sem reexportar e sem mudar a versão.

Suítes: `scripts/check.sh test_scene test_roster test_bigfoot test_classic_mobiles test_items_scene`.
Resultado: **324 checks, 0 falhas** (cena 27, roster 80, Bigfoot 28, clássicos 142, itens 47).

Pendente: aceite visual do usuário (pés na base, cabeça abaixo do nome, sentido). Sem captura nova. O cliente original não foi executado.

## Lobby clássico e sala — ADR-096

A entrada passou a ser o lobby (`gamelist_back`). Create abre a sala 1×1
(`ready_back`), que conserva mobile, CPU, itens, apelido, dificuldade, clima
e Iniciar. Buddy não entra. Ranking e Join ficam desabilitados. Sem rede.
Rank/GP do cartão são nível e XP locais. O mapa segue Miramo Town A. Jewel,
Death e Big Bomb não viram regra. A loja volta à tela que a abriu. O app não
foi reexportado e a versão do `project.godot` não mudou.

Extração: `python3 scripts/import_classic_lobby.py` (SHA do XFS conferido).
Suítes: `scripts/check.sh test_scene test_items_scene test_roster test_bigfoot test_classic_mobiles test_shop_wide`.

Resultado: **336 checks, 0 falhas** (cena 27, itens 46, roster 63, Bigfoot 28,
clássicos 136, loja larga 36). O ESC da loja aberta na entrada volta ao lobby;
`test_shop_wide` foi ajustado para essa volta, sem afrouxar o resto.

Pendente: aceite visual do lobby e da sala, escuta, e o cliente original não
foi executado. Sem captura nova. A grade de mobiles cabe no painel medido, então
os ícones de 63×47 aparecem reduzidos. Importação Godot dos PNG concluiu;
gravar `editor_settings` falhou por permissão ambiental, como nas entregas anteriores.

## Itens da sala no painel direito

Os seis lugares pintados em `ready_back` mostram o ícone do item. O nome
deixou de ser um rótulo no poço abaixo desses retângulos, onde vazava para
fora. A escolha fica nesse painel, grava em `options.items` ao mudar e não
abre o modal Select Item. Sem rede, sem regra nova de combate e sem app novo.

Suítes: `scripts/check.sh test_items_scene test_scene` — **74 checks, 0 falhas**
(itens 47, cena 27). Sem captura da sala nesta correção; o cliente original
não foi executado e não houve validação de escuta nem de mouse.

## Correções ASate/JD/Aduka/Raon — ADR-094

Ler SPECIAL_MOBILES_CLASSIC_FIX.md e os quatro registros CLASSIC_FIX.
Módulos próprios integrados ao passo real/previsão: Ion com1/3/6 filhos;
JD T2 atrai, SS repele e causa dano por tick; Aduka T2/SS chamam Thor fora
do clima Thor; Raon T1 três componentes e minas com autoria/clocks próprios.
Minas SS concluem antes da troca de turno; fase `mines` resolve S2 antes
do input. CPU reconhece plantio/Thor. Thunder preservado uma vez no guia.
Cristal JD novo substitui o anterior do mesmo dono. Render EPA/arte original,
laser Thor aditivo e PCM Ion T1/T2; SS Ion sem stream porque fonte ausente.

Verificação final: **11493 checks Godot +29 testes Python +29 partidas**,
zero falhas; parse aprovado. Integração nova263/0, revisão independente
tratada. App/ZIP0.20.5 reexportados e assinados, versão/CRC conferidos;
probe PCK isolado68/0/exit0, com ressalva ambiental de CA. Export/import
registram CA/editor_settings sem permissão; sem SCRIPT ERROR/leaks no PCK.
Após o último ajuste simultâneo da sala, seis suites dirigidas184/0 e nova
exportação/PCK confirmam a composição final, sem runtime mais novo que o pacote.
QA GPU não executou: SIGABRT/FontRegistry antes do primeiro quadro;
LaunchServices também falhou. Script temporal pronto e parse aprovado,
sem captura nem aceite visual/escuta novos. Detalhes/hashes/logs no registro.
Dano/colisão comum, apoio/parede e partes de minas S2 continuam adaptações
declaradas. Perfil, avatares/HD e mudanças locais da sala preservados.
Commit local autorizado pelo usuário em25/10/2026, sem envio ao remoto.

## Sala inicial 1×1 — ADR-092

A entrada deixou de ser o cartão “Preparar treino”. `menu_screen.gd` monta a
sala: lugar do piloto, lugar da máquina, Miramo Town A no centro, retrato e
Iniciar. Configurações da partida guarda apelido, dificuldade e clima até
Aceitar; Cancelar restaura. Mobile aplica no clique. O botão CPU escolhe o
mobile da máquina (ADR-093); sem escolha, vale `Mobiles.opponent`. Piloto e
máquina aparecem no casco nativo de 60 px (ADR-095), num palco da altura do sprite. Itens segue
o PopupSelectItem. Opções do cliente não entraram nesse menu. Sem regra nova
de combate, sem troca de mapa e sem build.

Validação: `test_scene` (cancelar/aceitar/mobile/CPU) e `test_items_scene`
(apelido e contagem de itens). Captura visual da sala ainda não registrada.
Aceite do usuário pendente.

## Ghidra adotado na skill — ADR-091

gunbound-client-port agora prefere Ghidra headless direto, com
`scripts/run_ghidra.py`, `scripts/ExportClientEvidence.java` e
`references/ghidra.md` na própria skill. Não depende dos scripts temporários
da avaliação anterior. Importação nova, seeding explícito de entradas
comprovadas, referências/vtable/dados e reabertura testados;22extratos
idênticos. Função ausente retorna falha apesar do exit0 do launcher.

Ponte estática→Godot: float8/LUTs extraídos e8checks independentes de
ângulo/seção passaram; suites dirigidas1368/0. Runner5testes Python
aprovados, incluindo descendente resistente ao TERM após timeout; validator,
links/UI/alias aprovados. Testes independentes antes/depois da skill;
detalhes, hashes, limites e evidência em GHIDRA_SKILL_VALIDATION.md.
Não executamos o cliente original/GUI nem QA visual novo. Esta tarefa não
conclui a implementação0.20.4 preexistente. Sem mudança de runtime/build.
Versionamento local autorizado posteriormente pelo usuário, após pull/merge
da main. Revisão final: cinco testes Python do runner aprovados; alterações
da skill e registros preparados para commit local, sem push. Override de
certificados permanece local e excluído do versionamento.

## Avaliação de ferramenta — Ghidra 12.2

Pedido atual: avaliar Ghidra após problemas no Hopper. Resultado em
[GHIDRA_EVALUATION.md](GHIDRA_EVALUATION.md): headless direto funciona no Mac
arm64/Java25, autoanálise26s/2408funções. Quatro de oito rotinas Mage exigiram
indicar entradas conhecidas em vtables; depois8/8 decompiladas e reabertura
readOnly com24extratos idênticos. Cache redirecionado e projeto fora de
`.tools` (Ghidra rejeita componente de projeto iniciado por ponto).
REA6.7.0 atual sem GHIDRA_INSTALL_DIR e sua política aceita12.1.x, rejeita12.2;
usar CLI direta neste ambiente. GUI/cliente original não executados; sem
benchmark novo do Hopper. Nenhuma regra/asset/build alterado nesta avaliação;
trabalho parcial0.20.4 preexistente não foi validado por ela.

## Estado atual — restauração Bigfoot/Mage 0.20.3

Pedido atual substitui parcialmente a preservação HD da ADR-088. Ler
ORIGINAL_MAGE_BIGFOOT.md e ADR-089. Atlas tank2/tank5, EPA, RiderPivot,
tiros/luzes/impactos extraídos em subpastas original/, sem sobrescrever os
arquivos anteriores. Catálogo ativo usa ClassicSprite/ClassicMageSprite,
escala nativa, miras e auras originais. Imagens/descritores HD anteriores
conservados como histórico; avatares/equipamentos, regras, IDs e perfil
mantidos. Mage T1/T2 conservam composição OpenBound adaptada; SS nativo usa
ssflame2. Bigfoot T2 usa seu flame52 em vez do Armor do fork.

Validação atual: **8059 checks Godot + 17 testes Python + 29 partidas**,
zero falhas e parse aprovado. Oráculo de pixels/hotspots/RiderPivot/EPA do
XFS; regressão ativa 39/0. Galeria GPU real 1920×1080/210 quadros/60 Hz:
poses, sentidos, inclinações, tiros/impactos; pausa de 30 quadros idênticos.
São fixtures de apresentação, não execução do cliente ou tiros reais.
PNG/MP4/hashes em docs/original-mobiles/. Captura específica menu/loja/arena
preparada e parse aprovado; execução posterior bloqueada por timeout UI.
Suites de cena/modelos cobrem esses fluxos.

App/ZIP **0.20.3** exportados, assinatura profunda/estrita, versão e CRC
conferidos. PCK isolado 44/0/exit0: 16 sprites/JSON/recursos carregam, sem
override/TLS local nem SCRIPT ERROR/leaks. Ressalvas ambientais de CA no
smoke e CA/editor_settings no export detalhadas no registro. Override de CA
usado apenas no harness e removido antes do build. Aceite visual do usuário,
mouse manual e escuta pendentes. Nenhum commit/push.

As seções abaixo são históricas; resultados anteriores não validam 0.20.3.

## Catálogo clássico — REQ-46, ADR-089

Pedido: manter todos os avatares originais do Gunbound clássico e refazer o
catálogo com equivalência ao launcher e ao servidor jglim. Ler
`AVATAR_CLASSIC_CATALOG.md`. A versão do aplicativo continua a da `main`
(0.20.2); este índice não reexporta o app.

Na `main`, REQ-45 e ADR-082 já nomeiam o roster dos 16 mobiles e o brilho do
chifre. O catálogo de avatares fica em REQ-46 e ADR-089 para não reutilizar
esses números.

- `avatar.xfs` local é o TestClient do launcher (22968 bytes, mesmo SHA-256).
  562 registros, 479 compráveis. Nenhum foi removido. `ff.dat` continua vazio;
  `ff00001.img` e `sff00001.img` ficam fora da loja. Love Cupid (id 143) não
  existe nesta versão e o decodificador não o inventa.
- `assets/xfs/avatars/classic.json` é o índice: DAT, slot do servidor, preços,
  oito status na ordem do AvatarInfoProcessor e texto CP949. A arte e a chave
  `xfs:gênero:categoria:id` permanecem. Categoria da loja não muda, então
  equipamento salvo continua na mesma peça.
- WORD: id nos 15 bits baixos, bit 15 masculino. DWORD: slot no terceiro byte
  (corpo, cabeça, olho, bandeira). Equipado: quatro WORDs nessa ordem. O
  conjunto `amigos` (`448043802480A480`) resolve Rocker Suit, Rocker Hair,
  Dizzy Glasses e Bazooka. Padrão masculino `0080008000800000`; feminino oito
  zeros. Bandeira vazia é WORD 0 nos dois gêneros.
- 28 descrições saem de CP1252 para CP949. A reticência volta a ser `…` e o
  UserID do concurso volta a `까꿍사냥꾼`. Preços e bônus intactos.
- Validação na branch, antes do merge: `test_xfs_import.py` 12 testes;
  `test_xfs_catalog.gd` 3816 checks, zero falhas; regressão de catálogo,
  perfil, equipamento, saldo, atributos, migração HD, arte e loja XFS, 2178
  checks, zero falhas. Sem partida completa: dano, atraso e o snapshot de
  bônus não mudaram de fórmula.
