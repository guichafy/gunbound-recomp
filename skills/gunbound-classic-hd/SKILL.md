---
name: gunbound-classic-hd
description: "Use quando a tarefa envolver ampliar ou suavizar imagens, botões, sprites e atlas Gunbound Classic/OpenBound em HD/4×, validar fidelidade/alpha/quadros, animar mobiles/avatares ou corrigir tremor, anatomia, proporção e encaixe."
---

# Gunbound Classic: ampliação conservadora e animação

Preserve o desenho clássico, geometria, enquadramento, estados e registro.
Para melhorar nitidez de uma imagem existente com contornos mais suaves, o
padrão é **suavização bicúbica conservadora4× por quadro**, sem redesenhar.
Ela interpola tons vizinhos; não recupera detalhes ausentes nem preserva os
pixels/cores exatamente. Originais e derivados aprovados ficam preservados.

## Escolher o método e escopo

| Pedido | Procedimento |
|---|---|
| Melhorar definição/suavizar arte existente | [Ampliação conservadora](references/conservative.md) |
| Preservar cada pixel e cor exatamente | `upscale_exact.py`, nearest inteiro |
| Gerar arte ou redesign explicitamente pedido | [Geração e prompt](references/generation.md) |
| Corrigir animação/encaixe de arte já boa | [Registro e movimento](references/animation.md) |

Imagem/prévia não autoriza integração ou lote. Integração solicitada inclui
catálogo, fallback e testes; não muda combate, perfil ou geometria lógica.
Aprovação de um acabamento vale para o escopo autorizado: não peça novamente
permissão para aplicar o método que o usuário já escolheu.

## Suavizar conservadoramente

Leia [conservative.md](references/conservative.md). Use a fonte nativa, não
um PNG já ampliado. Meça grade/células/ordem/pivôs. Na pasta da skill:

```sh
python3 scripts/upscale_conservative.py FONTE.png SAIDA.png --scale 4 --columns N --rows M
python3 scripts/validate_restoration.py FONTE.png SAIDA.png --scale 4 --columns N --rows M --report medidas.json
```

Cada quadro é filtrado isoladamente com BICUBIC e recolocado nas coordenadas
originais×4. Alpha mantém cobertura/valores via nearest; RGB transparente é
tratado em espaço pré-multiplicado para evitar vazamento. Sem padding, crop,
reposicionamento, sharpening, luz nova ou mistura entre estados.

Conserve anatomia, letras, contornos e intensidade dos efeitos. Compare todos
os estados no tamanho de uso: suavidade não basta se o texto perde legibilidade.
Para efeitos/transparência e grades não uniformes, confira janelas e camadas
nativas; o helper só aceita grade uniforme. Não invente FPS, poses ou recortes.

## Pixels exatos e geração

Quando o pedido exigir pixels/cores idênticos, use:

```sh
python3 scripts/upscale_exact.py FONTE.png SAIDA.png --scale 4
python3 scripts/validate_restoration.py FONTE.png SAIDA.png --exact-pixels
```

Esse modo conserva os degraus do pixel art. Não use `--exact-pixels` para
julgar BICUBIC, que altera RGB intencionalmente. Evite geração para limpeza
de raster: ela pode mudar símbolos, letras, cores e margens. Para geração
solicitada, use a ferramenta de imagens disponível e suas instruções atuais;
[restoration-prompt.txt](references/restoration-prompt.txt) é referência desse
modo, não substitui o procedimento determinístico aprovado.

## Integrar e validar

Dimensões reais devem ser4× por eixo, com a mesma grade e aspecto. Full HD é
uma composição1920×1080; atlas mantém seu aspecto. Registre fonte/hash, método,
parâmetros, dimensões, catálogo e limites. Métricas não substituem inspeção.

No jogo, multiplique apenas recortes da textura pela densidade; tamanho lógico,
pivôs, alinhamento e hitboxes ficam iguais. Confira estados, cliques, fallback
e render real; se entregar app, reexporte e confira o pacote.

Rig existente usa peças/pivôs/relógios contínuos. Atlas fiel conserva poses e
quadros; um mestre único não substitui a animação original. Para brilho preso
à anatomia em HD aprovado, leia [effects.md](references/effects.md). No Gunbound
Recomp, consulte o [mapa do projeto](references/demogame.md).
