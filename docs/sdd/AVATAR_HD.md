# Avatar HD — REQ-20/39

Pedido: melhorar qualidade e aproximar visual dos mobiles HD existentes.
Derivados GPT Images, mantendo os PNGs originais e a montagem corrigida0.14.1.

Escopo:13peças visíveis das quatro categorias, agrupadas por conjunto
Space Marine (cabeça/corpo/óculos/bandeira), Basic masculino/feminino, Miner,
Punk e Kappa. Sem catálogo/preço novo ou alteração de perfil/combate.

Pipeline: gerar peças constantes transparentes no estilo polido2.5D dos mobiles;
recortes em metadados, janela nativa de referência e pivôs preservados. O render
usa mesma escala/montagem e calendário do original; pequenos deslocamentos
vêm dos quadros originais. HD constante evita deformações da anatomia entre
quadros gerados; fallback original completo por peça quando derivado faltar.
Retratos da loja usam as mesmas peças HD para consistência. Flags/gestos usam
os quadros originais para o deslocamento; isso não é restauração quadro a quadro.

Plano: referências sem edição de arte (extração/empacotamento dos PNGs fonte),
5gerações GPT Images de folhas transparentes; inspeção/catálogo com hashes e
origem, teste de geometria/fallback, integração AvatarArt/portraits, captura
GPU inventário/poses, suites pertinentes e export/assinatura atualizados.

## Geração e integração observadas

Cinco folhas GPT Images pela ferramenta integrada image_gen, cada uma1254×1254
RGBA. Prompts completos, origens exec-*.png e modo em assets/hd/avatars/GENERATION.json;
referências empacotadas em source (fora do import/export por .gdignore).
Nenhuma edição nos PNGs originais. Regiões alpha>8/255, pivôs e quadros nativos
em catalog.json (scripts/catalog_avatar_hd.py regenera metadados sem editar pixels).

AvatarHD valida catálogo/texturas/regiões/deslocamentos e oferece fallback.
Aspecto da imagem gerada preservado dentro da janela opaca nativa; a posição
normalizada do pivô é mantida ao ajustar o tamanho. AvatarArt reutiliza o relógio
e pequenos deslocamentos do original com peças fixas; gestos/olhos não são
redesenhados quadro a quadro. Loja usa retratos dessas mesmas peças. Mipmaps e
filtragem linear dão nitidez nas escalas de menu/arena.

Testes RED→GREEN para módulo ausente, deslocamento inválido, proporção e card
com retrato HD além do limite. Capturas GPU inventory/poses/hd-comparison/hd-roster
conferem encaixe e estilo. App0.14.2 exportado após as alterações.

Resultado final:139checks HD,1454checks no harness quick, zero falhas;
GPU de6famílias, inventory/poses e comparação original/HD conferidas. App0.14.2
com assinatura estrita válida e smoke do PCK PASS (avatar2313pixels); ZIP101MB.

## Correção de continuidade0.14.4

ADR-063 substitui os deslocamentos de silhueta descritos acima: o registro HD
agora é constante nos22quadros. Animar centros de bbox movia cabeça/corpo
independentemente. O conjunto respira por transform contínuo, e mudanças de
pose do mobile são interpoladas por ator. Metadados originais/fallback e PNGs
permanecem preservados. Ver AVATAR_SMOOTH_0_14_4.md e vídeo GPU em
`docs/avatar-motion/motion.mp4`; o HD continua sem reanimar olhos/gestos nativos.
