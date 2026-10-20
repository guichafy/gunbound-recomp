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

- [ ] Catalogar todos os componentes; diferenciar miniatura, base vestível,
  efeito e validação. Gerar controle legível e contagens reproduzíveis.
- [ ] Preparar lotes com referência nativa de cada componente e estilo HD
  aprovado, direção/pose explícitas e margens; preservar prompts e brutos.
- [ ] Regenerar todos os componentes pendentes, conferir identidade/células,
  registrar dimensões úteis/hash; rejeitar ou corrigir resultados inadequados.
- [ ] Integrar masters na renderização real com registro constante e animação;
  miniatura não concede status HD à peça equipada.
- [ ] Validar composição e geometria de todos os550avatares, efeitos L, ambos
  gêneros/mobiles/sentidos, inclinação, poses/pausa/transições e fallback.
- [ ] Capturas GPU1920×1080/60Hz e contatos por lote; atualizar o controle
  somente com evidência. Completo exige550/550peças e todas as629camadas
  cobertas, sem fallback oculto nos registros marcados como concluídos.
- [ ] Regressões pertinentes, export/app/ZIP e smoke PCK; atualizar SDD/HANDOFF.

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
