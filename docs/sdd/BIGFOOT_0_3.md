# Bigfoot — primeira integração dos sprites reais

Data: 2026-10-11. Escopo solicitado: mostrar o Bigfoot com os assets recebidos,
dentro do jogo, substituindo a aproximação visual por animação real de quadros.
REQ-19 é atendido nesta etapa para Bigfoot; os demais mobiles permanecem pendentes.

Status: integração visual implementada, verificada e exportada em 0.3.0.
Não inclui equivalência integral de ataques. Aceitação pelo usuário pendente.

## Entrega planejada

- Terceira opção selecionável no menu: Bigfoot, inicialmente selecionado para
  facilitar a validação. Os dois veículos anteriores continuam disponíveis.
- Spritesheet original RGBA 2580×3120, sem editar seus pixels. Quadro 129×130,
  20 colunas, intervalos/FPS documentados pelo `MobileFlipbook.cs` do fork.
- Repouso, pouca vida, movimento, carga S1/S2/SS, disparo, dano e morte com quadros
  originais. Posição/direção/inclinação continuam vindo do modelo existente.
- Projéteis usam os PNGs originais Bullet1/2/3 quando o atirador é Bigfoot.
- Piloto usa Body/Basic e Hat/Basic originais, animados e alinhados com os offsets
  de `RiderPivot.json`. Amostragem nearest mantém os pixels na escala ampliada.
- Vida 1100 e movimento 90 (dados do fork); nesta integração visual continuam
  as três armas/regras de combate do protótipo, sem anunciar port completo dos
  padrões de salvas 4/6/8, resistências ou balística original.
- App 0.3.0 reexportado e capturas reais do menu, arena, movimento, carga e tiro.

## Plano e validação

1. Teste de existência/seleção real, limites de quadros e transições observáveis,
   pausa de animação e retorno ao repouso, usando perfil isolado.
2. Copiar apenas a spritesheet e três projéteis para `assets/openbound/bigfoot/`,
   registrar proveniência e SHA-256. Preservar origem em `.tools/source-assets/`.
3. Leitor de atlas em `scripts/bigfoot_sprite.gd`; apresentação muda o estado e
   reinicia seu tempo ao trocar de animação. Loop apenas onde apropriado.
4. Conectar a seleção/modelo/render, sem adicionar rodas/canhão fictícios por
   cima do sprite Bigfoot. Garantir que a CPU escolhida tenha índice válido.
5. Verificar suites existentes + Bigfoot, partidas com o terceiro veículo,
   renders, revisão e build/assinatura. Atualizar hand-off e commit local.

Os parâmetros de armas completos são uma próxima etapa de REQ-19. Não confundir
sprites originais com uma cópia integral de regras do Gunbound. Perfil, offline
1×1, ranking removido e roadmap permanecem.

Verificação: 130 checks (40+28 modelos, 13+21 cena, 28 Bigfoot), zero falhas.
Oito partidas passaram; seeds 87/88 usaram Bigfoot e terminaram em 34/9 tiros.
Revisão apontou SS trocando para S1 em turno curto: regressão RED→GREEN.
Outra regressão protege o reinício de carga ao trocar arma. Cinco capturas GPU
inspecionadas. Seis PNGs copiados têm hashes iguais às fontes. JSON/avisos estão
incluídos na exportação. Assinatura e launch do app verificados.
