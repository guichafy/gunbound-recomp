# Jogar

Abra `scenes/main.tscn` no Godot 4.7.2 ou o app exportado em `builds/Gunbound Recomp.app`.
O app atual é 0.20.5, mas foi gerado antes da loja, HUD e menu de batalha originais. Para vê-los, rode pelo editor
ou reexporte (veja [DESENVOLVIMENTO.md](DESENVOLVIMENTO.md)).

## Fluxo

1. **Lobby clássico.** CREATE abre a sala, AVATAR abre a loja e EXIT fecha o jogo.
   Ranking e Join ficam desabilitados, porque o treino é offline.
2. **Sala 1×1.** A grade 5×3 escolhe o seu mobile: 14 mobiles e Random. Dragon e Knight não
   têm botão, como no cliente, e saem só pelo Random, sorteado no START (ADR-105). Clique no
   lugar B e depois na grade para escolher o da máquina. Os seis lugares à direita trocam os itens. CHANGE
   ajusta apelido, dificuldade e clima. START abre a transição por 5 segundos,
   com o mobile já sorteado e o ponto de cada piloto no Miramo, e só então
   começa a partida. EXIT ou Esc voltam ao lobby.
3. **Partida** no Miramo Town A. Ao fim, o resultado dá XP e Gold, com revanche ou volta.

A loja segue o cliente: Experimentar mostra uma prévia temporária, Comprar gasta Cash ou
Gold e clicar numa peça possuída a veste. Os bônus valem na próxima partida. O perfil
padrão começa com 999.999.999 de Cash e de Gold **de teste**. Não é dinheiro real.

## Controles na partida

| Controle | Ação |
|---|---|
| A/D ou ←/→ | Mover e virar, gastando a barra de movimento |
| W/S ou ↑/↓ | Mirar 1° por toque. Segurar acelera |
| Espaço | Segurar carrega até 100% em 3 s, soltar dispara. No 100% dispara sozinho |
| Tab ou 1/2/3 | Trocar entre tiro 1, tiro 2 e SS |
| F1–F6 ou clique na barra | Usar um item, um por turno. No turno da máquina, agenda para o seu |
| F8 ou PASS | Passar o turno |
| Esc ou P | Menu clássico Configuration: música, efeitos, rolagem, fundo e modo de tiro |
| OK / X ou Esc / QUIT | Confirmar opções / cancelar alterações / abandonar o treino e voltar à sala |
| Modo Drag | Em Configuration, Shooting mode → DRAGSHOT. Arraste com o botão esquerdo e solte para disparar |
| Botão direito ou do meio | Olhar o mapa |
| F | Virar parado |
| H | Ajuda |

Cada decisão tem 30 segundos. O menu congela relógio, projéteis e animação no treino
offline e cancela uma carga sem disparar. Não há um segundo menu de pausa.
Sniper, MIDI e qualidade3d ainda não estão portados. Quem acumula menos atraso joga antes.

## Perfil

O perfil fica em `~/Library/Application Support/Godot/app_userdata/Gunbound Recomp/profile.json`.
Os testes usam arquivos separados e não alteram esse progresso.

Roteiro de validação manual: [VALIDACAO.md](VALIDACAO.md).
