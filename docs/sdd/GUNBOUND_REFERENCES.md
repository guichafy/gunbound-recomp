# Pesquisa de referência — Gunbound / OpenBound

Data: 2026-10-11. Pesquisa para o refinamento solicitado depois do baseline
`c530e23`. Status: pesquisa realizada, proposta apresentada; implementação
pendente de aprovação do design. Não confundir achados da referência com
comportamento já implementado em Brisa de Aço.

## Fontes consultadas

- [Vídeo 1 — Double Kill / 3000 damage](https://www.youtube.com/watch?v=_hloadUUxrY),
  39 s. Reprodução e observação do quadro final de combate: painel inferior,
  armas 1/2/SS, força, último ângulo, fila à esquerda, vida junto aos atores e
  feedback de eliminação. Não foi feita medição quadro a quadro de timings.
- [Vídeo 2 — Knight Horse / 2 turns](https://www.youtube.com/watch?v=yMnDB_2bE5c),
  27 s. Reprodução e inspeção visual de um trecho final: mira circular sobre o
  veículo, indicador de ator ativo, terreno curvo, HUD inferior e relógio.
- [Vídeo 3 — VIETNAM vs FATE](https://www.youtube.com/watch?v=oVo4pM5zEmI),
  7 min 37 s. Inspeção de trechos, incluindo aproximadamente 1:29 e 2:29:
  veículos inclinados no terreno, mira, força graduada, marcador anterior,
  cratera, detritos, dano destacado e fila de turnos. Não assistimos à íntegra.
- [Fork Chafy-Studio/_OpenBound](https://github.com/Chafy-Studio/_OpenBound),
  branch `master`, revisão `cb2fc197dd6b0498390219750ca6251bf0582d63`.
  Cópia de estudo em `.tools/reference-openbound/`, ignorada pelo Git.

As páginas de vídeo falharam no leitor web; os trechos foram inspecionados no
navegador pelo Computador. Não presumir que transcript/texto descreveu animações.

## Achados verificáveis no código

Links fixados na revisão estudada:

| Referência | Achado | Adaptação proposta |
|---|---|---|
| [Mobile.cs](https://github.com/Chafy-Studio/_OpenBound/blob/cb2fc197dd6b0498390219750ca6251bf0582d63/OpenBound/GameComponents/Pawn/Mobile.cs) | `Shoot` inicia carga no Espaço; soltar ou completar barra dispara | Carga crescente e disparo único ao atingir 100%, sem voltar a diminuir |
| [LocalMovement.cs](https://github.com/Chafy-Studio/_OpenBound/blob/cb2fc197dd6b0498390219750ca6251bf0582d63/OpenBound/GameComponents/MobileAction/Motion/LocalMovement.cs) | Direção pressionada vira o mobile antes do movimento | Deslocamento vira o veículo; manter F para virar parado |
| [Movement.cs](https://github.com/Chafy-Studio/_OpenBound/blob/cb2fc197dd6b0498390219750ca6251bf0582d63/OpenBound/GameComponents/MobileAction/Motion/Movement.cs) | Calcula inclinação a partir dos apoios laterais | Estimar inclinação a partir da máscara existente, com limite em bordas/crateras |
| [Crosshair.cs](https://github.com/Chafy-Studio/_OpenBound/blob/cb2fc197dd6b0498390219750ca6251bf0582d63/OpenBound/GameComponents/Interface/Crosshair.cs) | Mira, direção e rotação do veículo têm contratos explícitos; overlay animado | Mira graduada, ângulo legível e geometria que corresponda ao disparo real |
| [HUD.cs](https://github.com/Chafy-Studio/_OpenBound/blob/cb2fc197dd6b0498390219750ca6251bf0582d63/OpenBound/GameComponents/Interface/HUD.cs) | Barra de força, marcador do último tiro, ângulo anterior e movimento | Colocar essas informações juntas no painel inferior |
| [Delayboard.cs](https://github.com/Chafy-Studio/_OpenBound/blob/cb2fc197dd6b0498390219750ca6251bf0582d63/OpenBound/GameComponents/Interface/Delayboard.cs) | Ordem visual considera disponibilidades e custo da ação selecionada | Mostrar previsão do próximo ator após o tiro, sem alterar a fila real na view |
| [MobileFlipbook.cs](https://github.com/Chafy-Studio/_OpenBound/blob/cb2fc197dd6b0498390219750ca6251bf0582d63/OpenBound/GameComponents/Animation/MobileFlipbook.cs) | Estados de repouso, movimento, carga, tiro, dano, queda e morte | Dar respostas visuais distintas usando a arte original e animação por código |
| [WindCompass.cs](https://github.com/Chafy-Studio/_OpenBound/blob/cb2fc197dd6b0498390219750ca6251bf0582d63/OpenBound/GameComponents/Interface/WindCompass.cs) | Bússola com direção, intensidade e transição visual | Representação circular para o vento horizontal que já existe |

Os nomes acima pertencem ao OpenBound. A proposta é adaptar os comportamentos
ao modelo Godot já existente, sem portar a solução C#/MonoGame nem seus servidores.
Não prometemos reproduzir fielmente todos os valores ou todos os mobiles do jogo.

## Inventário e origem dos assets

O [README do fork](https://github.com/Chafy-Studio/_OpenBound/blob/cb2fc197dd6b0498390219750ca6251bf0582d63/README.md)
informa que o pacote principal de texturas não é compartilhado no repositório.
A árvore confirma ausência dos conjuntos completos de sprites referidos pelo
cliente; há metadados de pivôs, ferramentas, algumas imagens de interface e
arquivos de recursos do launcher. Não existe material suficiente aqui para
integrar as animações completas dos veículos Gunbound.

O código traz avisos GPL-3.0-or-later e a raiz contém `LICENCE.GPL`. O README
trata as texturas separadamente como pertencentes a seus titulares. A pesquisa
não incorporou código C#, imagens, música ou sons desse repositório ao projeto.
Os PNGs existentes em Brisa de Aço permanecem a fonte visual para a proposta.

## Diferenças que motivam o refinamento

Baseline: grandes cartões arredondados, informação dispersa, corpo estático,
carga que oscila ao chegar ao limite e canhão sem relação com a encosta.
Referências: HUD compacto e metálico, força graduada, informação perto do ator,
estados visuais distintos e feedback de impacto mais expressivo.

Os vídeos também mostram itens, múltiplos jogadores e sistemas adicionais.
Não incluí-los implicitamente: a solicitação está sendo aplicada ao treino
offline 1×1 existente. Multiplayer, ranking, mobile e contas ficam no roadmap.
