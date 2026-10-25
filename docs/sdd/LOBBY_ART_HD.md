# Acabamento conservador do lobby — REQ-02/12/19/20

Pedido25/10/2026: versionar a correção do lobby e terminar o acabamento das
imagens com gunbound-classic-hd. Commit-base5732568 conserva chat, carteira e GM.

## Contrato e plano

Aplicar o BICUBIC4× aprovado às quatro imagens estáticas do lobby (back, chat,
channel, buddy_fill) e aos dois atlas rank1/rank2,25quadros cada. Originais,
botões já aprovados e sala ficam preservados. Fonte única é cada PNG nativo;
quadros de patente processados isoladamente. Alpha nearest, sem padding,
recorte, sharpening ou iluminação. RGB interpolado; não são detalhes novos.

- [x] Registrar e gerar seis PNGs em assets/hd/classic/lobby_smooth_4x com
  fonte/hash/grade/dimensões/método e relatórios do verificador da skill.
- [x] Integrar seleção validada/fallback nativo; densidade4 só na textura.
  TextureRect conserva tamanho nativo; insígnia conserva15×25 ou25×15.
- [x] Conferir recursos inválidos/ausentes,50quadros e input/layout reais.
- [x] Capturar GPU1920×1080 antes/depois, cartão e stress; inspecionar bordas,
  letras, ícones e confirmar mesmas áreas de clique.
- [x] Atualizar SDD, repetir verificações e criar commit local do acabamento.

Sem mudança de combate/perfil/progressão, nova versão, publicação ou app
exportado. Preset inclui catálogo novo. Pacote isolado confere disponibilidade
e fallback se exportação possível; não equivale à atualização do aplicativo.

## Resultados

Concluído no projeto; sem aplicativo novo. Aplicação do método já aprovado
não exige geração por IA. Fontes e acabamento anteriores permanecem em disco.

### Arte e integração

Seis PNGs,54células (4estáticas+50insígnias), produzidos pelo helper da skill.
Fundo3200×2400, chat2196×1036, canal828×1036, preenchimento428×180;
rank1=1500×100 e rank2=2500×60. Catálogo/hashes em
`assets/hd/classic/lobby_smooth_4x/catalog.json`, relatórios em
`docs/lobby-art-hd/reports`. Os relatórios técnicos não equivalem a aceite do
usuário. Inspeção das50insígnias em `ranks-comparison.png` e do lobby na GPU:
letras/símbolos reconhecíveis, sem margens extras ou alteração de registro.
Cores são interpoladas; alpha permanece idêntico ao nearest da fonte.

`ClassicLobbyArt` valida registro/fonte, grade/dimensões e recurso importado;
inválido/ausente cai no original. `ClassicChrome.place` e os ícones fixam o
tamanho nativo depois de adicionar o nó, com EXPAND_IGNORE_SIZE antes da
textura. Sem isso, o mínimo inicial do TextureRect retinha o tamanho4×.
Os50recortes seguem (code+4), agora vezes4; fallback usa a janela nativa.
O schema/valorGM20 e o código de perfil não mudaram nesta etapa.

### Verificação observada

- Teste inicial63checks/58falhas antes da integração. Primeira integração
  revelou54falhas: TextureRect inflado e igualdade estrita de Dictionary
  (JSONframes25.0 versus literal25). Mínimos e registro corrigidos.
- Suíte nova93/0: seis importações sem perda visível,50recortes, catálogo
  inválido/ausente, registro danificado, arquivo ausente e textura de tamanho
  errado; controles mantêm retângulo nativo mesmo no fallback.
- Dez suítes dirigidas: **1045checks Godot/0** (lobbyart93, lobbyUI96,
  botões587, cena27, itenscena47, roster81, shopwide36, perfil25,
  saldoteste14, integraçãoitens39). Incluem Enter, scroll/cliques reais na
  viewport e navegação para sala. Nenhuma fórmula de combate alterada;
  partidas completas não foram repetidas neste trabalho de arte.
- **21testes Python** da skill passaram. Revisão independente repetiu
  **776checks/0**, recalculou BICUBIC54células/alpha nearest e confirmou
  **185arquivos originais/botões anteriores** idênticos à base5732568.
- GPU OpenGL4.1Metal/AppleM4Pro1920×1080, pares nativo/HD no mesmo cenário
  congelado. Lobby e stress: seis texturas trocadas, geometria/hitboxes
  idênticos. Sala: zero trocas e pixels idênticos. Captura espera três quadros
  de notificações de fonte/minimumsize antes de medir; medir no primeiro
  quadro produzia comparação instável e etiqueta lateral ainda ausente.
  Nova captura final conferida, etiqueta/versão visíveis.
- Exportação PCK isolada exit0,169065952bytes; **223checks/0/exit0** fora
  do projeto, seis recursos/catálogo,50recortesHD+50nativos, GM/carteira/chat,
  fallback e sala. Override/TLSlocal ausentes. Override restaurado byte a
  byte por finally. Diretório `/private/tmp/lobby-art-pck-u7vs0pus`.

Logs locais em `.tools/lobby-art-hd` e `.tools/check-logs`. A primeira captura
não encontrou o diretório do logfile, mas executou; recaptura final com log
válido concluiu sem erro. Import/export têm CA/editor_settings ambientais;
smoke registra somente CA, sem SCRIPTERROR. GPU executada fora do sandbox.
`git diff --check` aprovado. Hashes e medições em `docs/lobby-art-hd/files.json`.

### Limites e entrega

Revisão independente sem achados. Cliente original não executado; captura
estática não comprova escuta ou mouse físico. Aceite visual do usuário ainda
separado da inspeção técnica. Sem novo app/ZIP/versão ou publicação; app já
exportado continua anterior. Commit local autorizado neste pedido, separado
do5732568 que já versionou chat e patenteGM.
