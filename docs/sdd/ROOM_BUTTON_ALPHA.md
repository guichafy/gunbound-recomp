# Alpha e composição dos botões da sala — 25/10/2026

Composição da palavra refinada pelaADR-113, `SETTINGS_WORD_FINISH.md`.
Casca/alpha eSTART aprovados desta etapa permanecem iguais.

REQ-02/12/19/20. Pedido posterior à ADR-111: remover os retângulos visíveis
fora da silhueta dos botões e melhorar SETTINGS comparando com START.

Causa observada: STARTGAME nativo tem alpha255 em todos os pixels, incluindo
cenário gravado nos cantos. O renderer recompunha a casca mas o TextureButton
ainda recebia essa imagem opaca. SETTINGS também incluía parte do X no
recorte do I e usava T de EXIT, com peso diferente do T de START.

Plano: gerar casca azul limpa, sem texto/seta, com alpha recortado somente
fora do contorno preto; usá-la nas quatro texturas reais do TextureButton.
Preservar o raster de START e seu posicionamento. Para SETTINGS, usar T do
próprio START e limitar cada janela à letra correta, com baseline e espaços
coerentes. Copiar as cores/traços nativos; não substituir a fonte nem criar
um preenchimento novo. Compor antes da ampliação BICUBIC4× conservadora.

Preservar fontes e derivados anteriores. Conferir alpha dos quatro estados,
fallback, cliques e captura real lado a lado em fundo de sala. Aceite visual
do usuário separado dos checks. Sem app/ZIP, versão, commit ou publicação.

## Resultado observado

Casca ativa `room_footer_shell_clear`,107×45/quadro, recorta apenas o
exterior do contorno preto; o alpha é igual nos quatro estados. Texto/setas
não entram na casca. TextureButton recebe as imagens transparentes reais,
sem um sprite opaco desenhado pelo controle por baixo do desenho customizado.

SETTINGS ativo `room_settings_word_isolated`,83×20/quadro, copiado das
superfícies nativas. Letras com3px de separação entre caixas de face, topo
do núcleo em18 no botão como START. Componente8-conexa isola cada glifo
antes do contorno e elimina os3pixels do A seguinte em cada T.1436pixels
de face têmRGBA exatamente igual à fonte correspondente. Não há nova fonte,
reconstrução de tinta ou traço. Ampliação conservadora4×/alpha nearest.

Regressão inicial reproduziu8falhas: quatro cantos opacos em cada botão.
Verificação final:1344checksGodot/0 em8suítes de sala, entrada, itens, roster
e botões. GPU1920×1080 confirma fundo real nos cantos, letteringSTARTRGBA
idêntico ao aprovado e clique abre modal. Quatro estados e fallback da
palavra capturados. Evidências em `docs/room-button-alpha`; fonte e hashes
em `source-isolated.json`. Falhas intermediárias de margem e do script de
captura foram corrigidas antes da rodada final. Revisão da composição
inclui a inspeção semântica das janelas; paleta/hash sozinhos não detectavam
o fragmento do A no T.

Revisão final aprovada após remoção desses fragmentos. PCK isolado de
177729532bytes validado fora do projeto:96checks/0,exit0, semoverride e com
os cantos transparentes conferidos nas texturas empacotadas. Exportador
restaurou override byte a byte. CA e gravação de editor_settings registram
limitações ambientais, semSCRIPT ERROR no probe final.

Não é execução do cliente original nem aceite visual do usuário. App já
exportado continua anterior; não houve novo app/ZIP, versão ou publicação.
