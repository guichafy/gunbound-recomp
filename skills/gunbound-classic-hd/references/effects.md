# Efeitos presos à anatomia: brilho, aura e contorno

Use este fluxo para corrigir efeito sobre uma peça HD já aprovada ou numa
adaptação solicitada. Na restauração fiel de imagem/atlas inteiro, preserve
o efeito e o alpha da própria fonte, sem derivar uma composição nova.

Aprendido no brilho do chifre do Great Devil Head (três tentativas rejeitadas
antes do aceite: luz gerada à parte deslocada, halo atrás imperceptível e
meia-lua entortada por malha UV). A forma correta veio do próprio chifre HD.

## Classifique o efeito clássico antes de gerar

Abra a camada de efeito sobre a peça base, na mesma janela nativa, ampliada
em nearest. Pergunte: a forma do efeito **é a silhueta da anatomia**?

| Tipo | Exemplo | Como fazer o HD |
|---|---|---|
| Silhueta da peça (brilho, contorno luminoso, aura colada) | chifre, coroa, joia que acende inteira | Derive da máscara do mestre HD; não gere |
| Emissor independente | cone de lâmpada, halo flutuante, faísca, chama | Gere como camada própria e registre por âncora |

Um efeito gerado à parte nunca coincide com a anatomia HD, que também foi
regenerada. Entortar ou ancorar esse PNG (UV, nós, `base_uv`) só desloca o
erro: pontos de teste "tocam" a peça e mesmo assim a forma fica errada.

## Meça o clássico como o motor o mostra

Converta o efeito como o render faz (camada L do XFS: alfa × canal mais
claro) antes de medir. Registre:

- alfa do núcleo e rampa por pixel nativo para fora da peça;
- razão entre a área do efeito acima de alguns limiares (ex. 20/90/160) e a
  área da peça, contorno incluso;
- fração da energia do efeito que cai sobre a peça;
- cores do núcleo e da franja.

Calibre o HD por essas razões, não pela opacidade média: a média muda com a
resolução e a proporção da borda, e isso já tornou um brilho imperceptível.
Medida do chifre: núcleo 187/255, rampa ~4 px nativos, 1,81/1,43/0,98× e 71%.

## Receita da máscara derivada

1. Selecione a cor característica da peça na janela da base HD (ouro
   saturado: excluir pele, cabelo e contorno escuro), limitada à região dela.
2. Feche os sulcos (dilatar e erodir) **antes** de escolher o maior
   componente; sulcos de segmento separam a peça em ilhas.
3. Preencha furos e some o contorno escuro, que o núcleo clássico cobre.
4. Adicione margem ao redor: a borda não pode ser cortada onde a peça toca a
   janela (ponta, nuca).
5. Borda = máscara crescida + desfoque, ajustados por busca curta até as
   razões baterem com o clássico. Asse o alfa no PNG; mantenha o canal mais
   claro em 255 se o render multiplicar alfa pelo brilho.
6. Gere por script determinístico, salve como PNG novo (originais e masters
   intactos) e guarde os parâmetros e a origem nos metadados.

Registre o efeito derivado **na janela da peça base** (mesma origem e escala,
deslocamento só da margem) e desenhe por cima quando o clássico desenha por
cima. Não use a janela nativa nem âncora UV do efeito antigo. Valide tamanho,
deslocamento e opacidade; qualquer desvio cai no fallback original inteiro.
Preserve relógio e pulsação já aprovados; mude só forma e posição.

Isso é exceção ao fluxo GPT Images e deve ser dito ao usuário: a arte da
peça continua gerada; o efeito vem dela para coincidir por construção.

## Aceite que prova o pedido

- RED primeiro: a métrica nova falha no estado antigo.
- Cobertura: ≥98% dos pixels da peça HD com alfa do núcleo (ponta incluída).
- Vazamento: zero em pontos de rosto/cabelo fora da borda.
- Visibilidade: pulso pico/vale na prévia real (loja Avatar/Mobile) não
  menor que o estado anterior aprovado; isole o efeito por um campo de
  opacidade do registro, não por um campo que o novo caminho ignora.
- GPU 1920×1080/60fps: clássico em nearest, estado anterior e novo na mesma
  escala; dois sentidos, inclinação e pausa com quadros idênticos.
- Olho do usuário é o critério final; entregue as imagens lado a lado.
