# Bigfoot — acabamento bicúbico4× (ADR-115)

REQ-12/19/20/45. Pedido de 25/10/2026: aplicar ao Bigfoot a melhoria já
aprovada nos botões e no lobby (ADR-101/103), a suavização conservadora
BICUBIC4× por quadro. Não é redesenho nem nova arte gerada.

Numeração: criada como ADR-104 no commit 5f86a74; ao mesclar na `main`, que
já usava ADR-104…114 para a sala, passou a ADR-115. No mesmo merge,
`room_random_sprite.gd` (ADR-106, Random 4× da sala) deixou de redeclarar
`density`: o membro agora vem de `MobileSprite`, com o mesmo significado
(texels por pixel nativo); sem a remoção o parse falhava. A legenda gravada em
`docs/bigfoot-smooth-4x/composition.png` e no MP4 ainda mostra o número antigo.

## Escopo

As nove folhas originais de `assets/openbound/bigfoot/original/`, extraídas do
cliente na restauração 0.20.3 (ADR-089): `CharacterSpritesheet` (tank5,
20×24 células 86×65), `Bullet1/2/3`, `Bullet1Light`, `Bullet3Light` e
`Flame1/2/3`. A grade de cada folha vem das dimensões do PNG divididas pela
célula do `frames.json`, incluindo células vazias.

Fora do escopo: piloto padrão `RiderBody/RiderHead` (compartilhado pelos 16
mobiles via `LEGACY_RIDER`), avatares, aura UsingItem, Mage e os outros
mobiles clássicos. Regras, física, IDs, pivôs, contato, RiderPivot,
hitboxes, durações EPA, áudio e perfil não mudam.

## Método e integração

1. `scripts/build_bigfoot_smooth_hd.py` usa o helper da skill: cada quadro é
   filtrado isoladamente com BICUBIC em RGBA pré-multiplicado e o alpha é a
   cobertura nativa ampliada por nearest. Destino novo
   `assets/hd/classic/mobiles_smooth_4x/bigfoot/`; nunca sobrescreve.
   Catálogo registra origem/hash, registro da folha, grade, tamanho e hash.
2. `MobileLooks` liga o acabamento só no Bigfoot (`"smooth": ...`).
   `ClassicSprite` valida o catálogo por folha (versão, escala, origem, hash
   da fonte, grade e tamanho real) e guarda a densidade junto com a textura.
   Folha inválida/ausente volta ao PNG nativo com densidade1.
3. Apenas o recorte de origem é multiplicado pela densidade. Destino, pivô,
   contato, escala de batalha e encaixe do avatar continuam nativos. Filtro
   nearest mantido, como nos botões.

O contorno externo continua em degraus nativos: o método conserva o alpha.
Suavizam-se o RGB interno e as transições de cor. Não é paridade nova nem
detalhe recuperado; cores são interpoladas.

## Aceitação

- Dimensões4× por eixo, mesma grade, alpha idêntico ao nearest da fonte.
- Recortes de destino/pivô/contato idênticos ao nativo; origem ×4.
- Fallback por catálogo/PNG inválido; Mage e demais clássicos inalterados.
- Regressões de mobiles/cena, captura GPU1920×1080 nos dois sentidos e pausa.
- Custo medido do atlas4× (arquivo, memória e carga) registrado abaixo.

## Evidência

Implementado em 25/10/2026. `python3 scripts/build_bigfoot_smooth_hd.py`
(Pillow 11.3.0, 4,7 s) gerou as nove folhas; validador da skill aprovou
alpha/dimensões/grade de todas (relatórios em `docs/bigfoot-smooth-4x/reports`).

| Folha | Nativo | 4× | Grade |
|---|---|---|---|
| CharacterSpritesheet | 1720×1560 | 6880×6240 | 20×24 |
| Bullet1 / Bullet1Light | 144×12 / 248×26 | 576×48 / 992×104 | 8×1 |
| Bullet2 | 96×20 | 384×80 | 8×2 |
| Bullet3 / Bullet3Light | 160×14 / 184×23 | 640×56 / 736×92 | 8×1 |
| Flame1 / Flame2 / Flame3 | 660×428 / 312×196 / 768×512 | 2640×1712 / 1248×784 / 3072×2048 | 6×4 |

Import com os mesmos parâmetros do nativo (lossless, sem mipmaps). Custo do
atlas: PNG 12,1 MB, `.ctex` 8,1 MB, carga ~200 ms e 172 MB descomprimidos
(RAM/VRAM) contra 10,7 MB do nativo; `build_sprites` dos 16 mobiles ~0,9 s
headless. PCK isolado 180,9 MB. Aceitável no desktop; exportações móveis
futuras devem reavaliar esse custo.

- `test_bigfoot_smooth` **70/0**: recortes ×4, destino/pivô/contato/RiderPivot
  nativos, demais 15 mobiles em densidade 1, import sem perda visível (como no
  nativo, `fix_alpha_border` só recolore pixels com alpha < 20) e fallback por
  catálogo ausente, escala, kind, frames.json, grade e folha individual.
- Regressões dirigidas: **1196 checks/0** em 16 suítes (Bigfoot, ataques,
  originais, clássicos, cena, roster, avatar, itens, Mage, tiros, HUD,
  desempenho). Segunda rodada **1772/0** em 12 suítes (HD, animação, runner,
  especiais, timing, loja larga, lobby UI/arte, botões, Nak, refinamento,
  continuidade do avatar). `test_lobby_ui` falhou antes por falta da pasta
  `.tools/lobby-rank` no worktree novo; criada a pasta, 96/0. Skill: 21 testes
  Python aprovados (`unittest`).
- GPU 1920×1080, relógio 60 Hz, 210 quadros (`tests/capture_bigfoot_smooth.tscn`):
  nativo × 4× no mesmo renderer, dois sentidos, ±15°, low, tiros e impactos.
  Cobertura dos sprites idêntica (diferenças só da fumaça do Flame3 de outra
  linha); pausa 120–149 com hashes idênticos e movimento antes/depois.
  PNG/MP4 em `docs/bigfoot-smooth-4x/`.
- Escala real (`tests/capture_bigfoot_smooth_scene.tscn`): janela 1920×1080
  com stretch `canvas_items` do projeto (canvas 1728×1080, barras laterais),
  sala (casco 52) e arena (casco 60), par nativo/4× e 60 quadros movendo nos
  dois sentidos. Sem granulação ou cintilação visível no 4×; pose/posição
  iguais. Câmera em tempo real faz os pares de movimento diferirem no fundo.
  PNG/MP4 em `docs/bigfoot-smooth-4x/scene/`. Uma primeira execução encerrou
  no quadro 15 da segunda variante sem erro de script; a repetição completou.
- PCK isolado exportado do worktree, smoke fora do projeto **30/0, exit0**:
  catálogo, frames.json, atlas 6880×6240, oito folhas ×4, Mage/demais nativos,
  sem override.cfg.

Limites: contorno externo continua em degraus (alpha nativo); piloto padrão
nativo; cores interpoladas, sem detalhes recuperados. Aplicativo não
reexportado, aceite visual do usuário e partida manual pendentes. Regras de
combate não mudaram; partidas completas não foram repetidas.
