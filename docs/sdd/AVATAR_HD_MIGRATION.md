# Migração integral dos avatares XFS para HD

REQ-10/20/39; pedido20/10/2026 após validação da0.16. Catálogo HD não comprova
peça equipada HD. O usuário solicitou controle e migração completa, incluindo
o avatar vestido e animado. Usar gunbound-classic-hd; conservar combate/perfil.

## Resultado exigido

Controle individual dos562registros:550têm arte vestível real, três representam
ausência de acessório e nove são placeholders sem arte no XFS. Os550 com arte
devem ter retrato e todas as suas camadas vestíveis em HD, com registro fixo,
uso efetivo no Shop/Mage/Bigfoot e animação contínua. Não gerar um rosto novo
por quadro nem substituir peça vestida pela miniatura da loja.

629camadas reais:549bases e80efeitos/camadas L (Ghost usa somente L).
HD anterior reaproveitado apenas por identidade verificada. A primeira entrega
da0.16 regenerou18miniaturas; isso será registrado como miniatura, nunca como
personagem pronto. Três padrões vazios e nove placeholders serão N/A com motivo.

## Arquitetura e registro

- Fonte imutável: assets/xfs/avatars/catalog.json, PNGs e offsets por quadro.
- Controle: docs/avatar-hd-migration/catalog.json, migration.csv e index.html,
  derivados de um registro de geração/aceite; estados separados por componente.
- Referências/brutos/prompts em assets/hd/avatars/xfs/source (.gdignore).
- Atlas HD e catálogo de recortes aprovados em assets/hd/avatars/xfs.
- Leitor AvatarXfsHD fornece masters vestíveis e miniaturas por chave XFS,
  janela/pivô constantes; AvatarArt os consome efetivamente. Cada peça usa
  fallback nativo coerente se faltar uma camada obrigatória ou metadado válido.
- Rig compartilhado conserva respiração, ações/transições, espelhamento e
  inclinação. Efeitos têm relógio próprio sem mudar anatomia ou colisão.

## Plano e critério de conclusão

- [x] Catalogar todos os componentes; diferenciar miniatura, base vestível,
  efeito e validação. Gerar controle legível e contagens reproduzíveis.
- [x] Preparar lotes com referência nativa de cada componente e estilo HD
  aprovado, direção/pose explícitas e margens; preservar prompts e brutos.
- [x] Regenerar todos os componentes pendentes, conferir identidade/células,
  registrar dimensões úteis/hash; rejeitar ou corrigir resultados inadequados.
- [x] Integrar masters na renderização real com registro constante e animação;
  miniatura não concede status HD à peça equipada.
- [x] Validar composição e geometria de todos os550avatares, efeitos L, ambos
  gêneros/mobiles/sentidos, inclinação, poses/pausa/transições e fallback.
- [x] Capturas GPU1920×1080/60Hz e contatos por lote; atualizar o controle
  somente com evidência. Completo exige550/550peças e todas as629camadas
  cobertas, sem fallback oculto nos registros marcados como concluídos.
- [x] Regressões pertinentes, export/app/ZIP e smoke PCK; atualizar SDD/HANDOFF.

## Decisões de execução

Masters constantes por componente, sem geração quadro a quadro, seguem a
animação aprovada0.14.4. Camadas de efeito ficam separadas. O comportamento
visual é adaptação HD; os gestos/olhos originais não são automaticamente
restaurados por uma miniatura. Full HD refere-se ao framebuffer1920×1080;
registrar tamanho real dos atlas e pixels úteis de cada objeto.

Quadro de referência de cabeça:16 (olhos abertos);11/12são piscada e não
devem virar o mestre constante. Lotes003–006 que reproduziram a piscada foram
rejeitados e preservados como brutos, para refazer a partir da referência correta.
L pode conter um acessório opaco, além de luz/efeito: pulsação não se aplica
automaticamente a toda camada L. A opacidade da fonte determina esse tratamento.

Progresso será mantido no controle gerado, com pendências explícitas após cada
lote. Não marcar lote/registro completo apenas porque um PNG foi gerado.

## Resultado observado0.17

550/550registros reais,629/629camadas e550/550miniaturas validados.37lotes,
1161componentes novos (629vestíveis/efeitos +532retratos);18miniaturas anteriores
preservadas.38atlas selecionados:25de887×1774,11de1024×1536,1de1448×1086 e
um reparo1774×887. Maior dimensão útil por componente:145–942px;66.549.923bytes
de PNG selecionado. FullHD é a composição1920×1080, não o nome/tamanho do atlas.

AvatarXfsHD registra cada mestre na janela nativa uma vez, preserva aspecto,
material translúcido e pulsação de efeitos. As12bases antigas foram regeneradas
no lote037; o HD antigo permanece só como fallback/compatibilidade. Um componente
obrigatório ausente invalida o conjunto novo da peça, retornando ao render nativo
ou ao mestre legado integral verificado, sem misturar camadas novas incompletas.

Recortes de partículas desconectadas foram conferidos manualmente nos lotes014,
016,027 e035. O visor Battle Goggle foi refeito isoladamente; a miniatura de
corpo feminino padrão usa o novo mestre vestido correspondente, pois a fonte
também usa esse quadro. Resultados incorretos e referências anteriores continuam
preservados; overrides/assignments tornam os registros reproduzíveis.

37contatos GPU ×4instantes: Mage/Bigfoot, direita/esquerda, inclinação±10°.
Auditoria real dos550registros em seis instantes, ambos estados e gêneros
compatíveis, sem fallback. Vídeo360frames/60fps/6s com quatro conjuntos, poses,
transições e30quadros de pausa idênticos; ainda é adaptação do rig, sem redesenhar
todos os gestos e piscadas originais. HTML mostra evidência do avatar vestido,
CSV e JSON mantêm estados, e aceite exige hash atual da arte/registro/renderer.

Regressão completa3887checks+13partidas após integração paralela do Nak;
688checks dirigidos de itens/HD e depois1744checagens de cobertura integral,
mais11testes Python passaram. O fixture acelerado de itens aguarda a conclusão
assíncrona sem consumir a tarefa da cena. Nenhuma regra de combate foi alterada
pela migração de arte. Nak integrado por outro trabalho foi preservado, sem HD
novo para o mobile. App/ZIP0.17.0 exportados e assinatura estrita válida. Smoke
GPU do PCK fora do projeto passou:550peças/629camadas realmente carregadas,
550retratos, compra/vestir/recarga/atributos/batalha e telas1920×1080/1280×800.
Brutos/jobs excluídos do pacote. Evidência em docs/avatar-hd-migration.
