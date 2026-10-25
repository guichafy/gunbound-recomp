# Ampliação conservadora por quadro

Use para melhorar uma imagem clássica existente com contornos mais suaves,
preservando seu desenho. É o acabamento aprovado para botões Gunbound:
BICUBIC4×, sem redesenho por IA, luz nova ou sharpening. Tons vizinhos são
interpolados; não anunciar cores/pixels idênticos ou detalhes recuperados.

## Receita reproduzível

1. Inspecione a fonte nativa. Registre SHA-256, dimensões, modo/alpha e
   metadados da grade, estados, ordem, janelas e pivôs. Use as medidas reais.
2. Processe cada quadro isoladamente a partir da fonte. Não filtre o atlas
   inteiro em uma passagem: cores de estados vizinhos podem se misturar.
3. Use BICUBIC em RGBA pré-multiplicado. Preserve o canal alpha ampliado por
   nearest, incluindo opacidades parciais. Não aplique alpha outra vez ao
   montar o atlas; isso escureceria componentes semitransparentes.
4. Recoloque cada quadro em `(coluna × largura × escala, linha × altura × escala)`.
   Arquivo, células, margens e pivôs acompanham o mesmo fator. Sem espaços novos.
5. Grave um PNG novo e registre o método. O helper preserva metadados comuns
   ICC/gAMA/sRGB/cHRM; nunca converte a imagem para JPEG ou remove preto por cor.

Na pasta da skill, com Pillow disponível:

```sh
python3 scripts/upscale_conservative.py fonte.png saida-suave.png --scale 4 --columns 4 --rows 1
python3 scripts/validate_restoration.py fonte.png saida-suave.png --scale 4 --columns 4 --rows 1 --report medidas.json
```

O exemplo descreve quatro células horizontais; informe a grade observada.
PNG estático pode conter um atlas; APNG/animação de arquivo não é suportado.
Fonte/destino devem ser diferentes e o destino não pode existir. O helper
recusa dimensões não divisíveis pela grade. Janelas não uniformes precisam
de processamento pelas janelas originais, não de uma grade inventada.

## Validação correta

- Tamanho/aspecto4×, número/ordem/posição dos estados, sem padding/corte.
- Alpha equivalente à fonte ampliada em nearest; sem halos ou contaminação.
- Desenho, símbolos, texto, contraste e tons principais reconhecíveis na
  comparação lado a lado e no tamanho real. Inspecione todos os estados.
- RGB muda intencionalmente. `pixel_replication_verified=false` é esperado;
  `--exact-pixels` pertence ao modo de repetição, não a esta suavização.
- Preserve fonte e último derivado aprovado. Faça prévia representativa se
  o acabamento ainda não foi validado; respeite aprovação já dada ao lote.

Para botões integrados, o catálogo deve registrar origem, método, escala,
dimensões, células/estados, hashes e consumidor. Recortes de textura usam
densidade4; layout lógico, áreas de clique e estados não mudam. Teste os
consumidores reais e fallback, incluindo JSON/PNG no pacote exportado.

Para sprites/efeitos translúcidos, a cobertura alpha permanece clássica;
avaliar também luz aditiva, camadas e registro. Não confundir suavização de
RGB com autorização para expandir a silhueta ou alterar opacidade/pulsação.
Se for exigida preservação de cada pixel/cor, use `upscale_exact.py`.

Relatórios também usam um destino novo. O verificador recusa sobrescrever
fonte, candidato ou relatório existente; escolha outro nome para uma nova rodada.
