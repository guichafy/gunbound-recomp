# Validação funcional — Brisa de Aço 0.2

## Roteiro para você

1. Abra o aplicativo, digite seu apelido e inicie com Escaravelho / dificuldade Normal.
2. Mova com A/D; confirme giro na direção escolhida, rodas animadas, inclinação e redução do movimento. Deslocamento para ao esgotar o orçamento; F permite virar parado.
3. Ajuste mira e força. Compare a mira local no console com a direção efetiva junto ao canhão; a encosta muda a trajetória. Dispare por botão e observe recuo, vento e turnos.
4. Segure Espaço e solte para disparar. A força cresce; se chegar a 100%, dispara automaticamente uma vez. Soltar depois não cria outro tiro. O marcador branco indica força anterior.
5. Selecione Impacto (2). Observe cratera maior, dano e atraso diferente.
6. Acompanhe o tiro da máquina e tente melhorar seu tiro usando os valores anteriores.
7. No terceiro turno próprio, use Tempestade (3). Ela dispara três projéteis e não pode ser usada novamente na mesma partida.
8. Pause com Esc durante carga ou voo. Aguarde; relógio, força e animações ficam parados. A carga é cancelada; continuar não dispara sozinho. Um tiro em voo continua depois da pausa.
9. Abra ajuda por H/?; feche. Faça o mesmo na tela de resultado e confirme que revanche/menu continuam disponíveis.
10. Deixe o tempo de um turno terminar. O jogo deve passar o turno sozinho.
11. Termine uma partida. Confirme vida, queda ou vitória/derrota, XP e opções de navegação.
12. Faça revanche. Terreno, vida e especial devem reiniciar; XP deve permanecer.
13. Feche e reabra. Apelido e progresso devem permanecer. Experimente Carapaça e as três dificuldades.
14. Troque a arma e observe a fila prevista, que considera atraso do veículo. Durante a escolha da CPU, aguarda a arma real. É ordem da partida, sem ranking de usuários.
15. Confira clarão, detritos, fumaça e reação ao dano. Se cair numa cratera perto da fila lateral, o painel deve ir para o canto superior e preservar a leitura da vida/apelido.

## Evidência automatizada

- 40 verificações de modelos: máscara, cratera, balística, vento, dano, colisão longa e no canto de uma célula, disponibilidade da especial, fila de atraso, tempo, movimento, disparo único, resolução, mira legal, previsão igual ao impacto real, queda, empate, perfil corrompido, salvamento/carregamento, nível e recompensa única.
- 13 verificações da cena: compilação, menu, início, layout da barra de vida, pausa/retomada, carga de força e soltura por teclado, disparo, reinício, XP, resultado repetido, ajuda após resultado e retorno ao menu.
- 28 verificações de refinamento: virada, apoio em encostas positivas/negativas, direção e muzzle nos dois sentidos, previsão igual ao impacto real, apoio ausente, custo da arma, desempate e previsão sem mutar a fila.
- 21 verificações da cena refinada: carga máxima/soltura, tiro único, animações, pausa/retomada, timeout, previsões de arma, CPU indecisa, reinício, recompensa e legibilidade da vida após queda.
- Total: **102 verificações**, zero falhas. Seis partidas completas (seeds 81–86), variando veículos/dificuldade: **24, 10, 10, 17, 6 e 7 tiros**, todas concluídas sem falhas.
- Revisão independente de 0.2 encontrou a sobreposição da vida em crateras; corrigida com regressão que falhou antes e passou depois. A revisão inicial de 0.1 também corrigiu navegação, travessia de terreno e física compartilhada.
- Aplicativo Universal (arm64 + x86_64) exportado, assinatura ad-hoc verificada com `codesign --verify --deep --strict` e inicialização pelo executável independente. Sem publicação/notarização.

Capturas `menu.png`, `arena.png`, `charge.png`, `impact.png` e `result.png` documentam o render real de 0.2. A ferramenta de captura usa perfil isolado e uma condição controlada para mostrar a apresentação de vitória; a conclusão natural das partidas é verificada separadamente em `test_matches.gd`.

O controle de mouse pelo conector Computador não funcionou nesta sessão (janela disponível para leitura, mas interação recusada como sem janela). A captura inicial foi inspecionada pelo Computador e as verificações funcionais de cena foram executadas pelo próprio Godot. O funcionamento do mouse/teclado no seu uso normal faz parte deste roteiro de validação.

## Fora desta validação

Outras plataformas, multiplayer, ranking, reconexão, mobile, distribuição pública e notarização Apple. A primeira entrega é o protótipo offline para este Mac.
