# Itens do cliente — REQ-48 / ADR-133

Fonte: graphics.xfs SHA-256
`a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`,
TestClient jglim/gunbound-launcher commit `2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1`.
Extração reproduzível: `python3 scripts/import_xfs_items.py`.
Manifesto `assets/xfs/items/catalog.json`: hashes das entradas e PNGs,
quadros, dimensões, margens, pivôs e comparação com os arquivos herdados.

## Inventário e escolha

| Consumidor | Recurso anterior | Equivalente existente no cliente | Caminho ativo / limite |
|---|---|---|---|
| `scripts/item_art.gd:49` / `button_frame` | HD GPT Item*.png; fallback openbound/items | item1.img 0/2/4/12/28, item2.img 0/2/10/12/18/20 e quadro seguinte | assets/xfs/items/Item*.png; composição adaptada |
| `scripts/item_art.gd:143` `draw_beacon` | TeleportBullet HD | bulletiteml.img, 12 quadros | xfs/items/TeleportBullet.png, pivô nativo |
| `scripts/item_art.gd:165` `draw_flames` | TeleportFlame GPT, fallback Teleport1 herdado | teleport1.img e teleport2.img, 19 quadros cada | Teleport1 nativo; reversão prova exata de Teleport2 |
| `scripts/item_bar.gd:50` via ItemArt.region | MatchStatus HD | playmode.img quadro15 217×38 | MatchStatus nativo inteiro na caixa existente217×35 |
| `scripts/item_art.gd:52` | ShootTeleport.mp3 | sem associação ao evento comprovada | herdado, lacuna declarada |
| `scripts/item_art.gd:53` | BlastTeleport.mp3 | PE pede itemblast.xes, ausente no sound.xfs | herdado, lacuna declarada |
| `scripts/item_art.gd:67` `_load_using` | UsingItemMage/Bigfoot, original ou HD | sem equivalente comprovado nesta build | herdado1×, sem GPT ativo |
| `scripts/select_item_popup.gd:49/:195` fundo/abas | SelectItemBackground/TabIndex, original ou HD | popup herdado sem equivalente comprovado | herdado1×, sem GPT ativo |

Os quadros de item1 são: Bunge0, PowerUp2, Blood4, EnergyUp1=12,
ChangeWind28. item2: Dual0, Dual+2, Thunder10, EnergyUp2=12, Teleport18,
TeamTeleport20. O cliente só fornece normal e desabilitado por item nesta
build. Hover repete normal; clique/seleção repetem desabilitado. Não foram
inventados quatro estados novos. Margem transparente1px mantém as caixas
37×36/73×36 e os recortes existentes; nenhum PNG é redimensionado no import.

Chamas e beacon mantêm as janelas antigas só como armazenamento; os pivôs
originais determinam a posição do desenho. A afirmação inicial de identidade
RGBA com os atlas herdados estava incorreta: havia diferenças de registro
(chamas deslocadas4pxY, além de diferenças no beacon). Os novos atlas são
comparados diretamente aos frames/pivôs XFS, não aos arquivos herdados.
A física/colisão/teleporte de Match permanece inalterada.

Fallback: arquivo nativo ausente ou com tipo/tamanho inválido retorna à cópia
herdada. As dimensões e recortes de fallback são testados sem apagar arquivos
reais. A ausência de equivalente não motiva novo desenho nem som arbitrário.
Arte GPT permanece em disco; o renderer ativo não carrega os derivados HD.
A sala mantém sua arte conservadora do cliente aprovada anteriormente.

## Validação dirigida

- `test_client_item_assets`: 66 checks, caminhos ativos, dimensões,
  janelas dos11itens×4estados, fallback ausente/inválido, banner e aura.
- `test_client_item_source.py`: 4 testes; rejeição de outra build antes de gravar, pixels dos44estados e50quadros de
  teleporte/beacon, pivôs, reversão, banner e hashes contra o XFS original.
- `test_map`48 + `test_items_scene`49; integração dirigida total163/0.
- O primeiro teste da nova suíte falhou3checks com o renderer HD antigo;
  repetido após o porte:66/0. Sem alteração de regra/perfil real.

Capturas e harness completo são consolidados em `CLIENT_ASSETS_PORT.md`.
