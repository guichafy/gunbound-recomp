# Sala: dificuldade, contadores e START — 25/10/2026

REQ-02/12/19/20. Pedido posterior àADR-107: dificuldade ao lado deCPU no
card da máquina; números do clima brancos com fundo transparente; START
com o mesmo acabamento deEXIT/CHANGE.

Plano:
- Reutilizar o rótulo daCPU para `CPU · <dificuldade>` e atualizar somente
  ao aceitar configurações. Remover dificuldade do painel central.
- Os oito poços escuros são pixels de ready_back, não fundo dosLabels.
  Restaurar o laranja do painel sobre esses poços usando uma amostra limpa
  da própria textura ativa. Labels permanecem transparentes/brancos;
  ícones, valores, grade e demais pixels do fundo permanecem preservados.
- Usar b_ready_startgame.img/epa: quatro estados107×45,0/1/2/3; fonte do
  cliente já identificado emROOM_CARD_FIDELITY.md. START verde anterior
  preservado. NovoPNG nativo e4×BICUBIC/alpha nearest; integrar no catálogo
  compartilhado deChrome, alinhar emy552 comEXIT/CHANGE, manter açãoStart.
- Regressão de configuração/cancelamento/cliques/estados/fallback, captura
  GPU1920×1080 e conferência dos oito fundos, registrosSDD.

Sem mudança de regras/dificuldades, perfil, versão, app, commit ou publicação.

## Resultados

Implementado: `CPU · Normal` (ouLeve/Precisa) fica em503,172 no card da
máquina. Aceitar atualiza o texto; rascunho eCancelar preservam a dificuldade
confirmada. O painel central mantém somente a informação de clima.

Labels dos oito pesos continuam brancos e transparentes. Poços do fundo
original são cobertos em retângulos15×17 por uma amostra laranja limpa
(321,163) da textura ativa, respeitando densidade4×/fallback nativo. Cor nativa
RGB238,153,65. NenhumPNG do fundo foi editado e nenhum ícone foi alterado.
O pixel de amostra é constante; não se trata de transparência noPNG original.

START azul usa os quatro quadros originais107×45 deSTARTGAME eEPA correspondente,
com o mesmo processamento conservador dos demais botões. Posição660,552,
altura igual aEXIT/CHANGE. Catálogo compartilhado agora tem43registros;
START verde e42registros/PNGs anteriores permanecem. Extrator geral inclui
STARTGAME; `import_classic_start.py` acrescenta somente esse recurso e recusa
sobrescrever imagens/relatórios. Comparação independente:4quadrosRGBA e4alpha
nearest corretos,42registros nativos/HD e222PNGs rastreados anteriores intactos.

TDD:14falhas iniciais dos novos critérios. Regressão7suítes:1286checks/0;
repetição final de sala/botões após ajuste de metadados:752/0.21testesPython
da skillHD aprovados. Comando principal: `./scripts/check.sh test_room_polish
test_room_ui test_room_reference test_classic_buttons_hd test_scene
test_items_scene test_roster`. Revisão independente aprovada, sem pendências.

GPU real1920×1080,OpenGL/Metal AppleM4Pro:17escolhas/24quadros,20variações,
âncoras fixas/heldtime idêntico; oito amostras sem texto confirmam o laranja
em vez dos poços escuros. CapturasNormal/Precisa e três estados adicionais
doSTART inspecionados. Evidência emdocs/room-final-polish; logs locais em
.tools/room-contact/finish-*. Não é execução dinâmica do cliente original.
Mouse físico/escuta e aceite visual do usuário permanecem separados.

PCK local177003440bytes:55checks/0/exit0, executado com--path/private/tmp fora
do projeto. Confere catálogo/estadosSTART,CPU/dificuldade e oito baseslaranja,
além dos contratos daADR-107. Override ausente do pacote e restaurado byte a
byte no projeto. Aviso ambientalCA noPCK; import/export também registram erro
deeditor_settings sem permissão. SemSCRIPT ERROR. Semapp/ZIP,versão,commit ou
publicação.
