# Sala conforme referência do usuário — REQ-02/12/19/20/36

## Correção do relevo dos poços — plano (27/10/2026)

Pedido posterior substitui a cobertura azul da ADR-140: no 1×1 ocultar as
seis faixas A/B, preservando os poços rebaixados do próprio fundo original,
como na imagem fornecida. Manter apenas dois controles de seleção. Remover
as coberturas, testar a ausência delas, as faixas e cliques, e conferir a
captura GPU e o recurso nativo. Sem alterar assets, tamanho ou combate.

Evidência: REA/Hopper, PE x86 SHA-256 `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`,
string VA `0x557088`, referência `0x4d6839` em `0x4d6810`: carrega
`ready_back.img` com ID 10000 via `0x4f1790`. Evidências REA
`ev_0e1b7bea7c8cc32cd38994dea15eef05f05f6d7141420f2f3da3decadba30ea3`,
`ev_83f2a8e5e4ac11dc53b35ec0a0e025165d8e16b793d394b9bd287d02aafdfe3c`
e `ev_59e213236ec08c704481e7477c4f33716a6cf8af5536c9b8af3a94acb4452837`.
XFS SHA-256 `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`;
quadro 0 do recurso (entrada `d1042b8a8913a0c5ccbf5dfa7b6b7193116b38abad941c6329e8f230f9c021b9`)
é pixel idêntico ao `assets/classic/room/back.png`: borda e interior já
estão desenhados na imagem. Contrato comprovado no arquivo e carregamento;
visibilidade das faixas é adaptação do treino. Imagem do usuário é referência
visual, não prova de execução da mesma build. HD continua derivado do ativo.

Resultado: retiradas as coberturas da ADR-140; o próprio `room_back` volta
a mostrar os seis poços. Teste red anterior: oito falhas por coberturas
presentes; após correção, seis suítes (`test_room_reference`, `test_room_ui`,
`test_room_polish`, `test_room_settings`, `test_scene`, `test_match_loading`)
somaram 685 checks e zero falhas. Cliques nos seis poços não mudam o lado.
GPU OpenGL/Metal 1920×1080: sala, Random, rolagem e modal; nativo e HD
mantiveram geometria/hitboxes nas três comparações. Capturas e evidência REA
em `.tools/room-depth`; inspeção mostra os seis relevos. Sem cliente Windows,
mouse físico ou aceite visual humano; sem alteração de versão ou app/ZIP.

## Correção da issue #10 — plano

No treino 1×1, somente TeamA0 e TeamB0 aparecem e recebem os controles
existentes. A capacidade por time determina a visibilidade dos demais; não
há seletor de tamanho novo. O fundo também desenha os poços: cobrir os seis
excedentes com o azul do painel, sem alterar o asset. Testar visibilidade,
ausência de captura de clique e capacidade maior, além das regressões de
sala, loading e cena. A parte das oito faixas da ADR-105 fica substituída
para 1×1; grade, Random, itens e fluxo continuam vigentes.

Implementação: `TEAM_CAPACITY` é 1 por time; faixas excedentes ficam
invisíveis e retângulos sem captura de mouse cobrem os poços do fundo com
RGB (0,137,197), amostrado no painel nativo e no suavizado. Os assets não
foram alterados. `test_room_reference`: 232 checks, zero falhas, incluindo
cliques nas seis áreas e regra de capacidade 2. Captura GPU 1920×1080 em
`.tools/issue-10`: sala, Random, rolagem e modal; comparação nativo/HD
mantém geometria e hitboxes. Não é aceite visual humano nem teste de mouse
físico. A versão e o aplicativo exportado não mudaram.
Harness completo: 28.373 checks Godot, 29 partidas e suítes Python, sem
falhas, parse aprovado e exit 0.

Pedido25/10/2026 substitui a grade8×2 e catálogo em abas dasADR096/104.
A foto do usuário define composição, não dados de rede/regras novas.

## Contrato e plano

- [x] Grade5×3: quatorze mobiles comuns + Random; remover botões diretos
  Dragon14/Knight15, preservar esses IDs no modelo. Ordem igual à referência.
- [x] Random é escolha de interface, nunca ID0 ou novo mobile. Sorteia14/15
  com chances iguais somente ao iniciar cada partida, para piloto/CPU
  independentemente. Mantém seleção/retratoRandom entre visitas à sala.
- [x] Catálogo único dos11itens, sem abas1/2slots,3colunas e rolagem/wheel,
  setas originais. Continua6slots de equipamento e gravação existente.
- [x] Usar quadros1/2de ready_back para faixasA/B nos8lugares, nomes na faixa
  inferior e mobiles acima dela. Apenas um piloto/CPU ativos; demais vazios.
- [x] Extrair Random/setas/faixas em novas pastas, BICUBIC4× por quadro com
  alpha nearest. Preservar assets anteriores. Catálogo/fallback/exportação.
- [x] Testar layout/input, random somente14/15 e início real de partida,
  itens/rolagem/modal. GPU1920×1080, regressões pertinentes e revisão.
  AtualizarSDD; sem novoapp,versão,push ou commit não solicitado nesta etapa.

Janelas nativas existentes delimitam os novos controles. A grade muda por
pedido explícito, as demais ações/escopooffline permanecem. O RNG da sala
fica separado do RNG da física; perfil/equipamento e regras não mudam.

## Resultados

Concluído no projeto. Nenhuma alteração de perfil, recompensas, física ou
catálogo dos16IDs; somente o seletor de sala esconde14/15 atrás deRandom.

### Composição e comportamento

Grade: Armor,Mage,Nak,Trico,Bigfoot / Boomer,Raon,Lightning,JD,ASate /
Ice,Turtle,Grub,Aduka,Random. Cinco colunas/três linhas no mesmo poço;
origem33,396,passo66×44,controles63×44 com aspecto preservado. O texto de
seleção fica na faixa superior, sem ocupar uma linha da grade.

`room_choice.gd`: sentinelaUI−2, pool[14,15]. Flags independentes do piloto
/CPU ficam na cena; RNG privado, sem consumir o RNG da física. Seleção,
reabertura e loja não sorteiam; cadaStart resolve somente os ladosRandom.
Revanche/nova partida podem sortear novamente. Uma escolha comum cancela
apenas o lado correspondente. ID0 continua inválido; não reintroduzEscaravelho.
Random usa retrato0 e botão5estados originais; na sala a prévia não revela o
mobile concreto antes doStart. Modelo recebe somente IDs14/15 válidos.

Catálogo:11itens na mesma lista,3colunas,semabas. ScrollContainer recorta o
conteúdo e permite roda do mouse; setas originais sobem/descem uma linha e
refletem limites. Modal bloqueia cliques/roda; Cancelar restaura setas.
Equipamento mantém6slots e peças1/2slots, remoção/adição e gravação anteriores.

Os8lugares usam ready_back1(A) e2(B), com quatro por lado. Ativos ainda são
um piloto/CPU. Faixas na base, nomes escuros e mobiles com contato141 na
primeira linha, acima das faixas. As seis vagas extras permanecem vazias.
Mapas,clima,cabeçalhoGM,HD anterior e demais ações preservados.

### Extração e acabamento

`scripts/build_room_reference.py` gera novas pastas
`assets/classic/room/reference` e `assets/hd/classic/room_reference_4x`.
11PNGs/15janelas: Random5quadros,2faixas e8estados de setas. Estas têm16px
no normal/hover/disabled e17px no push; cada estado foi extraído/processado
separadamente, sem padding/corte para forçar grade uniforme. Botão lógico17×48
usaKEEP_ASPECT_CENTERED. FaixasA127×71/B127×72 mantêm alturas diferentes.

Fonte graphics.xfs SHA256a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08.
Random=b_ready_mobile15.img; setas=b_ready_itemup/down.img. PNGs nativos
conservam pixels decodificados. BICUBIC4× por janela,alpha nearest,semredesenho;
cores interpoladas. Catálogos/hashes/hotspots/ordem e relatórios em
`docs/room-reference/reports`. Fontes/derivados anteriores preservados: 359arquivos de assets
preexistentes conferidos por blobGit contra5c1c3b6, sem alterações.

### Verificação observada

- Baseline11checks/11falhas antes das correções. Depois11/0; suíte ampliada
  **209checks/0**: grade/ordem,8faixas, clique/roda/setas, modal, itens mistos,
  estadosRandom, reconstrução,6inícios reais com ambosRandom,100amostras
  restritas, cancelamento independente e fallback de janelas desiguais.
- Asserções históricas8×2/16botões/abas foram substituídas pelos novos
  requisitos; testes do roster16IDs e da batalha continuam existentes.
  A primeira regressão histórica parou no método de abas removido; fixtures
  atualizadas e nova rodada integral aprovada, sem esconder falhas.
- **1669checks Godot/0**,16suítes: reference209,roomUI172,roster79,
  itenscena47,cena27,botões585,Bigfoot28,clássicos141,runner39,lobbyUI96,
  lobbyart93,shopwide36,perfil25,saldoteste14,integração39,originaismobiles39.
- **21testes Python** da skill passaram. Revisor independente repetiu
  **455checks/0**,mais **7probes/0** (loja,Randomunilateral,clique no último
  item,modal com roda/cliques reais) e **81verificações de arte/0** (XFS,
  janelas,alpha nearest,dimensões,hashes). Sem achados acionáveis. Contraste
  final dos nomes foi inspecionado pelo implementador na recapturaGPU.
- GPUreal OpenGL4.1Metal/AppleM4Pro1920×1080, grade,piloto/CPURandom,
  final da lista e modal. Pares nativo/HD da mesma cena congelada mantêm
  geometria/hitboxes nas três comparações,85texturas de estado trocadas.
  Inspeção confirma5×3,Random,oitoA/B e acesso por rolagem. É captura Godot,
  não execução do cliente original ou aceite visual do usuário.
- PCK isolado175357320bytes,exportexit0; **53checks/0/exit0** em
  `/private/tmp/room-reference-pck-1v__3njj`: novosJSONs,11recursos4×,
 5estadosRandom,fallback,setasdesiguais,grade,itens,A/B,Randompendente,
 sorteio real eGM/progresso. Override/TLSlocal ausentes; arquivo local
 restaurado byte-a-byte porfinally. Export só após terminar testes eGPU.

Logs em `.tools/room-reference`. Import/export registram CA/editor_settings
ambientais; smoke registra CA, sem SCRIPTERROR. Avisos Image.load_from_file
são da comparação técnica em testes, não consumidores do pacote. Final
`git diff --check` aprovado; metadata/hashes em `docs/room-reference/files.json`.

### Limites

Sem novoapp/ZIP/versão ou publicação; pacote temporário é somente validação.
Perfil real não foi usado. Match/modelo/física não mudaram; partidas completas
não foram repetidas nesta tarefa de seletor/UI. A seleçãoRandom é adaptação
explicitamente solicitada, sem alegar a mesma tabela de sorteio do cliente.
A referência guia a composição; modos4×4,BIGBOMB/DEATH56,servidores e rede não
foram implementados. Escuta,mouse físico e aceite visual do usuário separados
dos eventos de viewport e da inspeção técnica. Sem commit novo solicitado.
