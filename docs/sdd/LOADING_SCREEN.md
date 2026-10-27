# Transição ao Start da sala — REQ-49 / ADR-138

Integrado à `main` local em 27/10/2026 (PR #5, branch `cursor/match-loading-screen-ba1a`).
O PR numerava esta entrega como REQ-48/ADR-133, já usados pelos assets de
batalha; foi renumerada para REQ-49/ADR-138 sem mudar o conteúdo.

O Start da sala 1×1 abre a tela de loading do cliente e só então entra na
partida. O tempo mínimo é 5 segundos. Random é resolvido nessa abertura:
o card e os lugares mostram Dragon ou Knight, não o collage Random.

## Evidência

| Peça | Fonte | Confiança |
|---|---|---|
| Painel 800×244 e barra 156×14 | `load_back.img` quadros 0 e 1, `graphics.xfs` `a52f9f46…` | Extraído |
| Prévia do Miramo 748×209 | `load_stage01.img` quadro 0; o bitmap traz o rótulo MIRAMO TOWN | Visual no arquivo |
| Máscara do chão | quadro 1 do mesmo arquivo; primeiro pixel RGB565 não zero por coluna | VA `0x004430c0` no `GunBound.gme` `4af6283d…` |
| Coluna do nome | `spawn_x * 748 / largura`, divisão inteira | A mesma rotina |
| Linha do nome | linha da máscara + 18; sem máscara, y = 122 | A mesma rotina |
| Largura do mapa | 1800 px do foreground do Miramo neste porte | Adaptação do mundo já usado pela partida |
| Espera de 5 s | Pedido desta etapa; no cliente a tela dura o carregamento | Adaptação declarada |

A montagem `map_id * 11 + lado` aparece no código que escolhe o arquivo, mas
`load_stage11.img` é cópia byte a byte do Cave. O quadro usado é o que está
rotulado como Miramo. Outros mapas não entram enquanto a sala só tem o Miramo.

Os pontos continuam os da lista já usada por `Match.start`: o piloto na
metade esquerda, a máquina na direita. A tela mostra esses pontos e a
partida recebe o mesmo par, sem novo sorteio.

O card central mostra o quadro idle do mobile sorteado, com a proporção
original (`STRETCH_KEEP_ASPECT_CENTERED`). Os lugares desenham só o casco
nativo: a folha de piloto legada é a do Bigfoot e estica os outros mobiles.
Os nomes no mapa usam a fonte 8×12 da sala, com contorno de 2 px.
A prévia fica recortada no vão de `load_back` (28, 30, 741×207), sem cobrir
a barra vermelha do cabeçalho. O pixel da máscara é o contorno escuro acima
do banco de neve; o texto desce mais 20 px para ficar sobre a neve.

## Limites

`start_match()` chamado direto não passa pela espera (a revanche saiu com a ADR-139). Não há
rede, barra ligada a download, nem prévias dos outros mapas. Não houve
execução do cliente Windows nem aceite visual.
