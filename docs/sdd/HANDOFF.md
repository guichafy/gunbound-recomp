# Hand-off — Gunbound Recomp 0.20.5

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
