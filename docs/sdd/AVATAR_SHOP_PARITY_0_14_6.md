# Auditoria OpenBound e interface HD 0.14.6

Pedido atual: investigar a implementação C# da Avatar Shop, corrigir diferenças
e regenerar os assets ainda sem qualidade HD usando gunbound-classic-hd.
REQ-20/38/39/40 e ADR-066. Fonte C# somente leitura; perfil real não é fixture.

## Contrato e comparação

Fonte: AvatarShop.cs, AvatarButton.cs, PopupBuyAvatar.cs, AttributeMenu.cs,
InGamePreview.cs, AnimatedButton.cs, MetadataManager.cs, Player.cs,
PlayerController.PurchaseAvatar e DatabaseSeed/AvatarMetadata.json.

Catálogo/ordem/preços/pivôs usam os 15 registros da fonte; Unissex é compartilhado.
Selecionar não compra/equipa; experimentar não possuído é temporário. Compra
debita uma moeda de preço positivo e registra posse atomicamente; não equipa.
Inventário veste uma peça possuída por categoria. Atributos têm oito posições,
rascunho/confirmar/cancelar e limites 50/180. Popup bloqueia a interface.

Adaptações vigentes preservadas: grade 3×3/inventário lateral (ADR-064),
Vestir persistido (ADR-063), perfis e gêneros locais, saldo de teste 1000 uma
vez, orçamento pelo nível local sem ranking, Bigfoot/Mage em vez de Raon,
modal de atributos, sem servidor/pagamento/presentes. Não reproduzir os bugs
do C#: débito no callback antes de conferir sucesso, preço zero habilitando
Buy, página sem clamp e consumo de ponto no teto do atributo.

Diferenças encontradas nesta auditoria:
- Ícones dos atributos divergentes: C# usa índices 13/17/15/23/9/19/21/11,
  nesta ordem Attack/Health/Defense/Regeneration/AttackDelay/ItemDelay/Dig/Popularity.
- FlipbookAnimation esclarece a semântica: Foward repete; Cycle é ida/volta
  com quadros terminais repetidos. Hover Buy/Try usa Cycle; os demais Foward.
  Click tem Normal enfileirado depois. Setas começam em 1, FPS28; Exit23/25.
- Popup de compra deve identificar visualmente o item pelo retrato, preços
  e categoria, além de saldos antes/depois. Uma moeda deve ficar centralizada.
- As peças de avatar já têm HD validado; arte raster da UI ainda é nativa.

## Plano antes do código

1. Conferir catálogo e hashes dos originais contra C# e criar regressões das
   diferenças de ícones/animação/compra, com perfil isolado.
2. Regenerar apenas UI consumida: mestres dos dez botões, ícones utilizados,
   molduras/card/popup, cidade do rodapé e cenário da prévia. Usar fonte para
   identidade e HD aprovado para acabamento. Textos continuam no Godot.
3. Construir derivados/metadados com registro nativo, alpha e hashes; originais
   intactos, bruto/prompt em source excluído do export. Peças aprovadas do
   avatar/rig não serão regeneradas. Controles geométricos nativos já são nítidos.
4. Corrigir os comportamentos identificados. Integrar carregador HD com
   fallback quando metadados/textura forem ausentes ou inválidos.
5. Executar regressões de cena/perfil/render e harness completo, capturar GPU
   1920×1080 e 120 frames a60Hz; exportar app, conferir assinatura e PCK real.
6. Atualizar SPEC/DESIGN/DECISIONS/TASKS/HANDOFF com evidências e limites.

Mestres constantes HD dos botões preservam identidade; sua animação visual
é adaptação por variações de brilho nos intervalos do original, sem
regenerar cada quadro/gesto. Isso não altera ações, filtros ou regras.

## Resultado e matriz de fidelidade

| Tema | Conferência / resultado |
|---|---|
| Catálogo/identidade/preços/datas/pivôs | 15 registros iguais ao JSON C#; 80 arquivos originais iguais aos SHA da fonte; zero diferenças em source-audit.json |
| Filtros | Ordem por categoria/ID, nome case-insensitive, gênero+Unissex e posse; paginação9/clamp é adaptação vigente |
| Selecionar/experimentar/comprar/vestir | Operações separadas, compra não equipa; Vestir/inventário persistidos com rollback e recarga/batalha |
| Compra Gold/Cash | Preço positivo/saldo revalidado, débito+posse juntos, repetição bloqueada; popup modal com retrato/categoria/preço/saldo e moeda única central |
| Atributos | Oito posições e ícones C# corrigidos; orçamento10por nível local, teto180/50por atributo, rascunho/salvar/cancelar; fórmulas e snapshot de combate preservados |
| Animação dos controles | Foward/Cycle, início/FPS das setas/Exit corrigidos; clique após soltura completa até Normal, coberto por input real |
| Composição da UI | Grade3×3, inventário lateral, prévia compacta no mobile e modal de atributos preservam ADR-064; não é cópia pixel a pixel da tela5×5 C# |
| Avatar/rig | 13 peças HD aprovadas preservadas, fallback nativo; montagem Body/anatomia/relógio não alterados |
| Recursos de rede/conta | Servidor/banco/GameList/ranks/pagamento/presentes substituídos pelo escopo local vigente; sem novos serviços |

Quatro folhas GPT Images **1254×1254 RGBA**, mais edição localizada da estrela
de Popularidade (removeu o plus inventado).20texturas runtime registradas4×:
10controles, folha dos19ícones usados, quatro texturas de marcadores/moedas,
card/popup e três texturas de cenário. O catálogo registra pixels úteis dos
mestres;4× do PNG final não é medida de detalhe gerado. Brutos, prompts e
metadados preservados em assets/hd/shop; referências em source não exportadas.

O primeiro render expôs bordas4× maiores e popup mínimo imposto pela textura.
Correções: ShopCardStyle separa recorte HD/borda lógica e expansão do popup
precede textura/tamanho. Nova GPU confirmou cards/popup completos, aspecto
preservado e ausência de cortes nos retratos. Revisão independente final sem
achados restantes.

Validação: **1848checks e10partidas completas**, zero falhas,42,1s nas partidas.
Inclui40checks de paridade,46HD,25Shop e25classic; test_items_scene46 também
cobre a aura UsingItem já presente no baseline. Somente perfis isolados.
GPU em docs/avatar-shop-parity: shop/body/inventory/attributes/purchase,
moeda única, gênero feminino e Bigfoot, todos1920×1080; vídeo120frames60FPS.

App/ZIP0.14.6 reexportados, assinatura estrita válida, ZIP127,4MB. Smoke GPU
do PCK rodou de/private/tmp com --path /private/tmp e passou:20texturasHD,
popup/retrato/dimensões, exclusão de source, compra/vestir/recarga/batalha.
Não executar essa conferência emcwddo projeto: o filesystem local pode causar
falso positivo para JSON externo ao PCK. Fonte C# e perfil real preservados;
alterações locais não publicadas.

Limites: interface e mestres são reconstrução artística; movimentos específicos
dos mascotes/ícones não foram redesenhados quadro a quadro. Rosto/peças HD e
combate aprovados não mudaram. Aceitação visual final depende do usuário.
