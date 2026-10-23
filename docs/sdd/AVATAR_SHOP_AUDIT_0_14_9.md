# Avatar Shop: estado, legenda e posicionamento0.14.9

Pedido: investigar bugs/design/posicionamento contra o C# e consultar o usuário
quando houver dúvida. REQ-20/38/39/40, ADR-069. Baseline main699caff limpo,
inclui integração de combate3ea8149; não alterar combate nessa tarefa.

Fontes: AvatarShop.cs (abas/filtros/rodapé), AnimatedButton.cs/Builder
(pivôs/legendas), InGamePreview.cs (proporção do cenário), AvatarButton.cs,
PopupBuyAvatar.cs. Fonte C# somente leitura; testes com perfil isolado.

## Investigação

- Model.filter deixa selected_key apontando para item que desapareceu da
  busca/página. A view habilita compra/experimentação sem card selecionado visível.
- Model.select altera selected_key antes de equipar; falha de save retorna false
  sem restaurar seleção. Clique na grade de inventário não mostra erro.
- Legendas têm y derivado de cada altura de atlas: Corpo começa antes do fundo
  visível do ícone; Bandeira/Gift/Buy/Try também se sobrepõem. C# usa uma linha
  comum relativa à posição/pivô; não toma altura variável do atlas como baseline.
- Miramo210×144 é esticado para201×100 na prévia (aspecto muda38%). C# conserva
  tamanho/proporção do sprite. Precisamos crop uniforme no painel compacto.
- Abas estão sobre a lista lateral, mas controlam cards à direita. Rodapé tem
  ordem inversa ao C#.
- Label.size era definido antes do override de fonte. A fonte padrão16px
  ampliava os controles, e eles não voltavam à caixa prevista depois de reduzir
  fonte para10px: Experimentar ficava106×23 apesar de caixa70×15. Isso também
  afetava centralização/contenção de textos do card. Reaplicar size após fonte.

Decisão explicitamente confirmada nesta conversa: **abas acima dos cards e
Experimentar/Vestir → Comprar → Presente**, como no C#. Grade3×3, inventário
lateral, Vestir persistido e modal de atributos aprovados permanecem.

## Plano antes do código

1. Reproduzir busca/seleção/rollback/feedback com modelos/cena e perfil isolado.
2. Reproduzir sobreposição das legendas e distorção do cenário; verificar inputs
   nos textos, modal/ESC e cabeçalhos/elementos contidos na tela.
3. Limpar seleção quando não estiver na página filtrada; confirmar seleção só
   depois de equipar com sucesso; mostrar erro de persistência na grade.
4. Dar área gráfica e área de legenda separadas aos botões, com padding virtual
   no AtlasTexture (região nativa intacta) e hitbox incluindo o texto. Atualizar
   estado disabled junto dos demais, para HD/fallback coerentes.
5. Reorganizar abas/título/rodapé conforme resposta; crop Miramo com escala única.
6. Capturar GPU HD/nativo/compra/busca/modal/roster em1920×1080; regressões
   rápidas, revisão independente, reexport0.14.9 e smoke do PCK isolado em/tmp.
7. Registrar resultados/limites em DESIGN/TASKS/HANDOFF. Sem bônus novos, PNGs
   novos, alteração de rig/anatomia/perfil/combate ou publicação.

Não reproduzir o estado stale do C# se ele deixar ações apontando para peça
invisível: o contrato da loja local exige seleção coerente e rollback de save.

## Resultado observado

Implementado conforme plano. test_shop_audit reproduziu falhas antes da correção
e terminou com42checks, zero falhas: input real de busca, vazio/retorno, rollback
de save/retry, legendas fora da arte/dentro da hitbox, clique no texto, abas,
rodapé, crop e ESC após foco na busca. test_avatar_shop_parity conserva40checks;
identificação de Gift/Try por nome evita depender da ordem antiga do array.

Harness completo: **1913checks e10partidas completas, zero falhas**
(45603ms nas partidas). Capturas reais GPU1920×1080 em docs/avatar-shop-audit:
HD/fallback, cabeças/corpos/inventário, gêneros, Mage/Bigfoot, compra com duas
moedas/moeda única, atributos e busca vazia. controls.mp4 contém120frames60Hz
com hover/retorno do botão Experimentar; quadros intermediários em .tools.
Faixa de preço mantém cor uniforme RGB121/159/211 em amostras sem texto da GPU
e do pacote exportado; caixas/pixels em price-pixel-check.json.

Revisão independente sem achados. App/ZIP0.14.9 reexportados; versão do menu
corrigida (ainda dizia0.14.5), assinatura profunda/estrita válida. Smoke GPU do
PCK executado de/private/tmp com script externo passou: layout/ordem, filtro
sem seleção invisível,13peçasHD/20texturasUI, popup, clique em quatro categorias
do inventário, recarga e equipamento na batalha. Brutos/referências excluídos.
Reprodução: copiar tests/capture_avatar_shop_audit_pck.gd para/private/tmp e
executar Godot com cwd/--path nessa pasta, --main-pack no PCK absoluto e
--script na cópia externa. exported-pck.png é a captura1280×800 do teste.

Somente perfis isolados/removidos; fonte C# e perfil real preservados. Sem novo
PNG de arte, alteração de rig/anatomia/combate ou publicação. Validação manual
do usuário no aplicativo permanece pendente; capturas e inputs automatizados
não substituem esse aceite. Grade3×3 é adaptação aprovada, sem alegar cópia
pixel a pixel da tela C#.
