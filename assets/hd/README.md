# Derivados HD — GPT Images

Arte gerada com a ferramenta integrada GPT Images a partir dos assets Gunbound/
OpenBound fornecidos pelo usuário. Direção confirmada: aparência clássica com
detalhes mais nítidos. Os PNGs originais em assets/openbound não foram editados.
Estes derivados não são restaurações exatas dos quadros originais.

- bigfoot/mage: grades4×8 com32 quadros chave por mobile.
- rider: corpo/cabeça separados, grade4×2,8 quadros.
- shots: grade4×6;4 variações dos3 tiros por mobile.
- effects: grade6×6;6 fases por explosão.
- heroes: grade2×1, versões maiores de seleção, sem piloto embutido.
- emp: círculo MageSS em fonte dedicada1254×1254 para efeitos grandes.

Prompts completos em GENERATION.json. Dimensões reais, SHA256, grade e recortes
em atlas_regions.json. O gerador não garantiu os tamanhos solicitados no prompt;
estes são os arquivos efetivamente recebidos. Full HD se refere à apresentação
validada em1920×1080, não a exigir1920×1080 para cada pequeno sprite.

O leitor preserva pivôs/contatos, tamanho arena60/menu180 e offsets do piloto,
usando a área visível do quadro original como destino. Duração/FPS/estados são
os antigos, com seleção proporcional dos novos quadros chave; há menos imagens
distintas por ciclo. Saúde baixa escurece o sprite HD. Sons continuam originais.
Ausência de um derivado usa automaticamente seu sprite original.

Recortes são metadados: scripts/catalog_hd_assets.py lê alpha>8/255 para ignorar
ruído quase invisível da geração; não altera pixels nem aumenta PNGs por escala.
Regenerar o catálogo ao substituir um PNG. A exportação inclui atlas_regions.json.
Fonte/proveniência dos originais: ../openbound/ATTRIBUTION.md.
