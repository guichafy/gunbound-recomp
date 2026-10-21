# Itens de batalha 0.13 — especificação e plano

## Pedido

"Precisamos implementar na batalha os itens que podemos usar nos turnos como
Dual, implemente copiando a lógica, física e demais características do jogo
Gunbound em C#." Complemento: "As imagens devem ser re-geradas em qualidade
Full HD usando Codex gpt-image." (2026-10-12)

## Fonte (OpenBound, `~/Workspaces/Gunbound`)

- `Openbound Network Object Library/Entity/Item.cs`: 11 itens, categoria,
  slots e custo de delay (`ItemCost`).
- `Common/NetworkObjectParameters.cs`: custos e valores (cura, ataque, cavar).
- `Entity/MatchManager.cs` `ComputePlayerItem`: o delay do item entra no
  delay do jogador no momento do uso, `(1 − ItemDelay/100) × ItemCost`.
- `GameComponents/Pawn/Mobile.cs` `UseItem` / `ShootWithModifiers` / `Shoot`:
  efeitos e disparo duplo; `Heal`.
- `Pawn/UnitProjectiles/GenericProjectile.cs` `TeleportationBeacon`: projétil
  do Teleport (massa 10, sem vento, colide só com o terreno, sem dano).
- `MobileAction/Projectile.cs`: `InteractionTime`/`SpawnTime`,
  `CalculateDamage` (× (1 + Attack/100)), erosão × (1 + Dig/100).
- `Interface/HUD.cs` `UseItemAction`/`GrantTurn`/`LockItem`/`DisableSS`,
  `Interactive/EquippedButtonBar.cs`, `Popup/PopupSelectItem.cs`,
  `Interactive/TabButtonList.cs`, `Interactive/Button.cs` (presets),
  `Interface/WeatherDisplay.cs` (Ignorance trava a barra),
  `Animation/SpecialEffectBuilder.cs` (`TeleportFlame1/2`),
  `Animation/MobileFlipbook.cs` (`UsingItem`), `Common/Language.cs`.

## Requisitos

### REQ-35 — Itens usáveis no turno

Desde o ADR-076 os custos seguem a coluna de delay do `itemdata.dat` original; entre parênteses, o valor anterior do C#.
Delay em unidades do protótipo: custo original ÷ 7,5 (mesma conversão de
Mage/Bigfoot, ADR-058). `ItemDelay` do jogador = `Attributes.points(actor, 5)` desde a 0.14.3
(antes 0 no treino).

| Item | Slots | Custo (orig. → protótipo) | Efeito |
|---|---|---|---|
| Dual | 2 | 600 → 80 | Dispara duas vezes o tiro selecionado; o 2º começa 1 s após o último lançamento do 1º |
| Dual+ | 2 | 250 → 33,33 (C# 450) | 1º = tiro selecionado; 2º = S2 se S1, senão S1 |
| Thunder | 2 | 200 → 26,67 | Todo projétil do turno ganha a propriedade elétrica (não acumula com a coluna Elétrico) |
| Energy Up 2 | 2 | 300 → 40 (C# 350) | Cura 30 % da vida máxima (sem escudo); Bionic +3 % (nenhum dos dois mobiles) |
| Team Teleport | 2 | 50 → 6,67 | Troca com o aliado mais ferido; sem aliado no 1×1: só chamas e som |
| Teleport | 2 | 100 → 13,33 (C# 150) | O tiro vira um sinalizador; o mobile vai para onde ele toca o chão |
| Blood | 1 | 0 → 0 | Ataque +33 % no turno; perde 8 % da vida máxima (nunca abaixo de 1) |
| Bunge Shot | 1 | 50 → 6,67 (C# 80) | Cratera × 1,25 (dano e raio de dano inalterados) |
| Power Up | 1 | 150 → 20 | Ataque +30 % no turno |
| Change Wind | 1 | 150 → 20 (C# 120) | Ângulo do vento + 180° (força igual) |
| Energy Up 1 | 1 | 100 → 13,33 | Cura 12 % da vida máxima (sem escudo) |

Regras de uso (HUD.cs/Mobile.cs):

- Só no próprio turno, na mira, antes de atirar; nunca enquanto o mobile cai.
- Um item por turno: após o uso a barra inteira fica desabilitada até o
  próximo turno próprio.
- Usar item desabilita o SS no turno (`DisableSS`): se SS estava
  selecionado, passa ao tiro 2.
- Clique num item durante o turno do adversário o marca (estado ativado);
  ele é usado automaticamente no início do próximo turno próprio. Novo
  clique desmarca; marcar outro troca.
- No turno próprio, selecionar o item (ou já tê-lo marcado no turno
  adversário) tira o botão do slot na hora e recompacta a barra
  (ADR-065). No OpenBound a remoção esperava o próximo `GrantTurn`
  (`removeItemFromBarAction`); o pedido atual antecipa esse sumiço para
  o momento do uso. A barra segue desabilitada até o próximo turno próprio.
- Clima Ignorância ativo trava a barra (sprite "ITEM LOCKED").
- O custo de delay entra na hora do uso; Delayboard e fila mostram na hora.
- Efeitos de turno (Dual, Dual+, Thunder, Teleport, Power Up, Blood, Bunge
  Shot) duram até o fim do turno próprio; passar ou tempo esgotado também
  os encerram (adaptação: no C# Attack/Dig só voltam no caminho do tiro).

Física e dano (Projectile.cs / Mobile.cs):

- Dual/Dual+: o 2º disparo usa o mesmo ângulo/força e a posição de lançamento
  do 1º; cada projétil guarda sua arma (raio, dano, EMP, som e arte). Espera
  do 2º = 1 s + maior `spawn` do 1º, depois os próprios `spawn` do 2º
  (InteractionTime, então SpawnTime). O delay de turno cobra só a arma
  selecionada, mais o custo do item.
- Power Up/Blood: dano final por alvo × (1 + Attack/100), truncado, depois do
  decaimento por distância e dos climas Força/Fraqueza/Espelho.
- Bunge Shot: só o raio da cratera × 1,25.
- Teleport: um sinalizador único no lugar do tiro (salvas não se repetem),
  velocidade × 14/10 (massa 14 → 10), vento × 0, colide só com o terreno,
  sem dano nem cratera. Ao tocar, o mobile vai para o ponto de contato,
  apoiado no chão daquele x; sair do mapa não teletransporta. Climas,
  Thor e Elétrico continuam agindo sobre ele como em qualquer projétil.
- Thunder: equivale à coluna Elétrico de escala 1000 (64 000 px) centrada no
  mobile e invisível: todo projétil fica elétrico desde o lançamento.
- Energy Up: cura limitada à vida máxima (adaptação: o C# não limita).
- Previsão da CPU e voo real usam as mesmas regras (efeitos no dicionário do
  ator, copiado por `flight_snapshot.gd`).

### REQ-36 — Seleção de itens (PopupSelectItem)

- No menu, "Itens" abre o `PopupSelectItem` original: fundo SelectItem, abas
  "2 Slots"/"1 Slot" (TabIndex), grade de itens (4 por linha nos de 2 slots,
  9 nos de 1 slot), nome com a cor da categoria, custo de delay e descrição
  ao passar o mouse, barra de 6 slots equipados (clique remove), Accept.
- No máximo 6 slots; itens repetem.
- Carga gravada junto das opções (`items`, nomes estáveis); testes usam
  arquivo isolado. Padrão sem arquivo: Dual, Teleport, Power Up, Energy Up 1.
- Cada partida (e revanche) começa com a carga completa.

### REQ-37 — Arte HD (Full HD) por GPT Images

- Originais copiados para `assets/openbound/items/` (SHA no manifest) e
  preservados: 11 botões SelectItem, `MatchStatus.png`, fundo do popup,
  `TabIndex.png`, `TeleportBullet.png`, `Teleport1.png`, `Teleport2.png`,
  sons `Shoot/Teleport.mp3` e `Blast/Teleport.mp3`.
- Derivados gerados no Codex CLI (`gpt-5.6-sol`, `image_gen`) a partir de
  folhas de referência com layout fixo, recortados e ajustados ao alfa
  original: botões/estado/popup/abas 3× (HUD desenhado a 1,6 = 2,4× em Full
  HD); sinalizador e chamas do Teleport 2× (mundo 1:1 = 1,5× em Full HD).
- Chamas do Teleport (19 quadros 190×192): 6 quadros-chave por chama com
  transição suave, duração original (19/30 s), como os impactos de 0.6.2.
- Fallback aos originais se o HD faltar.

### Barra de itens no HUD

- `EquippedButtonBar` em (−116, −37) do centro da barra de ação (painel
  F1–F6), botões 73×36 / 37×36 colados (largura − 1), K = 1,6.
- `MatchStatus` "ITEM LOCKED" sobre o painel quando Ignorância trava.
- Extras discretos (adaptação, como ← → F ●): teclas F1–F6 acionam o botão
  na posição; o OpenBound só as liga na DebugScene.
- Animação `UsingItem` (Bigfoot 234–253, Mage 243–262, 20 quadros a
  19 fps) ao usar. O rig HD não troca o corpo: diamantes e feixes verdes
  saem desses quadros e são redesenhados a 4× em
  `assets/hd/items/UsingItem{Bigfoot,Mage}.png` (grade 5×4), com o mesmo
  pivô e contato do atlas. Fallback: recorte colorido do original em
  `assets/openbound/items/`. `scripts/build_using_item_fx.py` regenera
  as duas folhas. GPT Images devolveu um diamante pixelizado e um feixe
  JPEG sem alfa; essas tentativas não entram no jogo.

## Fora do escopo / limites

- CPU não usa itens neste corte (sem novos sorteios: seeds 81–90 iguais).
- Ouro/preço em ouro não existe no treino; o popup mostra o custo de delay.
- `ItemDelay` (atributo de avatar) = `Attributes.points(actor, 5)`, aplicado
  em `Items.delay` (0.14.3; antes 0). Team Teleport fica no catálogo com o
  comportamento 1×1 do original (sem aliado).

## Resultado (2026-10-12)

- Fases A–E concluídas com commits locais por fase, sem push.
- `./scripts/check.sh`: **1205 checks + 10 partidas, zero falhas**
  (test_items 49, test_items_scene 42). Seeds 81–90 com vencedor, tiros e vida
  restante idênticos aos da 0.12 (rodada da base num worktree temporário).
- Geração HD: 5 folhas no Codex (`items2`, `items1`, `popup`, `beacon`,
  `flame`), origens em `assets/hd/GENERATION.json`, prompts em
  `assets/hd/ITEMS_PROMPTS.md`; densidade 3× (UI) e 2× (efeitos).
- Capturas GPU 1920×1200 em `docs/items/` (barra HD/original, Dual em uso,
  ITEM LOCKED, Select Item HD/original, sinalizador, chamas).
- App/ZIP 0.13.0 reexportados (`build_macos.py`), `codesign --verify --deep
  --strict` válido; PCK com itens HD/originais e sem folhas brutas.
- Limites: CPU sem itens; sem teste manual de mouse/áudio no app; queda
  após teletransporte sob teto não aplica dano de queda (o mobile é apoiado
  no chão da coluna); cor das bordas fracas das chamas vem do original.

## Fases

A. Especificação, decisão e plano (este documento, REQ-35..37, ADR-058).
B. Modelo: `items.gd`, regras em `match.gd`, previsão; `test_items.gd`.
C. Arte: originais, folhas e geração HD no Codex, pipeline e manifest.
D. Cena: barra no HUD, popup no menu, teclas, efeitos/sons do Teleport,
   animação; testes de cena.
E. Capturas GPU, documentação, check completo, export macOS. Commit por fase.
