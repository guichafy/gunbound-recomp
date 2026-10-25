# SETTINGS: restaurar letras completas — 25/10/2026

Composição e alpha substituídos pela ADR-112, `ROOM_BUTTON_ALPHA.md`.
Arte e evidências abaixo preservadas como histórico da ADR-111.

REQ-02/12/19/20. Correção explícita posterior: usuário rejeitou o aspecto da
fonte daADR-110. Aquela versão recuperava cobertura e reconstruía preenchimento/
contorno; isso mudou o peso visual. Não usar essa derivação no catálogo ativo.

Plano: copiarRGBA dos glifos e contornos nativos, sem sintetizar cores ou
redesenhar traços. Usar a paleta somente para localizar a área de cada letra,
limpar fundo/vizinhos e alinhar a linha superior. Desenhar contornos primeiro
e superfícies depois evita que o contorno vizinho corte a letra. Ajustar só
junções/espaço, mantendoSTART aprovado e modal. Compor antes da ampliação
conservadora4×/alpha nearest; preservar PNGs anteriores, inclusive rejeitados.

`build_settings_word_original.py` produz74×20/quatro estados. Cada estado
copia suas próprias cores, incluindo hover/push/disabled. Verifica629pixels
do núcleo e3156pixels exclusivos de contorno comRGBA idêntico às fontes;
o acabamento não gera preenchimento nem novo contorno. Tipografia e cores
são das fontes nativas; montagem/junções são adaptação solicitada.

## Resultados

Implementado no registro ativo. NovoPNG nativo296×20 eHD1184×80 em
room_settings_word_complete; PNGs rejeitados anteriores preservados.
Gerador não sintetiza tinta nem dilata um novo traço: máscara serve somente
para retirar o fundo/vizinhos. Cópia direta das quatro fontes por estado;
cores, espessura e desenho completos mantidos fora das áreas de junção.
Contornos são compostos antes das superfícies para preservar hastes.

Validação:969checksGodot/0 em4suítes (modal39/0, sala162/0,UI172/0,
botões596/0). Quatro checks adicionais comparam a paleta nativa de cada
estado às fontes, impedindo retorno da reconstrução cromática anterior.
Gerador verifica629núcleos/3156contornos exclusivos porRGBA exato.

Revisão identificou4pixels do contorno do últimoS cortados no push. Versão
final calcula união das máscaras de todos estados e margens transparentes;
4364pixels de stencil são conferidos dentro dos limites antes da composição.
Atlas final74×20/quadro;629núcleos/3156contornos completos, revisão aprovada
após reproduçãoRGBA independente. Não usar a primeira versão72×19.

GPU1920×1080: START aprovadoRGBA idêntico, SETTINGS abre o modal, quatro
estados e fallback nativo capturados. Evidência:docs/settings-lettering-original;
logs.tools/room-contact/word-original-*. Não é execução do cliente original;
aceite visual do usuário permanece separado.

PCK177417104bytes,79checks/0/exit0 fora do projeto, incluindo alpha do rótulo,
fontes/estados/fallback eausência deoverride. Override restaurado byte a byte;
CA/editor_settings ambientais registrados, semSCRIPT ERROR final. Semnovoapp/
ZIP,versão,commit oupush.
