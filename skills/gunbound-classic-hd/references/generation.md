# Da referência clássica à arte de alta resolução

## Contrato de resolução

| Resultado pedido | O que medir antes de entregar |
|---|---|
| Imagem Full HD | Arquivo final1920×1080, composição no aspecto16:9 |
| Sprite/atlas transparente | Dimensões reais do arquivo e de cada recorte útil; nitidez na maior escala |
| Jogo com apresentação Full HD | Framebuffer/captura real1920×1080; dimensão lógica/física preservada |

Para um sprite desenhado até180px, um recorte de720px oferece densidade4×;
um atlas enorme com a figura ocupando80px não oferece a mesma qualidade.
4× é a referência prática validada, não obrigação universal: dimensões maiores
de EMP, zoom ou menu precisam ser avaliadas separadamente.

Pedir resolução no prompt não garante a dimensão devolvida pela ferramenta.
Leia o arquivo retornado. Se não corresponder ao contrato, conserve o bruto,
ajuste usando capacidades realmente disponíveis ou relate o limite. Não
declare um arquivo quadrado como1920×1080 e não estique a figura para caber.
Diferencie arte regenerada com novos detalhes de simples ampliação interpolada.

## Preparar referências

1. Meça atlas original: grade real, FPS/duração, direção, pivôs e contato.
   Inspecione quadros em tamanho nativo e ampliados, sem alterar a fonte.
2. Separe a referência de **identidade/pose** da referência de **acabamento HD**.
   Um mobile aprovado pode orientar materiais/luz, sem inserir suas peças no
   avatar. Preserve identidade específica e cores do traje.
3. Para um kit, prepare layout com células e margens explícitas; anote quais
   células devem permanecer vazias. Cabeças isoladas e corpos sem cabeça
   evitam duplicar anatomia ao vestir. Um piloto não modular pode ser inteiro.
4. Use um mestre constante por peça. Novas poses não devem redefinir olhos,
   rosto, comprimento dos braços, rodas ou chassis. Estados são transformações
   do mestre; chamas, aura e clarão são assets/camadas próprios.

## Prompt que funcionou para avatares

Adapte os objetos e layout reais; não preserve nomes de uma família por acaso.

```text
Uso: regenerar um kit de sprites clássicos para jogo, com acabamento HD.
Imagem1: fonte de identidade, silhueta, pose e layout.
Imagem2: referência de estilo somente; não copiar suas peças.
Reconstrua os objetos de imagem1 em ilustração2.5D polida, contorno escuro
limpo, volumes suaves, materiais nítidos e iluminação coerente do alto/esquerda,
mantendo rosto, roupa, cores, direção e proporções da referência clássica.
Kit2×2: superior esquerda cabeça/rosto olhando para a esquerda;
superior direita corpo sem cabeça, sentado, braços e pernas na pose da fonte;
inferior esquerda óculos isolados; inferior direita bandeira e haste isoladas.
Cada objeto totalmente dentro de sua célula, com margem transparente, sem
unir cabeça ao corpo, sem duplicar membros e sem acrescentar um veículo.
Fundo RGBA realmente transparente, sem texto, rótulos, chão ou sombra externa.
Melhorar detalhes e acabamento; preservar identidade e geometria.
```

Para a **imagem final Full HD**, acrescente o enquadramento1920×1080 solicitado,
com margens adequadas e sem esticar o assunto. Para atlas, peça o layout
medido; a validação de pixels úteis é mais relevante que o rótulo Full HD.

## Execução e registro

Use a ferramenta de imagens conforme suas instruções atuais. Ao usar GPT
Images, aplique a skill `imagegen` disponível: geração/edição integrada é o
fluxo padrão aprendido; CLI/API exige escolha explícita. Antes de editar uma
referência local, inspecione-a com `view_image`. Solicite transparência no
parâmetro da ferramenta e no prompt quando o asset exigir recorte.

Não invente argumentos de tamanho/modelo que a interface não suporta. Não
regere todas as variantes para corrigir um defeito localizado: ajuste uma
restrição e confira novamente identidade, posição e anatomia.

Armazene o bruto e o PNG selecionado sem sobrescrever a fonte clássica.
Registre prompt completo, ferramenta/modo, referência de identidade/estilo,
dimensões realmente obtidas, layout/células, hashes e destino final. Resultado
consumido pelo jogo deve estar no projeto, não apenas na pasta do gerador.

## Recorte e inspeção

Meça bounding box de alpha acima de um limiar que exclua ruído. O projeto
validou alpha>8/255; examine luz/halo semitransparente legítimo antes de aplicar
o mesmo valor em outro asset. Recorte/catalogue uma janela estável, preserve
padding e registre pivô. Não use o bbox de cada frame para mover a peça.

Confira sobre fundos claro/escuro, no tamanho de menu e de arena: halo,
serrilhado, corte de cabelo/arma, detalhes legíveis, transparência e aspecto.
Use filtragem linear/mipmaps para derivados e preserve nearest no fallback
pixel art quando apropriado. Compare composição clássica/HD com o mesmo
apoio, escala e sentido antes de julgar somente o acabamento.
