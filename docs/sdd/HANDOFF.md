# Hand-off — Gunbound Recomp 0.20.5

## Aceite e commit local dos ajustes da sala — 25/10/2026

Usuário aprovou o resultado final ("Agora ficou bom") e autorizou o commit
de todos os ajustes pendentes da sala: ADR-107 a114, incluindo cards/Ready,
dificuldade da CPU, clima, START/SETTINGS, modal/fonte, alpha e alinhamento.
Código, fontes/derivados preservados, testes e evidências reunidos na main.

Verificação repetida para o versionamento:1350checksGodot/0 em8suítes,
21testesPython/0 da skillHD,24hashes dos catálogos novos conferidos e
git diff --check limpo. Aceite visual final confirmado; a versão aprovada
é `room_settings_word_baseline`. Sem push, nova versão ou nova exportação
de app/ZIP/PCK; os resultados de pacotes anteriores são históricos.

## Alinhamento visual dos T de SETTINGS — ADR-114

Usuário apontou TT acima deSE/INGS. Compensação óptica de+1pixel nativo
somente nos dois T, nos quatro estados, em `room_settings_word_baseline`
78×22. Usa a linha superior visível, incluindo suavização, em vez de alinhar
apenas a caixa de pixels fortes. Fonte/1436facesRGBA, espaços, acabamento,
transparência, demais letras e START aprovados preservados.

988checksGodot/0; dois novos checks reproduziram o erro anterior. GPUFullHD
e revisão aprovadas: START inteiro idêntico, bordas transparentes, estados,
fallback e clique/modal. Ver `SETTINGS_BASELINE.md` e `docs/settings-baseline`.
Sem nova exportação/PCK/app, versão, commit/push. Aceite visual separado.

## Acabamento único da palavra SETTINGS — ADR-113

Usuário aprovou alpha daADR-112 mas rejeitou os recortes. Agora
word_polished78×22/quatro estados mantém1436facesRGBA nativas exatas, com
espaço2px e um contorno azul único2px/alpha suave0,15px. RGBBICUBIC4×;
fallbackRGB nativo/alpha de áreaBOX semringing. Todas4bordas transparentes.
Casca eSTART aprovados intactos; topo absoluto das faces continua18.

986checksGodot/0 em4suítes. GPUFullHD confirmaSTART inteiro idêntico àADR112,
cenário nos cantos,4estados/fallback da palavra e clique/modal preservados.
Revisão final aprovada;PCK96/0/exit0, semoverride, ressalvas ambientais
CA/editor_settings registradas.
VerSETTINGS_WORD_FINISH.md e docs/settings-word-finish. Semapp/ZIP,versão,
commit/push; aceite visual do usuário separado.

## Alpha real e composição de SETTINGS — ADR-112

Casca107×45 `room_footer_shell_clear` nas texturas reais deSTART/SETTINGS:
cantos externos transparentes, sem cenário gravado no sprite. FonteSTART
aprovada preservada em camada separada. SETTINGS83×20 `word_isolated`, Tdo
START,IsemfragmentoX, espaçamento3px e topo18 comum; componente8conexa remove
fragmentos do A vizinho nosTs.1436pixels de faceRGBA exatos às fontes.

1344checksGodot/0 em8suítes. GPUFullHD: cenário nos cantos, letteringSTART
idêntico, quatro estados/fallback da palavra e cliqueSETTINGS preservados.
Revisão final aprovada;PCK96/0/exit0,semoverride, ressalvas ambientaisCA/
editor_settings registradas. Fontes/derivados anteriores mantidos. VerROOM_BUTTON_ALPHA.md e
docs/room-button-alpha. Semapp/ZIP,versão,commit/push; aceite visual separado.

## SETTINGS retorna aos pixels completos da fonte — ADR-111

Usuário rejeitou a reconstrução daADR-110 porque alterou a fonte. Registro
ativo room_settings_word agora aponta aWordComplete74×20/quatro estados,
copiandoRGBA completo dos glifos/contornos nativos. Limpar fundo/vizinhos e
ajustar junções; não recriar preenchimento ou traço. Versões rejeitadas
preservadas. START aprovado, modal e fonteASCII permanecem iguais.

969checksGodot/0;629núcleos e3156contornos exclusivosRGBA idênticos às fontes.
GPUFullHD:START aprovado idêntico,4estados/fallback eSETTINGS abre modal.
Revisão aprovada após corrigir margem do push;4364pixels de stencil dentro
dos limites. PCK79/0/exit0,semoverride,comressalvas ambientais registradas.
Contrato/evidência:SETTINGS_ORIGINAL_LETTERS.md e docs/settings-lettering-original.
Semapp/ZIP,versão,commit/push; aceite visual do usuário separado.

## Acabamento de SETTINGS; START aprovado preservado — ADR-110

Usuário aprovouSTART e rejeitou emendas deSETTINGS daADR-109. SETTINGS agora
usa palavraRGBA única81×17, recuperada dos glifos nativos, com altura/espaço/
contorno comuns e acabamento4×; não usaSystemFont. Quatro estados e fallback,
sem retângulos opacos dos recortes. Originais,modal efonteASCII preservados.

965checksGodot/0, revisão aprovada com reproduçãoRGBA dos dois atlas; GPU
FullHD dos4estados/fallback/clique real. START aprovadoRGBA idêntico na mesma
cena congelada. VerSETTINGS_LETTERING_FIX.md e docs/settings-lettering-fix.
Sem novoapp/ZIP,versão,commit/push; aceite visual permanece separado.

## SETTINGS, modal clássico e fonte preservada — ADR-109

START semseta eCHANGE substituído porSETTINGS semsetacircular. Bordas azuis
recortadas doSTARTGAME; START conserva palavra raster eSETTINGS usa letras
dos sprites originais, conforme correção do usuário que rejeitouSystemFont.
Modal azul560×470 com moldura nativa, rádios eOK/Cancel;95glifosASCII8×12 do
font.fnt original, fallbackexistente para caracteres fora desse repertório.
Layout é adaptação solicitada, sem novos modos/regras/perfil.

1317checksGodot/0 em8suítes (modal25/0),21Python/0. GPUFullHD comprova fonte
visível/corouro, botões/modal eidle;9quadrosRGBA/95glifos/9120bits conferidos.
Revisão aprovada após correção deESC com foco noLineEdit; cancelar/aceitar e
Start testados com cliques reais. VerROOM_SETTINGS_CLASSIC.md e captura atual
docs/room-settings-classic; versões intermediárias de fonte foram descartadas.
PCK isolado70/0/exit0,semoverride,comressalvasCA/editor_settings ambientais;
semapp/ZIP,versão,commit/push. Aceite visual,
mouse físico eescuta separados das verificações automatizadas.

## Ajustes finais da sala — ADR-108

Dificuldade agora aparece comoCPU · Normal/Leve/Precisa no card da máquina,
atualizada só aoAceitar. Oito pesos brancos têm base laranja restaurada por
amostra da textura ativa, sem poços escuros; fontePNG original intacta.
START usaSTARTGAME azul nativo107×45/quatro estados em660,552, no padrão
EXIT/CHANGE. CatálogoChrome43registros; START verde e42anteriores preservados.

1286checks Godot/0 em7suítes,752/0 na repetição final,21Python/0. GPUFullHD
confirma8baseslaranja,Normal/Precisa,estadosSTART eidle preservado. Revisão
independente aprovada.4quadros/alpha conferidos;222PNGs prévios intactos.
PCK isolado55/0/exit0,semoverride;CA/editor_settings ambientais registrados.
Contrato/resultados:ROOM_FINAL_POLISH.md e docs/room-final-polish. Sem novoapp,
ZIP,versão,commit/push; app exportado anterior não atualizado.

## Cards da sala, Ready e configuração do mapa — ADR-107

Pedido posterior corrige apoio144 daADR-106: composição em105/563,155,
encaixada na faixa nativa. Nomes dos mobiles ocultos nos dois cards, incluindo
Random; apelido/CPU,avatar/idle preservados. Ready/chave e cinco placas
SOLO/1:1/A SIDE/NODEATH/BASIC usam arteXFS,4×conservador/fallback. Placas
refletem somente regras existentes; nenhum modo novo. Chave não cobre nome.

7PNGs/25janelas,64checks independentes deRGBA/alpha/hash;456assets prévios
intactos. Regresso1093Godot/0 em10suítes,21Python/0. GPU1920×1080,17escolhas
nos dois lados,Nak equipado,24quadros20Hz/20variações,âncorasfixas/heldtime
idêntico. Revisão aprovada apósP2: Ready usaIGNORE e preserva clique no card,
com cliques reais de viewport e probe negativoPASS reproduzindo2falhas.
PCK40/0/exit0,semoverride; ressalvas ambientaisCA/editor_settings registradas.
VerROOM_CARD_FIDELITY.md e docs/room-card-fidelity. Sem novoapp/ZIP,versão,
commit/push; app anterior não atualizado. Aceite visual/mouse físico/escuta
separados das verificações automatizadas.

## Versionamento e push solicitados — 25/10/2026

Usuário autorizou versionar todas as correções pendentes da sala e enviar ao
origin. Preparação na main, incluindo ADR-105/106, assets nativos/4×, Random
com avatar, idle ativo, catálogo/slots e evidências/testes. Verificação repetida:
1027checks Godot/0 em10suítes deUI/avatar/animação,21testes Python da skill,
100hashes do manifest conferidos e git diff --check limpo. Fetch confirmou
origin/main como ancestral, com3commits locais anteriores ainda não enviados;
o envio solicitado inclui esses ancestrais. Sem novoapp/ZIP ou versão.

## Sala corrigida, Random com piloto e idle ativo — ADR-106

Catálogo agora usa tiles nativos uniformes64×43 com símbolos1/2slots; barra
usa35/71×31, seis posições. Setas encaixadas. Mobile tem âncora fixa no chão144,
faixaA/B atrás e nome à frente; idle/avatares recebem elapsed, sem seno adicional.
Random usa corpo original OpenBound12quadros, avatar equipado e4×/fallback;
UI−2 e sorteio14/15 noStart intactos. Nome/mapa duplicados removidos, só setas
laterais nativas; inativas enquanto MiramoTownA for o único mapa implementado.

23PNGs/56janelas,132checks de arte +Randomfonte/alpha/hash conferidos;
359arquivos anteriores e11PNGs da etapa anterior intactos. Regressão1720/0,
rodada finalUI/animação1027/0,21Python. GPU24quadros com animação/âncoras fixas,
avatarRandom altera só piloto/semRNG. PCK109/0/exit0 semoverride/TLSlocal,
CA/editor_settings ambientais registrados. VerROOM_POLISH.md e docs/room-polish.
Sem novoapp/versão/commit/publicação; aceite visual/mouse/escuta separados.


## Sala conforme foto — ADR-105

Pedido substitui grade8×2/abas daADR104:14mobiles comuns+Random em5×3.
Knight/Dragon não têm botões diretos;Random−2 é apenas escolhaUI e sorteia
14/15 aoStart, com RNGprivado e flags independentes piloto/CPU. Mantém seleção
na sala/loja. Catálogo único11itens com roda/setas,6slots preservados.
Oito lugares têm faixasA/B nativas,nomes na base e mobiles acima delas.

11PNGs/15janelas4× novas emroom_reference_4x,alpha nearest; source eHD anteriores
intactos. Setaspressed17px versusnormal16 são PNGs separados, sem padding.
1669checks Godot/0,21Python; revisão455+7+81semfalhas. GPU1920×1080 ePCK53/0/exit0,
semoverride/TLSlocal. Fonte/hash/limites:ROOM_REFERENCE_LAYOUT.md;
capturas emdocs/room-reference. Sem novoapp/versão/push/commit solicitado.
Perfil/batalha/recompensas preservados. Aceite visual,escuta/mouse físico
permanecem separados das verificações automatizadas.


## Sala clássica e acabamento4× — ADR-104

Trabalho anterior já versionado emd8b50c7. Sala usa mapa/retratos nativos,
fundo e11folhas de itens em BICUBIC4× (14PNGs/84células,alpha nearest).
Ghidra confirma janelas332,51/378,390. CabeçalhoGM, pesos de clima, avisos e
contenção dos textos implementados. Dragon/Knight ficam textuais, pois a
fonte éRandom. Grade8×2,16mobiles,estados/hitboxes e6slots preservados.
ItemArt de batalha e perfil/combate/versão intactos. Fallback nativo validado.

1256checks Godot/0,21Python, revisão final172/0 e auditoria95/0. GPU real
1920×1080 normal/stress, mesma geometria; galeria16retratos. PCK183/0/exit0,
semoverride/TLSlocal. Fonte/PNG/catálogos incluídos, commitlocal autorizado.
Limites ambientais e escopo adaptado em ROOM_UI_FIDELITY.md; capturas/hashes
emdocs/room-ui. Sem push/appnovo; app previamente exportado continua anterior.
Aceite visual/escuta/mouse físico permanecem separados.


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
