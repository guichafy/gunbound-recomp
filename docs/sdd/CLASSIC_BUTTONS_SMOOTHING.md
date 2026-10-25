# Suavização aprovada dos botões — REQ-02/12/19/20

O usuário aprovou a prévia EXIT bicúbica e solicitou aplicação e adoção na
skill para próximas sessões. O escopo do lote é o mesmo:42atlas/197estados
dos botões clássicos do lobby/sala. As cores vizinhas são interpoladas;
preservação exata de pixels continua sendo outro modo disponível.

## Plano de implementação

- [x] Criar `skills/gunbound-classic-hd/scripts/upscale_conservative.py` com
  CLI `FONTE SAIDA --scale 4 --columns N --rows M`: PNG estático, grade
  uniforme medida, BICUBIC em cada quadro isolado e posição multiplicada
  pela escala. Preservar alpha por nearest e metadados comuns de cor.
- [x] Testar antes da implementação: isolamento entre estados, alpha,
  dimensões, entrada/saída intactas e grade inválida. Conferir o EXIT contra
  o PNG aprovado, sem alterar essa referência.
- [x] Gerar em `assets/hd/classic/buttons_smooth_4x`, com catálogo/hashes e
  relatório por atlas. Manter `assets/classic` e `buttons_4x` intactos.
- [x] Trocar somente o diretórioHD de `ClassicChrome` e o JSON incluído
  no preset. Tamanho lógico, estados, filtro, alinhamento e hitboxes ficam
  iguais. Atualizar os testes de cores para o contrato interpolado.
- [x] Atualizar a skill com receita reproduzível e distinção entre suavização
  aprovada, pixels exatos e geração. Avaliar comportamento em agente separado;
  sincronizar a instalação com backup e conferir estrutura/links/testes.
- [x] Rodar regressões de cena/input, capturaGPU1920×1080 e smokePCK isolado,
  sem override/TLS local. Documentar limites e resultados atuais.

Usar nova captura em `docs/classic-buttons-smoothing`, conservando a evidência
anterior de identidade entre atlas exatos/nativos. Nesta entrega a aparência
é intencionalmente suavizada; não usar igualdadeRGB com o original como aceite.
O teste gráfico deve conferir mesma geometria dos controles e que a diferença
de pixels esteja contida nos botões. Sem versão nova, app novo ou publicação.

## Baseline da skill

Avaliação independente apontou a lacuna: não existe comando bicúbico; o fluxo
atual encaminha melhoria de nitidez à geração e preserva degraus no modo exato.
O novo fluxo precisa ensinar a suavização sem redesenhar nem misturar estados.

## Resultados

Concluído no projeto e na skill instalada; limites descritos abaixo.

### Aplicado e conferido

Os seis itens do plano foram concluídos. O novo diretório ativo é
`assets/hd/classic/buttons_smooth_4x`: **42atlas/197estados** com BICUBIC
por quadro e alpha nativo ampliado em nearest. Catálogo contém origem,
método, dimensões/estados/regiões, hashes e referência da aprovação.
EXIT é idêntico em pixels à prévia aprovada. **8087792pixels** tiveram
alpha conferido por coordenadas independentes; não houve divergência.
Os **180arquivos** das fontes e dos atlas exatos anteriores permaneceram
intactos por hash. Os derivados anteriores não foram sobrescritos.

`ClassicChrome` agora aponta para o novo catálogo; preset inclui seu JSON
e o manifest nativo. A conversão lógica de recortes permanece a da ADR-100.
Nenhuma posição, dimensão lógica, estado ou callback precisou ser alterado.

### Testes e revisão

- Helper novo:5testes inicialmente falharam; isolamento entre estados,
  interpolação, alpha, fonte/destino e grade inválida passaram após implementação.
- Teste dirigido do runtime antes da troca de diretório:587checks/106falhas;
  as falhas identificavam o atlas exato anterior, ainda ativo.
- Após integração,2comparações de importação falharam: Friends/GoTo têm
  alpha0, cujo RGB invisível é reparado por `fix_alpha_border` do Godot.
  Probe confirmou2044pixels invisíveis diferentes por atlas e **zero pixels
  visíveis/alpha alterados**. Teste passou a comparar cor pré-multiplicada e
  alpha, preservando o reparo de borda existente.
- Suítes dirigidas: `test_classic_buttons_hd test_scene test_items_scene
  test_roster test_shop_wide`: **778checks,0falhas**, incluindo587na suíteHD.
  Exercitam todos os atlas/estados, importação sem perda visível, o EXIT
  aprovado, fallback e cliques reais nas mesmas áreas.
- Testes Python da skill: **21aprovados**, também na instalação sincronizada.
  Avaliação independente executou EXIT suave/exato e grades2×2, inclusive
  alpha128/64/192 e padrões internos, sem mistura entre quadros.
- A revisão independente reproduziu um risco do checker antigo: `--report`
  podia sobrescrever imagem/JSON existente. Três casos falharam antes da
  correção; agora há recusa antecipada e criação exclusiva. Revisão posterior
  confirmou fonte/candidato/relatório intactos e relatório novo funcional.
- Estrutura da skill aprovada;14arquivos idênticos na cópia instalada,
  links válidos. Backup em
  `.tools/skill-backups/gunbound-classic-hd-before-conservative-2026-10-25`.

### GPU e pacote

`tests/capture_classic_buttons_smooth.gd` gerou comparações reais em
**1920×1080**, OpenGL4.1Metal/AppleM4Pro. Todos os retângulos, mínimos e
filtros de mouse dos controles permaneceram idênticos. DiferençasRGBA:
lobby117657pixels, sala85008pixels, **zero fora dos retângulos dos botões**
(máscara floor(início)→ceil(fim)−1, sem margem extra). Cenas congeladas;
isto não equivale a validação temporal ou escuta manual.

PNGs e medições em `docs/classic-buttons-smoothing`; catálogo/relatórios
registram os novos hashes. ZIP42PNGs+catálogo conferido por CRC e hashes.
Capturas da entrega exata anterior foram preservadas em outra pasta.

PCK temporário conferido fora do projeto, em
`/private/tmp/smooth-buttons-pck-vk3u1j5p`: **92checks,0falhas,exit0**.
42atlas suavizados e os dois JSONs carregam; hashRGBA do EXIT coincide com
a prévia aprovada; fallback original funciona; override/TLS local ausentes.
Logs em `.tools/classic-buttons-smoothing`. Revisão independente de código e
evidências aprovada, sem achados pendentes.

Import/export registram as ressalvas ambientais de CA/editor_settings; smoke
registra CA, sem SCRIPT ERROR ou falha de teste. Override local foi retirado
somente durante exportação do pack e restaurado byte-a-byte em `finally`.
Captura gráfica executada fora do sandbox, como na verificação anterior.

Sem mudança de combate/perfil/versão, commit, publicação ou reexportação do
aplicativo distribuído. O projeto usa o acabamento aprovado; app anterior
continua exigindo nova exportação. Aceite visual do EXIT confirmado pelo
pedido atual; inspeção visual integral do lote pelo usuário permanece separada.
