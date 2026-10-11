# Validação funcional — Brisa de Aço 0.6.2

## Piloto e tiros 0.6.2

Selecione Bigfoot e Mage. Mova/vire nos dois sentidos e observe o piloto em
encostas: cabeça e corpo devem continuar unidos, com apoio no assento.
TesteT1/T2 e SS após terceiro turno próprio: cabeça do tiro não muda tamanho
ou identidade; Bigfoot aponta na direção do voo, chama fica atrás. MageT2 tem
um rastro contínuo por laser em hélice; SS mantém orbe e círculo EMP constante.
Impactos expandem/desaparecem sem saltos de centro. Pause durante voo/impacto:
todos os efeitos devem congelar e retomar juntos. Compare docs/projectiles
(fixture ampliada) com capturas naturais docs/hd.783checks zero falhas;
72frames GPU, revisão e build independentes. Validação manual completa e
aceitação visual do usuário ainda pendentes.

## Bigfoot T1/T2/SS nesta entrega

Teste Bigfoot com mira30° e força75%: T1 lança4 bombas com intervalo0,2s; T2 duas
rajadas de3 em0,2/0,4s, com forças ligeiramente diferentes; SS lança8 a cada0,125s
(após terceiro turno próprio). Observe sprites, sons individuais e explosões.
Mira T1/T2 limitada18–40°; SS23–35°, com ajuste ao selecionar a arma. Pausar antes
da primeira rajada deve impedir lançamentos até continuar. Auto-carga dispara
uma salva, sem repetição na soltura. Próximo turno espera todas as bombas.

251 checks e dez partidas passaram; revisão independente conferiu fonte/assets
e72 cenários adicionais de previsão versus voo. Capturas GPU `bigfoot-t1.png`,
`bigfoot-t2.png`, `bigfoot-ss.png` e respectivos impactos. Sem validação manual
completa de mouse/áudio. Dados/adaptações em `sdd/BIGFOOT_ATTACKS_0_5.md`.

## Mage nesta entrega

Bigfoot inicia contra Mage. Verifique o adversário com piloto/atlas original e
barra azul de escudo. Selecione Mage no menu para testar mira15–50°, laser1,
dois lasers em hélice no tiro2 e orbe EMP no especial. Escudo absorve dano antes
da vida, regenera20 por turno próprio e reinicia em220 na revanche. Pausa congela
lasers/animações, inclusive quando a CPU carrega. Mage tem760 de vida/movimento90.

181 checks e oito partidas passaram (seeds81–88,24/10/8/17/17/8/29/19 tiros).
Revisão corrigiu previsão da segunda colisão após cratera do primeiro laser.
Capturas `mage-*.png` são render GPU real; impacto usa fixture controlada.
Sem teste manual completo de mouse. SS/delays/balística têm adaptações descritas
em `sdd/MAGE_0_4.md`; outros sistemas Gunbound continuam fora do escopo.

## Bigfoot nesta entrega

Selecione Bigfoot (já selecionado ao abrir). Verifique piloto e animações reais
quando mover, carregar, disparar, receber dano e morrer. Trocar de arma durante
a carga reinicia a pose correspondente; pausa congela quadros e revanche reinicia
estado. Projéteis têm imagens originais, com dano/regras ainda do protótipo.

Passaram 130 verificações e oito partidas, incluindo 28 checks Bigfoot e duas
partidas com o novo veículo. Revisão independente corrigiu SS trocando para S1
após turno rápido. Sem validação manual completa de mouse. Os números específicos
de 0.2 abaixo permanecem como histórico; o roteiro também serve para 0.3.

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
13. Feche e reabra. Apelido e progresso devem permanecer. Experimente Mage e as três dificuldades.
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

## Validação visual HD 0.6

1. Abrir o aplicativo0.6.0; selecionar Bigfoot e Mage, conferir contornos/piloto.
2. Iniciar treino: veículos continuam pequenos e apoiados no terreno; mover e
   virar, carregar e soltar tiros1/2/SS, verificar cores/efeitos e recuo.
3. Conferir ausência de blocos opacos, cortes entre quadros ou salto no chão.
4. Conferir pausa, dano, morte e revanche; estados mantêm duração, mas a arte
   HD tem menos imagens distintas. Avaliar se a fluidez e estilo agradam.
5. Comparar docs/hd/original-bigfoot-menu.png com bigfoot-menu.png; ambas são
   capturas1920×1080. Campo/balística/HUD não foram redesenhados nesta entrega.

## Aceitação da correção de animação 0.6.1

No aplicativo0.6.1, verificar Bigfoot e Mage: movimento sem trocar silhueta,
piloto estável no assento, rodas girando/parando sem reset, carga das três armas
sem esticar o carro, recuo após disparo, dano e morte sem troca brusca de desenho.
Pausar durante movimento/carga/voo e retomar; iniciar revanche/menu e conferir
que o estado anterior não persiste. Prévia animada em docs/animation/animation.gif
é fixture do renderer, não substitui este teste funcional.
