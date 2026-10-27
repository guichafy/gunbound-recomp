# Avatar Shop com assets originais — REQ-47, ADR-130

## Pedido e decisões do usuário (27/10/2026)

Corrigir e ajustar os assets/imagens do Avatar Shop usando os assets originais
do jogo, com REA sempre que preciso. Referências: jglim/gunbound-server
(`Other/gb-avatar.png`) e jglim/gunbound-launcher (TestClient `graphics.xfs`
versão 280 e `avatar.xfs`). Respostas às dúvidas que as fontes não resolviam:

1. **Avatares: tudo original.** Retratos, prévia vestida, sala e batalha
   desenham as peças nativas do XFS. A migração HD 0.17 (ADR do
   AVATAR_HD_MIGRATION) deixa de ser o consumidor ativo e fica preservada em
   disco como histórico/fallback opcional.
2. **Botões: imagens originais** com o texto em inglês gravado (Try, Buy,
   Sell, Laundry, Gift, EXIT, BUDDY, CASH CHARGE), sem rótulo PT sobreposto.
3. **Extras: igualar ao original.** Sem busca, contador de página, "Nível",
   linhas "Standard" nem "Treino offline"; cabeçalho com nome/Rank/GP/Gold/Cash
   e inventário com nome+status como no cliente.

Substitui, na loja, a composição vetorial/GPT da 0.16 (AVATAR_SHOP_XFS_0_16,
ADR-070 seguintes), o fundo/retratos GPT de `assets/hd/shop/xfs_*` e o uso
ativo de `assets/hd/avatars/xfs` (0.17/0.18). Arquivos HD permanecem em disco.
Catálogo, preços, bônus, compra/vestir/rollback, atributos e perfil não mudam.

## Fontes fixadas

| Fonte | Identidade |
|---|---|
| Cliente PE | `.tools/mobile-animation-port/GunBound.gme`, SHA-256 `4af6283d…0fcde` |
| graphics.xfs | `.tools/gunbound-client/graphics.xfs` (versão 280, mesmo pacote do catálogo) |
| Captura do cliente | `Other/gb-avatar.png` 806×627; área cliente 800×600 em (3,23) |
| REA | Hopper via MCP REA: strings, xrefs, leitura de `%8d`/`%02d` |
| Ghidra 12.2 headless | `builds/ghidra-shop-ev1` (0x44a000, 0x50ae40), `builds/ghidra-shop-ev2` (0x44c460, 0x4ed9f0) |

## Matriz por comportamento

Confiança: **comprovada** (ASM/dado do cliente), **medida** (casamento de
template na captura original 1:1, erro RMS registrado), **adaptada**.

| Elemento | Fonte original | Regra/posição (palco 800×600) | Confiança |
|---|---|---|---|
| Fundo | `store_back.img` 800×600 | (0,0); fora do 4:3, faixa lisa como o lobby | comprovada (`sub_447760` carrega id 0x2710) |
| Painel My Avatar | `store_myavatar.img` 0 (pivô 0,104) | âncora (552,5) | medida (552,109) |
| Card | `store_avatar` 0/1 160×156 | `x=(i%3)·163+21`, `y=(i/3)·161+69`; 1 = selecionado | comprovada (0x44a000) |
| Tag BOY/GIRL | `store_avatar` 2/3 | card+(125,5); bandeiras sem tag | medida |
| Nome | `font.fnt` ASCII 8×12, avanço 6 | card+(24,5), branco | medida; formato verificado |
| Ícone da categoria | `store_icon` cabeça 2/3, corpo 0/1, óculos 4/5, bandeira 6 (+pivô) | card+(7,6) | medida |
| Retrato | `s*.img` do XFS, tamanho nativo | card+(52,62)+pivô do IMG (ADR-131) | medida nos 9 cards |
| Status do card | `store_icon` 8–23 + `numfont` 40–49 | ordem shot_delay, popularity, attack, defense, health, item_delay, bunge, shield; zeros omitidos; no máximo 3; ícone card+(104,34+18n), dígitos `%02d` card+(123,35+18n) avanço 6 | comprovada (0x44a000, `%02d`) |
| Sinal do ícone | par par/ímpar | shot_delay: valor ≤0 → ícone ímpar (+) e valor negado; demais: valor <0 → ícone par (−) e valor negado | comprovada (SETLE/SETL+NEG) |
| Preço Cash | `numfont` 50–59, vírgula 279 | `%8d`, card+(14,110), dígito avança 10, vírgula avança 4 a cada grupo e só desenha após o 1º dígito; rótulo `store_avatar`4 em card+(110,110) | comprovada (0x44c460, 0x44afb0) |
| Preço Gold | `numfont` 60–69, vírgula 280 | idem em card+(14,126); rótulo `store_avatar`5 em card+(110,126) | comprovada |
| Sem Gold / sem Cash | `store_avatar` 6 / 7 | CASH ONLY em card+(66,126); GOLD ONLY em card+(66,110) | comprovada |
| Categorias | `b_store_cap/cloth/glasse/flag` 5 estados (4 = ativo) | (35+53i,556) | medida |
| Rolagem dos cards | `b_store_up/down` | (517,80) e (517,488) | medida |
| Try / Buy | `b_store_puton` / `b_store_buy` | (359,556) / (448,556) | medida |
| Sell / Laundry / Gift | `b_myavatar_sell/dry/gift` | (566,513) / (639,513) / (712,513) | medida |
| EXIT / BUDDY | `b_store_exit` / `b_store_buddygame` | (562,550) / (680,550) | medida |
| CASH CHARGE | `b_store_cashcharge` | (485,7) | medida |
| Rolagem do inventário | `b_scroll_up/down` | (759,117) / (759,326) | medida |
| Linhas do inventário | `store_myavatar` 1 (destaque) | x=571, y=109+17k; seta `store_icon`7 em +(0,4); ícone em +(6,2); nome em +(24,3) | medida |
| Status da linha | `store_icon` + `numfont` 40–49 | da direita para a esquerda: ícone (724−25k,+2), dígitos (733−25k,+4); até 2 | medida |
| Grade de status | `store_icon` 9…23 + `numfont` 40–49 | colunas 672/729, linhas 39+17r, ordem acima; dígitos +20 | medida |
| Contador LCD | `numfont` 0–9 | contagem do inventário, sem zeros à esquerda, `x=761−8k, y=16` | medida |
| Cabeçalho | `font.fnt`, patente do lobby | nome (191,23); "Rank" (326,9); GP, GOLD (173,39), CASH (320,39) | medida; textos locais adaptados |
| Popup de compra | `store_window_back` 1 + `b_storewindow_gold/cash/cancel` | centralizado | adaptada (sem captura) |
| Prévia vestida | peças nativas do XFS (AvatarArt sem HD) | caixa da prévia | adaptada (rig existente) |

## Adaptações declaradas

- Linha 1 do cabeçalho (guilda) fica vazia: o perfil não tem guilda. Rank usa
  a patente atribuída do lobby (ADR-102); GP é o XP local.
- Laundry restaura a prévia ao conjunto vestido; Sell, Gift, BUDDY e CASH
  CHARGE ficam no estado desabilitado original (sem rede/dinheiro).
- Gênero e atributos não existem na tela original. Ficam acessíveis por dois
  controles discretos na faixa lateral fora do palco 800×600, sem tocar na
  moldura original. Atributos continuam no modal aprovado (ADR-064).
- Texto não ASCII (apelido acentuado) usa a fonte do sistema como fallback;
  os 562 nomes do catálogo são ASCII.
- Acabamento: frames da loja recebem o BICUBIC4× por quadro com alpha nearest
  (ADR-101/103), com fallback nativo. Retratos e peças vestidas ficam nativos.
- O inventário lista também os itens padrão ("Standard"), que o perfil local
  trata como possuídos; sem eles não haveria como voltar ao padrão. Na captura
  original só aparecem itens comprados. O contador LCD segue as linhas listadas, portanto
  inclui os padrões (9 no cenário da captura, onde o original mostra 6).
- Smoke de pacote: `tests/capture_shop_original_pck.gd`. Capturas/smokes
  anteriores da loja ficaram marcados como históricos (pré-ADR-130).
- Janela de compra: `store_window_back`1 (BUY ITEM) centralizada, com retrato,
  nome, até três status e os preços na regra do card; um botão por moeda com
  preço e Cancel, centralizados. Não há captura do popup original.
- Seleção da loja fora da página filtrada é limpa (contrato 0.14.9); por isso a
  linha laranja só aparece quando o item selecionado está visível.

## Plano

1. Extrator `scripts/import_xfs_shop.py` reproduz os 22 frames já versionados
   e acrescenta os faltantes, `numfont` usado e o atlas ASCII do `font.fnt`.
2. `scripts/build_shop_smooth_hd.py` gera `assets/hd/classic/shop_smooth_4x`.
3. Reescrever a view `avatar_shop.gd` sobre esses frames; manter a API usada
   por cena/testes (model, refresh, open_buy, close_buy, try_selected,
   set_preview_mode, toggle_gender, open_attributes, ESC).
4. `AvatarArt` passa a preferir as peças nativas por padrão.
5. Ajustar suítes da loja ao novo oráculo, mantendo os checks de
   comportamento; captura GPU 1920×1080 lado a lado com a referência.

## Resultado observado

- `import_xfs_shop.py`: 171 frames em 26 entradas; os 116 já versionados
  ficaram byte a byte iguais. `build_shop_smooth_hd.py`: 171 derivados 4×,
  verificador da skill sem falhas (relatórios em `docs/avatar-shop-original/reports`).
- `avatar_shop.gd` reescrito sobre `classic_shop_art.gd`; GPT de loja
  (`assets/hd/shop/xfs_*`, `wide_background`) e HD de avatares fora do uso ativo,
  preservados em disco. `AvatarArt` nativo por padrão (sala/batalha incluídas).
- Suíte nova `test_shop_original` (70 checks): oráculos independentes do ASM
  para preço/vírgula/dígitos/LCD/sinal, ordem de status pela captura, posições
  medidas, ausência de busca e de texturas GPT, fallback nativo, compra única,
  Try/Laundry, inventário e avatar nativo no rig. Seis suítes antigas da loja
  adaptadas ao novo oráculo sem afrouxar compra/rollback/ESC/atributos.
- Suítes dirigidas: 20 suítes de loja/avatar/cena, **6663 checks, 0 falhas**.
- Harness completo: parse + 99 suítes, **27085 checks e 29 partidas, 0 falhas**;
  com o check 1280×800 posterior, `test_shop_original` passou a 73/0.
- GPU real 1920×1080 (`tests/capture_shop_original.gd`): loja, nativo, compra,
  categorias, gênero, sala e batalha; 120 quadros a 60 Hz (`preview.mp4`, só a
  prévia anima). `comparison.png` põe a área 800×600 de `gb-avatar.png` ao lado
  do palco do Godot.

Limites: captura Godot não é execução do cliente Windows; popup de compra e
posições não cobertas pela captura são adaptações; aceite visual e uso com
mouse pelo usuário pendentes; aplicativo não reexportado.

## Correção ADR-131 — contorno pontilhado dos retratos

O usuário apontou contornos pontilhados (Safety Helmet, Marine Hat). O
decodificador apagava o preto dentro das faixas RLE; o cliente o desenha opaco.
Agora só frames cheios RGB565 usam preto como chave. 496 retratos ganharam
versão `_rle` (anteriores preservados), 98 frames da loja e os derivados 4×
foram regenerados, e o retrato usa `card+(52,62)+pivô` (`portrait_pivot` no
catálogo), que casa com os nove cards da captura. Peças vestidas (ARGB4444) não
mudaram. Testes: `test_shop_original` 77/0 (posições medidas e contorno opaco),
`test_xfs_import` 14/0 (regra RLE/tipo 0 e pivô), suítes da loja/avatares 0 falhas.
