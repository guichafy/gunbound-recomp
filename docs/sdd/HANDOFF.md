# Hand-off — Gunbound Recomp 0.16.0 / migração HD em andamento

## Migração HD integral — pedido atual20/10/2026

Usuário apontou que só as miniaturas novas foram regeneradas, enquanto a
maioria das peças vestidas continuava original. Solicitou controle e migração
completa. Ler AVATAR_HD_MIGRATION.md; controle em docs/avatar-hd-migration.
Não confundir retrato HD com personagem HD. Escopo:550registros com arte,
629camadas; três acessórios vazios e nove placeholders N/A. Preservar regras,
perfil e fontes. Preparação dos lotes e registro individual em andamento.

O controle encontrou erro do decodificador: ARGB4444 preto com alpha explícito
era apagado, deixando cinco acessórios invisíveis. Teste reproduziu e passou
após respeitar alpha; derivados corrigidos usam sufixo_alpha, sem apagar os
PNGs anteriores nem os XFS. Importação0.17 ainda requer validação/export próprios.

37lotes/1161componentes preparados por prepare_xfs_avatar_hd.py.
Fonte/jobs/prompts em assets/hd/avatars/xfs/source (.gdignore). Controle inicial:
zero peças migradas validadas,18/550miniaturas anteriores. As12bases do HD
anterior foram incluídas no lote037: reaproveitamento provisório não comprova
migração XFS. Controle gerado é a fonte das contagens atuais, sem aceitar
automaticamente uma imagem por ter sido gerada.

AvatarXfsHD/AvatarArt consomem masters próprios, sem usar a miniatura como peça.
Capturas por lote com fonte/HD/vestido/Mage+Bigfoot em docs/avatar-hd-migration/qa;
audit_xfs_hd_runtime confirma uso real e registro constante por camada.
Aceite exige hashes da arte e do renderer atuais. Lotes003–006 refeitos com
olhos abertos; fase preta de fh46L rejeitada em favor da fase luminosa real.
Transparência de luz adaptada em memória, sem modificar os PNGs fonte.
112checks dirigidos passaram; migração integral/export0.17 ainda pendentes.

## Avatar Shop XFS0.16 — entrega funcional de referência

REQ-20/38/39/40/41, ADR-071/072; AVATAR_SHOP_XFS_0_16.md. Catálogo562ativo,
479compráveis, preços/modificadores nativos, namespaces separados e Profile3.
Migra apenas identidades verificadas; Pilot Goggle antigo1→XFS2, Kappa legado
continua possuído. Saldo/XP preservados. Atributos do piloto+equipamento são
copiados na partida, com teto50, penalidades assinadas e previsão compartilhada.

Layout ciano800×600 do graphics.xfs, catálogo3×3 à esquerda/inventário à direita,
centralizado1440×1080 em FullHD; laterais com fundo regenerado. Compras,
vestir/recarga, filtros/páginas/gêneros e previews funcionam. Nome/badge,
miniatura/stats e busca/saldo em áreas separadas. Preço vetorial uniforme
RGB0/131/179, confirmado por amostra GPU. Controles sem regra local ficam
indisponíveis com explicação. Sem rede/contas/amigos/presentes/venda nova.

3163checks+10partidas passaram; após último atlas de retratos,106checks
dirigidos e oito testes Python passaram. GPU1920×1080,120frames60Hz/MP4,
compra/atributos/fallback/gêneros/mobiles/Ghost e três contatos de montagem
em docs/avatar-shop-xfs. Smoke PCK fora do projeto PASS:562registros,
assets/compra/vestir/recarga/batalha,1920×1080 e1280×800. App/ZIP0.16.0
reexportados/assinados. Perfis isolados; C# intocado; sem commit/publicação.

HD efetivo desta entrega: fundo1672×941,18miniaturas em atlas887×1774 e
identidades vestíveis reaproveitadas do HD antigo. Demais peças/miniaturas
mantêm fallback original; não é migração HD completa. Revisão inicial corrigiu
seleção invisível no fallback; revisão final interrompida por limite de uso.
Testes e inspeção local concluídos, sem segunda aprovação independente.

## Avatar Shop Full HD pelo vídeo0.15 —20/10/2026

REQ-20/38/39/40, ADR-070; ler AVATAR_SHOP_VIDEO_0_15.md. Usuário confirmou
**Presente→Comprar→Experimentar**, substituindo a ordem C# da0.14.9.
Loja16:9, grade3×3, cards240×140, inventário compacto/equipado amarelo, abas
sobre a grade e prévia Avatar/Mobile. Preços vetoriais uniformes e fonte com
oversampling local; no FullHD não há barras.1280×800 centra1280×720.

Window salva/desativa/restaura o stretch da arena ao entrar/sair da loja.
Revisão independente encontrou esse problema de escala; corrigido e coberto
por input real, ESC, reentrada, redimensionamento e batalha. Rodada final do
revisor interrompida por limite de uso, sem segunda aprovação independente.
Capturas anteriores que desligavam stretch artificialmente foram substituídas.

GPT Images/gunbound-classic-hd: fundo1672×941 e retrato No Goggles/No Flag
1254×1254RGBA (recorte870×1076, mipmaps). Originais/brutos/prompts preservados;
metadados validados com fallback. Retrato é só UI:15registros/13peças vestíveis
mantidos. FullHD é a composiçãoGPU1920×1080; não confundir com tamanho do PNG.

**1949checks rápidos sem falhas, incluindo36de test_shop_wide**. Dez partidas
completas passaram nesta entrega antes do último ajuste só de retrato/loader.
GPU1920×1080 e120frames/60Hz, MP4 de2s, estados de compra/inventário/atributos,
categorias/gêneros/mobiles/fallback em docs/avatar-shop-video. Force_draw no
harness evita espera da GPU quando a janela fica encoberta no macOS.
Faixa de preço verificada:1corRGB121/159/211, tanto GPU quanto PCK.

App/ZIP0.15.0 reexportados, versão e assinatura estrita conferidas. Smoke real
do PCK isolado em/tmp passou com novos assets/metadados, exclusão de brutos,
vestir/recarga/batalha e capturas1920×1080/1280×800. Perfil real e fonte C#
preservados. Baseline0.14.9 sujo foi mantido; sem commit/push/publicação.
Próximo passo: usuário reabrir builds/Gunbound Recomp.app e validar aparência.

## Auditoria de estado e layout da loja0.14.9

Pedido: investigar bugs/design/posicionamento usando o C#. REQ-20/38/39/40,
ADR-069; AVATAR_SHOP_AUDIT_0_14_9.md. Usuário confirmou abas sobre os cards e
ordem Experimentar/Vestir→Comprar→Presente. Inventário lateral/grade3×3 mantidos.

Corrigidos seleção invisível após busca/página, seleção alterada antes de save,
feedback ausente na grade e busca vazia sem explicação. Legendas separadas da
arte com hitbox incluindo texto/baseline comum. Label reaplica size após fonte
para evitar caixa mínima da fonte padrão16px. Prévia Miramo usa crop uniforme;
rig/mobile/anatomia não alterados. Preço vetorial0.14.8 continua nítido: GPU e
PCK com uma única cor RGB121/159/211 nas amostras sem texto.

**1913checks+10partidas completas, zero falhas**, incluindo42da nova auditoria
e40de paridade. Revisão independente sem achados. GPU1920×1080 HD/fallback,
compra/moeda única, atributos, busca vazia, gêneros/mobiles e120frames60Hz em
docs/avatar-shop-audit. App/ZIP0.14.9 reexportados, assinatura estrita válida;
smoke do PCK isolado em/tmp passou com compra/vestir/recarga/batalha e assets.
Versão do menu também atualizada (ainda mostrava0.14.5). Perfis isolados somente;
sem publicação, alteração de combate/atributos, novo PNG de arte ou edição C#.
Próximo passo: aceite visual/funcional do usuário no app0.14.9.

## Fundo dos preços nítido0.14.8

Usuário ainda viu borrado após0.14.7. REQ-20/38, ADR-068. Causa: linha da
textura75..76 (4px HD) ampliada para27px lógicos espalhava suas variações
em manchas. Centro da faixa agora é retângulo vetorial azul uniforme no
StyleBox; recortes de laterais/borda branca/rebites preservados. Sem novo
PNG, alteração de regras, retratos, layout, perfil ou atributos.

GPU1920×1080 HD/fallback/compra/roster em docs/avatar-price-crisp. Amostra
sem texto passou de527cores diferentes para1(RGB121/159/211); região do
PCK1280×800 também tem essa única cor. Evidência em pixel-check.json.
1848checks em check.sh --quick, zero falhas. Partidas longas não repetidas:
alteração apenas visual,10passaram na0.14.6. App/ZIP0.14.8 reexportados,
assinatura estrita válida e smoke GPU/PCK isolado em/tmp passou. Perfis
isolados, fonte C#/arte original preservados; validação do usuário pendente.

## Cards: preço e informação do avatar0.14.7

Validação do usuário: retângulo dos preços cobria detalhes da moldura; imagem
externa mostrava bônus. REQ-20/38/39, ADR-067, AVATAR_CARD_FIX_0_14_7.md.
ColorRect foi retirado; a faixa azul agora é parte da composição da textura,
mantendo a borda branca, laterais e acabamento inferior/rebites. Card166×147,
retrato126×66 com aspecto preservado e linha “Cosmético · sem bônus”. Tooltip
explica melhorias via Atributos; confirmação de compra também informa o efeito.

Fonte conferida: AvatarMetadata.cs/JSON sem modificadores; Player.Attribute
é do piloto e EquipAvatar só altera IDs. Vestir não aumenta ataque/mobile
nesta versão do OpenBound, esclarecido na conversa. Não copiamos números de
outra imagem. Nenhuma mudança de combate/perfil/preços/PNG/anatomia.

1848checks em check.sh --quick, zero falhas; inclui280de loja/cena/continuidade.
Partidas longas não repetidas porque só apresentação mudou (10passaram na0.14.6).
Revisão independente sem achados. GPU HD/fallback/compra/roster em
docs/avatar-card-fix,1920×1080 e120frames60FPS; imagem enviada pelo usuário
preservada em before-cards.png. App/ZIP0.14.7 reexportados, assinatura estrita
válida; smoke GPU do PCK isolado em/tmp passou (card/efeito/retrato/compra,
20texturasHD, exclusão de brutos, vestir/recarga/batalha).
Perfis de teste isolados; fonte C#/perfil real preservados. Sem publicação.

## Auditoria OpenBound e UI Shop HD0.14.6

Pedido: conferir implementação da Avatar Shop contra fonte C# e regenerar
arte ainda sem HD pela skill gunbound-classic-hd. REQ-20/38/39/40, ADR-066;
plano/matriz em AVATAR_SHOP_PARITY_0_14_6.md. Trabalho local na main.

Catálogo15 e80arquivos originais idênticos à fonte (source-audit.json).
Preservadas adaptações aprovadas: grade3×3/inventário lateral, Vestir
persistido, perfil/gêneros/saldo/nível local e Bigfoot/Mage. Corrigidos ícones
dos atributos e relógios/FPS/Foward/Cycle do C#; clique das setas continua
após soltar. Popup mostra retrato/categoria/preço/saldo e centraliza moeda
única. Transações/perfil/combate/13peças HD/rig aprovados não alterados.

Quatro folhas GPT Images1254×1254RGBA, uma correção de estrela;20texturas
da UI com catálogo/origem/prompt/alpha/registro4× e fallback. Fonte clássica
é identidade; Space Marine HD aprovado é acabamento. Pixels úteis medidos
em catálogo; janelas4× não significam4× detalhe gerado. source/.gdignore
separa referências/brutos do runtime. GENERATION.json documenta geração.

GPU inicial encontrou popup mínimo da textura e bordas4× maiores: corrigidos
com expansão antes do tamanho e ShopCardStyle em nove recortes independentes.
Revisão independente final sem achados. **1848checks+10partidas sem falhas**,
42,1s partidas;40paridade/46UIHD/25Shop/25classic. Perfis isolados somente.
Capturas1920×1080 e120frames60FPS em docs/avatar-shop-parity cobrem compra,
moeda única, atributos, gêneros, Mage/Bigfoot e controles animados.

App/ZIP0.14.6 reexportados em builds, assinatura estrita válida; ZIP127,4MB.
Smoke GPU do PCK real passou:20texturasHD, popup/retrato/tamanho, cliques do
inventário, recarga do perfil e quatro peças na batalha. Referências/brutos
não estão no pacote. Verificação inicial de JSON emcwddo projeto deu falso
positivo pelo filesystem local; repetir fora do projeto eliminou esse fallback.
Filtro novo inclui explicitamente catalog.json/GENERATION.json. Reproduzir:
copiar tests/capture_avatar_shop_parity_pck.gd para /private/tmp e executar
Godot nessa pasta, com --path /private/tmp, --main-pack <PCKabsoluto> e
--script <scriptabsoluto>. App inclui também a aura UsingItem do baseline;
a suíte completa acima resolve a pendência de validação anterior. Sem push.
Limite: mestres HD variam brilho pelos relógios; os gestos originais completos
dos mascotes continuam no fallback. Validação visual do usuário pendente.

## Paridade Mage/Bigfoot com o C# (ADR-066)

Worktree `mobile-csharp-parity`, a partir de `c20f040`. REQ-42. Escudo do Mage
regenera em todo turno, SS abre no primeiro e recarrega em quatro turnos
próprios, dano segue `base × raio / distância`, caixas 38×33 e 46×40, queda
curta não tira vida, sinalizador do Bigfoot espera 0,4 s, fumaça e poses de
dano/choque/queda/parede entram no catálogo. Skill
`skills/gunbound-mobile-port/SKILL.md`. App não foi reexportado. Harness desta
worktree: 1785 checks e 10 partidas, zero falhas. A `main` com a loja 0.14.6
não foi misturada.

## Item no turno próprio — aura UsingItem (ADR-065)

No turno do jogador, usar um item (clique agora ou marca feita no turno
adversário) tira o botão do slot na hora e recompacta a barra. A aura verde
de diamantes e feixes do `UsingItem` (Bigfoot 234–253, Mage 243–262, 20
quadros a 19 fps) é desenhada sobre o mobile, em folhas 4× separadas do
corpo. `test_items_scene.gd`: **46 checks, zero falhas**. Captura GPU
1920×1080 em `docs/items/using-item-12.png`: aura verde sobre o Bigfoot,
escala uniforme e botão do slot oculto. A suíte completa não foi repetida.
O app 0.14.5 já exportado não inclui esta correção até um novo export.
Detalhes em ITEMS_0_13.md.

## Integração da loja clássica à main 0.14.5

Solicitação explícita do usuário: trazer as alterações da worktree para main.
Integração fast-forward de959db5f para5dda3d8, preservando todo o commit da
branch codex/avatar-shop-classic, sem conflitos ou alteração de comportamento.
REQ-20/38/39/40 e ADR-064 permanecem os contratos desta entrega.

Validação na main: check.sh completo passou com **1758checks e10partidas
completas, zero falhas** (42,604s nas partidas). App/ZIP0.14.5 reexportados em
`/Users/guichafy/Workspaces/DemoGame/builds`, assinatura estrita válida.
Smoke GPU do PCK da pasta principal passou: layout clássico,13peçasHD,
inventário com cliques reais, recarga do perfil e quatro peças na batalha.
Somente perfis isolados de teste; fonte C# e perfil real preservados.

Worktree/branch mantidos como referência; nenhum envio remoto. Capturas
FullHD e vídeo estão agora também na pasta principal docs/avatar-shop-classic.
Os parágrafos seguintes que descrevem main preservada retratam a etapa anterior
no worktree; esta integração substitui essa condição. Validação visual/manual
do usuário continua pendente.

## Loja clássica 0.14.5 — worktree

Pedido atual: loja mais fiel à primeira foto; segunda foto mostra a adaptação
anterior5×5, três grandes painéis laterais e pouco aproveitamento da grade.
Worktree `codex/avatar-shop-classic`, baseada na main959db5f, em
`/Users/guichafy/.codex/worktrees/avatar-shop-classic/DemoGame`.
REQ-20/38/39/40; ADR-064, AVATAR_SHOP_CLASSIC_0_14_5.md.

- Grade3×3/nove itens por página, cards166×147 com bordas/header preservados,
  retratos126×78 centrados em janela146×90; Cash azul e Gold amarelo com milhares.
- Meu Avatar sempre visível, oito linhas/rolagem, ícones por categoria e marcas
  de equipamento. Clique veste/salva pela transação Profile, sem cobrar saldo,
  e atualiza a prévia. Busca/categoria não escondem a lista de posse.
- Prévia mobile/conjunto e saldo compactos no topo esquerdo; quatro categorias,
  setas e ações originais no rodapé. Atributos em painel próprio com rascunho,
  confirmação/cancelamento, ESC, bloqueio da interface e erro visível ao falhar.
- Rig/peças HD/animação aprovados mantidos. Não regeneramos anatomia nesta mudança
  de layout; skill gunbound-classic-hd orientou aspecto/registro/verificação.
  Exit/LeftArrow/RightArrow originais copiados com SHA/source relativo; demais
  sprites/fontes e PNGs originais preservados.

Validação: RED reproduziu4diferenças de paginação/grade/recorte; GREEN final
**1758checks, zero falhas** em check.sh --quick, incluindo25Shop e25classic.
Cobertura de cliques reais, inventário entre categorias, gênero, busca vazia,
rollback de equipamento/atributos, cancelamento ESC e recarga/batalha. Combate
não alterado, partidas longas não repetidas. Revisão independente sem achados
Critical/Important; busca/caption/moldura disabled e origem de manifest ajustados.

GPU em docs/avatar-shop-classic: shop/body/inventory/attributes1920×1080,
composição4:3 com barras laterais, vídeo120frames60fps. App/ZIP0.14.5 em builds
da worktree reexportados, assinatura estrita válida. Smoke do PCK real passou
com inventário/cliques,13derivadosHD, recarga e conjunto completo na batalha.
Reprodução: copiar tests/capture_avatar_shop_classic_pck.gd para /private/tmp
antes de executar Godot --main-pack <PCK> --script <script externo>.
Perfis isolados e removidos; nunca o perfil real.

Limites: catálogo C# tem15registros e só cinco cabeças masculinas; os nove
chapéus da primeira foto não estão nessa fonte. Não adicionamos catálogo/preços
fictícios, bônus por peça, venda/descarte, amigos ou presentes offline. Foto
orienta composição; C# orienta dados/mecânicas. Main não foi integrada nesta
entrega e não houve publicação. Validação visual/manual do usuário pendente.

## Aprendizado reutilizável

Usuário confirmou que o resultado ficou bom e pediu uma skill para próximas
tarefas de regeneração Gunbound Classic em alta resolução/Full HD e animação.
`skills/gunbound-classic-hd/SKILL.md` reúne o fluxo validado e referências de
geração, registro/movimento e aplicação no projeto. Skill pessoal também
instalada no Codex para invocação `$gunbound-classic-hd`; cópia versionada
preserva o aprendizado neste repositório. Imagem isolada não exige integração;
regeneração usa referência clássica de identidade e HD aprovado de acabamento.
Full HD1920×1080 distingue-se das dimensões reais de atlas/sprites. Não houve
novo asset, mudança de runtime nem novo build nesta consolidação.

Validação da skill: quick_validate aprovado na cópia do projeto e na instalação;
cinco arquivos instalados idênticos aos versionados. Teste independente aplicou
prompt, registro Body/apoio, rig por ator e resolução real; variação de imagem
estática respeitou o escopo sem integração. Verificação numérica do exemplo:
Body local no apoio(3,673469,−31,836735), relativo ao ator com apoio24px
(3,673469,−7,836735). Não geramos novas imagens para avaliar a instrução.

## Animação contínua e Vestir no Shop 0.14.4

Relato do usuário: avatar/personagem parecem imagens diferentes alternadas;
vestir no Shop deve persistir para batalha. REQ-10/19/20/38/39, ADR-063,
AVATAR_SMOOTH_0_14_4.md. Correção local na main após a integração anterior.

- Peças HD conservam registro/anatomia/aspecto: centros variáveis da silhueta
  original não deslocam mais cabeça/corpo/acessórios a cada0,1s. Avatar respira
  como conjunto no Shop; no mobile acompanha o corpo e o relógio contínuo.
- BattleArt mantém histórico visual por ator e interpola mudanças/interrupções
  de pose em0,14s. Repetir recuo também reinicia a partir da geometria exibida.
  Pausa congela a interpolação; física, colisões e duração das ações preservadas.
- Experimentar mantém item não possuído na prévia temporária. Após comprar,
  Vestir salva o item e confirma “Avatar vestido e salvo”. Também restaura o
  item vestido sobre uma prévia temporária. Inventário continua equipando ao
  selecionar; falha de escrita reverte equipamento/prévia.

Validação: RED reproduziu13registros instáveis e2falhas do fluxo Vestir;
continuidade inicialmente ausente também reproduzida. GREEN: **1731checks e
10partidas completas sem falhas** (42,1s partidas), incluindo130checks de
continuidade/equipamento,23Shop,152HD. Testes usam apenas perfis isolados.
Revisão independente sem achados. Captura GPU360frames/60fps em
docs/avatar-motion/motion.mp4 inclui Mage/Bigfoot, sentidos, três conjuntos,
idle/movimento/carga/recuo/dano e retorno ao idle.

App/ZIP0.14.4 reexportados em builds, assinatura estrita válida. Smoke GPU do
PCK passou: quatro peças vestidas pela ação do Shop, recarga de perfil,
batalha com conjunto persistido, interpolação real e13peças HD registradas.
Imagem do Shop em docs/avatar-motion/shop-vestido.png. Fonte C#, arte original
e perfil real não modificados; sem publicação. Usuário confirmou aparência e
suavidade após a entrega. HD preserva peças constantes; gestos/olhos originais não
foram reanimados, fallback nativo mantém o flipbook original.

## Integração à main 0.14.3

Pedido explícito: levar todo trabalho de codex/avatar-shop à main. Main já
continha itens0.13; ambos preservados, incluindo histórico e correções. Merge
local entre f76a6d0 (itens) e ca888f8 (Shop/HD), sem remoto configurado.
REQ-35..41, ADR-062; INTEGRATION_MAIN_0_14_3.md.

- Match.start conserva loadout7º e recebe atributos8º; cena passa ambos e
 equipamento. Itens/menu/restart, Shop, Gold/perfil e avatares HD coexistem.
- Ataque persistente+bonus de item−defesa formam fator único; Dig persistente+
 Bunge somam antes de aumentar cratera. ItemDelay agora ativo no uso real,
 com inteiro original reduzido/truncado antes÷7,5. AttackDelay só nos tiros.
- Previsão e voo compartilham shot_shells, armas/tempos do Dual+ e modificadores
 em cópias. Gold climático também agregado no caminho do sinalizador Teleport.

Evidências: worktree pré-merge1454checks+10partidas sem falhas; árvore combinada
**1584checks+10partidas, zero falhas**,43,3s nas partidas. Integração39checks cobre
custo/preview, ataque+Power Up+defesa+escudo, Dig+Bunge, HP+Energy Up, Dual+,
previsão isolada, Shop+itens e restart. Regressão de Gold climático do Teleport
reproduzida e corrigida. Revisão independente antes do commit: nenhum
Important/Critical. Perfis de teste isolados, nunca o perfil real.

App/ZIP0.14.3 reexportados na pasta principal builds, assinatura estrita válida.
Smoke GPU do PCK PASS: loja/catálogo15, derivados13, item HD e uso real com
ItemDelay (12unidades para Power Up com40pontos); avatar2285pixels. Fonte C# não
modificada. O histórico0.14.2 abaixo dizia que ItemDelay dependia dos itens;
esta integração resolve essa dependência. Worktree anterior permanece como
referência da entrega isolada, sem apagar histórico/artefatos antigos.

## Entrega atual 0.13.0: itens de batalha

Pedido: implementar na batalha os itens usados nos turnos (como Dual), copiando
lógica, física e características do OpenBound em C#; imagens regeneradas em
Full HD pelo Codex com GPT Images. REQ-35..37, ADR-058, plano ITEMS_0_13.md.

- 11 itens com custo de delay original ÷ 7,5 cobrado no uso: Dual (repete o
  tiro 1 s após o último lançamento), Dual+ (S1↔S2), Thunder (todo projétil
  elétrico), Teleport (sinalizador massa 10/sem vento, só terreno, leva o mobile
  ao chão do ponto de contato), Power Up/Blood (dano final ×1,3/×1,33; Blood
  −8 % da vida, mínimo 1), Bunge Shot (cratera ×1,25), Change Wind (+180°),
  Energy Up 1/2 (12/30 %, limitado ao máximo), Team Teleport (no 1×1 só
  efeito). Um por turno, trava o SS, Ignorância trava a barra.
- Previsão e voo real usam `shot_shells`; efeitos no dicionário do ator. CPU
  sem itens neste corte: seeds 81–90 idênticas à 0.12.
- HUD: barra F1–F6 do OpenBound (clique ou F1–F6), clique no turno da máquina
  agenda o uso, item usado sai da barra no turno seguinte, ITEM LOCKED.
  Menu: botão Itens abre o Select Item original (6 slots, gravado nas opções).
- Arte: originais em `assets/openbound/items`; HD em `assets/hd/items` via
  `scripts/build_items_hd.py` + Codex (5 folhas). Teleport2 é o Teleport1
  invertido (pixel a pixel), então as chamas usam 8 quadros-chave HD.

Validação: `./scripts/check.sh` — **1205 checks + 10 partidas, zero falhas**.
Capturas GPU em docs/items. App/ZIP **0.13.0 reexportados**, assinatura
estrita válida. Commits locais por fase, sem push.
Limites: CPU não usa itens; sem teste manual de mouse/áudio no app; queda após
teletransporte sob teto não causa dano.

Próximo passo: usuário validar os itens no app (roteiro em VALIDACAO.md).

## Histórico do worktree — 0.14.2

## Avatares HD 0.14.2

Pedido do usuário: melhorar qualidade dos assets para aproximar o design dos
mobiles. REQ-20/39, ADR-061; AVATAR_HD.md.13peças em5folhas1254×1254RGBA geradas
pela ferramenta integrada GPT Images: Space Marine+óculos/bandeira, Basic
masculino/feminino, Miner, Punk e Kappa. PNGs originais intactos.

AvatarHD valida recortes/catálogo/texturas, preserva a proporção intrínseca da
imagem e posição normalizada do pivô dentro da janela original. AvatarArt usa
peças HD fixas no menu/previews/arena, com relógio/deslocamentos originais e
fallback original por peça. Loja usa as mesmas regiões nos retratos, com
limites87×45 para impedir tamanho mínimo de textura alta ultrapassar o card.
Encaixe/oclusão0.14.1 preservados; perfil/combate/IDs/preços não mudam.

Evidências: teste HD139 (13peças, densidade≥4×, aspecto e tamanho estáveis,
clock/pivô/fallback, offsets/regiões inválidas), regressão de retrato no Shop19.
Harness quick final **1454checks, zero falhas**; partidas longas não repetidas
porque só a arte/render mudaram. Capturas GPU inventory/poses/battle/hd-roster
conferidas; comparação original/HD em hd-comparison.png. Pré-HD preservado em
inventory-before-hd.png. App/ZIP0.14.2 reexportados, assinatura estrita válida,
ZIP101MB; smoke GPU do PCK renderiza avatar (2313pixels, PASS). Perfis isolados.

Prompts completos/origens/modo em assets/hd/avatars/GENERATION.json. Ativos:
space.png/basic.png/miner.png/punk.png/kappa.png+catalog.json; source/.gdignore
exclui referências do pacote. Regenerar metadados com catalog_avatar_hd.py ao
trocar PNG. Originais gerados permanecem também na pasta padrão do image_gen.

Limite: peças constantes preservam registros e evitam deformação entre quadros,
mas gestos/olhos não são regenerados quadro a quadro. UI do Shop continua fonte
original. ItemDelay segue dependendo da integração de itens. Usuário validar
novo design no inventory/hd-roster e app; branch/worktree mantidos.

## Correção de encaixe do avatar 0.14.1

Relato do usuário: inventory.png mostrava corpo/cabeça/acessórios recuados e
sem encaixe no mobile. REQ-39/19, ADR-060; AVATAR_MOUNT_FIX.md.

Causa confirmada: centro Body do avatar aplicado no pivô dos quadris do piloto
HD, com offset arbitrário(0,−8); camadas também desenhavam avatar sobre chassis,
ao contrário de AvatarBody0.046/Mobile0.05 do C#. A montagem agora deriva de
RiderPivot idle, contact_y/pivot_y e largura nativa: Bigfoot(3,−26)×60/49 e
Mage(5,−26)×60/46. Chassis/arma/rodas ficam à frente das peças equipadas;
piloto legado preserva seu caminho. Movimento contínuo e física preservados.

Validação: test_avatar_mount vermelho2→verde24, registrando escala uniforme,
ponto Body, flip, encosta e5poses. Suites pertinentes432checks; harness quick
final1314checks, zero falhas. Não repetimos partidas longas porque só o render
mudou. Comparação GPU original/HD (render Godot com metadados C#) em
mount-comparison.png e inventory/poses atualizados. Prévia anterior preservada
em inventory-before-mount-fix.png. App/ZIP0.14.1 reexportados, assinatura estrita
válida; PCK renderiza preview, PASS. Sem uso do perfil real.

Próximo passo: usuário conferir o encaixe na nova imagem/app. A inspeção anterior
não cobria equivalência do ponto Body com a fonte; nova regressão cobre isso.

## Shop de avatar 0.14.0 — entregue no worktree

Branch `codex/avatar-shop`, criada da `main`. Pedido/decisões aprovados em
AVATAR_SHOP.md; execução AVATAR_SHOP_PLAN.md. REQ-38..41, ADR-059.

- Catálogo original15 registros: cabeça/corpo/óculos/bandeira,15 retratos e
 13atlas.80arquivos originais/interface copiados com SHA, sem edição dos PNGs.
- Shop/Inventário, busca, páginas25, gêneros/unissex, experimentação temporária,
 compra Gold/Cash e popup modal. Primeiro perfil Shop tem1000por moeda;
 transações com rollback, repetição sem débito e corrupção sem refill.
- Perfil version2 conserva nickname/XP/wins/matches/awarded e guarda posse,
 equipamento separado por gênero e oito atributos. Pontos pelo nível local:
 min((nível−1)×10,180), até50cada; rascunho/confirmar/cancelar.
- AvatarArt junta peças com pivôs/FPS/grade originais, substituindo o piloto no
 assento do rig no menu/previews/arena; CPU básica. Caminho legado preservado
 sem contexto. Atlas multi-row e altura feminina27vs metadata33 tratados.
- Vida/dano/defesa/regen/atraso/Dig aplicados no Match/voo/previsão em cópias;
 GoldRewards e Popularity seguem caminhos1×1 C#. Ângulo HUD=trajetória central
 +180, sem dispersão do primeiro pellet; metadados Gold só de dano positivo.
 Resultado4/1Gold e Popularity acumulada/branch2000 inalcançável são da fonte;
 empate0é adaptação. XP local preservado; crédito final único com ID da partida.

Validação final: check.sh completo **1282checks+10partidas, zero falhas**,40,5s
nas partidas. Mais8 checks de atributos (fixture válida de180pontos, dano/cratera
reais) passaram; check.sh --quick consolidou **1290checks, zero falhas**.
Revisão independente encontrou3Important reproduzidos e corrigidos em RED→GREEN:
shop inválido renovando saldo, ângulo Gold espelhado e pellets sem dano alterando
bônus. Um quarto candidato sobre remap do .gd não se reproduziu neste Godot:
PCK original já tinha preview1786pixels; gate redundante removido por robustez.

Sete capturas GPU1920×1200 em docs/avatar-shop: loja, compra, inventário,
atributos, Mage/Bigfoot e poses/sentidos/encosta. PCK do app exportado carregou
catálogo15 e renderizou preview (1786pixels da figura, PASS), com perfil isolado.
`capture_avatar_pck_smoke.gd` preserva reprodução: copiar o script para fora do
projeto (ex.: /tmp) e executar Godot --main-pack <PCK> --script <script>.
App/ZIP0.14.0 em builds do worktree, ZIP98MB; assinatura ad-hoc estrita válida.
Nenhum teste usou o perfil real. Main e fonte C# não foram editadas nesta execução.

Limites: **ItemDelay tem fórmula/teste, sem uso real até integrar código de itens**
(a main tinha alterações não commitadas e não foram copiadas). Assets são
originais; GPT Images opcional não gerado. Fonte/interface têm adaptações de
viewport e controles nativos de texto. Sem teste manual do app por usuário;
roteiro em docs/VALIDACAO.md. Próximo passo: usuário validar o app e decidir a
integração da branch; worktree permanece disponível.

## Reorganização SOLID (mesma versão, sem export)

Pedido: aplicar o plano de arquitetura SOLID, incluindo os três itens que
estavam fora da dívida. ADR-057. Nenhuma regra de combate, mira ou roster
mudou. App/ZIP não foram reexportados.

- `mobiles.gd` é o catálogo de Mage e Bigfoot. `weapon_rules` e `aim_limits`
  leem o catálogo. IDs 1 e 2 e o oponente `3 - id` permanecem.
- `flight_snapshot.gd` é a única cópia usada por `predict_shot` e
  `begin_cpu_plan`.
- `damage.gd` e `turn_table.gd` são chamados pelo Match, que guarda `phase`,
  `actors` e `events`.
- `aim_control.gd`, `camera_rig.gd` e `match_overlay.gd` recebem a lógica que
  estava em `game.gd`. A cena continua a superfície dos testes (`angle`,
  `charging`, `drag_aiming`, `camera`, overlays).
- `battle_art` desenha com um contexto (pose, arma, atlas, tempo).
- `Match.PLAYER` / `Match.CPU` nomeiam os índices 0 e 1. `start` aceita a
  máscara; sem ela, cria o terreno. Som e perfil nascem na cena se ninguém
  os injetou antes.

Validação nesta sessão: `./scripts/check.sh` com 1114 checks e zero falhas,
mais 10 partidas seeds 81–90 em 41 s, zero falhas. Vencedor, tiros e vida
restante de cada semente coincidem com a entrega 0.12. App e ZIP não foram
reexportados.

## Entrega atual 0.12.0: modo de mira Drag/Slice

Pedido: implementar o Aiming Mode com opção de ligar/desligar no menu de
configuração; Mouse Speed desabilitado com TODO; Interface só skin Blue.
REQ-34, ADR-056, plano AIMING_0_12.md. O OpenBound não implementa o modo;
o comportamento vem de guias do GunBound (StrategyWiki, GameFAQs).

- Rádio Aiming Mode do popup ativo e gravado (`aiming`: 0 Drag, 1 Slice;
  padrão Slice = comportamento anterior, como o `AimType` do original).
- Drag (game.gd): no turno do jogador, botão esquerdo pressionado no mundo
  zera a barra; força = deslocamento horizontal / 640 px (largura da barra de
  força na tela), 0–100, voltar reduz; tremor ±2 a cada 0,04 s quando o
  cursor não avança (`drag_rng` próprio); soltar dispara uma vez, inclusive
  soltando sobre a barra do HUD (`_input`); clique sem arraste não atira; sem
  disparo automático a 100. Popup, pausa, ajuda, troca de turno e recomeçar
  cancelam (setter de `charging`). Espaço e arraste exclusivos; Espaço segue
  ativo no Drag. Botão direito/meio olha o mapa nos dois modos; no Slice o
  esquerdo continua só olhando o mapa.
- Mouse Speed: desabilitado, `TODO(Mouse Speed)` em options_popup.gd e em
  `DRAG_FULL_POWER` (game.gd). Interface: só Blue (decisão registrada).
- Ajuda, README e VALIDACAO atualizados; AGENTS registra a exceção do Drag à
  invariante da carga.

Validação: `./scripts/check.sh` — **1114 checks + 10 partidas, zero falhas**
(nova suíte test_aiming 25, com cliques reais pela viewport: Slice faz pan,
rádio grava, 320 px = 50, voltar reduz, soltar dispara uma vez, clique parado
não atira, soltura sobre o HUD e soltura perdida, exclusão com Espaço,
tremor com seed, 100 sem auto-disparo, cancelamentos, botão direito; seeds
81–90 inalteradas). Captura do popup com o rádio ativo. App/ZIP **0.12.0
reexportados**, assinatura estrita válida. Commit local, sem push.
Limites: amplitude do tremor e escala 640 px são adaptação (fontes não dão
valores); com toque emulado, no Drag o próprio turno não permite olhar o
mapa arrastando; sem teste manual de mouse no app.

Próximo passo: usuário validar o Drag no aplicativo.

## Entrega anterior 0.11.0: performance da troca de turno, BGM e popup HD

Pedido: "implementar e rever os limites" (exemplo: popup Full HD gerado no
Codex com GPT Images) e melhorar a performance da batalha, que travava entre
as trocas de turno. REQ-32/33 e revisão de REQ-31, ADR-053..055, plano e
medições em PERF_LIMITS_0_11.md.

- **Travamento corrigido (REQ-32).** Causa medida: `choose_cpu_shot` avaliava
  a grade de mira inteira (105–168 previsões no laço de voo) num único frame
  no início do turno da CPU (90–484 ms conforme o mobile da CPU). Agora `begin_cpu_plan` (thread
  principal: vira, sorteia arma, retrato da máscara/atores/vento/clima),
  `search_cpu_plan` (WorkerThreadPool, só lê o retrato) e `finish_cpu_plan`
  (thread principal: erros de mira). Mesmo plano e mesma ordem de RNG; seeds
  81–90 com os mesmos tiros. Medido a 60 FPS no app com Metal (M4 Pro): pior
  frame do turno da CPU 17,8 ms; antes 160–185 ms com CPU Mage e
  **336–484 ms com CPU Bigfoot** (salvas). Disparo da CPU em 1,83–1,87 s nos
  dois casos (antes 1,88–2,20 s, atrasado pela própria trava). O fatiamento em frames foi testado e descartado (disparo em
  ~3,3 s). Recomeçar/menu/troca de turno/sair esperam a thread e descartam.
- **BGM (REQ-33).** 12 temas originais `LevelScene/Theme*` em
  assets/openbound/music (SHA no manifest, ~17 MB): faixa aleatória ao iniciar
  a batalha e outra ao terminar, para no menu. Slider BGM ativo (padrão 50,
  gravado); "Som" da pausa silencia música e efeitos; testes mudos nunca
  tocam. Reprodução real conferida fora do headless.
- **Popup HD (REQ-31).** Folha `options` no `build_hud_hd.py`, gerada pelo
  Codex `image_gen` (gpt-5.6-sol; origem em GENERATION.json, prompt em
  HUD_PROMPTS.md); fundo, Accept e rádio 3× com alfa original; barra, moldura
  e ponteiro ampliados direto; mipmaps; fallback ao original com regiões pela
  densidade. Capturas `docs/hud/hud-options-popup(-original).png`.
- **Limites revistos:** Aiming Mode e Mouse Speed seguem desabilitados (sem
  implementação no OpenBound; cursor do sistema), Interface só tem a skin
  Blue no pacote, Consolas é proprietária e fora do pacote.

Validação: `./scripts/check.sh` — **1088 checks + 10 partidas, zero falhas**
(nova suíte test_performance 19, CPU Mage e CPU Bigfoot com T1/T2/SS: plano direto = em passos = em thread,
retrato isolado, nenhum frame roda a busca, CPU dispara, descarte seguro;
test_hud 140: HD/fallback do popup, BGM). App/ZIP **0.11.0 reexportados**
(`build_macos.py`), assinatura estrita válida, ZIP ~102 MB (antes ~80 MB, pela
música); PCK contém músicas, HD do popup e BMP original, sem folhas brutas.
Commits locais por fase, sem push. Limites: o pico de ~45 ms no primeiro frame
da partida (carga de texturas) continua; sem teste manual de áudio/mouse no
app.

Próximo passo: usuário validar a troca de turno, a música e o popup no app.

## Entrega anterior 0.10.1: popup de opções original (PopupGameOptions)

Pedido: ESC/Options deve abrir o popup de configurações do OpenBound em vez da
pausa própria, com os sprites originais, mantendo a pausa acessível e aplicando
as opções que existem no jogo. REQ-31, ADR-052, plano na seção 0.10.1 de
HUD_0_10.md.

- ESC/Options abrem o popup; sair dele para a pausa/ajuda também grava.
- `scripts/options_popup.gd` porta `PopupGameOptions`/`PopupMenu`/`SliderBar`/
  `RadioButtonSet` com os offsets do C# × 1,6 a partir do centro da tela:
  fundo Blue/Options 323×328, textos com as cores de Parameter.cs (fonte
  monoespaçada do sistema no lugar da Consolas 10), sliders com
  BarFrame/Bar/ponteiro, rádios, Accept 20×25 com 4 estados e barra de título
  arrastável limitada à tela.
- Aplicadas: **SFX** (`sound.set_volume`, linear sobre −19 dB; 0 silencia),
  **Scroll Speed** (multiplicador `2^((v−50)/50)` do arrasto da câmera; 50 =
  comportamento anterior) e **Background On/Off** (fundo do mapa preto na
  batalha). Desabilitadas, com o padrão do C#: Aiming Mode (Slice), Mouse
  Speed (50), BGM (0, o jogo não tem música) e Interface (TH Blue; só a skin
  Blue existe no pacote).
- ESC/Options abrem o popup (Options desabilitado enquanto aberto, como em
  HUD.cs); ESC ou Accept fecham e gravam `scripts/options.gd` em
  `<perfil>-options.json` (`user://profile-options.json`; testes no caminho
  isolado do perfil). O popup pausa o treino e cancela a carga. Pausa própria
  em P (partida ou popup) e no extra discreto "PAUSA" do popup;
  `show_pause()` inalterado. Ajuda/README/VALIDACAO atualizados.
- Sprites: 5 de Interface/Popup/Blue/Options e StaticButtons/Popup/Accept em
  assets/openbound/hud (prefixo Options*/PopupAccept), SHA no manifest.
  `BarFrame.png` do pacote é BMP; copiado com bytes idênticos como `.bmp`.

Validação: `./scripts/check.sh` — **1045 checks + 10 partidas, zero falhas**
(test_hud 116, +29 do popup, incluindo cliques reais pela viewport no slider e no Accept: abrir/pausar/cancelar carga, Options desabilitado,
layout, SFX 0/50 no volume real, padrões desabilitados, fundo, rolagem 2×/1×
no arrasto, arrastar janela, ESC/Accept/P/PAUSA gravando no caminho isolado). Captura GPU `docs/hud/hud-options-popup.png` (1920×1200)
conferida: textos, sliders e rádios alinhados ao fundo original. Versão do
menu e do preset 0.10.1; **app/ZIP não reexportados** nesta entrega (continuam
0.10.0) — rodar `scripts/build_macos.py` para entregar o app. Commit local,
sem push.
Limites: no C# lançado Scroll/Mouse/rádios estão desativados ("Pre-release
deactivation"); aqui Scroll e Background ficam ativos e os demais aparecem
esmaecidos. O original não pausa (online). Sem HD do popup (PNG 1,6×).
Toggle "Som" da pausa continua como mudo geral, separado do SFX. Sem teste
manual de mouse/áudio no app.

Próximo passo: usuário validar o popup no aplicativo após reexportar.

## Entrega anterior 0.10.0: HUD de batalha original do OpenBound

Pedido: deixar os sprites da batalha iguais ao OpenBound — seleção de arma,
barra de força e demais opções. Decisões do usuário: **arte HD via GPT Images
(Full HD) ajustada ao layout original**, **carga igual ao original**, controles
extras **discretos**. REQ-27..30, ADR-049..051, plano HUD_0_10.md.

- `hud_art.gd` desenha o HUD com os offsets de HUD.cs (tela virtual 800×500 ×
  1,6): barra de ação 1280×136, S1/S2/SS/ESC/F8 PASS (`TextureButton`, estados
  de Button.cs), barra de força com marcador anterior e seletor arrastável,
  barra de movimento, ângulo atual e LAST, roleta de clima na janela branca,
  Gold (= XP ganho na partida), Delayboard, bússola original, TurnTimer +
  ClockSecond, balão do relógio sobre a CPU (≤ 20 s); no mundo (1:1) mira
  original (moldura, faixa legal Ally/Enemy por mobile/tiro, ponteiro pela
  direção real do tiro, ângulo), vida 76 px (vida+escudo, vermelha < 30%),
  nome e contador de dano acumulado.
- Input original: Espaço zera e soma 2 a cada 0,04 s (2 s até 100), soltar ou
  encher dispara; Tab cicla (pula SS bloqueado); F8 passa; ↑/↓ 1° por toque com
  repetição 0,15 s → 0,03 s. Extras ← → F ● acima da barra (● segura/solta).
- Arte: 42 sprites originais em assets/openbound/hud (SHA no manifest);
  `build_hud_hd.py` monta 5 folhas de layout fixo, o Codex `image_gen` remasteriza
  e o script recorta cada sprite a 3× com o alfa original (assets/hd/hud,
  manifest; prompts em HUD_PROMPTS.md). Faixas de mira, barras planas e
  ponteiros ampliados direto.
- Removidos: console próprio (painéis, sliders, DISPARAR grande, fila lateral,
  bússola desenhada, banner "SUA VEZ", seta TURNO e caixa de nome). Mundo
  visível 1280×664. `match.gd` e a balística não mudaram.

Validação: `./scripts/check.sh` — **1016 checks + 10 partidas, zero falhas**
(novo test_hud 87 checks; testes de cena migrados dos sliders/labels para o
estado do HUD; partidas seeds 81–90 idênticas à 0.9). Capturas GPU 1920×1200
em docs/hud (turno do jogador HD e original lado a lado, carga, turno da CPU
com balão e dano). App/ZIP 0.10.0 reexportados, assinatura válida; PCK isolado
carrega HUD HD/originais e exclui as folhas brutas. Commits por fase; sem push.
Faixas verdes originais cobrem exatamente os limites legais (Mage 15–50°,
Bigfoot 18–40°, SS 23–35°), verificado em test_hud. Mipmaps nas texturas HD do
HUD deixam a janela 1× (1280×800) nítida.
Limites: balística mantém o piso de velocidade equivalente a 15 (a barra vai de
0 a 100); itens, ouro, chat, rank e MatchStatus não existem (slots vazios, Gold
mostra XP só no fim); ESC abria a pausa própria (substituído na 0.10.1), o PopupGameOptions original
(configurações de mira/rolagem/volume/skin) não foi portado; fonte dos nomes é
do sistema (NotoSans10 original não incluída); sem teste manual de
mouse/toque/áudio no app. Roteiro manual atualizado em docs/VALIDACAO.md.

Próximo passo: usuário validar o HUD no aplicativo.

## Entrega anterior 0.9.0: câmera rolante, vento 2D, clima, Thor e partícula

Pedido: implementar clima, Thor, partícula de chão, outros mapas e câmera
rolante. Decisões do usuário: **sem outros mapas nem HD novo**, escala nativa
1:1, vento 2D do original, commits locais por fase. REQ-22..26, ADR-044..047,
plano WEATHER_CAMERA_0_9.md. Fases commitadas: A (mundo/câmera), C (vento,
clima, Thor no modelo), D (visuais), E (docs/export).

- Mundo = ForegroundA inteiro 1800×1800 (grade 900×900); spawns do Map.cs
  nativos; limites derivam do tamanho do mundo. Câmera segue mobile/tiro/impacto
  (1/25), arrasto com mouse/toque até o próximo turno ou disparo; parallax do
  fundo dentro da cobertura HD; setas na borda para mobiles fora da vista.
- Vento 2D (0–35, 0–360, perturbação ±2/±3 por rodada, Wind re-sorteia;
  adaptação: sorteio de Wind na largada). Fator 1,3 px/s² por ponto.
- Clima (weather.gd): pesos do Miramo A, fila de 4, rodada = 2 turnos, colunas
  com fusão/limpeza; Força ×1,2+10, Fraqueza ÷1,2−10, Espelho inverte vx
  ×1,1+5, Elétrico (raio vertical, cratera 10, choque 30), Tornado (3 etapas e
  relançamento), Aleatório (ativa uma vez), Proteção +35, Ignorância sem efeito.
- Thor: satélite em x10–90%/y10–70%, raio do satélite ao impacto (25,
  40+20·nível), XP pelo dano, tabela 800…3000; desativa com outro clima.
- Tudo no laço de voo comum; `predict_shot` sempre simula em cópias (CPU
  120–290 ms por decisão, antes 70–270).
- Apresentação (weather_art.gd) com sprites/sons originais: colunas rolando,
  satélite com LV/XP, feixes Thor/elétrico, ícones da previsão, marcas nos tiros,
  partículas de chão do Particle.png (pixels removidos ÷ 32); pausa congela.
- Opção do menu (ADR-048): "Clima: original do mapa" (padrão, Map.cs: Força,
  Tornado, Elétrico, Vento, Proteção, Aleatório; Espelho/Fraqueza só como extra
  do Aleatório; **sem Thor**) ou "todos os efeitos" (pesos iguais, Thor incluído).
- Arrasto exige botão pressionado (release consumido pelo HUD não prende) e
  toque emulado como mouse não desloca em dobro.
- Fixtures: vento migrado para Vector2 (−30 → −35 pela troca de fator);
  fixtures com literal 640 pedem o terreno procedural.

Validação: `./scripts/check.sh` — **928 checks + 10 partidas, zero falhas**
(test_weather 62, test_map 41; modo "todos" ativa o Thor por rodadas naturais e
um tiro real dispara o satélite). Seeds81–90: 56/12/13/15/19/10/8/12/9/15 tiros.
Capturas GPU 1920×1080 em docs/map e docs/weather (colunas, Thor/raio,
partículas; pausa congela confirmada). App/ZIP 0.9.0 reexportados, assinatura
válida; PCK isolado carrega mapa nativo, clima e assets de clima/Thor.
Commits por fase A/C/D/E + opção de clima; tag local v0.9.0; sem push.
Limites: choque elétrico aproximado pela distância ao segmento; arte de
clima/Thor em baixa resolução original; sem teste manual de input/áudio no app.

Próximo passo: usuário validar câmera, clima e Thor no aplicativo.

## Entrega anterior 0.8.1: fundo HD do Miramo Town

Após o reset do limite do Codex, gerado o 2º bloco do fundo (exec-ad42a28a).
`build_map_hd.py` costurou `background.png` 1920×1536 (1,48× o original);
sobreposição de 127 px HD com diferença média ~12/255, emenda no canyon de
nuvens inspecionada em 1:1 sem degrau visível (cano/nuvens contínuos). A arena
já preferia o HD quando presente. test_map 33 checks (fundo HD + hash do
manifest); `./scripts/check.sh` **858 checks + 10 partidas, zero falhas**;
capturas `docs/map` atualizadas; app/ZIP 0.8.1 reexportados, assinatura e PCK
isolado válidos. Commit/tag local v0.8.1, sem remoto.


## Entrega anterior 0.8.0: mapa Miramo Town A

Pedido: implementar um mapa do projeto C# com sprites HD por GPT Images. Usuário
escolheu Miramo Town A e arena fixa 1280×800. REQ-21 (REQ-04/05/08/11/12);
plano MAP_0_8.md, ADR-042/043.

- Dados de `Map.cs` (ID20, clima, 11 spawns) em `scripts/maps.gd`. Colisão =
  alpha>0 do `ForegroundA.png` original (cópia intacta em
  `assets/openbound/maps/miramo_town/`) amostrado na grade 640×400; o recorte
  1766×456 vira x0–1280, y420–750 e a colisão termina em y670 (linha do HUD),
  abaixo é abismo.
- Visual: GPT Images via `codex exec -m gpt-5.6-sol` (`image_gen`), 3 blocos 3:2
  do foreground; `scripts/build_map_hd.py` costura e aplica a máscara original
  como alpha → `foreground_a.png` 2560×661. Brutos em `source/` (.gdignore).
- Crateras apagam células e pixels HD e escurecem o anel `r+3` ×0,4
  (`Topography.CreateErosion`). `collision_copy` sem visual; CPU usa a mesma máscara.
- Spawns: adaptação do sorteio livre do original — um spawn por metade, pelo
  `rng` da partida (jogador esquerda, CPU direita). Podem ficar a ~114 unidades.
- Terreno procedural continua como fallback (`start(..., "")` e mapa inválido,
  com `push_warning` se faltar recurso). Sem `foreground_a.png`, o visual cai
  no ForegroundA original na mesma geometria (achado da revisão: antes a
  colisão ficaria invisível). Duas fixtures de `test_runner` passaram
  a pedir o procedural explicitamente (dependem de x235 e espessura antiga).
- Fundo: janela 1300×812,5 alinhada à base do `Background.png`. Em 0.8.0 o
  fundo HD tinha só 1 de 2 blocos (limite do Codex); concluído em 0.8.1.

Validação: `./scripts/check.sh` — **856 checks + 10 partidas no mapa, zero
falhas** (seeds81–90: 34/17/15/10/16/10/7/6/7/12 tiros). Evidência principal
de concordância é independente do GDScript: alpha HD (pipeline Python) contra
células, <1% de amostras de borda divergentes; o check "máscara = alpha" usa a
mesma transformação de `maps.gd` e não detectaria erro dela. Previsão × tiro
real concordam no mapa; cavar até y670 elimina por queda. Capturas GPU
1920×1080 em `docs/map` (arena, tiro, crateras, original×HD). App/ZIP 0.8.0
reexportados, assinatura estrita válida; PCK isolado carrega o mapa e exclui
os blocos brutos. Sem commit, remoto ou publicação.

```sh
python3 scripts/build_map_hd.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
./scripts/check.sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_map.gd
python3 scripts/build_macos.py
```

Usuário validou o mapa e pediu revisão/versionamento: commit/tag local v0.8.0.
Próximo passo: concluir o fundo HD (commit separado). Clima/Thor,
partícula de chão, outros mapas e câmera rolante pendentes.

## Entrega anterior 0.7.0: identidade Gunbound Recomp e harness

Pedido: revisar configurações/strings, melhoria contínua do harness de qualidade
e definir a identidade do projeto como "Gunbound Recomp". REQ-01/12; sem mudança
de regras, combate, roster ou arte. Herda todo o conteúdo de0.6.4 (tag v0.6.4).

- Renome: project.godot nome/descrição, nó raiz `GunboundRecomp`, bundle id
  `com.local.gunboundrecomp`, assinatura `GREC`, copyright, ícone do piloto.
- App/ZIP: `builds/Gunbound Recomp.app` e `Gunbound-Recomp-macOS.zip`;
  executável/PCK internos `GunboundRecomp` (ASCII, normalização preservada).
- Menu: título GUNBOUND/RECOMP, tag 0.7.0; pausa "Uma pausa no combate.";
  rótulos das capturas de QA atualizados.
- Perfil: por decisão do usuário, recomeça do zero na pasta nova
  `app_userdata/Gunbound Recomp/profile.json`; perfil antigo não é migrado
  nem apagado.
- Harness: `scripts/check.sh` roda as14suites headless, grava logs em
  `.tools/check-logs/`, consolida os checks e sai!=0 em qualquer falha.
  `--quick` omite `test_matches`; `GODOT=...` sobrepõe o binário padrão.
- Docs vivos atualizados (README/VALIDACAO/AGENTS/SPEC/DECISIONS/TASKS/
  ATTRIBUTION); seções históricas deste hand-off preservam os nomes antigos.
- Complemento posterior: `/Users/guichafy/Workspaces/Gunbound` (projeto C#
  OpenBound de referência) configurado como pasta adicional das sessões em
  `.devin/config.json`, `.claude/settings.json` e `~/.codex/config.toml`;
  instrução no AGENTS.md. No Devin CLI, `/add-dir` anexa como workspace extra.

Validação: `./scripts/check.sh` completo — **825 checks +10partidas, zero
falhas**. App/ZIP0.7.0 reexportados por `build_macos.py`; assinatura
profunda/estrita e runtime independente verificados. Commit/tag local
`v0.7.0`; nenhum remoto/push/publicação.

```sh
./scripts/check.sh          # todas as suites headless
./scripts/check.sh --quick  # sem as dez partidas completas
python3 scripts/build_macos.py
```

Próximo passo: usuário validar título/menu e funcionamento geral no app.
Observação: "Gunbound" é marca de terceiros; uso é protótipo local, sem
publicação ou distribuição. Histórico abaixo.

## Entrega anterior 0.6.4: perna oculta e roster Gunbound

Usuário aprovou proporção0.6.3 e pediu esconder a perna distante do piloto;
remover Escaravelho por não seguir Gunbound. REQ-19/20/12 e REQ-02/08;
plano SIDE_PILOT_ROSTER_0_6_4.md. Progresso REQ-10 e pausa REQ-09 preservados.

GPT Images editou mestre anterior: pilot_side.png1254×1254 RGBA, apenas a perna
próxima visível. Far-leg era conteúdo interno do PNG, ordem de camadas não o
ocultava. Origem/prompt em assets/hd/SIDE_PILOT_PROMPT.md e GENERATION.json.
PNG/alpha copiados intactos. Fonte anterior preservada. Registro271/153/703/977
inclui4px extra inferiores para não cortar; conserva padding esquerdo/assento.
MobileRig só muda piloto, sem alterar proporção/animações0.6.3 ou tiros0.6.2.

Somente Mage(ID1) e Bigfoot(ID2). VEHICLES Dictionary, PLAYABLE_VEHICLES=[1,2];
UI usa ID separado do slot, normalize_vehicle mapeia ID0/inválido para Bigfoot.
CPU recebe3−id. Não reindexar. Removidos registro/armas/render/carregamento
Escaravelho ativos. Combat mantém integrador comum, mesma velocidade dos dois;
tabela de armas genéricas removida. Ícones apontam ao piloto; scarab/tortoise
históricos preservados no Git mas excluídos do pacote. Perfil/terreno/projéteis/
peças/áudio originais e HD anteriores sem alterações. Perfil não guarda mobile.

Validação fresca: **825 checks, zero falhas** em13suites (251modelos/cenas/ataques,
193HD,240animação,108piloto/tiros,33roster). Regressão roster/perfil RED26/6,
GREEN33/0; IDs/menu/oponentes/armas/dificuldades/registro. Fixtures antigas com
Escaravelho migraram para regras reais: escudo com bombas90, EMPcontraBigfoot,
retorno do laser em máscara inclinada legal50°, preview com delays Mage100/120.
Preservar essas coberturas; não reintroduzir mobile removido só para teste.

**10 partidas naturais** seeds81–90, alternando Mage/Bigfoot e dificuldades;
29/18/15/22/26/9/34/9/11/26 tiros, zero falhas. CPU atua com ambos, inclusive
Bigfoot contra Mage. Perfis isolados nos testes, antes de adicionar cena.
Logs locais .tools/side-roster-final-*. Revisão independente sem bugs concretos.
144framesGPU/24fps em docs/occlusion, PNG1600×1080 e MP4/GIF: ambos mobiles,
dois sentidos, encosta−30°, repouso/movimento/carga/recuo/dano/destruição.
16capturas reais de menu/arena/tiros/impactos atualizadas em docs/hd.
Galeria usa poses controladas; não prova contato físico em todas as encostas.
Sem teste manual completo de áudio/input; aceitação visual do usuário pendente.

App/ZIP Universal0.6.4 reexportados por build_macos.py. Assinatura profunda/
estrita, runtime e PCK isolado verificados: recursos/piloto/recortes, menu2,
oponente de Mage, salvas4/6/8 e ausência scarab/tortoise. Git local/tagv0.6.4;
nenhum remoto/push/publicação.

```sh
mkdir -p .tools
python3 scripts/catalog_hd_assets.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_roster.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_matches.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_side_pilot.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_hd_assets.gd
python3 scripts/build_macos.py
```

Próximo passo: usuário validar perna/sobreposição dos dois mobiles e seleção
no app. Arte HD adaptada; não anunciar reprodução exata de todos os sistemas.
Histórico abaixo.

## Entrega anterior 0.6.3: proporção e composição

Feedback: tiros0.6.2 corrigidos, composição piloto/carrinho ainda inadequada.
REQ-19/20/12; plano COMPOSITION_FIX_0_6_3.md. Piloto unido tinha altura29,
pequeno em relação ao canhão/rodas. União alpha nativa corpo/cabeça mede44px;
hulls49/46 dão altura53,88/57,39 no layout60. Recalibrados assentos, chassis,
arma e rodas; peça preserva aspecto. Camadas chassis→piloto→arma→rodas.
Mesmo rig menu/arena, flip/inclinação uniformes, quadris no assento e mãos
próximas aos controles. Nenhum asset novo: PNGs HD/originais intactos. Tiros,
combate, clocks, perfil e áudio sem diff. Detalhes concretos em DESIGN/ADR-037.

Validação fresca: **788 checks, zero falhas**, nas12suites anteriores (108
piloto/tiros;189HD;240animação;251modelos/cenas/ataques). Regressão RED106/3,
GREEN108/0: proporção nativa e montagem arma/rodas/controles. Não repetir dez
partidas como evidência nova, pois combate não mudou. Perfis isolados.
Capturas reais de menu/arena/tiros atualizadas em docs/hd, rótulo0.6.3.
Comparação original/HD e encostas±30° espelhadas em docs/composition/comparison.png,
120framesGPU/24fps com repouso/movimento/carga/recuo/dano e MP4/GIF.
Galeria usa poses controladas sobre fundo plano; não prova contato físico
com terreno em encostas nem inclui destruição. Arena real foi inspecionada.
Revisão independente sem achados bloqueantes; observou pequena margem inferior
por aspect fit das rodas (~0,49unidade), sem impacto físico. Teste manual
completo e aceitação visual do usuário pendentes.

App/ZIP Universal0.6.3 reexportados por build_macos.py; assinatura profunda/
estrita válida, runtime independente sem erros. PCK em projeto vazio validou
assets/recortes/rig/tiros e salvas4/6/8, zero falhas. Git local/tagv0.6.3;
sem remoto/push/publicação.

```sh
mkdir -p .tools
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_pilot_projectiles.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_mobile_animation.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_hd_assets.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_mobile_composition.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_hd_assets.gd
python3 scripts/build_macos.py
```

Próximo passo: usuário avaliar composição menu/arena no aplicativo. Arte HD
adaptada; não anunciar recuperação exata de Gunbound. Históricos abaixo.

## Entrega anterior 0.6.2: piloto, tiros e impactos

Pedido: corrigir personagem e animações dos tiros após o print do piloto no
Bigfoot inclinado. REQ-19/20/12 e pausa REQ-09; especificação/plano em
PILOT_SHOTS_FIX_0_6_2.md. Diagnóstico: cabeça/corpo esticados separadamente,
cabeças de tiro variáveis e Bigfoot com orientação invertida; impactos mudavam
recorte/escala por quadro. Corrigido tecnicamente; aceitação do usuário pendente.

GPT Images gerou pilot_seated.png (1254×1254, figura completa) e
projectile_heads.png (1536×1024, seis cabeças constantes em grade3×2).
PNGs copiados intactos. Prompts/origens em assets/hd/PILOT_SHOTS_PROMPTS.md e
GENERATION.json; recortes/hashes em atlas_regions.json. Rider/atlas anteriores,
originais e áudio preservados. Mobile usa um único piloto proporcional com
pivô dos quadris no assento, nos dois sentidos e em encostas.

projectile_art.gd mantém cabeça/aspecto fixos centrados em hit_pos/pos;
Bigfoot usa velocity.angle (fonte aponta DIREITA), chama atrás, pulsação contínua.
Chamas HD são componentes isolados de shots.png. Mage usa rastro contínuo
sobre trail físico, tint por fase e orbe constante com overlays. Impactos
fazem crossfade6fases e envelope suave; EMP círculo constante, centro/duração
originais. Offset de tremor só visual, aplicado também aos tiros/Fx. Pausa
congela clocks. Catálogo/recortes válidos obrigatórios, senão usa original.
Modelo de combate, terreno, perfil, regras, salvas e tamanho dos mobiles sem diff.

Validação fresca: **783 checks, zero falhas**: 251 modelos/cenas/ataques,
189 atlas HD, 240 animação e103 piloto/tiros. Continuidade de tiro cobre180
amostras por configuração e efeito120; não contar cada amostra como um teste.
RED→GREEN para renderer, chama ausente e catálogo inválido de impactos/EMP.
Perfis isolados. Dez partidas anteriores são histórico, não foram repetidas
pois regras de combate não mudaram. Logs locais .tools/pilot-shots-final-*.

GPU:72frames a24fps, seis armas/impactos, PNG1920×1080 e MP4/GIF em
docs/projectiles; piloto em ±30°, plano e recuo virado. Galeria de tiros usa
fixtures e escala4×, não prova voo natural.16capturas reais de jogo atualizadas
em docs/hd com capture_hd_assets.gd. Revisão independente conferiu fontes e
frames; P2 de fallback de catálogo corrigido com duas regressões; revisão
aprovada sem pendências. Inspeção de frames, sem avaliação manual completa.

App/ZIP Universal **0.6.2** reexportados via build_macos.py. Assinatura
profunda/estrita válida, runtime exportado sem erros. PCK isolado em projeto
vazio validou novos assets/recortes/catálogo/chamas, piloto1×1 e salvas4/6/8,
zero falhas. Git local/tag v0.6.2; sem remoto/push/publicação.

```sh
mkdir -p .tools
python3 scripts/catalog_hd_assets.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_hd_assets.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_mobile_animation.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_pilot_projectiles.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_pilot_projectiles.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_hd_assets.gd
python3 scripts/build_macos.py
```

Limite: arte/animação HD adaptadas, não restauração quadro a quadro Gunbound.
Próximo passo: usuário validar personagem, T1/T2/SS e impactos no aplicativo.

## Entrega anterior 0.6.1: correção de sprites/animação

Usuário relatou inconsistências visuais/animadas Bigfoot/Mage. Diagnóstico:
atlas GPT mudava anatomia, Bigfoot moving tinha clarão; recorte de aura junto
ao corpo redimensionava silhueta e piloto. REQ-19/20/12; plano completo em
`ANIMATION_FIX_0_6_1.md`. Corrigido e revisado, aceitação visual do usuário pendente.

`mobile_parts.png` gerado via GPT Images a partir de heroes, 1536×1024 RGBA,
cinco peças constantes: chassis/canhão/roda Bigfoot; corpo/cajado Mage. Prompts
em `assets/hd/ANIMATION_PROMPTS.md`, origens em GENERATION.json. PNGs antigos
e originais preservados. Janelas reais x0–570/570–1040/1040–1536, y0–512/512–1024,
alpha>8; fronteiras sem corte opaco. Haze RGB fora das peças tem alpha0.

`mobile_rig.gd` anima peças contínuas com âncoras e dimensões fixas, mesmo render
menu/arena. Piloto usa cabeça/corpo constantes sobre assento do chassis.
Suspensão, canhão/cajado, carga/recuo/dano/morte separados de auras/clarões.
BattleArt passa pose_age/arma correta e acumula wheel_phase pelo deslocamento:
rodas conservam fase ao parar. Pausa congela tudo. Fallback integral ao atlas
original/piloto/offsets originais se rig incompleto ou catálogo de peças inválido.
Removidos hd_frame/hd_rows e referências ativas aos atlas variáveis de mobile
e portraits heroes; arquivos mantidos como histórico. Tiros/Fx permanecem HD0.6.
Sem mudanças de física, colisão, dano, turnos, progresso ou sons.

Validação fresca: **667 checks**, zero falhas (251 modelos/cenas/ataques,
176 atlas HD atualizados +240 animação). Cada critério contínuo avalia90
amostras a60Hz por estado/arma; não contar cada amostra como teste distinto.
RED→GREEN para rig, continuidade/fase de roda e catálogo inválido. Perfis
isolados. Capturas GPU: 216 frames a24fps, storyboard1920×1080 e prévias
MP4/GIF em `docs/animation`; 16 capturas de jogo atualizadas em `docs/hd`.
Revisão independente aprovou após examinar fontes, 240checks e frames
representativos. Inspeção de frames, sem teste manual completo da fluidez.

App/ZIP Universal **0.6.1** reexportados via build_macos.py, assinatura
profunda/estrita válida, runtime independente sem erros. PCK sozinho em
projeto vazio validou rigs/recortes/tiros/Fx e salvas4/6/8, zero falhas.
Git local tag `v0.6.1`, nenhum remoto/push/publicação.

Limites: animação articulada é adaptação; morte colapsa/faz fade do mesmo
corpo, não restaura os destroços originais quadro a quadro. Próximo passo:
usuário avaliar movimentos/cargas/recuo/morte e uso funcional do aplicativo.

```sh
python3 scripts/catalog_hd_assets.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_mobile_animation.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_mobile_animation.gd
python3 scripts/build_macos.py
```


## Entrega anterior 0.6.0: assets HD

Pedido: melhorar Bigfoot, tiros e assets importados com GPT Images. Preferência
confirmada: aparência clássica com detalhes mais nítidos. REQ-19/12/20; plano
em `HD_ASSETS_0_6.md`. Sete PNGs separados em `assets/hd`: Bigfoot/Mage4×8,
piloto4×2, tiros4×6, efeitos6×6, heroes2×1 eEMP1254×1254. Seleção usa heroes;
arena60/menu180 preservados. Originais PNG/MP3/JSON comparados byte a byte com
Git, nenhum alterado. Sons, combate, terreno e progresso permanecem os atuais.

`hd_sheet.gd` alinha a figura à área visível do quadro original, filtro linear.
`mobile_sprite.gd.hd_frame` converte estado antigo a4 quadros chave, preservando
duração/índices originais; saúde baixa modula cor. Tiros têm4 fases/Fx6; MageSS
usa fonte maior girando com o efeito. Menos imagens distintas por animação:
não anunciar recuperação exata dos419 quadros ou equivalência artística total.
Ausência de derivado/quadro usa original automaticamente.

Prompts/ferramenta em `assets/hd/GENERATION.json`; dimensões/hashes/recortes em
`atlas_regions.json`. Alpha1/255 fora da figura deformava enquadramento:
catálogo considera alpha>8/255 somente para recorte, sem editar PNGs. Regenerar
por `scripts/catalog_hd_assets.py` (Python+Pillow) depois de trocar derivado.
JSON normaliza números em int; preset inclui explicitamente esse arquivo.

Validação: **439 checks**, zero falhas (251 anteriores+188 HD). Dez partidas
naturais seeds81–90 mantiveram17/10/8/7/10/8/15/9/11/20 tiros, zero falhas;
modelos de combate sem diff. RED→GREEN para suporte HD, ruído, heroes eEMP.
CenaMage15/Bigfoot14 repetidas após EMP final. Perfis isolados nos testes.
App/ZIP0.6.0 Universal reexportados, assinatura profunda/estrita válida e
runtime nativo sem erros. PCK sozinho em projeto vazio validou derivados,
JSON de recortes e salvas4/6/8, zero falhas.

16 capturas GPU em `docs/hd`, framebuffer1920×1080, cena1280×800 escalada1,35
com margem96px. Resolução lógica/exportação não mudaram. Script exige efeito
do mobile/arma antes de salvar impacto; primeiras capturas MageT1/SS tinham
chegado à CPU sem explosão e foram rejeitadas. Mage usa força65 na captura
natural corrigida. Não houve teste manual completo; usuário avalia arte/fluidez.
Revisão independente aprovou a implementação e os impactos corrigidos de Mage
T1/SS, sem achados pendentes. Commit/tag local v0.6.0.

```sh
python3 scripts/catalog_hd_assets.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_hd_assets.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_hd_assets.gd
python3 scripts/build_macos.py
```

Versionamento local; sem remoto, push ou publicação. Próximo passo: usuário
validar aparência, animações e uso funcional. Seções abaixo são histórico.

## Entrega anterior 0.5.0: ataques Bigfoot

Pedido atual: identificar no C# e assets os tiros T1/T2/SS e reproduzir as
salvas próprias do Bigfoot. Requisitos03–09/19; plano e dados exatos em
`BIGFOOT_ATTACKS_0_5.md`. Bigfoot mantém arena60/menu180. Mage preservado.

- T1:4 bombas, intervalos0,2s, dispersão local+3/−3/0/0°.
- T2:duas rajadas de3 em0,2/0,4s, força−4/0/+4 pontos por rajada.
- SS:8 bombas, intervalos0,125s, dispersão T1 repetida.
- Dano por bomba90/70/90 e raio25; delays770/920/1320÷7,5; mira18–40° eSS23–35°.
- Bullet1/2/3, explosões e seis sons originais. T2 usa Armor/Flame2 como a chamada
  C# executada; SS imagem tem20 quadros, não os30 solicitados no fork.

`bigfoot_attacks.gd` guarda dados/emitter. `spawn_at`/`launched`/`flight_elapsed`
separam espera e voo; bombas pendentes não envelhecem, aparecem ou colidem.
Todo turno espera a salva acabar. CPU executa o mesmo avanço e agendamento em
cópias isoladas, incluindo crateras/mortes, até12s após o último lançamento.
`shot_velocity` aplica dispersão depois de limitar mira base; força T2 pode
chegar11–104% após ajuste, sem comprimir variantes nas bordas. HUD muda limites
por tiro e bloqueia sinais do slider ao ajustar faixa, evitando sobrescrever
mira com thumb antigo. Pausa congela pendentes/voo; reinício limpa a salva.

Validação **251 checks**, zero falhas: anteriores181 +56 ataques +14 cena.
Dez partidas naturais seeds81–90 concluíram com17/10/8/7/10/8/15/9/11/20 tiros;
87–88 Bigfoot jogador,89–90 Bigfoot adversárioCPU. Teste Mage de escudo agora usa
Escaravelho para isolar o Pulso145; fila de cena usa ready215 para ficar entre
novos delays Bigfoot. São fixtures atualizadas por mudança intencional de perfil.
Revisão independente aprovada: dados/assets conferidos por hash e72 cenários
adicionais de previsão versus voo, incluindo bordas, direções e deltas.

Capturas GPU reais: `docs/bigfoot-{t1,t2,ss}.png`, `*-impact.png` e
`bigfoot-t2-pending.png`; capturas antigas de menu/arena/carga/movimento/tiro
atualizadas. Sem validação manual completa de áudio/mouse. Balística mundial,
resistências, clima/Thor, itens e regenHP35 não foram portados. SS continua
terceiro turno próprio/um uso por partida. Não anunciar equivalência integral.

App/ZIP **0.5.0 Universal arm64/x86_64** reexportados por `build_macos.py`,
assinatura profunda/estrita válida. Runtime independente iniciou sem erros;
PCK carregado sozinho em projeto vazio com perfil isolado validou salvas4/6/8,
quadros/piloto, efeitos e12 streams de áudio Bigfoot/Mage, zero falhas.
Commit/tag local `v0.5.0`; nenhum remoto/push/publicação.

Novos comandos:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_bigfoot_attacks.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_bigfoot_attacks_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_bigfoot_attacks.gd
```

Perfis isolados em `.tools/`. Próximo passo: usuário validar T1/T2/SS, mouse,
áudio/volume, pausa e fim de partida conforme `docs/VALIDACAO.md`. Demais mobiles
ou rede/ranking/mobile exigem nova solicitação. Seções abaixo são histórico.

## Entrega anterior 0.4.0: Mage

Pedido: implementar o outro veículo como Mage do Gunbound com os assets recebidos.
Mage substitui Carapaça (índice 1), selecionável e adversário do Bigfoot padrão.
Bigfoot mantém escala de arena 60/menu 180. Fonte/escopo em `MAGE_0_4.md`; REQ-19
avança com Mage, sem concluir ataques oficiais do Bigfoot ou os demais mobiles.

Mage usa atlas/piloto/offsets, lasers/orbe, efeitos e seis sons originais. PNGs,
MP3s e JSON intactos, hashes/avisos em `assets/openbound/`. `mobile_sprite.gd`
compartilha leitor de atlas; `mage_sprite.gd` traz dados e efeitos específicos.
Vida 760, escudo 220, regeneração 20 por turno próprio até 220 + HP perdido,
mira 15–50°. Tiro 1: laser 150; tiro 2: dois lasers helicoidais de 200; SS: orbe
200 com EMP zerando escudos próximos. Dano/raios/delays no plano. SS usa valor
executado do fork (200, apesar da constante 300 não usada). Delays normalizados
por 7,5; força/gravidade/vento e desbloqueio SS mantêm adaptações do protótipo.
Não declarar reprodução integral do cliente Gunbound.

`weapon_rules/aim_limits` abastecem modelo, CPU, fila e HUD. Hélice usa
`Combat.sample_position`; `hit_pos` guarda collider físico real. Salvas previstas
executam o mesmo voo em cópias de máscara/atores, incluindo crateras e mortes,
sem imagens GPU. Revisão encontrou divergência quando o primeiro laser abre
passagem para o segundo; corrigida e revisada com regressão RED→GREEN da parede.
HUD mostra escudo, limites reais de mira e nomes de arma. Pausa congela hélice e
quadros; carga da CPU segue plano/arma. Morte Mage completa antes do resultado.

Validação fresca: **181 checks** (40 + 28 modelos, 13 + 21 cena, 28 Bigfoot,
36 Mage e 15 cena Mage), zero falhas. Oito partidas naturais seeds 81–88 concluíram
em **24/10/8/17/17/8/29/19 tiros**. Revisão independente aprovada após correção.
Capturas GPU em `docs/mage-{menu,arena,charge,s2,ss,impact}.png`; Bigfoot capturas
atualizadas com Mage adversário. Impacto Mage é fixture visual controlada; partidas
naturais são evidência separada. Não houve teste manual completo de mouse.

App/ZIP **0.4.0 Universal arm64/x86_64** reexportados pelo script. Assinatura
profunda/estrita válida; runtime independente headless iniciou sem erros. O
runtime release não aceita `--script`; a validação detalhada do PCK foi feita
carregando somente o pacote exportado em projeto vazio, com perfil isolado: JSON,
seis áudios, estado Mage e disparo carregados, zero falhas. Avisos incluídos.
Versionamento local com tag `v0.4.0`; nenhum remoto/push/publicação.

Novos comandos, além das suites anteriores:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_mage.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_mage_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_mage.gd
```

Perfis de teste/captura isolados em `.tools/`. Aplicativo e ZIP nos caminhos do
baseline abaixo; usuário deve validar funcionalmente seguindo `docs/VALIDACAO.md`.
Próximo passo é feedback da entrega, sem ampliar rede/ranking/mobile ou demais
mobiles automaticamente. Seções abaixo preservam evidências e limites históricos.

## Ajuste anterior 0.3.1: Bigfoot menor

Pedido do usuário: diminuir o carro e realizar versionamento. Bigfoot e piloto
reduzidos juntos de 80 para 60 unidades visuais na arena (25%) e de 230 para 180
na prévia do menu. Não houve alteração de PNG, regras, colisão ou perfil.
Capturas `docs/bigfoot-*.png` atualizadas. Passaram os 28 checks Bigfoot existentes;
novos testes de constantes de estilo não foram necessários. Aplicativo/ZIP 0.3.1
reexportados; assinatura e execução independente verificadas. Commit local da
mudança; nenhum remoto/push. Os 130 checks e oito partidas abaixo são evidência
da integração 0.3.0 anterior, não uma nova execução integral neste ajuste visual.

## Integração 0.3.0: Bigfoot com sprites originais

Bigfoot foi integrado como terceira opção, selecionada inicialmente no menu.
Atlas, piloto padrão masculino, offsets por quadro e projéteis são os originais
do pacote recebido, sem alterar PNGs. Arquivos usados em `assets/openbound/`;
leitor `scripts/bigfoot_sprite.gd`, poses em `battle_art.gd`. Capturas GPU reais:
`docs/bigfoot-menu.png`, `bigfoot-arena.png`, `bigfoot-moving.png`,
`bigfoot-charge.png` e `bigfoot-firing.png`. Fonte/avisos e hashes preservados.

Plano em `BIGFOOT_0_3.md`. 130 verificações (40+28 modelos, 13+21 cena, 28 Bigfoot)
passaram; oito partidas seeds 81–88 concluíram, incluindo duas Bigfoot. Revisão
independente encontrou troca de quadros SS após turno rápido; corrigida com
RED→GREEN. Trocar arma durante carga também reinicia seu próprio ciclo. JSON do
piloto e avisos de referência incluídos no pacote. App/ZIP 0.3.0 Universal exportado.

Esta é a integração visual Bigfoot. Armas ainda mantêm dano, quantidade, atraso
e balística do protótipo; salvas 4/6/8, resistências, áudio específico e outros
mobiles não foram portados. Vida 1100 e movimento 90. Não anunciar reprodução
completa de Gunbound. Usuário ainda precisa validar funcionalmente no aplicativo.

Novo teste: Godot `--headless --path . --script tests/test_bigfoot.gd`.
Nova captura: Godot `--path . --script tests/capture_bigfoot.gd` (perfil isolado).
Demais comandos do baseline abaixo continuam válidos; `test_matches` agora joga
oito partidas. Próximo passo: feedback visual/funcional e ataques/próximos mobiles
conforme nova solicitação. Textos sobre a entrega 0.2 abaixo são histórico.

## Histórico do pedido e recebimento de assets

O usuário pediu copiar e integrar Bigfoot e outros mobiles reais do fork
informado, substituindo a aproximação visual por maior fidelidade. Nova auditoria
das duas branches/releases e do pipeline confirma ausência do pacote: 803 fontes
referidas por `Content.mgcb`, todas ausentes. Código/metadados Bigfoot existem;
pixels dos sprites e projéteis não. Ver `ORIGINAL_ASSETS.md`.

O usuário forneceu a pasta Drive; **Game Assets.rar já está baixado, extraído e
validado** em `.tools/source-assets/`. Conteúdo em `.tools/source-assets/content/`;
manifesto em `.tools/source-assets/manifest.json`. São 813 arquivos, incluindo os
dez mobiles reais, projéteis, efeitos e áudio; todos os 803 assets referidos pelo
pipeline estão disponíveis. RAR íntegro e 628 PNGs verificados, sem imagens inválidas.
Detalhes e checksum em `ORIGINAL_ASSETS.md`. Não pedir novamente o pacote.

Próximo trabalho: integrar spritesheets e regras por mobile, começando por Bigfoot.
Versão executável permanece 0.2.0; não anunciar integração ou novo build antes de
implementar e verificar. Não gerar substitutos visuais nem usar a restrição de
arte original do baseline como veto ao pedido. Os downloads ficam fora do Git;
copiar para `assets/openbound/` somente os recursos usados na implementação.

## Estado atual: refinamento 0.2 entregue

Em 2026-10-11, após `c530e23`, o usuário solicitou melhorias de mecânica,
animações e design a partir de três vídeos e do fork Chafy-Studio/_OpenBound.
Pesquisa registrada em `GUNBOUND_REFERENCES.md`; design/execução em
`REFINEMENT_0_2.md`. O usuário aprovou com “implementa”. Versão 0.2.0 implementada,
testada, revisada e reexportada; próxima etapa é feedback funcional do usuário.

O pacote principal de sprites não está no fork. Nenhum código/asset do OpenBound
foi incorporado; a proposta utiliza nossa arte original e adapta comportamentos.
Aplicativo e ZIP locais agora são 0.2.0. A pesquisa está em `.tools/`, fora do Git.

Mudanças: console azul metálico, armas 1/2/SS, força graduada e marcador anterior,
fila prevista, bússola, movimento que vira, apoio inclinado afetando mira e
auto-disparo a 100%. `battle_art.gd` cuida de repouso/movimento/carga/recuo/dano/
destruição e clarão/detritos/fumaça. Animações por código sobre PNGs originais.
Pausa cancela carga sem atirar e congela animação. Perfil e nome do app preservados.

Verificação desta versão: 40 + 28 modelos, 13 + 21 cena = **102**, zero falhas;
seis partidas seeds 81–86 com **24, 10, 10, 17, 6 e 7 tiros**, zero falhas.
Revisão independente encontrou sobreposição de vida após cratera, corrigida com
RED→GREEN. A fila espera a arma da CPU e muda de posição para proteger a vida.
Build Universal 0.2.0, assinatura profunda/estrita válida, executável independente
headless encerrou com código 0. Capturas GPU atualizadas, incluindo `charge.png`.
Não foi realizada validação manual completa de mouse; o roteiro continua pendente.

Comandos adicionais da versão atual, além dos três do baseline abaixo:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_refinement.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_refinement_scene.gd
```

Commits desta entrega são obtidos em `git log`; nenhum push/remoto foi criado.

## Histórico do baseline 0.1 (preservado)

Atualizado em 2026-10-11. Protótipo entregue; aguardando feedback funcional do
usuário. Esta sessão acrescenta SDD e o primeiro snapshot Git, sem mudar o jogo.

## Retomar em uma nova sessão

1. Ler este documento, `SPEC.md`, `DESIGN.md`, `TASKS.md` e `DECISIONS.md`.
2. Conferir `git status`, `git log -5 --oneline` e a solicitação atual do usuário.
3. Consultar requisitos `REQ-*` antes de mudar comportamento; ler o código afetado.
4. Priorizar feedback funcional. Sem nova solicitação, não começar o roadmap.
5. Atualizar especificação, tarefas, decisões e este hand-off ao concluir mudanças.

## O que existe

Jogo 2D original offline 1×1: dois veículos, três armas, vento, terreno destrutível,
vida, dano e quedas, turnos por atraso, CPU com três dificuldades, pausa, ajuda,
resultado/revanche/menu e perfil local. PNGs gerados com GPT Images e efeitos
visuais/sonoros originais. Ranking foi retirado explicitamente.

O aplicativo macOS Universal foi entregue e aberto no computador na sessão
inicial. Fonte é o projeto Godot; aplicativo e ZIP são artefatos locais ignorados.

| Caminho | Uso |
|---|---|
| `project.godot` | Importar no Godot e executar com F5 |
| `scenes/main.tscn` | Cena principal; executar com F6 |
| `builds/Gunbound Recomp.app` | Aplicativo local independente |
| `builds/Gunbound-Recomp-macOS.zip` | Pacote local da entrega |
| `docs/VALIDACAO.md` | Roteiro de aceitação funcional pelo usuário |
| `docs/APRENDIZADO.md` | Explicação da implementação para aprender com o resultado |
| `docs/ART.md` | Prompts e origem das imagens |

## Ambiente e checkout novo

Ambiente validado: macOS, Godot **4.7.2.stable.official.ed1daf0bf** em
`/Applications/Godot.app`, GDScript, renderer Compatibility. Python 3 é usado
apenas no empacotamento. Sem dependências Node.js. Outros alvos não foram testados.

Git local na branch `main`, sem remoto na consolidação. Identidade já configurada
no ambiente foi utilizada; não foi criada configuração global nova. O snapshot
contém código, UIDs/import settings, arte, evidências e documentação. Exclui
`.godot/`, `.tools/`, `builds/`, temporários e arquivos locais de credenciais.

Depois de clonar/copiar uma revisão em outro diretório, prepare a pasta usada
pelos testes e importe recursos antes de rodar os scripts:

```sh
mkdir -p .tools
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
```

Execute a partir da raiz. Em outras máquinas, ajuste o caminho do Godot;
comandos de pacote e assinatura abaixo são exclusivos do macOS.

## Verificações

```sh
./scripts/check.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_runner.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_scene.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_matches.gd
```

Evidência inicial: 40 verificações de modelos + 13 da cena, zero falhas; seis
partidas naturais de modelos, seeds 81–86, encerradas em 10–28 tiros. Os testes
de partidas deixam a IA controlar ambos os atores; não simulam um humano usando
mouse. Testes de cena exercitam handlers reais de input e usam áudio mudo.
Todos os perfis de teste são isolados em `.tools/`, sem conceder XP ao jogador.

As mesmas suites foram reexecutadas na consolidação Git/SDD; consultar o registro
ao final deste hand-off. A revisão independente inicial confirmou as correções
registradas em `DECISIONS.md`.

Capturas de QA em `docs/menu.png`, `arena.png`, `impact.png`, `result.png`.
São renders reais; a captura de resultado usa vitória controlada, não comprova
término natural. Partidas naturais são verificadas separadamente na suite.

Limite da validação inicial: Computador conseguiu ler captura, mas recusou
interação de mouse como `noWindowsAvailable`. Não alegar teste manual completo
do aplicativo por mouse. Ainda falta o relato do usuário sobre uso funcional.

## Reproduzir o aplicativo

O exportador requer `.tools/macos.zip`, não versionado. No computador original
esse arquivo está disponível. Em um checkout novo, baixar o pacote oficial
`Godot_v4.7.2-stable_export_templates.tpz` na
[release Godot 4.7.2](https://github.com/godotengine/godot/releases/tag/4.7.2-stable),
extrair `templates/macos.zip` e colocá-lo em `.tools/macos.zip`. Não confundir
esse template com o editor. Os presets debug/release apontam para esse arquivo.

```sh
python3 scripts/build_macos.py
codesign --verify --deep --strict --verbose=2 'builds/Gunbound Recomp.app'
open 'builds/Gunbound Recomp.app'
```

O script exporta, normaliza executável/PCK para `GunboundRecomp`, inclui avisos de
licença Godot, assina ad-hoc, verifica e cria ZIP. Não publicar uma exportação
direta sem essa normalização: foi necessário corrigir assinatura inválida com
nomes internos acentuados. Pacote não notarizado nem publicado; teste local.
Mudanças no código só chegam ao aplicativo depois de reexportar.

## Progresso do jogador e limites

Perfil real no Mac:
`~/Library/Application Support/Godot/app_userdata/Gunbound Recomp/profile.json`.
Não apagar, migrar ou usar esse perfil em testes. Sem conta, ranking ou nuvem.

Limites: um mapa, dois veículos, CPU não se move, sprites estáticos com efeitos
por código, terreno de 2 px e fragmentos suspensos. Balanceamento provisório.
Não há protocolos online, builds Windows/Linux ou interface mobile implementados.

O próximo passo é validar a entrega com o usuário e registrar feedback.

## Registro desta consolidação — 2026-10-11

- `test_runner.gd`: 40 verificações, zero falhas, código de saída 0.
- `test_scene.gd`: 13 verificações, zero falhas, código de saída 0.
- `test_matches.gd`: seis partidas, zero falhas, código de saída 0; tiros por
  seed 81–86: 18, 10, 10, 28, 10, 10.
- Assinatura do aplicativo existente: `valid on disk` e
  `satisfies its Designated Requirement` na verificação profunda/estrita.
- Links locais da documentação principal/SDD e os 12 IDs de requisitos conferidos.
- Exclusões Git conferidas para cache, template, build e credenciais locais.

Nenhum comportamento do jogo foi alterado nesta consolidação. Não houve novo
build nem nova validação manual por mouse; o aplicativo é o da entrega inicial.
O commit inicial registra o snapshot completo. Consulte `git log` para obter sua
identificação e `git status` para detectar alterações posteriores.
