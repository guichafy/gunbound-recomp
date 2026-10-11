# Design implementado

## Componentes e responsabilidades

| Arquivo | Responsabilidade |
|---|---|
| `scenes/main.tscn`, `scripts/game.gd` | Cena, menu/HUD, input, pausa, overlays, desenho, efeitos, CPU e recompensa |
| `scripts/ui.gd` | Construção e estilo de controles |
| `scripts/terrain.gd` | Máscara sólida 640×400, células de 2 px, textura, superfície, crateras e raycast DDA |
| `scripts/combat.gd` | Parâmetros das armas, integração, colisão, dano e previsão de trajetória |
| `scripts/match.gd` | Atores, RNG, projéteis, fases, movimento, disponibilidade, CPU e resultado |
| `scripts/profile.gd` | JSON local, saneamento, recompensa e gravação temporária seguida de rename |
| `scripts/sound.gd` | Efeitos PCM originais sintetizados em memória |
| `scripts/build_macos.py` | Exportação, nomes internos ASCII, assinatura ad-hoc, verificação e ZIP |

Os modelos herdam `RefCounted`; apresentação usa `Node2D`/controles Godot.
Não há backend, servidor, banco externo, serviço de conta ou dependência npm.

## Fluxo de partida

`menu → aim → flight → settle → aim`, até `finished`.

- `start`: gera arena, cria dois atores, limpa filas/projéteis/especial e inicia
  o jogador em `aim` com vento, orçamento e 30 segundos novos.
- `aim`: aceita deslocamento e um disparo válido; timeout/passar agenda novo ator.
- `flight`: usa acumulador com passo `1/120 s`; varre todo o segmento entre posições.
- `settle`: espera 0,55 s, acomoda veículos, aplica quedas e decide o resultado
  antes de agendar a próxima ação.
- `finished`: elimina projéteis, emite resultado; a apresentação concede XP uma
  vez e abre as ações de revanche/menu. Ajuda fechada nessa fase restaura resultado.
- Pausa pertence à apresentação, que deixa de avançar a partida e o trabalho da
  CPU. `screen`/overlay da view e `phase` do modelo são estados distintos.

## Contratos e invariantes

`MatchModel` expõe atores, projéteis, fase e uma fila `events`. A view consome os
eventos `turn`, `pass`, `fire`, `explosion`, `damage`, `fall`, `finished` para
som, partículas, texto e resultado. View não calcula dano nem ordena turnos.

`Combat.advance` integra aceleração constante: `a=(vento×1,5, 260)`,
`p'=p+vΔt+aΔt²/2`, `v'=v+aΔt`. Previsão e voo real usam esse integrador e
`trace_segment`: primeiro impacto entre máscara sólida e círculos dos veículos.
O atirador é ignorado somente durante os primeiros 0,15 s em ambos os caminhos.

Terreno desenhado e colisão derivam da mesma máscara. Explosão altera a máscara,
depois atualiza sua textura. Fragmentos não desabam; veículos perdem suporte e caem.
Os atrasos `ready`/`clock` representam disponibilidade lógica, não segundos reais.

Perfil padrão: `user://profile.json`, versão JSON 1, campos `nickname`, `xp`,
`wins`, `matches`, `awarded`. Nível é derivado. `awarded` retém os últimos 64 IDs
para impedir recompensa repetida recente; não é um histórico ilimitado nem
proteção antifraude. Não renomear `config/name` sem planejar migração do caminho.

## Arte, execução e distribuição

Três PNGs gerados com GPT Images. As regiões dos sprites são selecionadas pela
view; arquivos originais permanecem intactos. Cenário, veículos e canhões são
combinados com terreno e efeitos por código. Fontes são do sistema, com fallback.

Build macOS Universal arm64/x86_64 usa `.tools/macos.zip`. Nome exibido contém
acento; executável/PCK internos usam `BrisaDeAco` para evitar falha de assinatura
observada. Build ad-hoc local sem notarização; só macOS foi testado.
App exportado incorpora a fonte no momento da exportação e exige novo build
após alterações. Caches, templates e binários não entram no Git.

Não há garantia de determinismo entre plataformas nem protocolo de rede definido.
RNG com seed explícita permite cenários repetíveis nos testes atuais.
