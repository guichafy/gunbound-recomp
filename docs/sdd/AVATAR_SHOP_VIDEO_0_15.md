# Avatar Shop Full HD — referência em vídeo0.15

REQ-20/38/39/40. Pedido de19/10/2026: implementar design igual ao vídeo
GunboundWcLatam no TikTok (4).mp4, usando gunbound-classic-hd. Baseline é a
entrega0.14.9 ainda não commitada; preservar essas correções e arquivos.

## Referências observadas

Vídeo734×576,158,261s/30fps: grade3×3, cabeçalho azul fino, cards com área
branca e preços integrados no rodapé; avatar sozinho em painel superior
esquerdo, atributos/saldo sob ele; inventário compacto com seleção amarela;
categorias e paginação abaixo da grade; cenário branco/azulado muito claro.
Imagem adicional RageZone801×629 confirma estrutura3×3 e inventário lateral,
mas contém um alerta de erro que não faz parte do design desejado.
O vídeo apresenta catálogo/atributos próprios: usar como referência visual,
sem copiar bônus ou produtos inexistentes no catálogo C#15registros.

## Implementação autorizada / escolhas de composição

- Tela virtual16:9 com apresentação real1920×1080. A loja calcula encaixe
  uniforme pelo viewport e ignora transformações do mundo/menu; demais telas
  seguem seu comportamento. Em outras proporções centraliza sem deformar.
- Grade3×3, nove itens/página; aproveitar a largura extra nos cards mantendo
  retratos com aspecto constante. Slots não preenchidos ficam visualmente
  discretos; não criar produtos fictícios.
- Painel Meu Avatar com prévia de avatar sozinho, como no vídeo, e alternância
  Avatar/Mobile para acessar a prévia já existente. Montagem/rig preservados.
- Inventário compacto com oito linhas visíveis, nomes legíveis, item vestido
  amarelo e ícones/rolagem. Clique mantém vestir/persistir/rollback0.14.9.
- Categorias sob a grade; abas Loja/Inventário e busca acima dela. A ordem do
  rodapé foi confirmada pelo usuário: Presente → Comprar → Experimentar,
  substituindo a ordem C# aprovada anteriormente.
- Arte de fundo regenerada com GPT Images: identidade da referência clássica,
  acabamento HD aprovado, cenário muito claro sem texto/controles embutidos.
  Molduras, preços e texto permanecem separados e nítidos. Originais preservados.
- Inspeção do PCK identificou o retrato compartilhado No Goggles/No Flag ainda
  nativo (60×56). Regenerar apenas esse retrato por GPT Images, com alpha e
  metadados próprios. Os dois slots continuam vazios no rig; não criar peça
  vestível nem alterar o catálogo de15registros/13peças HD.
- Atributos do piloto em modal existente; não adicionar bônus de avatar, venda,
  descarte, amigos, pagamentos externos nem mecânicas de combate.

## Plano e validação

1. Registrar referências, produzir fundo HD e medir dimensões/pixels úteis.
2. Extrair geometria de layout para constantes compartilhadas; adaptar fluxo
   e controles existentes à tela16:9, prévia alternável e inventário compacto.
3. Validar input real, filtros, seleção, compra/vestir/rollback/modal, viewport
   FullHD e1280×800, fallback de arte e persistência. Ajustar testes que fixam
   posições antigas, preservando seus contratos funcionais.
4. Capturas reais1920×1080 de cabeças/corpos/gêneros/inventário/compra/atributos
   e sequência60Hz; inspecionar nitidez, recortes e hover/transições.
5. Regressões pertinentes, revisão independente, app0.15.0 reexportado/assinado
   e smoke do PCK em/tmp com perfil isolado. Atualizar SDD com resultados/limites.


## Resultado observado —20/10/2026

Implementado canvas16:9, cards240×140/retratos172×68, oito linhas de inventário,
prévia Avatar/Mobile, rodapé confirmado e texto nítido com oversampling local.
A revisão independente encontrou que o stretch1280×800 da Window ainda se
somava à loja; corrigido com estado temporário/restauração da Window. Regressão
real inclui ESC, reentrada e batalha. A rodada final do revisor foi interrompida
por limite de uso da ferramenta; não registrar uma segunda aprovação independente.
O responsável verificou a correção com testes/capturas e pacote isolado.

Arte gerada e integrada (GPT Images, skill gunbound-classic-hd):

- `assets/hd/shop/wide_background.png`:1672×941 opaco. Cena final1920×1080.
- `assets/hd/shop/empty_slot_portrait.png`:1254×1254RGBA, alpha0..255,
  recorte alpha>8 em(209,71,870,1076), mipmaps para redução. Substitui somente
  a miniatura60×56 compartilhada por No Goggles/No Flag.15retratos cobertos,
  mantendo13peças vestíveis HD e os20spritesHD da interface existentes.
- JSONs de mesmo nome registram dimensão/hash/origem/recorte. Prompts e brutos
  em `assets/hd/shop/source/video_0_15`; fonte clássica preservada, runtime
  não exporta esses brutos. Carregamento valida metadados e mantém fallback.

`./scripts/check.sh --quick`:1949checks, zero falhas;36de test_shop_wide.
As10partidas completas passaram nesta entrega; não repetidas após ajuste
exclusivo da miniatura/loader de apresentação. Capturas reais1920×1080 de
cabeças/corpos/óculos/bandeiras, gêneros, Mage/Bigfoot, inventário, modais,
busca vazia e fallback em `docs/avatar-shop-video/`. Sequência120frames com
passo1/60s e MP4 de2s/60fps; isso verifica movimento, não mede throughput.
Captura usa `RenderingServer.force_draw()` para registrar GPU mesmo quando
outra janela encobre o teste no macOS.

Aplicativo/ZIP0.15.0 reexportados e assinatura ad-hoc estrita válida. Smoke do
PCK fora do projeto em/tmp com perfil isolado: arte/metadados presentes,
brutos ausentes, compra/vestir/recarga e passagem de equipamento à batalha.
GPU confirma1920×1080 e encaixe1280×720 dentro de1280×800, sem distorção.
Catálogo/preços/atributos/combate/perfil real preservados; sem publicação.
Amostras do fundo de preço possuem uma única corRGB121/159/211 na GPU e
no PCK nas duas resoluções; ver pixel-check.json. Aceite visual e uso manual
pelo usuário continuam pendentes.
