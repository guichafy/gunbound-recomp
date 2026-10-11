# Derivados HD — GPT Images

Arte gerada com a ferramenta integrada GPT Images a partir dos assets Gunbound/
OpenBound fornecidos pelo usuário. Direção confirmada: aparência clássica com
detalhes mais nítidos. Os PNGs originais em assets/openbound não foram editados.
Estes derivados não são restaurações exatas dos quadros originais.

- bigfoot/mage: atlas anteriores 0.6, preservados para histórico, inativos no render dos mobiles.
- rider: corpo/cabeça separados, grade4×2,8 quadros.
- shots: grade4×6;4 variações dos3 tiros por mobile.
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
mesmo conjunto no menu/arena. Uma cabeça e corpo do rider são usados, sem
trocar rosto/proporções. Rodas conservam fase ao parar. Auras/clarão são camadas
separadas. Morte tem colapso/fade do mesmo corpo; não reproduz os destroços
quadro a quadro do original. Saúde baixa escurece a peça HD; sons/combate
preservados. Ausência de peça/piloto/catalogo válido usa atlas/piloto originais
como um conjunto inteiro, sem misturar estilos. Tiros/Fx continuam o pipeline0.6.

Recortes são metadados: scripts/catalog_hd_assets.py lê alpha>8/255 para ignorar
ruído quase invisível da geração; não altera pixels nem aumenta PNGs por escala.
Regenerar o catálogo ao substituir um PNG. A exportação inclui atlas_regions.json.
Fonte/proveniência dos originais: ../openbound/ATTRIBUTION.md.
