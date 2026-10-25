# Botões clássicos4× no lobby/sala — REQ-02/12/19/20

Pedido de25/10/2026: integrar os atlas4× existentes, mantendo tamanho visual,
alinhamento, estados e áreas de clique. Este documento amplia a ADR-099:
os derivados agora podem ser consumidos pelo jogo. Originais preservados.

## Contrato e plano antes do código

1. `ClassicChrome` permanece o ponto único de recorte dos botões do lobby e
   da sala. Manifest nativo continua definindo tamanho lógico, estados e ordem.
2. Ler o catálogo4×, validar versão/escala, correspondência com registro
   original, dimensões/células e recurso importado. Usar o atlas4× válido;
   ausência/invalidez retorna ao atlas nativo, sem mudar a geometria lógica.
3. Multiplicar somente `AtlasTexture.region` por4. `frame_size`, palco800×600,
   escala4/3, posição, mínimo/tamanho do controle, filtro nearest e stretch
   existentes permanecem. A grade de mobiles continua36×28 e cada clique usa
   a área atual. Estados ready/mouse/push/disable/active mantêm seus índices.
4. Fundos/painéis/itens fora do catálogo4× continuam nos caminhos atuais.
   Incluir JSONs de ambos os catálogos no preset de exportação.
5. Teste dirigido antes da implementação: recursos/recortes4×, estados, fallback
   e geometria/eventos do lobby/sala. Rodar regressões de cena/input pertinentes.
   Importar novos PNGs; conferir render quando a GPU estiver disponível.

Sem regra nova de combate, mudança de perfil, versão, build ou envio ao remoto.
Trabalhar sobre os derivados e alterações locais existentes, sem apagá-los.

## Resultados

Integração concentrada em `scripts/classic_chrome.gd`: catálogo nativo
continua decidindo tamanho lógico/estados; catálogo4× fornece somente o atlas.
Região é multiplicada pela densidade4, com validação de versão/escala,
registro original, arquivo, dimensões/células/ordem e tamanho real da textura
importada. Ausência/invalidez usa recortes nativos. Cache distingue caminhos
HD e originais. Não foi necessário alterar lobby/menu, posições ou controles.

Preset inclui `assets/classic/manifest.json` e
`assets/hd/classic/buttons_4x/catalog.json`. Os42PNGs4× foram importados,
preservando configurações nativas;95arquivos de origem e42PNGsHD intactos
por hash após a execução. As novas `.png.import` são preservadas no projeto.
`scripts/check.sh` inclui a suíte nova na rotina completa.

## Verificação observada

- Baseline de cena/itens/roster/loja:191checks,0falhas.
- Novo teste antes da implementação:334checks,265falhas por ainda consumir
  texturas/recortes nativos. Sem erro de parse.
- Após implementação: `scripts/check.sh test_classic_buttons_hd test_scene
  test_items_scene test_roster test_shop_wide`: **735checks,0falhas**.
  Nova suíte544/0 cobre42atlas/197estados, tamanho lógico, regiões, cores
  importadas, normal/hover/push/disable/active, catálogos inválidos e fallback.
  Eventos reais encaminhados à viewport verificam clique fora/dentro do
  CREATE, seleção do Mage e escolha de Dragon para CPU nas áreas existentes.
- Captura GPU real: `tests/capture_classic_buttons_hd.gd`, OpenGL4.1 Metal,
  AppleM4Pro. Cena congelada; troca apenas atlas4×↔nativo nos mesmos controles.
  Comparação de todos os bytes RGBA: **lobby e sala idênticos em1920×1080**.
  Lobby76texturas de estado; sala88. PNGs/JSON/hashes em
  `docs/classic-buttons-integration/`. É comparação estática, não sequência
  temporal ou aceite visual manual do usuário.
- Smoke do PCK executado fora do projeto, em
  `/private/tmp/classic-buttons-pck-0pcicjn6`: **91checks,0falhas,exit0**.
 42atlas carregam do HD; os dois JSONs estão presentes, os fundos nativos
  carregam e override/caminhoTLS local estão ausentes. Logs em
  `.tools/classic-buttons-hd/pck-smoke.log`; pack temporário não é app novo.
- Revisão independente de código e evidências aprovada, sem achados acionáveis.

## Ambiente e limites

GPU sob sandbox abortou antes do primeiro quadro em registro gráfico/fontes
do macOS (`SIGABRT`). Execução fora do sandbox funcionou. A primeira captura
do viewport interno foi1728×1080; a captura final usa framebuffer1920×1080,
escala uniforme1,35 e margem96px, conservando o encaixe do jogo.

Import/export registram falha ambiental de CA (`ret != noErr`) e de gravação
de `editor_settings`. Smoke isolado registra apenas CA, sem SCRIPT ERROR ou
falha de assertiva. O PCK definitivo de teste foi refeito com `override.cfg`
temporariamente retirado e restaurado byte-a-byte em `finally`; nenhum
override/TLS local foi incluído no pacote conferido.

Não houve validação manual de escuta/mouse, mudança de versão, exportação de
app/ZIP do aplicativo, commit ou publicação. O aplicativo anteriormente
exportado não recebe alterações só por executar o projeto.
