# Proposta delimitada — refinamento 0.2

Status: design aprovado pelo usuário com “implementa”; versão 0.2.0 implementada, verificada e empacotada. Aceitação funcional pelo usuário pendente. Data: 2026-10-11.
Base: `c530e23`; fontes em [GUNBOUND_REFERENCES.md](GUNBOUND_REFERENCES.md).
Objetivo: aproximar a sensação de jogar, a animação e a composição visual das
referências, mantendo Godot, arte original e a partida offline existente.

## Requisitos da mudança

| ID | Mudança e aceitação |
|---|---|
| REQ-13 | HUD compacto azul metálico: armas 1/2/SS, força graduada, referência do último tiro, movimento e ângulo no painel inferior; vida legível junto ao veículo |
| REQ-14 | Fila lateral mostra ator ativo e previsão da ordem após a arma selecionada, calculada segundo os mesmos atrasos do modelo; não é ranking de usuários |
| REQ-15 | Movimento vira o veículo; corpo acompanha a inclinação do terreno; canhão, indicador e trajetória usam a mesma direção resultante da mira |
| REQ-16 | Espaço inicia carga crescente; soltar dispara; atingir 100% dispara automaticamente uma única vez; soltar depois não dispara de novo |
| REQ-17 | Repouso, movimento, carga, recuo, dano e destruição têm feedback animado distinto; pausa congela as animações de combate |
| REQ-18 | Impacto combina clarão, detritos, fumaça e dano destacado; vento aparece em bússola com intensidade/direção do modelo |

REQ-03/04/08/09/11/12 são afetados. REQ-01/02/05/06/07/10 permanecem:
vida, armas, orçamento, atraso, timer, especial, perfil e plataformas não mudam.

## Decisões aprovadas

- Preservar arquitetura modelo/view. `MatchModel` continua a decidir resultados;
  HUD pode simular a ordem para exibição sem alterar disponibilidades reais.
- Inclinação estimada nos apoios próximos ao centro do ator, limitada a ±30°;
  ausência de apoio em borda não deve produzir NaN nem virar o veículo de cabeça
  para baixo. Recalcular após deslocamento e alteração de suporte.
- Mira 10–85° passa a ser relativa ao corpo/apoio. Derivar direção no mundo
  antes de lançar/prever; CPU deve usar exatamente a mesma conversão.
  Mostrar a direção efetiva no indicador; não desenhar uma trajetória completa.
- Carga preserva faixa 15–100% e taxa de 65 pontos percentuais/s do protótipo;
  mudar o comportamento no limite, sem copiar parâmetros completos do OpenBound.
  Botão/Enter continuam a disparar diretamente com a força escolhida.
- Animações são transformações e efeitos sobre PNGs originais, não spritesheets
  oficiais. Não afirmar equivalência quadro a quadro com Gunbound.
- Preservar arena e fundo; melhorar acabamento do terreno/veículos e separar
  o cenário ilustrado do HUD metálico. Fonte de sistema com fallback continua.
- Excluir nesta rodada câmera com zoom/scroll, itens de combate, novos veículos,
  movimentação tática da CPU, multiplayer e alterações de recompensa.

## Plano de execução

- [x] Criar testes de regressão para virar ao mover, inclinação nos dois sentidos,
   estabilidade em borda/cratera e previsão igual ao voo real em terreno inclinado.
- [x] Implementar geometria de lançamento compartilhada e novos controles de carga;
   verificar tiro único, limite e pausa durante carga.
- [x] Refinar HUD/mira/fila e animações na apresentação existente; preservar
   navegação de pausa, ajuda, resultado e revanche.
- [x] Executar suites de modelos/cena/partidas completas, inspecionar renders reais
   e revisar colisão, input e idempotência das recompensas.
- [x] Reexportar macOS, verificar assinatura/launch, atualizar SDD, README e roteiro
   funcional; registrar a revisão no Git para validação do usuário.

## Validação específica

- Mesmo ângulo local em apoios diferentes produz direções diferentes no mundo,
  coerentes com canhão e previsão; direção esquerda é corretamente espelhada.
- Carga monotônica até 100%; auto-disparo/release tardio não duplicam projéteis.
- Pausa durante carga não avança força/clock/animação nem dispara no resume.
- Mudança de arma altera previsão da fila, sem alterar estado do combate.
- Troca de turno cancela carga antiga; reinício cancela efeitos/ações pendentes.
- Dano e destruição dão feedback visual, mas não alteram colisão/recompensa.
- Treino continua terminando naturalmente com ambos os veículos e dificuldades.
- Capturas inspecionadas para sobreposição, texto legível e hierarquia visual;
  mouse/teclado no aplicativo continuam no roteiro de aceitação do usuário.

## Evidência da execução

102 verificações passaram: 40 modelos baseline, 28 de refinamento, 13 cena baseline,
21 cena refinada. Seis partidas completas passaram com 6–24 tiros. Revisão
independente encontrou vida encoberta em cratera; regressão RED→GREEN protege o
reposicionamento da fila. Outro teste RED→GREEN evita previsão de arma ainda não
escolhida pela CPU. Capturas GPU inspecionadas; assinatura e launch do app
Universal 0.2.0 verificados. Sem incorporação de assets/código do OpenBound.
