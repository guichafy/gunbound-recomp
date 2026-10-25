# Restauração com ferramenta de imagens

Para melhorar nitidez/suavizar raster existente, o padrão é o procedimento
determinístico de [conservative.md](conservative.md). Este documento trata
da geração/edição solicitada, e do modo separado de pixels exatos. Não
encaminhe a suavização aprovada a um gerador nem imponha o prompt estrito
de preservação de cada pixel a uma interpolação bicúbica autorizada.


## Preparar o contrato

1. Inspecione o arquivo fonte em tamanho nativo e ampliado. Registre caminho,
   SHA-256, dimensões, modo e extremos do alpha. RGBA pode ser totalmente opaco;
   extensão PNG e modo RGBA não comprovam transparência.
2. Para atlas, obtenha grade, janelas/células, ordem, quadros vazios e tempos
   nos metadados existentes. Registre a origem desses dados. Não confunda
   quantidade de células com quantidade visual de estados preservados.
3. Calcule o alvo: `(4 × largura, 4 × altura)`. Cada coordenada, margem e
   célula acompanha o mesmo fator. Não recentralize objetos por bbox.
4. Guarde o original intacto. Candidatos/brutos ficam em diretório separado,
   fora do runtime até integração solicitada e aceite.

| Fonte | Contrato |
|---|---|
| Imagem comum | Mesmo conteúdo, aspecto, enquadramento e fundo |
| Atlas/sprite sheet | Arquivo inteiro, mesmas células/ordem/posições e estados |
| Pixel art | Se exigidos pixels idênticos, nearest; se pedida suavização, usar conservative.md |
| Efeito/transparência | Mesmo alpha e emissão/sombra; sem luz extra ou halo |
| UI com texto | Letras, ícones e espaços originais; não redesenhar tipografia |

## Prompt e ferramenta

Carregue [restoration-prompt.txt](restoration-prompt.txt): é o prompt completo
fornecido pelo usuário, sem instruções concorrentes de acabamento. Acrescente
apenas um contrato factual, por exemplo:

```text
SOURCE CONTRACT: Source 428x45, fully opaque. Target 1712x180.
FOUR horizontal frames of 107x45, in order ready, mouse, push, disable.
Preserve CREATE in all four frames, the hand icon, borders and grey disabled
state. Preserve exact wide aspect ratio; do not introduce transparency.
```

Envie somente a imagem fonte desse asset. Não envie outro HD como acabamento,
não peça volumes suaves, reconstrução, materiais polidos, novo contorno,
iluminação do alto/esquerda, margens extras ou arte 2.5D. Esses comandos da
versão anterior foram substituídos para restauração. Um pedido explícito de
redesign é outro contrato; identifique o resultado como adaptação.

Use a ferramenta de imagens disponível e suas instruções atuais. No fluxo
integrado de GPT Images, aplique `imagegen`, inspecione o arquivo local com
`view_image` e use a referência local no modo de edição suportado. Peça fundo
transparente apenas quando a fonte o tiver, preservando as regiões opacas.
Fonte opaca deve continuar opaca; não remover preto por chave de cor.

Não invente parâmetros de tamanho/modelo. Um alvo escrito no prompt não
garante dimensões exatas. Se a ferramenta não suportar o aspecto/resolução,
registre o limite. Não complete com padding, corte ou esticamento e não
remonte frames gerados isoladamente como se o atlas inteiro tivesse passado.

## Validação técnica e visual

Use `python3 scripts/validate_restoration.py FONTE CANDIDATO --scale 4`
na pasta da skill, com `--columns N --rows M` para uma grade uniforme conhecida.
Requer Pillow. `--report caminho.json` preserva as medidas. O script não edita
imagens nem aprova fidelidade. Metadados não uniformes exigem comparação com
as janelas originais, sem inventar uma grade uniforme.

O relatório distingue falhas técnicas de revisão visual pendente:

- Dimensões e aspecto reais, integridade da grade e alpha opaco preservado.
- Alpha comparado com a fonte ampliada em nearest, sem tolerância nos bytes:
  alteração de cobertura/opacidade, mesmo halo abaixo de8, reprova. É um
  contrato conservador de alpha; não aprova suavização nova de bordas.
- RGB visível reduzido à escala nativa, bboxes e medidas por célula como
  diagnóstico. Erro médio baixo não prova detalhe, registro ou texto.
- A grade mede onde deveriam existir estados. Inspecione todos: faltas,
  duplicações, troca de ordem, corte, vazamento e efeitos específicos.

Quando o contrato exigir cores/pixels **exatamente** preservados, acrescente
`--exact-pixels`. O checker compara todos os pixels RGBA na resolução integral
com a fonte ampliada por repetição inteira; qualquer mudança reprova. Consulte
`pixel_replication_verified` e a contagem `rgba_changed_pixels` por célula.
A média RGB na escala nativa sozinha pode esconder mudanças que se anulam.
O modo estrito inclui RGB escondido por alpha0, por ser uma comparação exata
dos dados RGBA, enquanto a métrica de aparência ignora RGB invisível.

Compare lado a lado no mesmo enquadramento e escala; examine também o tamanho
de uso e fundos claro/escuro para alpha. Não desloque a comparação para melhorar
a coincidência. Alpha zero pode guardar RGB irrelevante; não conte esse RGB
como erro visual.

Rejeite silhueta, geometria, expressão, paleta, sombra, textura, texto ou estado
alterado, mesmo se a dimensão for exata. Preserve ambiguidades. Não use a
resolução maior como evidência de fidelidade. Quando necessária uma animação,
revise sequência, tempos e pausa: quadros isolados não comprovam continuidade.

Para exigência de pixels estritamente preservados, uma ampliação determinística
é a alternativa conservadora, identificada como tal; ofereça-a se a geração
falhar. Não a apresente como restauração neural nem como detalhe recuperado.

## Ampliação exata aceita pelo usuário

Quando o usuário pedir repetição de pixels/nearest ou já aceitar este método,
execute a ampliação sem outro pedido de confirmação. O script usa nearest em
escala inteira: cada pixel RGBA original vira um quadrado4×4 da mesma cor.
Texto, estados, espaços e bordas são preservados por construção. Ele exige
PNG estático, saída PNG nova e não sobrescreve fonte nem destino existente.
Pillow é a única dependência; perfis ICC/gAMA/sRGB/cHRM comuns são preservados.

Na pasta da skill:

```sh
python3 scripts/upscale_exact.py /caminho/fonte.png /caminho/saida-4x.png --scale 4
python3 scripts/validate_restoration.py /caminho/fonte.png /caminho/saida-4x.png --columns 4 --exact-pixels --report /caminho/relatorio.json
```

Use a grade medida, não o4do exemplo para qualquer atlas. Confira dimensão,
`pixel_replication_verified=true`, zero `rgba_changed_pixels` em todas as
células e o PNG no visualizador. Não introduza blur, sharpen, remoção de fundo
ou ajustes de paleta depois. O modo preserva os pixels e o aspecto pixelado;
resolução4× não significa novos detalhes. A revisão visual do usuário continua
separada da comprovação exata dos dados. Não continue regenerando por IA uma
saída cujo objetivo já foi atendido por repetição autorizada.

## Registro e entrega

Guarde bruto, prompt completo, ferramenta/modo, referência única/hash,
dimensões alvo/reais, alpha, grade e parecer por candidato. Não sobrescreva
originais ou normalize um bruto rejeitado para ele parecer conforme.

Classifique: **rejeitado**, **pendente de inspeção/aceite** ou **aceito** com
evidência. Informe limitações de resolução e diferenças observadas. A frase
“Return only [...] image” é a instrução ao gerador; não suprime relatório
solicitado de implementação da skill ou validação.

Integração solicitada exige registro/catálogo, fallback, inspeção no consumidor
real e regressões pertinentes. O alvo de 4× não muda dimensões lógicas, pivôs,
hitboxes ou regras. Uma composição Full HD é 1920×1080; um atlas estreito
preserva seu próprio aspecto e não precisa virar 16:9.
