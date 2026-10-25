# Entregas e próximos trabalhos

## Lobby/chat e patente GM — REQ-02/10/12/19, ADR-102

- [x] REA no cliente original: convençãoThorWORD+4, GM20/quadros24.
- [x] Extrair50quadros de insígnias; catálogo/extrator reproduzível.
- [x] Patente separada deXP/level, defaultGM, migração e persistênciav4.
- [x] Corrigir cartão/carteiras, chat/rolagem/entrada e alinhamento dos filtros.
- [x] 1086checks/0; teste novo96/0 e comparaçãoXFS repetidos pelo revisor.
- [x] GPU1920×1080 normal/stress e PCK isolado109/0, semoverride/TLSlocal.
- [x] Revisão independente, parse/Python/whitespace e registros finais.
- [ ] Aceite visual pelo usuário; app exportado permanece anterior.

## Versionamento local autorizado — 25/10/2026

- [x] Revisar alterações da sessão anterior para commit local, sem envio ao remoto.
- [x] Reexecutar regressões dirigidas: 778 checks Godot/0 falhas e 21 testes Python aprovados.
- [x] Conferir whitespace e cópia Codex da skill client-port (9 arquivos idênticos).

## Aplicação bicúbica e skill — REQ-02/12/19/20, ADR-101

- [x] Registrar aprovação do EXIT e autorização para aplicar ao lote.
- [x] Helper BICUBIC por quadro, alpha preservado, grade/saída validados.
- [x] Gerar42atlas/197estados em `buttons_smooth_4x`; EXIT coincide com a prévia.
- [x] Manter180arquivos de fontes/exatos intactos e atualizar consumidor/preset.
- [x] Preservar layout/hitboxes/estados;778checks Godot e21testes Python aprovados.
- [x] GPU1920×1080: alterações só nos botões; PCK isolado92/0/exit0.
- [x] Skill com receita conservadora, modo exato e checker seguro; instalação sincronizada.
- [x] Revisão independente aprovada; estrutura/links/14arquivos/21testes da instalação conferidos.
- [ ] Inspeção visual integral pelo usuário e eventual reexportação do aplicativo.

Registro: `CLASSIC_BUTTONS_SMOOTHING.md`; capturas/ZIP em `docs/classic-buttons-smoothing`.

## EXIT — validar suavização antes de lote

- [x] Testar duas prévias IA; registrar desvios e rejeitá-las para produção.
- [x] Registrar escolha do usuário por suavização algorítmica conservadora.
- [x] Produzir EXIT BICUBIC1712×180, quatro estados alinhados, alpha preservado e zero padding.
- [x] Comparação antes/depois com quatro estados e slider conferidos; fontes/atlas ativo intactos.
- [ ] Aceite visual do usuário antes de qualquer integração ou lote.

Prévia: `docs/exit-restoration-preview/exit-4x-bicubic.png`. Registro:
`CLASSIC_HD_RESTORATION_SKILL.md`. Pixels/tons interpolados, sem alegar cópia exata.

## Botões4× integrados — REQ-02/12/19/20, ADR-100

- [x] Usar atlas4× em `ClassicChrome`, com validação e fallback nativo.
- [x] Manter tamanho lógico, layout, estados e hitboxes; recortes de textura×4.
- [x] Importar42PNGs; incluir JSON nativo eHD no preset de exportação.
- [x] Teste dirigido antes/depois; suíte nova544/0 e regressões, total735/0.
- [x] GPU1920×1080: lobby/sala idênticos em todos os bytesRGBA na troca de atlas.
- [x] PCK isolado91/0/exit0;42atlas/catálogos presentes, override/TLS local ausentes.
- [x] Revisão independente aprovada e hashes das fontes/PNGsHD preservados.
- [ ] Aceite visual do usuário, escuta/mouse manual; aplicativo não reexportado.

Registro: `CLASSIC_BUTTONS_HD_INTEGRATION.md`. Capturas em `docs/classic-buttons-integration`.

## Demais botões clássicos4× — REQ-12/19/20, ADR-099

- [x] Inventariar42atlas e conferir contra todos os PNGs de botão `b_*`.
- [x] Ampliar41atlas restantes e reunir o CREATE já validado em `assets/hd/classic/buttons_4x`.
- [x] Preservar197estados/ordem/células, cores, alpha e alinhamento, sem margens novas.
- [x] Checker42/42 e enumeração independente de8087792pixels, zero divergências.
- [x] Conferir95arquivos de origem por hash antes/depois, todos intactos.
- [x] Catálogo e relatórios por atlas; ZIP com42PNGs+catálogo, CRC/hashes válidos.

Registro: `CLASSIC_HD_RESTORATION_SKILL.md`. Sem integração ao runtime ou build.

## CREATE4× exato na skill HD — REQ-12/19/20, ADR-099

- [x] Repetir tentativa IA com contrato explícito; rejeitar2164×726 por aspecto/margens/cores.
- [x] Registrar escolha do usuário por ampliação determinística com pixels exatos.
- [x] Entregar PNG1712×180, quatro estados, sem margens acrescentadas.
- [x] Conferir308160pixels e648cores por enumeração independente, zero divergências.
- [x] Helper e checker `--exact-pixels`, com15testes aprovados.
- [x] Revisão independente aprovada; cópia instalada sincronizada e15testes aprovados também nela.

Arquivo: `docs/classic-hd-restoration/output/create-4x.png`. Registro em
`CLASSIC_HD_RESTORATION_SKILL.md`. Aceite visual/integração não presumidos.

## Skill HD: restauração fiel — REQ-12/19/20, ADR-099

- [x] Reproduzir reconstrução/volumes suaves na skill antiga em contexto independente.
- [x] Adotar prompt integral do usuário, fonte visual única e contrato4×/alpha/estados.
- [x] Separar restauração de adaptação/rig/efeitos aprovados.
- [x] Validar três PNGs de `assets/classic`: todos rejeitados; brutos/prompts/hashes preservados.
- [x] Avaliação comportamental posterior em cinco cenários; checker com9testes aprovados.
- [x] Sincronizar a skill instalada com backup e conferir9testes/estrutura/links/hashes.
- [ ] Aceite visual de arte futura e integração: nenhum candidato atual é conforme.

Registro: `CLASSIC_HD_RESTORATION_SKILL.md`. Runtime/build/versão preservados.

## Lobby clássico e sala — REQ-02, ADR-096

- [x] Extrair `gamelist_back`/`ready_back` e os botões EPA para `assets/classic`.
- [x] Abrir o lobby na entrada; Create chega à sala 1×1 já existente.
- [x] Deixar Buddy de fora; Ranking e Join desabilitados; sem rede.
- [x] Conservar mobile, CPU, itens, apelido, dificuldade, clima e Iniciar.
- [x] Loja volta à tela que a abriu. EXIT do lobby encerra; EXIT da sala volta ao lobby.
- [x] Suítes de cena: 336 checks, 0 falhas (`test_scene`, `test_items_scene`, `test_roster`, `test_bigfoot`, `test_classic_mobiles`, `test_shop_wide`).
- [x] A grade é a única escolha de mobile; lugares A/B mostram avatar do perfil e mobile. Sem modal de mobile.
- [x] Ícone de Knight e Aduka sem o Armor por baixo; item de 2 slots é uma peça só nos dois lugares.
- [ ] Aceite visual do lobby e da sala, e escuta. App não reexportado. Cliente original não executado.

## ASate/JD/Aduka/Raon 0.20.5 — ADR-094

- [x] Investigar os quatro mobiles com Ghidra/ASM/dados e fixtures independentes.
- [x] Corrigir Ion/filhos, cristais JD, Thor Aduka e tiros/minas Raon.
- [x] Integrar autoria, cópia profunda, fim de efeito/turno e candidatos da CPU.
- [x] Preservar Thunder/Thor anexos e impedir multiplicação por filhos.
- [x] Resolver minas S2 antes do input; SS mantém o turno até detonar.
- [x] EPA, recursos originais e laser Thor aditivo; PCM Ion T1/T2 separado.
- [x] Harness completo11493 checks Godot/29 Python/29 partidas e parse sem falhas.
- [x] App/ZIP0.20.5 assinados, versão/CRC e PCK isolado68/0 conferidos.
- [ ] Executar captura GPU: script pronto, bloqueio FontRegistry/LaunchServices antes do primeiro quadro.
- [ ] Aceite visual do usuário e escuta manual; cliente original não executado.

Plano e limites: SPECIAL_MOBILES_CLASSIC_FIX.md e quatro registros por família.

## Sala inicial 1×1 — REQ-02/09/36, ADR-092

- [x] Trocar o cartão “Preparar treino” pela sala com piloto, máquina e Miramo.
- [x] Menu da partida com apelido, dificuldade e clima; Aceitar grava, Cancelar restaura.
- [x] Mobile em popup próprio; itens no PopupSelectItem; Iniciar num clique.
- [ ] Aceite visual do usuário na sala, no menu da partida e no popup de mobile.
- [x] Botão CPU escolhe o mobile da máquina; o pareamento antigo segue como padrão (ADR-093).
- [ ] Aceite visual da escolha do mobile da CPU.
- [x] Sala desenha o mobile no casco nativo de 60 px (ADR-095).
- [ ] Aceite visual do tamanho do mobile na sala.

## Ghidra na skill de porte — REQ-12/19/44/45, ADR-091

- [x] Adotar Ghidra headless direto e incluir runner/exportador reproduzíveis.
- [x] Validar importação nova, entradas indicadas, dados/vtable e22extratos
      idênticos na reabertura; ausência de função retorna falha explícita.
- [x] Validar5testes do runner e8checks independentes de LUT/seção no Godot;
      suites dirigidas1368/0. Estrutura/links/UI/alias conferidos.
- [x] Aplicar a skill em contexto independente antes e depois da atualização;
      reproduzir/corrigir cleanup de descendentes resistentes ao timeout.
- [x] Revisão para commit local autorizada após pull/merge: cinco testes do
      runner aprovados; override local excluído do versionamento.

Registro: GHIDRA_SKILL_VALIDATION.md. Sem port/runtime/build novo nesta tarefa.

## Avaliação Ghidra — REQ-12/19/44/45

- [x] Testar instalação12.2/Java25 no PE local, com hash preservado.
- [x] Exportar8rotinas de tiros/render Mage após indicar4entradas conhecidas;
      reabrir projeto e conferir24extratos idênticos.
- [x] Comparar cobertura ASM com extratos Hopper e verificar política do REA:
      6.7.0 aceita12.1.x, rejeita12.2; CLI direta funciona.
- [x] Registrar comandos, ajustes de cache/projeto e limites em GHIDRA_EVALUATION.md.
- [ ] Integração MCP com12.2 depende de conector compatível; configuração global preservada.

## Bigfoot/Mage originais 0.20.3 — REQ-12/19/20/45

- [x] Extrair tank2/tank5, EPA, RiderPivot, tiros/luzes/impactos em original/.
- [x] Ativar ClassicSprite e composição Mage original, escala nativa, miras/auras originais.
- [x] Preservar HD anterior, avatares/equipamentos, regras, IDs e perfil.
- [x] Oráculo de pixels/hotspots; regressão ativa 39/0; harness 8059 checks,
      17 testes Python, 29 partidas e parse aprovados.
- [x] Galeria GPU 1920×1080/210 quadros/60 Hz; pausa 30 quadros idênticos.
- [x] App/ZIP 0.20.3, assinatura/CRC/versão e PCK isolado 44/0/exit0.
- [ ] Captura específica menu/loja/arena (UI timeout); galeria e suites concluídas.
- [ ] Aceite visual do usuário; escuta e mouse manual.

Ver ORIGINAL_MAGE_BIGFOOT.md e ADR-089; composição dos lasers Mage permanece adaptação.

## Catálogo clássico de avatares (REQ-46, ADR-089)

- [x] Conferir `avatar.xfs` com o TestClient do gunbound-launcher (mesmo SHA-256, versão 280, 562 registros).
- [x] Índice `classic.json` com slot, preços, status e texto CP949; nenhuma peça removida.
- [x] WORD/DWORD do gunbound-server: bit 15 masculino, slot corpo/cabeça/olho/bandeira, conjunto do `amigos` e padrões `/gender`.
- [x] Love Cupid (id 143) e `ff.dat` vazio permanecem fora do catálogo comprável.
- [x] Chaves e categoria da loja preservadas para equipamento já salvo.
- [x] `test_xfs_import.py` (12) e `test_xfs_catalog.gd` (3816 checks, zero falhas).
- [x] Regressão de loja/perfil/atributos/HD: 2178 checks, zero falhas.
- [x] No merge com a `main`, REQ-45/ADR-082 permanecem do roster e do chifre; este catálogo usa REQ-46/ADR-089.
- [ ] Usuário validar na loja as descrições com reticência e o nome coreano do concurso.
- [ ] App não reexportado nesta entrega.
