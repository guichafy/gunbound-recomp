# Entregas e próximos trabalhos

## Menu clássico único durante a batalha — ADR-137

- [x] REA do loader/render/input/dispatch e dos setters de áudio originais.
- [x] Painel276×408 e OK/QUIT/X, sem distorção, labels sobrepostos ou PAUSA extra.
- [x] Unificar ESC/Options/P/show_pause; OK grava, X/ESC restauram, QUIT volta à sala.
- [x] Portar níveis e curva de atenuação; OFF corta efeitos ativos; preservar valores antigos.
- [x] Validar fallback nativo integral e pixels RLE por oráculo independente.
- [x] Revisão final semP1/P2 após corrigir scroll legado e piso/corte de áudio.
- [x] GPU360quadrosFullHD,3pausas/retomadas, input via viewport e fallback idêntico.
- [x] Recapturar README4telas/86quadrosT1/GIF/MP4.
- [x] Harness completo final:110suítes/28.279Godot/88Python/29partidas/0; manifesto.
- [ ] Aceite visual e escuta humanos.

Contrato em `BATTLE_OPTIONS_NATIVE.md`. Treino congela como adaptação;
Sniper/MIDI/3d não portados ficam desabilitados. Sem versão/app/commit/push.

## Fundo opaco do footer — ADR-136

- [x] Confirmar RGB565 retangular, spans e flush da camada3 via REA/ASM.
- [x] Reproduzir preto transparente com oráculo independente de palavras brutas.
- [x] Corrigir somente importação play_back, preservar decoder global e regras.
- [x] Regerar atlas/catálogo/imports;11 Python +1.195 checks dirigidos aprovados.
- [x] GPU480 quadrosFullHD,4 pausas/retomadas, fallback e probe35.200pixels.
- [x] Regenerar README4telas/86quadrosT1/GIF/MP4 com fundo corrigido.
- [x] Harness completo:109 suítes/28.157 checks Godot/86 Python/29 partidas, exit0; manifesto.
- [ ] Aceite visual do usuário.

Contrato em `FOOTER_BACKGROUND_NATIVE.md`. Sem versão/app/commit/push.

## MOVE no footer — ADR-135

- [x] Confirmar produtor/consumidor/estágios/pivôs/clip por Ghidra+ASM.
- [x] Extrair play_back[6] nativo; preservar compact5/fill8 e fallbacks.
- [x] Sobrepor MOVE à parte inferior da carga, dentro do footer.
- [x] Oráculos de geometria0/50/100 e transições; cenas e107suítes quick verdes.
- [x] GPU240quadrosFullHD, dois sentidos, pausa/retomada/soltura e fallbacks.
- [x] Prova independente do preenchimento na pausa e retomada;22PNGs.
- [x] Registrar contrato/manifesto e preservar evidências anteriores como histórico.
- [ ] Aceite visual do usuário nesta correção.

Cobertura combinada: 109 suítes/28.157 checks Godot/85 testes Python/29 partidas, zero falhas,
exit0 (`--quick` + duas suítes de partidas; manifesto). Sem regra/app/versão/commit/push novos. Registro
`MOVE_BAR_NATIVE.md`; evidência `docs/move-bar/verified-source.json`.

## Header/footer, cronômetro e vento — ADR-134

- [x] Substituir composição antiga por faixas nativas; fonte/pivô sem fit por peça.
- [x] Header Options/clima/Gold/itens/Skip; footer tiros/ângulo/modo/carga/MOVE.
- [x] Retângulos de input e câmera compartilham geometria; regras preservadas.
- [x] Cronômetro numfont original, segundos/décimos e limites30.0..0.0.
- [x] Vento moon.xtf+numfont, anel girado e WIND imóvel; força/direção físicas.
- [x] Fallback por grupo, bytesRGBA e pivôs originais; cliques reais pelo viewport.
- [x] GPU960quadros1920×1080,8pausas30idênticos/retomada e prova de direção.
- [x] README4telas+86quadrosT1/GIF/MP4 regenerados depois de cronômetro/vento.
- [x] Consolidar harness completo final29partidas e manifesto desta correção.
- [ ] Aceite visual do usuário sobre estas capturas; escuta não realizada.

Final: **109 suítes, 28.131 checks Godot, 85 testes Python e 29 partidas, zero falhas**; parse aprovado, exit0.
Manifesto `docs/battle-hud-layout/verified-source.json`.

Registro `HUD_CLIENT_LAYOUT.md`. ClienteWindows não executado. Sem versão,
exportação/app/ZIP, commit ou push. Alterações anteriores do Git preservadas.

## Assets de batalha do cliente — REQ-48 / ADR-133

- [x] Retomar/preservar o delta existente e inventariar consumidor/origem/equivalente.
- [x] Miramo mos.img/mos.lnd/pmos com alpha original e fallback de pixels idênticos.
- [x] HUD do cliente em composição adaptada, sem GPT; lacunas1× identificadas.
- [x] Clima/Thor/XTF/EPA nativos, preservando regras e adaptadores existentes.
- [x] Itens/beacon/chamas/ITEM LOCKED nativos; lacunas declaradas.
- [x] Música stage1..6 e turno local/adversário; áudio validado por payload.
- [x] Revisão independente: P2 de dígitos da fila corrigido e coberto por oráculo.
- [x] Consolidar harness completo29partidas, GPU final/pausa e capturas README.

Resultado final: 107 suítes, 27.945 checks Godot, 82 testes Python e 29 partidas, zero falhas. GPU720quadros/7casos/pausa30; README86quadros e4telasFullHD.
Evidência: `docs/client-assets/verified-source.json`.

Registro: `CLIENT_ASSETS_PORT.md` e relatórios por grupo. Sem versão/app,
commit/push. Escuta, cliente Windows executado e aceite humano são limites.

## Objetivo jglim e OpenBound fora do escopo — ADR-132

- [x] Objetivo jglim/multiplataforma/extensões em README, AGENTS, PORTE e skill.
- [x] Apagar gunbound-mobile-port; desanexar `~/Workspaces/Gunbound`; limpar agente/hook.
- [x] Limpar orientação vigente; registros antigos preservados como histórico.
- [x] Capturas GPU atuais do README (`tests/capture_readme.gd`, `docs/readme`).
- [ ] Remover `~/Workspaces/Gunbound` do `~/.codex/config.toml` (global, usuário).
- [ ] Substituir pelo cliente o que ainda vem de `assets/openbound/` e o HD do Miramo/HUD.

## README e documentação de entrada — 27/10/2026

- [x] README com visão, estado e TODOs; detalhe em `docs/PORTE.md`,
  `MOBILES.md`, `JOGAR.md`, `DESENVOLVIMENTO.md` e `HISTORICO.md`.
- [x] Links relativos conferidos. Só documentação, sem código/app/commit.
- [ ] Revisão do texto pelo usuário.

## Avatar Shop original — ADR-130

- [x] Fixar PE/XFS/captura; REA/Ghidra do card, preço e dígitos; matriz.
- [x] Extrair 171 frames (116 idênticos) e gerar BICUBIC4× com verificador.
- [x] Reescrever a loja sobre os frames originais; avatares nativos por padrão.
- [x] Suíte `test_shop_original` e seis suítes da loja adaptadas; 20 dirigidas 0 falhas.
- [x] GPU 1920×1080, 120 quadros60Hz, sala/batalha e comparação com `gb-avatar.png`.
- [x] Harness completo (ver HANDOFF).
- [ ] Aceite visual/mouse do usuário; reexportar app quando solicitado.

## Partículas decorativas Mage — ADR-129

- [x] REA emissão/coarse/refino, fábricas, densidade passiva, clock e renderer.
- [x] CrashTexture original65536pixels, UV/quadfloat32 e blendADD nativos.
- [x] Registros determinísticos/copied20Hz; RNGvisual só no apresentador.
- [x] TDD63+206Godot/2Python; FPS10/30/40/60, born1/last15/delete16.
- [x] Revisão independente; corrigir segunda rolagem comum quandoForce0.
- [x] GPU360quadrosFullHD/12casos,pausa30; arena real/retomada/menuclear.
- [x] Harness98suítes/parse/exit0,27046Godot+60Python+29partidas/0,
  hashes estáveis, evidênciaGPU e limitações registradas.
- [ ] Aceite visual humano e execução dinâmica do clienteWindows separados.

## Climas secundários Mage — ADR-128

- [x] REA calendário/vento/stage, Moon/Eclipse e anexos elétrico/Thor.
- [x] Fixtures independentes, estado copiável e mesmo passo real/previsão.
- [x] Substituir bridges no modoMage e conservar outras duplas.
- [x] Extrair três texturasXTF e portar quads/UV/blend/clock das colunas.
- [x] Revisão independente; corrigir confusão17e4 percentual ×15c0 Force.
- [x] GPU1920×1080/540quadros, seis casos, pausa30 idêntica por caso.
- [x] Harness95suítes/parse/exit0,26775Godot+58Python+29partidas/0;
  UI final49/0 e consolidação26777; hashes/evidências/limites registrados.
- [ ] Aceite visual humano, escuta e mouse; execução Windows não realizada.

## Lightning: revisão de batalha pelo cliente — ADR-127

- [x] Fixar PE/XFS/DAT e realizar11consultasGhidra12.2/JDK26, extratos/ASM/strings.
- [x] Especificação/plano antes do código, matriz e limites emLIGHTNING_CLIENT_REVIEW.
- [x] T1stride3/T2stride8, sóterreno; primeira superfícievertical/duasdiagonais.
- [x] SSraio120estrito/strikeT1, choque76/76/46, chain20 e ordem letal.
- [x] Dano/Defense/caixas/crateras; Force+3/+8/+8 e tornado24.8 compartilhados comCPU.
- [x] 524quadros/EPAs/PCM auditados; raioXTF/UV/alpha nativos;SSglowADD.
- [x] Dead oculta avatar/efeitos; montagem/HD em vida e originais preservados.
- [x] GPU300T1/T2/SS+300vento/tornado+150poses, dois sentidos e pausas30idênticas;
  sala/Miramo reais, HUD, retomada e limpeza de dados/RIDs ao sair.
- [x] Harness final25416Godot+55Python+29partidas/0,90suítes/parse/exit0;
  revisão independente semP1/P2; docs/hash/limites registrados.
- [ ] Aceite visual/escuta/input do usuário e execução dinâmicaWindows separados.

Semapp/export/PCK/ZIP/versão/commit/push. Bridges restantes de clima/itens,
origem/apoio e scheduler explícitos; trabalhoMage simultâneo preservado.

## Mage: assets, força e Tempo — ADR-126

- [x] REA do MainAction, laser, T1/T2/SS, atributos, dano/contato e EMP.
- [x] Dados nativos e divisão1/2/1, dano linear/scanlines/terreno1px.
- [x] EMP esgota escudo antes do blast; raio estrito150 no hotspotY−10.
- [x] Tornado preserva velocidade/vento; borda do T2 usa ponto da hélice.
- [x] Revisão independente corrigiu umP2 de borda; revisão final semP1/P2.
- [x]4054checks Mage,567fixtures independentes de distância e489quadros/PCM.
- [x] GPU480quadrosFullHD/dois sentidos, ambos cenários/pausa30; sala e
  arena Miramo/HUD/T1/T2/SS com pausa/retomada; vídeo emdocs/mage-review.
- [x] Consolidar20598checksGodot+48Python+29partidas/87suítes aprovadas;
  referência de botões reanexada/repetida e limite do exit1 parcial registrado.
- [ ] Aceite visual do usuário, escuta e execução dinâmica do cliente original.

Ver `MAGE_CLIENT_REVIEW.md`: demais climas/calendário, itens, muzzle/apoio e
limite12s continuam bridges identificadas. Semapp novo, versão, commit/push.

## Aduka: dano/colisão/clima e T2 com3 criaturas — ADR-125

- [x] REA dos consumidores nativos de dano, escudo/XP, caixa e contato.
- [x] Portar queda linear/passes inteiros e cratera, sem inversa de distância C#.
- [x] Máscara1px original, stride8/refino1, raioThor2 e snapshot profundo.
- [x] T2 com3emissões explícitas e alpha do asset original legível no mapaHD.
- [x] REA/porte do tornado: velocidade conservada, duas inversões, saída3 e vento.
- [x] Force separado;616fixtures de dano e2000ticks de tornado independentes.
- [x] Revisão independente: corrigir assimetriaLUT/Y0 e preservar efeitoBunge.
- [x] GPU Miramo: três criaturas visíveis, feixe, HUD/saída;300quadros de
  T1/T2/SS e300de vento/tornado, dois sentidos e pausa30 idêntica.
- [x] Harness final16544checksGodot+44Python+29partidas/0,84suítes/parse/exit0;
  registro e limites atualizados, semapp/export/commit/push.
- [ ] Aceite visual/escuta do usuário e execução dinâmica do cliente original.

Limites globais de clima, itens, muzzle/apoio e coordenadas continuam
identificados no registro; sem publicar/reexportar aplicativo.

## Auditoria da família Aduka — ADR-124

- [x] Fixar PE/XFS; pesquisar MainAction, vtables, impacto/Thor e renderer.
- [x] Matriz e plano antes do código: `ADUKA_AUDIT.md`.
- [x] Reproduzir divergências e corrigir assets/camadas/Thor/sons.
- [x] 495quadros/PCM/ASM auditados; harness13241Godot+42Python+29partidas/0.
- [x] Corrigir dois P2 de HUD/limpeza; revisão final aprovada e quick13253/0.
- [x] GPU300quadros/dois sentidos/pausa30; T2 na arena real, HUD/saída por pixels.
- [x] Registro e limites em `ADUKA_AUDIT.md`; sem app/versão/commit/push.
- [ ] Aceite visual e escuta do usuário; dano/colisão comuns ainda adaptados.

## Centralização do piloto Aduka — ADR-123

- [x] Orientação aprovada; delimitar só compensação horizontal constante.
- [x] Conferir XFS/tank16 e pontos/poses; plano em `ADUKA_CENTER.md`.
- [x] Aplicar(+8,0) ao encaixe no catálogo/consumidor, sem modificar fontes.
- [x] GPU sala A/B antes/depois, padrão/HD, seis poses/dois sentidos;
  150quadros, pausa30 idêntica e retomada. `docs/aduka-center`.
- [x] 1018checks/0 em 11suítes; registrar resultados/limites no HANDOFF.
- [ ] Aceite visual do encaixe; orientação anterior aprovada.

## Orientação do Aduka na sala — ADR-122

- [x] Corrigir contrato pela imagem: personagem à direita, mira traseira à esquerda no A.
- [x] Restaurar RiderPivot original e converter apenas orientação da prévia.
- [x] GPU da sala real A/B, padrão/GreatDevil; galeria seis poses/dois sentidos,
  padrão/HD, 150quadros/pausa30 idêntica; `docs/aduka-orientation`.
- [x] 982checks/0 em dez suítes; resultados e limites no HANDOFF.
- [x] Orientação aprovada pelo usuário; centralização posterior pela ADR-123.

## Encaixe do piloto no Aduka — ADR-121

Histórico rejeitado pelo usuário; substituído pela ADR-122.

- [x] Delimitar com o usuário: mover o piloto para a direita, sem virá-lo.
- [x] Inverter somente X do RiderPivot do Aduka no consumidor; fontes intactas.
- [x] 694 checks/0 em oito suítes; GPU150 quadros, seis poses, dois sentidos,
  padrão/HD, pausa30 idêntica e retomada; `docs/aduka-mount`.
- [x] Registrar evidência e limites; sem app novo, versão, commit ou publicação.
- [ ] Aceite visual do usuário.

## Bigfoot com acabamento4× — 25/10/2026, ADR-115

- [x] Plano SDD e ADR antes do código; escopo nas nove folhas originais.
- [x] Gerar BICUBIC4× por quadro com o helper da skill, catálogo e relatórios.
- [x] Integrar densidade só nos recortes de origem, opt-in e fallback por folha.
- [x] test_bigfoot_smooth70/0, regressões1196/0+1772/0, GPU galeria/sala/arena e PCK30/0.
- [ ] Aceite visual do usuário; app novo somente em entrega solicitada.
- [ ] Avaliar o mesmo acabamento para piloto padrão, aura, Mage e demais mobiles se pedido.

## Aceite e versionamento dos ajustes da sala — 25/10/2026

- [x] Aceite visual final do usuário e autorização de commit local.
- [x] Reunir ADR-107 a114: código, assets, fonte original, testes e evidências.
- [x] Verificação atual:1350checksGodot/0,21Python/0,24hashes e diff limpo.
- [x] Manter versão/aplicativo atuais; publicação não solicitada.

## Alinhamento de SETTINGS — ADR-114

- [x] Abaixar os dois T em1px, preservando demais letras/fonte/acabamento.
- [x] Dois checks de topo visível reproduzem o erro;988checksGodot/0 finais.
- [x] GPU4estados/fallback/clique;START inteiro e transparência idênticos.
- [x] Revisão confirma delta exclusivo dos T e1436facesRGBA preservadas.
- [x] Aceite visual do usuário. Sem app novo; ver `SETTINGS_BASELINE.md`.

## Acabamento de SETTINGS — ADR-113

- [x] Preservar fonte nativa e transparência aprovada daADR112.
- [x] Compor contorno único/alpha suave e espaçamento2px sem emendas.
- [x]1436facesRGBA exatas;986checksGodot/0 eGPU4estados/fallback/clique.
- [x] START inteiroRGBA idêntico; quatro bordas transparentes nos dois atlas.
- [x] Revisão final aprovada;PCK96/0/exit0, semoverride local.
- [ ] Aceite visual do usuário. Semapp novo; verSETTINGS_WORD_FINISH.md.

## Alpha e composição da sala — ADR-112

- [x] Remover cenário opaco dos cantos nas texturas reais de START/SETTINGS.
- [x] Isolar glifos nativos, T de START, I limpo, espaçamento e topo comuns.
- [x]1436pixels de faceRGBA originais;1344checksGodot/0 em8suítes.
- [x] GPU confirma fundo nos cantos, lettering START idêntico e clique/modal.
- [x] Revisão final aprovada ePCK isolado96/0/exit0, semoverride local.
- [ ] Aceite visual do usuário. Semapp novo; verROOM_BUTTON_ALPHA.md.

## SETTINGS com fonte completa — ADR-111

- [x] Descartar reconstrução de preenchimento/contorno do catálogo ativo.
- [x] CopiarRGBA nativo completo, lapidando só fundo/junções e alinhamento.
- [x]629núcleos/3156contornos exatos;969checks/0,GPU4estados,PCK79/0.
- [x] Revisão aprovada; margem completa do push e4364pixels no canvas.
- [x] START aprovadoRGBA idêntico; modal e cliques preservados.
- [ ] Aceite visual do usuário. Semapp novo; verSETTINGS_ORIGINAL_LETTERS.md.

## Acabamento de SETTINGS — ADR-110

- [x] Remover mattes/contornos quebrados dos recortes; manter formas nativas.
- [x] Palavra única transparente, quatro estados, baseline/espaço/contorno comuns.
- [x]965checksGodot/0,GPUFullHD e revisão independente com atlas reproduzidos.
- [x] START aprovadoRGBA idêntico; fonte/modal/regras e cliques preservados.
- [ ] Aceite visual do usuário. Semnovoapp; verSETTINGS_LETTERING_FIX.md.

## SETTINGS, modal e fonte original — ADR-109

- [x] START semseta; SETTINGS substituiCHANGE esetacircular.
- [x] Lettering raster dos botões originais, semfonteTTF substituta.
- [x] Janela azul clássica, rádios eOK/Cancel nativos;95glifosASCII dofont.fnt.
- [x] Preservar rascunho/aceite/cancelamento; ESC funciona com foco de texto.
- [x]1317checksGodot/0,21Python/0,GPUFullHD,PCK70/0 e revisão aprovada.
- [ ] Aceite visual do usuário. Semnovoapp; verROOM_SETTINGS_CLASSIC.md.

## Dificuldade, contadores e START — ADR-108

- [x] Dificuldade confirmada ao lado deCPU, fora do painel central.
- [x] Números brancos transparentes sobre base laranja restaurada.
- [x] STARTGAME azul original107×45/quatro estados, alinhado ao rodapé.
- [x] Fonte/HD,catálogo43,extração e42registros/222PNGs prévios preservados.
- [x]1286checksGodot/0,752/0 finais,21Python/0,GPUFullHD,PCK55/0 e revisão aprovada.
- [ ] Aceite visual do usuário; semapp novo. Evidência:ROOM_FINAL_POLISH.md.

## Cards, Ready e placas da sala — ADR-107

- [x] Encaixar mobile na faixa em155 com posições105/563 derivadas do cliente.
- [x] Retirar nome do mobile dos dois cards, incluindoRandom; preservaridle/avatar.
- [x] Ready/chave e placas nativas, refletindo regras offline existentes.
- [x]7PNGs/25janelas4×conservador/fallback,64checks dearte e456assets intactos.
- [x]1093checksGodot/0,21Python/0,GPU17escolhas/24quadros,PCK40/0.
- [x]P2deinput corrigido, cliques automatizados e revisão final aprovada.
- [ ] Aceite visual do usuário; mouse físico/escuta separados. Semapp novo.

Evidência/limites:ROOM_CARD_FIDELITY.md e docs/room-card-fidelity.

## Sala: itens, apoio, mapa e Random — ADR-106

- [x] Catálogo nativo uniforme64×43 com indicação1/2slots e custo.
- [x] Equipamento35/71×31 sobre seis posições; setas encaixadas/rolagem.
- [x] Mobile sobre faixaA/B no chão144 e abaixo do nome, sem seno adicional.
- [x] Idle e avatar animados por elapsed; posição não congelada nem oscilante.
- [x] Random original com avatar real,12quadros4×/fallback e sorteio só noStart.
- [x] Somente título/setas laterais da prévia; um único mapa disponível.
- [x] Regressão1720/0 + rodada final1027/0,21Python, GPU24quadros ePCK109/0.
- [ ] Aceite visual do usuário; escuta/mouse físico separados. Semapp novo.

Evidência e limites: ROOM_POLISH.md e docs/room-polish/render.json.


## Sala conforme foto — 25/10/2026

- [x] Grade5×3 com14comuns+Random; esconder escolhas diretas14/15.
- [x] Random independente para piloto/CPU, sorteado noStart apenas14/15.
- [x] Catálogo único11itens,rolagem/setas,semabas e6slots preservados.
- [x] FaixasA/B nativas nos8lugares,nomes na base e mobiles acima.
- [x] Extrair11PNGs/15janelas conservadoras4×,sem sobrescrever fontes/HD.
- [x] Validar1669checks Godot,21Python,revisão455+7+81,GPU ePCK53/0.
- [x] AtualizarSDD/metadata, sem novoapp/versão/commit/publicação solicitados.
- [ ] Aceite visual do usuário.


## Sala clássica e acabamento4× — 25/10/2026

- [x] Confirmar base anterior versionadad8b50c7 e árvorelimpa.
- [x] Conferir recursos/posições viaGhidra/ASM e extrair39quadros nativos.
- [x] Gerar14PNGs/84células conservadores, catálogo/fallback e fonte preservada.
- [x] Completar mapa/retratos, cabeçalhoGM, clima, avisos e textos/tooltip.
- [x] Preservar grade8×2/16mobiles,estados,6slots,hitboxes e arte de batalha.
- [x] Validar1256checks Godot,21Python, revisão172/0+auditoria95/0,
  GPU1920×1080 ePCK183/0/exit0; documentar/versionar localmente.
- [ ] Aceite visual do usuário; appnovo somente quando solicitado.


## Lobby com acabamento4× — 25/10/2026

- [x] Versionar correção chat/GM:5732568,735checks/0 repetidos antes do commit.
- [x] Ampliar/integrar seis imagens restantes,54células, fallback e geometria.
- [x] Conferir1045checks Godot,21Python, revisão776/0 eGPU1920×1080.
- [x] Conferir PCKisolado223/0/exit0, semoverride/TLSlocal; originais intactos.
- [x] Documentar e versionar localmente o acabamento (ADR-103).
- [ ] Aceite visual do usuário; app novo somente em entrega solicitada.


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

## Rastro só no T1 do Raon — ADR-120

- [x] Usuário recusou o rastro nos outros tiros; `has_trail` limita ao T1 do Raon.
- [x] Revertidos Nak, espelho Facing e T2/SS do Raon; `test_raon_trail` 93/0; harness rápido 13202/0.
- [ ] Aceite visual do T1 no jogo.

## Rastro em todas as balas comuns — ADR-119 (substituída pela ADR-120)

- [x] Censo do slot3 de todas as classes: rastro, rastro+espelho (`0x488880`) ou desenho próprio.
- [x] `ClassicSprite.trail_style/facing_flip/_draw_bullet`, cauda após impacto para qualquer mobile com rastro; Nak com cópias na orientação aprovada.
- [x] `test_raon_trail` 95/0; Python 13/13; `check.sh --quick` 13204/0.
- [x] Substituída pela ADR-120 a pedido do usuário.

## Rastro das balas Raon — ADR-118

- [x] Vídeo de referência (YouTube fd9VsdZQbsI, 1:15–1:20): T1 com cauda de cópias translúcidas.
- [x] Binário: publicação 0x458690, render 7..0 com alfa 255−32k, deslocamento por quadro, 1 quadro/tick.
- [x] `trail_levels`/`lingering_levels` (cauda escoa após o impacto) para o Raon; `test_raon_trail` 45/0; Python 12/12; harness rápido 13154/0.
- [x] Usuário pediu “Adicione rastro”: estendido a todas as balas comuns (ADR-119).
- [ ] Aceite visual do usuário.

## Minas Raon no terreno — ADR-117

- [x] Relato do usuário: robôs do T2 virados, mina deve estourar ao encostar, falhas ligadas ao terreno.
- [x] Ghidra (r1..r5): AnimateMine/SuperMine, inclinação 0x4986a0, desenho 0x499d50/RayonTexture, raio 8 do bloco S2/SS.
- [x] Mina no pixel do chão, inclinação nativa, queda/quique, remoção fora do mundo, gatilho 8 px pelos pés, explosão y−10.
- [x] Desenho girado pela inclinação e espelho correto; supermina detona junto de outra mina.
- [x] `test_raon_mines` RED→33/0; Python 11/11; harness 13102 Godot/80 suítes/partidas, exit0.
- [x] GPU em relevo inclinado `tests/capture_raon_mines.gd`: 330 quadros, pausa30 idêntica, duas detonações.
- [x] T1 "maior/mais extenso": rastro nativo de 8 níveis (ADR-118) a partir do vídeo de referência.
- [ ] Aceite visual, escuta/mouse; app não reexportado; busca nativa de 30 px da mina enterrada e brilho por cima pendentes.

## Tiros Raon T1/T2/SS — ADR-116

- [x] Reproduzir com GPU real e testes RED (39 falhas em `test_raon_shots`).
- [x] Fixar ASM/dados: idx0/2/3, força ±15 (0x794bf0), SS +15, Simulate sem HitTestMobilesAndJewels, direção vx>0.
- [x] T1 fases comum/0/180; T2 P+15/P−15 sem leque; SS P+15; balas de mina atravessam mobiles.
- [x] Prova Python do PE 9/9; `test_raon_shots`, `test_raon_effect`, integração especial.
- [x] Captura GPU temporal 3 tiros × 2 sentidos, pausa30 idêntica e retomada.
- [x] Harness completo: 13062 checks Godot, 33 Python, 29 partidas, parse e exit0.
- [ ] Aceite visual do usuário, escuta/mouse; app não reexportado; cliente original não executado.
- [ ] Pendentes: ponto exato do plantio, rotação do sprite pelo heading, contato/encosta das minas.

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
