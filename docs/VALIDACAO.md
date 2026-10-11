# Validação funcional — Brisa de Aço 0.1

## Roteiro para você

1. Abra o aplicativo, digite seu apelido e inicie com Escaravelho / dificuldade Normal.
2. Mova com A/D; confirme redução do movimento e impedimento ao esgotar o orçamento.
3. Ajuste ângulo e força nos controles. Dispare por botão. Observe trajetória, vento e troca de turno.
4. Segure Espaço e solte para disparar. O indicador de força deve acompanhar a carga.
5. Selecione Impacto (2). Observe cratera maior, dano e atraso diferente.
6. Acompanhe o tiro da máquina e tente melhorar seu tiro usando os valores anteriores.
7. No terceiro turno próprio, use Tempestade (3). Ela dispara três projéteis e não pode ser usada novamente na mesma partida.
8. Pause com Esc durante mira ou voo. Aguarde; o relógio e o projétil devem permanecer parados. Continue.
9. Abra ajuda por H/?; feche. Faça o mesmo na tela de resultado e confirme que revanche/menu continuam disponíveis.
10. Deixe o tempo de um turno terminar. O jogo deve passar o turno sozinho.
11. Termine uma partida. Confirme vida, queda ou vitória/derrota, XP e opções de navegação.
12. Faça revanche. Terreno, vida e especial devem reiniciar; XP deve permanecer.
13. Feche e reabra. Apelido e progresso devem permanecer. Experimente Carapaça e as três dificuldades.

## Evidência automatizada

- 40 verificações de modelos: máscara, cratera, balística, vento, dano, colisão longa e no canto de uma célula, disponibilidade da especial, fila de atraso, tempo, movimento, disparo único, resolução, mira legal, previsão igual ao impacto real, queda, empate, perfil corrompido, salvamento/carregamento, nível e recompensa única.
- 13 verificações da cena: compilação, menu, início, layout da barra de vida, pausa/retomada, carga de força e soltura por teclado, disparo, reinício, XP, resultado repetido, ajuda após resultado e retorno ao menu.
- Seis partidas completas (seeds 81–86), variando veículos e dificuldade, encerradas sem falhas após 10–28 disparos na execução final dos modelos de combate.
- Revisão independente verificou as correções de navegação, travessia de terreno e física compartilhada.
- Aplicativo Universal (arm64 + x86_64) exportado, assinatura ad-hoc verificada com `codesign --verify --deep --strict` e inicialização pelo executável independente. Sem publicação/notarização.

Capturas `menu.png`, `arena.png`, `impact.png` e `result.png` documentam o render real. A ferramenta de captura usa perfil isolado e uma condição controlada para mostrar a apresentação de vitória; a conclusão natural das partidas é verificada separadamente em `test_matches.gd`.

O controle de mouse pelo conector Computador não funcionou nesta sessão (janela disponível para leitura, mas interação recusada como sem janela). A captura inicial foi inspecionada pelo Computador e as verificações funcionais de cena foram executadas pelo próprio Godot. O funcionamento do mouse/teclado no seu uso normal faz parte deste roteiro de validação.

## Fora desta validação

Outras plataformas, multiplayer, ranking, reconexão, mobile, distribuição pública e notarização Apple. A primeira entrega é o protótipo offline para este Mac.
