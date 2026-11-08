# Peças offline e loja com os dois gêneros — REQ-38..41/46/47

Pedido de 08/11/2026: disponibilizar as 67 peças da auditoria no treino offline
e mostrar ambos os gêneros na mesma loja, na worktree da investigação.

## Contrato

- Conceder gratuitamente os 67 registros XFS não padrão, não vendáveis, com
  camadas/arte disponíveis; concessão idempotente no início do app para
  perfis novos/existentes, transacional com rollback em falha de gravação.
- Não conceder nove lacunas de arte, padrões adicionais ou imagens sem DAT.
  Preservar os JSONs originais, buyable, preços, bônus, IDs e imagens.
- Catálogo e inventário da loja mostram ambos os gêneros, atual primeiro,
  ordenados por id dentro de cada grupo, compartilhados sem duplicação.
  A coleção ofertada tem 546 peças (479 vendáveis +67 liberadas).
- Cards extras são possuídos, sem compra/preço mostrado; usar Try e inventário
  existentes para vestir. Não adicionar botões nem textos sobre arte nativa.
- Seleção não persiste gênero/equipamento. Experimentar não possuído usa
  prévia inteira do gênero da peça sem gravar. Comprar peça de outro gênero
  não troca piloto. Vestir uma peça possuída troca gênero/equipamento numa
  única transação; falha mantém perfil e prévia anteriores. Inventário idem.
- Conjuntos separados por gênero, bandeiras compartilhadas, aparência nativa,
  atributos e pipeline sala/loading/batalha permanecem.

Concessão gratuita é adaptação offline autorizada; lista mista e prioridade
por gênero vêm de 0x00449540 (evidência em AVATAR_CATALOG_AUDIT.md). A troca de
conjunto ao vestir é integração offline, sem alegação de reprodução do fluxo
original de gênero. Sem rede/export/publicação nesta tarefa.

## Plano de implementação — concluído

1. Testes de concessão (67 exatas, idempotência, perfil existente, rollback),
   lista mista (546 únicas/ordem/paginação), seleção/prévia/compra/vestir de
   outro gênero e passagem do conjunto até a batalha. Rodar antes do código.
2. AvatarCatalog define elegibilidade offline e listagem da loja sem mudar
   items/compatible usados nas regras. Profile concede no startup e suporta
   vestir com troca explícita e atômica; compra não impõe gênero no XFS.
3. AvatarShopModel mantém gênero da prévia, permite os dois grupos e reseta
   conjunto na troca de gênero; AvatarShop integra inventário misto, estado de
   Try, seletor e omissão de preço nas peças concedidas.
4. Verificar cenas/loja/perfil/avatares/atributos e harness pertinente, capturar
   loja mista e Skeleton em loja/sala/batalha com perfil temporário. Registrar
   resultados e limites, atualizar TASKS/HANDOFF/decisões.

## Implementação e validação observadas

- `AvatarCatalog.offline_piece` mantém a elegibilidade separada de buyable;
  `shop_items` combina os gêneros e remove duplicatas compartilhadas.
- `Profile.grant_offline_avatars` acrescenta posses no startup, sem marcador
  ou alteração de schema, e só grava quando há itens faltantes. Em arquivo
  ilegível não sobrescreve o save; em erro de escrita restaura o snapshot.
- `Profile.equip(key, switch_gender=false)` mantém o contrato estrito por
  padrão; a loja solicita troca explícita numa única transação. Compra XFS
  aceita ambos os gêneros sem alterar gênero/equipamento.
- O modelo acompanha o gênero da prévia e recompõe o conjunto ao mudar de
  gênero; page_for mantém o card selecionado visível após reordenar a loja.
  Inventário misto, seletor e Try acompanham o conjunto efetivamente salvo.
- Totais conferidos: 546 peças ofertadas; cabeça156, corpo151, olhos72,
  bandeira167. Perfil novo recebe 67 posses além dos sete padrões (74 linhas
  no inventário). Perfis existentes preservam compras, XP, saldos e conjuntos.

Teste novo `test_avatar_offline`: 1.195 checks/0, fixture independente com as
67 chaves fixadas pela auditoria. Cobre concessão nova/existente, repetição,
reload, falha de gravação, save ilegível, exclusão das lacunas, 546 chaves
únicas, ordem dos gêneros, prévia/compra sem troca persistida, vestir com
rollback, retenção do card, inventário e passagem para apresentação de batalha.
O cenário original falhou antes da implementação; a falha de retenção do card
foi reproduzida isoladamente e corrigida antes da rodada final.

Rodada final: **25 suítes Godot / 5.819 checks, zero falhas**, mais
**14 testes Python XFS**, exit0. Sete scripts alterados/novos compilam.
Comando da rodada, com perfis isolados nas próprias fixtures:

```sh
./scripts/check.sh test_avatar_offline test_avatar_catalog test_avatar_profile \
  test_avatar_shop test_avatar_shop_classic test_avatar_shop_parity \
  test_shop_audit test_shop_wide test_shop_xfs test_shop_original \
  test_xfs_catalog test_shop_test_funds test_xfs_equipment test_avatar_art \
  test_avatar_mount test_avatar_continuity test_attributes \
  test_shop_items_integration test_scene test_match_loading test_ci_smoke \
  test_settings_i18n test_lobby_settings test_roster test_items_scene test_xfs_import
```

A tentativa inicial dentro do sandbox marcou 19 suítes como falha pelo erro
ambiental `get_system_ca_certificates`, todas com zero falhas de assertiva.
A execução fora do sandbox eliminou esse erro; o exit0 citado é da rodada
final. Sem override de certificados ou alteração de configuração global.

Revisão independente somente leitura: nenhum achado acionável de runtime;
67 chaves e totais conferidos novamente. Revisão não executou testes nem
validou GUI do cliente Windows. Código de combate/fórmulas não mudou;
partidas completas não repetidas. Originais/catálogos/versão intactos por
`git diff HEAD -- assets project.godot` e testes XFS.

## Evidência visual

`tests/capture_avatar_offline.gd` usa perfil temporário, removido ao terminar,
sem modificar o perfil real. OpenGL/Metal Apple M4 Pro, janela1920×1080:

- `docs/avatar-offline-access/mixed-genders-male-skeleton.png`: BOY/GIRL na
  mesma página, Skeleton masculino vestido e preço omitido para a concessão.
- `female-skeleton.png`: Skeleton feminino, inventário misto e Buy inativo.
- `offline-skeleton-sword.png`: acessório compartilhado concedido, sem cobrança.
- `room-skeleton.png`, `loading-skeleton.png`, `battle-skeleton.png`: mesmo
  conjunto feminino e espada no fluxo de treino existente.

PNGs da loja medem1920×1080. Com a escala normal canvas_items, a textura
capturada de sala/loading/batalha mede1728×1080: as barras laterais de96px da
janela ficam fora do viewport e não foram recriadas nem a imagem ampliada.
São capturas Godot de cenários preparados; não execução do cliente Windows
nem ensaio temporal novo de animações. Aceite visual e uso manual continuam
separados. Primeiras tentativas do harness de captura tinham suposições
erradas de nome da tela e de tamanho do viewport; corrigidas no script,
e somente a rodada final sem SCRIPT ERROR é evidência de sucesso.

Sem commit/push, rede, nova versão ou exportação do aplicativo. As mudanças
estão na worktree `codex/avatar-catalog-ghidra-audit`; app exportado anterior
continua separado. Logs locais em `.tools/avatar-audit/offline-*` e hashes das
capturas em `docs/avatar-offline-access/validation.json`.
