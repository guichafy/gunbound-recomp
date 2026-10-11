# Derivados HD — GPT Images

Arte gerada com a ferramenta integrada GPT Images a partir dos assets Gunbound/
OpenBound fornecidos pelo usuário. Direção confirmada: aparência clássica com
detalhes mais nítidos. Os PNGs originais em assets/openbound não foram editados.
Estes derivados não são restaurações exatas dos quadros originais.

- bigfoot/mage: atlas anteriores 0.6, preservados para histórico, inativos no render dos mobiles.
- rider: corpo/cabeça anteriores, preservados como histórico, inativos no rig HD.
- shots: grade4×6 anterior; somente recortes constantes das chamas T1/SS são ativos.
- effects: grade6×6;6 fases por explosão.
- heroes: referência artística HD anterior, preservada; menu agora monta as mesmas peças da arena.
- emp: círculo MageSS em fonte dedicada1254×1254 para efeitos grandes.

Prompts completos em GENERATION.json. Dimensões reais, SHA256, grade e recortes
em atlas_regions.json. O gerador não garantiu os tamanhos solicitados no prompt;
estes são os arquivos efetivamente recebidos. Full HD se refere à apresentação
validada em1920×1080, não a exigir1920×1080 para cada pequeno sprite.

Em 0.6.1, mobile_parts.png é uma única fonte constante por peça:
Bigfoot chassis/canhão/roda; Mage corpo/cajado. 1536×1024 RGBA, seleção 3×2
com última posição vazia. As peças avançam um pouco além da grade solicitada;
recortes por janelas reais x0–570/570–1040/1040–1536, y0–512/512–1024,
preservam contornos completos. O brilho visível em alguns visualizadores no
RGB vazio tem alpha0; não é fundo desenhado no jogo. Nenhum PNG foi editado
por código. Prompts desta correção em ANIMATION_PROMPTS.md.

mobile_rig.gd usa medidas constantes/âncoras fixas e transformações contínuas;
mesmo conjunto no menu/arena. Em0.6.1, uma cabeça e corpo do rider eram usados;0.6.2 substitui por figura
completa pilot_seated.png, sem remontar anatomia. Rodas conservam fase ao parar. Auras/clarão são camadas
separadas. Morte tem colapso/fade do mesmo corpo; não reproduz os destroços
quadro a quadro do original. Saúde baixa escurece a peça HD; sons/combate
preservados. Ausência de peça/piloto/catalogo válido usa atlas/piloto originais
como um conjunto inteiro, sem misturar estilos. Tiros/Fx usam o pipeline contínuo0.6.2 descrito abaixo.

Recortes são metadados: scripts/catalog_hd_assets.py lê alpha>8/255 para ignorar
ruído quase invisível da geração; não altera pixels nem aumenta PNGs por escala.
Regenerar o catálogo ao substituir um PNG. A exportação inclui atlas_regions.json.
Fonte/proveniência dos originais: ../openbound/ATTRIBUTION.md.

Em0.6.2: pilot_seated.png1254×1254 RGBA é um único piloto coeso; cabeças de tiros
projectile_heads.png1536×1024 RGBA em grade3×2, BigfootT1/T2/SS e MageT1/T2/SS.
Prompts/origens em PILOT_SHOTS_PROMPTS.md e GENERATION.json. Uma cabeça constante
por tiro preserva aspecto. Chamas t1_flame/ss_flame vêm de componentes do
shots.png preservado. Laser usa trail contínuo, orbe/EMP overlays contínuos;
impactos fazem blend6fases/envelope com centro/duração fixos. Ausência de textura,
catálogo ou recortes válidos usa original. Prévia GPU em docs/projectiles.
Adaptação artística, não restauração quadro a quadro nem garantia de igualdade
com Gunbound. Full HD é o framebuffer de validação, fontes têm dimensões reais.

Composição0.6.3 conserva esses PNGs intactos e recalibra o rig pelas proporções
do piloto/veículo original. Altura do piloto54/57 contra base60, canhão e rodas
menores, novo assento/sobreposição; piece preserva aspecto de cada peça.
Prévia/comparação GPU em docs/composition; tiros0.6.2 preservados.

0.6.4 usa pilot_side.png: edição GPT Images com perna distante inteiramente
oculta, resto do mestre preservado. Registro271/153/703/977 contém a figura sem
corte, mantendo padding esquerdo da fonte anterior para preservar encaixe.
Prompt/origem em SIDE_PILOT_PROMPT.md/GENERATION.json. PNGs anteriores intactos.
Prévia montada em docs/occlusion.

Mapa0.8 (Miramo Town A): `maps/miramo_town/source/` guarda os blocos GPT Images
brutos (3 do foreground 1536×1024, fundo 1024×1536), intactos e com `.gdignore`
(não importados nem exportados). `scripts/build_map_hd.py` gera
`foreground_a.png` 2560×661 (2× arena) com alpha = máscara original ampliada e,
quando os dois blocos existirem, `background.png`. `manifest.json` registra
SHA-256 de blocos, originais e saídas. A colisão vem sempre do ForegroundA
original; o HD é só visual. Prompts em MAP_PROMPTS.md.
