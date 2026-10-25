# Sala clássica e acabamento4× — REQ-02/12/19/20/36

Pedido25/10/2026: versionar e aplicar acabamento conservador às imagens da sala,
e evoluir a implementação para usar corretamente os assets originais.
Base já versionada d8b50c7, árvore limpa; não criar commit vazio.

## Contrato e plano

- [x] Fixar evidência do cliente/recursos: ready_back10000,
  ready_selectmap10001 e ready_selectcharacter10002. Mapas nativos em332,51;
  retrato378,390. Miramo A=quadro1. Não converter C# moderno em provaThor.
- [x] Extrair folhas de mapa/retratos sem modificar fontes existentes.
  Gerar14PNGs BICUBIC4× por quadro: fundo, mapas22, retratos17 e11botões
  de itens clássicos OpenBound(4estados cada). Alpha nearest, sem margens,
  sharpening/redesenho. Cores interpoladas. Catálogo/hashes e fallback.
- [x] Completar cabeçalho local, íconeGM, pesos de clima do modelo, mapa e
  retrato; conter textos após tema/minimumsize. Informar seleção/itens na
  faixa do alto da grade. RetratosDragon/Knight são placeholdersRandom na
  fonte: manter identificação textual nesses dois, sem falsificar arte.
- [x] Preservar grade8×2,16mobiles, lugaresA/B, botões/estados/hitboxes, itens
  com6slots e seleçãoCPU; não restaurar o popup antigo contra pedido vigente.
  Interface continua treinooffline; sem rede,ladder, mapas/regras adicionais.
- [x] Testar recursos/fallback, mudança de seleção/clima/itens/modal, entrada
  real na viewport; GPU1920×1080 antes/depois e pacote isolado. Revisar,
  documentar resultados/limites e criar commitlocal, sem push/appnovo.

O acabamento4× só muda densidade dos recortes. Correções de composição usam
as janelas comprovadas da fonte, sem mudar áreas de clique. Avatares/mobiles
animados já aprovados e arte de batalha preservados. Perfil/combate/versão
não mudam. Pesos dos8ícones vêm dos primeiros8tiposWeather; mirror/random
não têm ícone nesse fundo e ficam informados no tooltip. Não inventarprobabilidade.

## Resultados

Concluído no projeto, com commit local solicitado; sem aplicativo novo.

### Evidência e arte

Cliente PE SHA2564af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde;
XFS SHA256a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08.
Ghidra12.2/JDK25 direto, mesmo banco/hash, manifestos finaisok=true:
`docs/room-ui/evidence/ghidra-room` e `ghidra-draw`. Recurso10000/10001/10002
registrado em004d6810. ASM de004d7db0 confirma mapa332,51 em004d84f4…004d8510,
e retrato378,390 em004d8adb…004d8afa. Pedido inicial em004d6839 não encontrou
função; a entrada comprovada004d6810 foi então semeada. Consulta004dbb50
resolveu a função contenedora004dba80, preservando VA solicitada/canônica;
não foi criada função artificial naquele ponto interno.

| Elemento | Fonte/contrato | Uso e confiança |
|---|---|---|
| Fundo | ready_back.img0,800×600 | fonte anterior preservada; HD3200×2400 |
| Mapa | ready_selectmap.img22quadros136×84 | frame1MiramoA; janela332,51 comprovada |
| Retrato | ready_selectcharacter.img17quadros113×146 | janela378,390 comprovada;14mobiles mapeados |
| Dragon/Knight | células14/15 sãoRandom | fallback textual, não rebatizarRandom |
| Clima | oito ícones pintados no fundo | pesos do modeloC# vigente; não são porcentagens |
| Itens |11folhas OpenBound nativas,4estados | adaptação declarada; sem afirmar índicesThor equivalentes |
| Cabeçalho/avisos | widgets Godot no espaço nativo | adaptação offline; GM20 vindo do perfil |

Extração nova em `assets/classic/room/details`, sem regravar manifest/fontes
anteriores. Gerador `scripts/build_room_art_hd.py` usa receita da skill e
recusa sobrescrever pastas de saída.14PNGs em
`assets/hd/classic/room_smooth_4x`,84células (1+22+17+44), hashes/registro,
BICUBIC por célula e alpha nearest. Relatórios em `docs/room-ui/reports`.
As métricas aprovam dimensões/alpha, não o aceite visual do usuário.

### Integração e verificação

`ClassicRoomArt` compartilha o validador parametrizado de `ClassicLobbyArt`,
conservando seu diretório padrão do lobby. Sala tem catálogo/diretório próprios;
JSONs nativo/HD incluídos no preset. Inválido/ausente recua para PNG nativo,
sem mudar o recorte/estado nem o tamanho lógico. Itens da sala usam originais
clássicos suavizados; `ItemArt`/HUD/batalha continuam usando a arte anterior.

Cabeçalho agora identifica treino,1×1 e donoGM; aceitar apelido atualiza ambos
os lugares e contém texto longo. Tag lateral tem versão completa como no lobby.
Mapa/retrato preenchidos, pesos de clima atualizados somente em Aceitar;
Cancelar mantém anterior. Faixa superior da grade informa seleção e item
sob o ponteiro. Retratos mantêm dados de vida/movimento/resumo em tooltip.

- Teste inicial9checks/9falhas antes da implementação;9/0 depois.
- Suíte ampliada169/0. Revisão encontrou P2: MOUSE_FILTER_IGNORE bloqueava
  tooltip do retrato/mapa quando os dados textuais estavam ocultos. Teste de
  regressão172checks/3falhas antes da correção;172/0 apósPASS nesses controles,
  incluindo hover real na viewport. Proprietário tambémPASS, íconeGMIGNORE.
  Revisor repetiu172/0 e confirmou resolução, sem novos achados.
- Doze suítes dirigidas finais: **1256checks Godot/0** (sala172, cena27,
  itenscena47, roster81, botões587, lobbyart93, lobbyUI96, shopwide36,
  perfil25, saldoteste14, integraçãoitens39, originaismobiles39).
  Clique real selecionaMage e atualiza retrato; CPU não troca retrato do
  piloto. Modal, clima,16mobiles,6slots, reload/fallback e navegação cobertos.
- **21testes Python** da skill passaram. Auditoria independente95checks/0:
 14hashesfonte+14hashessaída+14dimensões+14alpha+39quadrosXFS RGBA exatos.
- GPU real OpenGL4.1Metal/AppleM4Pro,1920×1080, cenários normal e stress
  (apelido20W aceito pelo modal, Dragon/Knight, todososclimas, aba1slot).
  Pares nativo/HD na mesma cena congelada: mesma geometria/hitboxes,43/39
  texturas de estado trocadas, imagens intencionalmente diferentes.
  Galeria dos16mobiles em `portraits-live.png`; configurações também capturadas.
  Inspeção confirma mapa/retratos, texto contido e bordas. Isto não é execução
  do cliente original nem QA temporal de toda a animação da sala.
- PCK isolado175094808bytes,exportexit0, **183checks/0/exit0** em
  `/private/tmp/room-ui-pck-v2pni5by`: catálogos,39quadros+44estadosHD,
  fundo4×, fallback nativo,GM/cabeçalho/clima,itens,seleção e volta ao lobby.
  Sem override.cfg/TLSlocal. Override restaurado byte-a-byte emfinally.

Logs em `.tools/room-ui`. Uma regressão coincidiu com a retirada temporária
do override para exportar: duas suítes tiveram CAambiental apesar de suas
assertivas passarem. A rodada foi rejeitada; após restauração foi repetida
integralmente,1256/0 sem erros. Export/PCK registram CAambiental; editorimport
registra editor_settings sem permissão e uma tentativa inicial de logfile
relativo emuser://. Captura/log final usam caminho absoluto e concluem limpos.
Avisos Image.load_from_file pertencem à comparação técnica em testes excluídos
do export; recursos do runtime/PCK usam ResourceLoader. Sem SCRIPTERROR.

### Entrega e limites

325arquivos de assets preexistentes (assets/classic, assets/hd/classic e
assets/openbound/items) conferidos por blobGit contra d8b50c7, sem mudanças.
Originais, atlasHD/exatos anteriores e avatares preservados. Nenhuma fórmula,
perfil ou versão modificada; teste com perfil isolado, nunca perfil real.
Sem app/ZIP novo ou publicação. Original multiplayer, nomes/decorações de
slots e popup nativo completo não foram portados; a grade8×2 segue a decisão
atual do usuário e esta sala continua adaptação offline1×1, sem alegação de
paridade integral. Aceite visual do usuário/escuta/mouse físico permanecem
separados da captura e dos eventos de viewport automatizados.

`docs/room-ui/files.json` registra hashes e resultados finais. Commit local
autorizado neste pedido; d8b50c7 já preservava o trabalho anterior ao início.
