# Shop de avatar — proposta de especificação

Data: 2026-10-12. Estado: **proposta para revisão; código não implementado**.
Branch: `codex/avatar-shop`, worktree criado do commit de `main` disponível
no início desta sessão. Alterações não commitadas da pasta principal não foram
copiadas. A especificação de itens 0.13 já está no baseline; o código de itens
em andamento não está.

## Pedido e decisões confirmadas

Portar o Shop do projeto C# em `~/Workspaces/Gunbound` para Godot,
reproduzindo as mecânicas das categorias cabeça, corpo, óculos e bandeiras.
O usuário confirmou saldo inicial de teste em Gold/Cash, sem dinheiro real,
e inclusão da distribuição dos oito atributos com seus efeitos no combate.
GPT Images foi permitido para derivados de maior qualidade, sem exigir
substituição de todos os atlas neste pedido.

Sucesso: abrir o Shop no menu, experimentar sem equipar, comprar pelo preço
original, equipar apenas itens possuídos, ver a composição no preview e na
arena, distribuir/cancelar/confirmar pontos e observar os efeitos reais na
partida e na previsão da CPU. Tudo persiste localmente sem perder progresso.

## Abordagem proposta

Portar catálogo, regras e layout do C# para módulos Godot separados, trocando
somente servidor/banco por transações no perfil local. Isso preserva o treino
offline e permite reaproveitar as regras se houver rede no futuro.
Uma loja simplificada com cosméticos liberados não satisfaz compra/saldo;
um porte dos servidores e contas amplia o escopo além do autorizado.

Os números novos abaixo são adaptações propostas, claramente separados das
regras encontradas no C#: saldo inicial 1.000 Gold + 1.000 Cash; pontos
`min(max(nível_local - 1, 0) * 10, 180)`. O nível 1 equivale ao rank inicial
sem pontos. Não reintroduzir ranking; o XP/nível existente continua intacto.

## Fonte de verdade e auditoria

Consultar o código, não usar os documentos históricos como autorização:

- `OpenBound/GameComponents/Level/Scene/Menu/AvatarShop.cs`: abas, filtros,
  busca, 25 cards (5×5), experimentar, seleção, compra e equipamento.
- `.../Interface/Popup/PopupBuyAvatar.cs`: confirmação, antes/depois do saldo,
  moedas apenas com preço positivo, compra indisponível sem saldo.
- `.../Interactive/AvatarShop/AvatarButton.cs`: retratos e indicadores.
- `.../Interactive/AvatarShop/AttributeMenu.cs`: rascunho, aceitar/cancelar,
  pontos remanescentes e oito atributos.
- `.../Interactive/AvatarShop/InGamePreview.cs`, `Pawn/Rider.cs`,
  `Pawn/Avatar.cs`: previews, âncoras, flip, pivôs, estados e relógio.
- `.../Asset/MetadataManager.cs`: ordenação por categoria/ID e união de
  itens Unissex com o gênero do jogador.
- `Openbound Network Object Library/DatabaseSeed/AvatarMetadata.json`:
  identidade, preços, data, dimensões e pivôs.
- `.../Models/Player.cs`: propriedade/equipamento, atributos e orçamento.
- `.../Common/NetworkObjectParameters.cs`: 10 pontos por nível, 180 total,
  50 por categoria; valores originais de recompensas.
- `.../Database/Controller/PlayerController.cs`: compra transacional,
  preço positivo e validação do saldo.
- `.../Entity/MobileMetadata.cs`: vida e atraso; `Entity/MatchManager.cs`:
  atraso dos itens e passagem sem redução de AttackDelay.
- `OpenBound/GameComponents/MobileAction/Projectile.cs`: dano e erosão.
- `OpenBound/GameComponents/Pawn/Mobile.cs`: regeneração e itens.
- `Openbound Game Server/Service/GameClientProvider.cs`: Gold e Popularity.

Auditoria: **15 registros** nas quatro categorias, **13 atlas visíveis** e
**15 retratos** presentes em `OpenBound-Assets/Game Assets`. Os dois registros
sem óculos/bandeira usam o dummy do original. Existem 5 cabeças, 4 corpos e
1 óculos masculinos; 1 cabeça e 1 corpo femininos; 1 óculos vazio e 2 bandeiras
unissex. Não inventar catálogo feminino nem novos preços. Kappa custa
99.999.999 em cada moeda; os demais compráveis custam 100; básicos/vazios
custam zero e já pertencem ao jogador.
SHA-256 do JSON fonte:
`746bca156dac7ab47d8fca9ca4e16ac48eda0618f17c3f2b598c4d67a7c53ed4`.

## REQ-38 — Shop e compra local

Entrada pelo menu e retorno preservando apelido/mobile/opções. Tela com
layout e sprites do OpenBound adaptados à viewport 1280×800: abas Shop e
Inventário, filtros das quatro categorias, busca case-insensitive por nome,
ordem original, paginação de 25 cards, saldos e preview de avatar/mobile.
Gênero selecionável, masculino como padrão de compatibilidade, unissex nos
dois catálogos; compras guardadas por identidade composta gênero/categoria/ID.

Selecionar na loja não equipa nem compra. Experimentar altera só o conjunto
do preview da loja. Inventário mostra somente itens possuídos e clicar equipa
um item por categoria. Óculos/bandeira ID0 removem a peça. Cabeça/corpo ID0
restauram Basic. Troca de gênero usa conjuntos separados para não perder
compras/equipamento incompatível. Compra não equipa automaticamente.

Popup bloqueia o restante da interface, oferece Gold/Cash somente com preço
positivo e saldo suficiente, mostra saldo antes/depois e permite cancelar.
Transação valida catálogo, identidade/gênero, propriedade e saldo novamente;
débito e propriedade são gravados juntos. Falha de gravação não confirma nem
mantém débito. Clique duplo/repetido não compra duas vezes; saldo nunca negativo.

Saldo de teste é concedido uma única vez na criação/extensão do perfil para o
Shop (1.000 por moeda), nunca a cada abertura. Valores, posses, equipamentos,
gênero e atributos persistem sem apagar apelido/XP/vitórias/partidas/awarded.
Perfil legado/corrompido recebe saneamento e padrões seguros. Não usar o perfil
real nos testes. Gift/CashCharge continuam desativados, como no C#; sem Token,
pagamento, presente, conta ou serviço de rede.

## REQ-39 — Composição do avatar

Preservar PNGs originais, pivôs/dimensões/FPS e estados do C#. Preview de loja
e inventário independentes, incluindo avatar separado e mobile com piloto.
Na arena, jogador usa equipamento confirmado; CPU usa conjunto básico.
Manter Bigfoot/Mage, seu rig e suas âncoras; adaptar o rider composto ao assento
atual com escala única. Substituir o piloto monolítico no caminho que usa avatar,
sem sobrepor dois pilotos. Cabeça/corpo/óculos/bandeira usam camadas e flip
coerentes nos dois sentidos, inclinação, recuo, movimento e destruição.
Relógio visual é pausável; render não determina colisão nem modifica combate.

Manifest com origem e SHA-256 de atlas/retratos/interface; originais preservados.
Derivados GPT Images são opcionais: exigem geometria, alfa e fallback válidos;
não anunciar HD se houver apenas ampliação ou geração ainda não validada.
Interface fiel com fonte disponível (Consolas original não está distribuída).
O preview usa Mage/Bigfoot selecionado em vez do Raon fixo do C# (adaptação
necessária ao roster autorizado).

## REQ-40 — Distribuição dos oito atributos

Ordem: Attack, Health, Defense, Regeneration, AttackDelay, ItemDelay, Dig,
Popularity. Cada valor é inteiro 0..50 e a soma não ultrapassa o orçamento.
Abrir o painel copia valores para um rascunho. +/- alteram rascunho/remanescentes;
Confirmar valida e salva; Cancelar restaura. Sair com rascunho descarta mudanças
não confirmadas. Falha de gravação mantém os valores confirmados anteriores.
Equipar/comprar avatar não concede pontos nem muda atributos automaticamente:
o catálogo do C# não tem bônus por peça.

Proposta de adaptação do orçamento ao protótipo: 10 pontos por avanço do nível
local, teto 180. Sem ranking visual ou tabela de ranks. Mudanças só se aplicam
na próxima partida; a partida copia atributos e não consulta o perfil vivo.

## REQ-41 — Efeitos dos atributos no combate

Aplicar os modificadores originais sobre os valores/regras atuais do protótipo;
não substituir toda a balística/falloff/resistências neste corte.

| Atributo | Efeito encontrado no C# a portar |
|---|---|
| Attack / Defense | dano de projétil × (1 + (Attack do atirador − Defense do alvo) / 100), truncado; aplicar antes da absorção de escudo |
| Health | vida inicial/máxima = int(vida base × (1 + Health/100)); escudo base não aumenta |
| Regeneration | cura por turno e regeneração de escudo × (1 + Regeneration/100), truncadas e limitadas como no C#; Mage/Bigfoot têm regen HP base zero; Proteção base 35 e escudo Mage base 20 |
| AttackDelay | atraso do tiro × (1 − AttackDelay/100), truncado na unidade original antes da conversão ÷7,5; passe conserva custo atual |
| ItemDelay | custo do item × (1 − ItemDelay/100), truncado antes da conversão ÷7,5; não reduz atraso do tiro |
| Dig | raio da cratera × (1 + Dig/100); não altera raio de dano/EMP |
| Popularity | bônus percentual sobre Gold, conforme fluxo 1×1 de GameClientProvider; não altera XP/Cash |

Popularidade precisa de Gold ganho: portar a contabilidade original pertinente
a Mage/Bigfoot no 1×1 (tiro, dano, morte, resultado e condições especiais), com
valores/eventos identificados no C# e testes para truncamento e ordem. Saldo
inicial de teste não é bonificado. Recompensa de resultado não pode duplicar
Gold nem XP em revanche/reabertura. Preservar XP local existente; efeitos de
Gold não exigem ranks/chat online. Não aplicar Attack/Defense indiscriminadamente
a quedas/Thor/raio: verificar cada caminho da fonte e registrar o porte.

Match permanece a fachada autoritativa. Atores e flight_snapshot transportam
atributos copiados; previsão de tiro e busca em thread usam os mesmos cálculos
e o mesmo terreno com Dig. Dano, regeneração, atraso e HUD consultam funções
compartilhadas. Atributos zerados preservam partidas seeds 81–90 do baseline.

Dependência explícita: o baseline contém só a especificação dos itens 0.13.
Não copiar alterações não commitadas da main. ItemDelay deve ter função/teste
com custo original e ponto de integração definido; seu efeito em uso real
só pode ser declarado validado após a integração do código de itens em branch.

## Separação de responsabilidades proposta

- `avatar_catalog.gd`: catálogo imutável e resolução por identidade.
- `avatar_shop_model.gd`: filtros/páginas, seleção/experimentação e operações.
- `avatar_shop.gd`: tela, input, popup e desenho da interface original.
- `avatar_art.gd`: composição e animação de peças, compartilhada nos previews
  e no rider do mobile, sem lógica de compras/combate.
- `player_attributes.gd`: orçamento/validação e funções de modificadores.
- `profile.gd`: persistência atômica do progresso e das transações locais.
- `gold_rewards.gd`: regras pertinentes de Gold do C#, apuração única.
- `match.gd`, `damage.gd`, `mobiles.gd`, `turn_table.gd`, `flight_snapshot.gd`:
  aplicação compartilhada dos modificadores, sem dependência de interface.
- `game.gd`: entrada/retorno do Shop, snapshot de perfil no início e apresentação.

## Critérios de validação

1. Catálogo/preços/IDs/pivôs/atlas/retratos conferidos contra fonte e manifest.
2. Compra Gold/Cash, preço zero indisponível, Kappa sem saldo, repetição,
   cancelamento, falha de save, reload e perfil legado/corrompido isolados.
3. Experimentar não persiste; inventário equipa; sem óculos/bandeira funciona;
   gêneros/unissex e sets de equipamentos não se misturam.
4. Paginação usando catálogo fixture >25, busca que reduz páginas/zera resultados,
   cliques reais nas abas/cards/popup, modal/input/retorno corretos.
5. Pontos 0/50/180 e sem remanescentes, rascunho/confirmar/cancelar/reload;
   fórmulas testadas em exemplos derivados do C#, incluindo Attack−Defense.
6. Tiros reais e previsão iguais com atributos em Mage/Bigfoot/T1/T2/SS,
   crateras Dig, escudo/Proteção, fila/HUD e thread sem acesso ao estado vivo.
7. Contabilidade de Gold e Popularity testada com eventos/resultados repetidos;
   XP/progresso existente preservados. ItemDelay integrado quando houver itens.
8. Capturas GPU do Shop, compra, inventário e piloto equipado nos dois mobiles
   e sentidos; comparar fonte/composição, sem clipping/saltos nas animações.
9. Importar checkout, preparar .tools e executar check.sh completo com novas
   suites de modelos e cena. Atualizar TASKS/HANDOFF com evidências e limites.
10. Caso seja entregue app, reexportar com build_macos.py e verificar assinatura;
    não confundir execução do projeto com app atualizado. Nenhum push/publicação.

## Estado observado nesta preparação

Worktree importado no Godot e baseline completo executado: **1114 checks +
10 partidas, zero falhas** (partidas em ~41 s). Ainda não existem Shop nem
modificadores implementados. Próximo passo: revisar esta proposta, fechar as
adaptações de saldo/orçamento e preparar o plano de implementação.
