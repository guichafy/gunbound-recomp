# SETTINGS e modal clássico da sala — 25/10/2026

REQ-02/12/19/20. Pedido posterior àADR-108 autoriza adaptar a apresentação:
START sem seta de retorno; CHANGE passa aSETTINGS sem seta circular; modal
compatível com Gunbound Classic. Não altera regras ou opções disponíveis.

Plano de implementação:
- Reutilizar a moldura azul107×45 deSTARTGAME, desenhando bordas e faixa
  central limpa por recortes da textura por estado. START conserva a palavra
  raster original; SETTINGS compõe letras recortadas deSTART/EXIT/CHANGE,
  sem trocar por fonteTTF. Quatro estados e cliques mantidos.
  Não gerar novo desenho nem apagar os PNGs originais com setas.
- Extrair ready_back.img quadro8 (313×160), b_ready_ok/cancel (4×82×34),
  do mesmo graphics.xfs identificado naADR-107. BICUBIC4× por janela com
  alpha nearest, novos catálogos/fontes e fallback, sem sobrescrever arte.
- Moldura do modal reconstruída por recortes limpos da janela nativa:
  cabeçalho ciano, corpo azul, borda escura e títuloSETTINGS. Não esticar
  ROOMTITLE ou o campoTitleName gravados na janela de referência.
- Modal560×470 centrado em1280×800. Apelido em campo azul escuro; grupos
  de dificuldade e clima com rádios clássicos; OK/Cancel nativos no rodapé.
  Hierarquia em ouro/branco, sem os cartões arredondados verdes anteriores.
- Correção posterior do usuário rejeita a tipografia substituta: modal usa
  95glifosASCII8×12 dofont.fnt original, sem redesenhar. Caracteres fora desse
  repertório em apelidos usam a fonte já existente da sala comofallback.
- Preservar rascunho/aceite/cancelamento, fechamento porESC, foco de texto,
  bloqueio do fundo, dificuldade confirmada no cardCPU e demais elementos.
- Testes de cena/configuração/entrada e fallback, capturaGPUFullHD com
  modal e estados, revisão independente e registrosSDD.

Este layout é adaptação solicitada usando componentes nativos, não alegação
de que o cliente original tinha exatamente este formulário offline.
Sem versão/app/commit/push solicitados.

## Resultados

Concluído no projeto. START/SETTINGS usam bordas doSTARTGAME por estado,
com o canto direito limpo espelhado à esquerda e faixa central sem setas.
START é recorte da palavra raster nativa; SETTINGS compõeS/E/T/I/N/G de
START/EXIT/CHANGE, com os mesmos pixels, contorno e estados dos sprites
ativos. As fontesPNG anteriores não foram editadas. Não usarSystemFont
para substituir esse lettering, conforme correção explícita do usuário.

Modal560×470 em360,165: moldura azul derivada de9recortes limpos da janela
313×160, títuloSETTINGS, apelido, dificuldade e clima; OK/Cancel clássicos.
Font.fnt doXFS fornece95glifosASCII8×12. O atlas de128×72 tem9120bits
conferidos independentemente; importaçãoBMFont preserva o desenho e tint
é aplicado noCanvasItem. Caracteres fora deASCII nos apelidos conservam
fallback da fonte existente da sala. O layout é uma adaptação solicitada,
não reprodução comprovada de um formulário offline do cliente.

3PNGs nativos/HD,9janelas, mais o atlas/fonteASCII. Fonte XFS/hash dofont.fnt,
catálogos, relatórios e medições emdocs/room-settings-classic. Revisor conferiu
os9quadros contraXFS,95glifos/9120bits e hashes. Catálogos novos incluídos
noexport; ausência/invalidez deHD usa os recortes nativos.

TDD:6falhas iniciais de apresentação; teste de cena detectou oESC consumido
peloLineEdit. O painel agora capturaESC enquanto visível, cancela e marca
o evento tratado antes doGUI, evitando também sair da sala. Probe corrigiu
referência ao campoCPU e adicionouphysical_keycode ao evento. A troca de
canalBMFont e uma tentativa de modulação interna causaram texto invisível
em capturas intermediárias; descartadas. Versão final usaRGBA nativo e
modulate noCanvasItem, com824pixels ouro visíveis no título. Captura verifica
essa condição, além de posição/idle/hold. Não usar capturas intermediárias.

Verificação final:1317checksGodot/0 em8suítes, incluindo nova25/0 com cliques
reais deSETTINGS/rádios/OK/Cancel/START, rascunho/rollback, foco eESC.
21testesPython da skillHD aprovados. Comando: `./scripts/check.sh
test_room_settings test_room_polish test_room_ui test_room_reference
test_classic_buttons_hd test_scene test_items_scene test_roster`.
Primeira importação acusou inferência de tipo no painel; tipagem corrigida.
Revisão independente final aprovada, sem pendências acionáveis.

GPU1920×1080,OpenGL/Metal AppleM4Pro: botões semsetas, modal padrão/rascunho,
17escolhas/24quadros20Hz,20variações deidle, âncorasfixas/holdidêntico.
Não executa o cliente original. Mouse físico/escuta não exercitados;
aceite visual do usuário permanece separado.

PCK177221220bytes:70checks/0/exit0 fora do projeto, comcatálogos,9janelas,
fonteASCII,captiondosbotões/fallback/CPU econtratosanteriores. Override ausente
do pacote e restaurado byte a byte. Aviso ambientalCA noPCK; import/export
também registramCA/editor_settings sem permissão. SemSCRIPT ERROR no final.
Semnovoapp/ZIP,versão,commit oupush; aplicativo exportado continua anterior.
