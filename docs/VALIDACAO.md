# Validação funcional — Gunbound Recomp 0.7.0

## Avatar Shop clássico 0.14.5

Abra Avatar Shop e compare com a primeira imagem: três colunas, inventário
lateral, prévia compacta e categorias no rodapé. Cabeças/corpos devem aparecer
inteiros e centralizados, sem distorcer. O catálogo da época tinha cinco cabeças
masculinas, não os nove chapéus da foto, e mantém seus próprios preços.

Compre uma peça, clique na sua linha em Meu Avatar e observe a prévia; volte
para batalha, feche/reabra o aplicativo e confira o mesmo conjunto. Experimentar
uma peça não possuída permanece temporário. Troque gênero, filtre nome e abra
Inventário: a lista lateral continua acessível e mostra apenas peças compatíveis.
Abra Atributos, altere e cancele/ESC; o perfil permanece igual. Repita e salve
para levar os pontos à batalha. Confirme a prévia de Mage e Bigfoot.

Capturas1920×1080 e sequência120frames/60fps em docs/avatar-shop-classic.
Validação automatizada usa perfis isolados; aprovação visual/manual ainda pendente.


## Piloto e tiros 0.6.2

Selecione Bigfoot e Mage. Mova/vire nos dois sentidos e observe o piloto em
encostas: cabeça e corpo devem continuar unidos, com apoio no assento.
Teste T1/T2 e o SS já no primeiro turno: cabeça do tiro não muda tamanho
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
(já no primeiro turno). Observe sprites, sons individuais e explosões.
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

## Roteiro para você (0.10.0, HUD original)

1. Abra o aplicativo, digite seu apelido e inicie com Bigfoot / dificuldade Normal.
2. Confira a barra de ação original na base: WEAPON com 1 / 2 / SS, ESC e F8 PASS, janela LAST com ângulo atual e anterior, previsão de clima na janela branca, barras de força e movimento, contador G. No topo: bússola com o número do vento e o relógio vermelho do turno; acima da barra, à esquerda, o Delayboard com a ordem e o atraso.
3. Mova com ←/→ (ou A/D); a barra de movimento diminui e o deslocamento para ao esgotar. F vira parado.
4. Ajuste a mira com ↑/↓: um toque muda 1°; segurar repete cada vez mais rápido. A moldura da mira gira com o chassi, o ponteiro anda dentro da faixa verde e o número ao lado mostra o ângulo no mundo, o mesmo da janela LAST.
5. Segure Espaço: a barra vermelha enche de 0 a 100 em cerca de 2 s; soltar dispara, cheia dispara sozinha e soltar depois não cria outro tiro. O triângulo marca a força anterior e LAST guarda o ângulo anterior. Arraste o seletor amarelo na barra: ele só marca uma referência e não muda a força.
6. Troque o tiro com Tab (ou 1/2/3 ou clique): o botão ativo fica com a aba amarela. O SS já pode ser escolhido no primeiro turno; depois de usá-lo, fica cinza por quatro turnos próprios e o Tab pula ele. A faixa verde da mira muda com o tiro (Bigfoot SS é mais estreita).
7. No turno da máquina, o relógio some e um balão numerado aparece sobre ela nos últimos 20 s; o tique do relógio toca nos últimos 10 s.
8. Ao acertar, o dano sobe como número vermelho e soma acertos seguidos; a barra de vida sob o mobile encolhe (azul = escudo do Mage; vermelha abaixo de 30%).
9. F8 ou PASS passam o turno. ESC ou o botão ESC abre o popup OPTIONS original (o botão ESC fica desabilitado enquanto aberto): relógio, força e animações param e a carga é cancelada sem disparar. Arraste SFX (0 silencia), BGM (música de batalha; 0 silencia), Scroll Speed (arrastar o mapa fica mais lento/rápido) e Background Off (fundo preto); Aiming Mode, Mouse Speed e Interface aparecem esmaecidos. O popup aparece em HD. A barra de título arrasta a janela. Accept (✓) ou ESC fecham e gravam; reabra o jogo e confira que os valores voltam. P ou PAUSA abrem a pausa (recomeçar, menu, ajuda).
   - Música (0.11): a batalha toca um tema herdado; ao terminar, outro aleatório; o menu fica sem música; "Som: desligado" na pausa silencia música e efeitos.
   - Mira Drag (0.12): no popup marque Aiming Mode → Drag e Accept. No seu turno, segure o botão esquerdo no mapa e arraste para a direita: a barra de força acompanha (largura da barra = 100) e treme se o cursor parar; soltar dispara uma vez (também soltando sobre a barra do HUD). Clique sem arrastar não atira; ESC durante o arraste cancela. Botão direito olha o mapa; Espaço continua funcionando. Volte para Slice e confira que o esquerdo só olha o mapa.
   - Itens (0.13): no menu, clique em **Itens**: o popup SELECT ITEM mostra as abas 2 Slots/1 Slot, nome colorido, Delay Cost e descrição ao passar o mouse; clique para equipar (até 6 slots) e clique na barra inferior para remover; Accept grava. Na batalha, os botões aparecem no painel F1–F6. Use Dual (clique ou F1): o SS fica cinza, a barra escurece, o Delayboard soma 80 e o tiro sai duas vezes (a segunda 1 s depois). No turno da máquina, clique num item para agendá-lo (aparece pressionado) e confira que ele é usado no início do seu turno e que o item usado antes sai da barra. Teleport: atire com S1/S2; um sinalizador ciano voa sem vento e, ao tocar o chão, o mobile aparece lá entre duas chamas. Em clima Ignorância a barra mostra ITEM LOCKED.
   - Performance (0.11): na troca para o turno da máquina não deve haver travada; a máquina dispara cerca de 1,9 s depois de o turno começar.
10. Com mouse/toque: use ← → F e segure ● (acima da barra, à direita) para carregar e soltar. Arrastar a tela fora da barra olha o mapa.
11. Termine uma partida: a janela WIN/LOSE mostra você no time A e a CPU no B, com P (XP ganho) e G (Gold); OK volta à sala. Feche e reabra: apelido e progresso continuam.

O roteiro das versões anteriores (0.2–0.9) valia para o console antigo, substituído pelo HUD de batalha em 0.10.

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

## Composição0.6.3

No menu compare Bigfoot/Mage com docs/composition/comparison.png: piloto maior
em relação ao veículo, canhão/rodas menores, mãos perto dos controles e quadris
no assento. Inicie treino, vire e mova em encostas; composição deve girar unida,
sem separar peças ou deformar figura. Teste carga/recuo/dano e pausa. Tiros
corrigidos em0.6.2 devem manter aparência/animação. Confirmação visual final
continua a cargo do usuário.

## Perfil e seleção0.6.4

Menu deve mostrar somente Mage/Bigfoot; teste iniciar com cada um e confirme
que a CPU recebe o outro. Vire os dois: piloto deve apresentar uma perna e um
pé, sem perna distante atravessando o mobile. Confira encosta, carga, recuo,
dano/morte e pausa. Proporção/assento permanecem0.6.3; tiros0.6.2 preservados.
825checks e10partidas passaram; inspeção GPU não substitui aceitação visual.

## Shop e atributos 0.14.0

1. Abrir Shop no menu: confirmar 1.000 Gold/Cash na primeira abertura; sair e
   abrir novamente sem renovação. Buscar nome, trocar categoria e gênero.
2. Selecionar Space Marine e Experimentar: preview muda, equipamento não.
   Abrir Comprar, Cancelar/ESC sem débito; comprar por Gold e outra peça por
   Cash. Repetir clique não pode duplicar compra. Kappa permanece sem saldo.
3. Inventário: equipar cabeça/corpo/óculos/bandeira; ID0 retira acessórios.
   Trocar gênero e voltar deve conservar compras e conjuntos. Reiniciar app
   deve preservar XP/partidas/saldos/equipamento.
4. Nível1: zero pontos; após XP subir, usar +/−, cancelar, confirmar e sair com
   rascunho. Valores não confirmados não entram no treino.
5. Com cada mobile, observar equipamento nos dois sentidos, encostas, movimento,
   carga/recuo/dano e pausa. Vida/dano/cratera/regen/atraso devem refletir pontos;
   o escudo base Mage continua220. Popularity afeta Gold, não XP/Cash.
6. Validar no app exportado (projeto aberto no editor não atualiza app).
   ItemDelay não terá uso real até os itens serem integrados neste worktree.

Testes automatizados usam perfis isolados. Capturas GPU e smoke do PCK não
substituem este teste manual de experiência e áudio pelo usuário.

## Avatares HD0.14.2

Conferir Basic masculino/feminino, Space Marine, Miner, Punk, Kappa, óculos e
bandeira na loja e no mobile. Comparar hd-roster.png; peças devem ter contornos
suaves/material próximo do mobile, sem esticar ou mudar encaixe ao virar.
Trocar equipamento/aba e abrir compra; retratos não ultrapassam cards.

## Integração Shop+itens0.14.3

No aplicativo da pasta principal, selecionar equipamento no Shop e pontos,
voltar ao menu, escolher itens e iniciar treino. Verificar ambos presentes.
Testar Power Up/Blood com ataque, Bunge com Cratera e Atraso item; recomeçar
mantém equipamento/atributos/carga de itens, reiniciando consumo. ItemDelay agora
funciona no uso real; limites anteriores0.14.0/0.14.2 ficam como histórico.
