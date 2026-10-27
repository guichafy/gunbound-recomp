# Gunbound Recomp

Reescrita fiel, em **Godot 4.7.2 + GDScript**, dos projetos
[jglim/gunbound-launcher](https://github.com/jglim/gunbound-launcher) (launcher e TestClient
do cliente **GunBound Thor's Hammer**) e [jglim/gunbound-server](https://github.com/jglim/gunbound-server)
(emulador do servidor). A meta é manter o jogo original e, sobre essa base, levá-lo a várias
plataformas e estendê-lo com funcionalidades novas.

Hoje o projeto cobre o cliente: um treino offline **1×1 contra a máquina no macOS**, no mapa
Miramo Town A, com os 16 mobiles, itens, clima, lobby, sala e Avatar Shop clássicos.

> **Gunbound** é marca de terceiros. Este repositório é um protótipo local de estudo, sem
> publicação, notarização ou distribuição.

<img src="docs/readme/shot.gif" width="720" alt="Bigfoot dispara o T1 de quatro bombas contra o Mage no Miramo Town, com avatar original vestido">

| Lobby | Sala 1×1 | Avatar Shop |
|---|---|---|
| <img src="docs/readme/lobby.png" width="280" alt="Lobby clássico com Create, Avatar e Exit"> | <img src="docs/readme/room.png" width="280" alt="Sala 1×1 com Bigfoot contra Mage, grade de mobiles e itens"> | <img src="docs/readme/shop.png" width="280" alt="Avatar Shop desenhada com os quadros originais do cliente"> |

Capturas GPU do jogo atual, 1920×1080 ([como regenerar](docs/readme/README.md)).

## Visão

1. **Fidelidade.** Reproduzir o comportamento **comprovado** do cliente e do servidor
   originais, não reinventar o jogo.
2. **Multiplataforma.** A mesma base em macOS, Windows, Linux, Android e iOS. Hoje só o
   macOS é exportado e validado.
3. **Extensão.** Funcionalidades novas entram sobre o porte fiel, declaradas como extensão e
   sem alterar o comportamento original.

Cada regra, tiro ou animação segue uma ordem de fontes:

1. **Cliente original** (binário e arquivos XFS/DAT, lidos com Ghidra ou REA). Prevalece
   quando a prova existe.
2. **Projetos jglim** (TestClient e servidor), como referência do que se está reescrevendo.
   O servidor sozinho não prova o render do cliente.
3. **Adaptação declarada.** Quando o cliente ainda não fecha a questão, a regra fica
   registrada como adaptação, sem alegar paridade, até ser portada.

Versões posteriores do jogo, como o OpenBound (Season 2), estão fora do escopo deste
repositório ([ADR-132](docs/sdd/DECISIONS.md)). O que ainda vem dessa fase é adaptação
herdada, a substituir pelo cliente.

Física, colisão e apresentação são contratos separados. Cada um exige a sua prova: oráculo
independente para números, captura GPU temporal para animação, escuta e interação para som
e input, reexportação conferida para o pacote. A aparência já aprovada é preservada.
Modernizar o design de mobiles e avatares é uma etapa futura, sob pedido.

Método completo em [docs/PORTE.md](docs/PORTE.md).

## Estado

| | |
|---|---|
| Versão do código | **0.20.5** (fonte única: `application/config/version` em `project.godot`) |
| O que dá para jogar | Lobby → sala 1×1 → transição de 5 s com o mapa e os spawns → partida no Miramo Town A, janela WIN/LOSE do cliente com OK de volta à sala, loja e perfil local |
| Última validação completa (ADR-137) | 110 suítes, 28.279 checks Godot, 88 testes Python e 29 partidas, zero falhas ([registro](docs/sdd/BATTLE_OPTIONS_NATIVE.md)) |
| Aplicativo exportado | `builds/Gunbound Recomp.app` 0.20.5, **anterior** à loja original, aos assets e ao HUD corrigido (ADR-130/131/133/134/135/136/137). Reexporte para incluí-los |

## TODOs

Critérios usados nesta lista:

- **Entregue:** base estável na `main`, validada pelo harness e sem pendência de
  implementação. A validação manual que falta fica no roteiro. Quando o aceite do usuário
  foi registrado, isso aparece no item.
- **Em progresso:** implementado e com o harness verde, mas ainda aguarda aceite
  visual, escuta ou mouse, reexportação do app ou execução no cliente original.
- **Pendente:** só pesquisa ou plano, sem código.
- **Roadmap:** fora do escopo atual. Só entra com um pedido novo.

O estado mobile a mobile está em [docs/MOBILES.md](docs/MOBILES.md). O detalhe de cada
tarefa está em [docs/sdd/TASKS.md](docs/sdd/TASKS.md).

### Entregue

- Partida 1×1: terreno destrutível, vento, dano, queda, fila por atraso, três dificuldades,
  pausa, resultado e perfil local.
- Elenco dos 16 mobiles do cliente, com IDs fixos e arte original ([ADR-083](docs/sdd/DECISIONS.md)).
- Balística comum do cliente: passo de 20 Hz, ponto fixo 24.8, carga de 3 s e força mínima
  nativa ([BATTLE_FIDELITY_0_20](docs/sdd/BATTLE_FIDELITY_0_20.md)).
- Regras de turno do cliente: delay com tempo gasto, abertura sorteada e passe de 200 ([BATTLE_RULES_AUDIT](docs/sdd/BATTLE_RULES_AUDIT.md)).
- Miramo Town A em escala nativa, câmera, vento 2D, clima e Thor.
- HUD de batalha e menu clássico único (ESC/Options/P), música e mira Slice/Drag.
- Onze itens de batalha, com barra F1–F6 e Select Item.
- Turtle T1, T2 e SS com a onda original. O T2 foi aceito pelo usuário.
- Lobby e sala clássicos, com a escolha do mobile da máquina. Os ajustes da sala foram
  aceitos pelo usuário (ADR-107 a 114).

### Em progresso

- **Encerramento da partida** (ADR-139): janela WIN/LOSE de `result_back.img` com P, G e OK nas posições do cliente; P mostra o XP do porte e o OK volta à sala. Aceite visual do usuário nas capturas. [Contrato](docs/sdd/RESULT_SCREEN_NATIVE.md).
- **Assets de batalha do cliente** (ADR-133): Miramo, HUD, clima/Thor, itens e música migrados, com fallback testado. Header/footer, cronômetro e vento corrigidos na ADR-134; lacunas declaradas, aceite/escuta e reexportação pendentes. [Inventário e validação](docs/sdd/CLIENT_ASSETS_PORT.md).

- **Avatar Shop e avatares originais** (ADR-130/131): falta o aceite visual e de mouse. O
  popup de compra ainda é adaptado e o app não foi reexportado.
- **Mage revisado pelo cliente** (ADR-126/128/129): combate, climas secundários e
  partículas em voo. Faltam aceite e escuta. Itens, ponto de disparo e apoio continuam
  como pontes.
- **Lightning** (ADR-127) e **Aduka** (ADR-124/125, encaixe ADR-123): falta o aceite visual
  e de escuta.
- **Raon** (ADR-116 a 120): falta o aceite. Ponto exato do plantio, rotação pelo heading,
  contato das minas na encosta e busca de 30 px da mina enterrada ainda estão em aberto.
- **ASate e JD** (ADR-094): a captura GPU ficou bloqueada antes do primeiro quadro, e o
  aceite ainda não veio.
- **Bigfoot e Mage com arte original**, Bigfoot suavizado 4× (ADR-089/115): faltam o aceite e
  a captura específica de menu, loja e arena.
- **Turtle SS:** dano e física dos seis filhos continuam adaptados.

### Pendente

- Armor S2 com dois impactos, Trico S2 e Dragon S2/SS (família de rajadas).
- Satélites do Knight, ricochetes do Grub e campo do Ice.
- Revisão pelo cliente de Bigfoot, Nak e Boomer. Bigfoot usa ataques herdados, e Nak e Boomer
  têm porte parcial.
- Dano, colisão, apoio e parede comuns. Hoje são adaptados fora das famílias já revisadas.
- A máquina não se move nem usa itens. Mouse Speed segue desligado.
- Uma queda depois do teleporte, sob um teto, não causa dano.
- Roteiro manual no aplicativo: [docs/VALIDACAO.md](docs/VALIDACAO.md).

Planos de porte: [BATTLE_MOBILE_FAMILY_PLANS](docs/sdd/BATTLE_MOBILE_FAMILY_PLANS.md).

### Roadmap

1. Ajustes de desktop depois do feedback: balanceamento, máquina, controles e apresentação.
2. Builds de Windows e Linux. A engine também mantém Android e iOS possíveis.
3. Reescrita do servidor (jglim/gunbound-server) e multiplayer: autoridade, sincronização,
   salas, reconexão e segurança.
4. Ranking (retirado do treino offline), modos 2×2 e outros formatos.
5. Mobile: interface de toque, Android, iOS e progresso compartilhado.
6. Contas, campanha e distribuição.
7. Modernização visual de mobiles e avatares.

## Começar

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
```

```bash
./scripts/check.sh --quick
```

O primeiro comando importa o projeto, o que um checkout novo exige. O segundo roda as
suítes sem as partidas longas. Para jogar, rode `scenes/main.tscn` no editor ou abra o app
exportado. Controles em [docs/JOGAR.md](docs/JOGAR.md). Testes e exportação em
[docs/DESENVOLVIMENTO.md](docs/DESENVOLVIMENTO.md).

## Documentação

| Documento | Para quê |
|---|---|
| [docs/PORTE.md](docs/PORTE.md) | Visão e método do porte fiel do cliente |
| [docs/MOBILES.md](docs/MOBILES.md) | Estado dos 16 mobiles e seus registros |
| [docs/JOGAR.md](docs/JOGAR.md) | Fluxo, controles e perfil |
| [docs/DESENVOLVIMENTO.md](docs/DESENVOLVIMENTO.md) | Verificações, exportação e mapa do código |
| [docs/HISTORICO.md](docs/HISTORICO.md) | O que entrou em cada versão |
| [docs/sdd/HANDOFF.md](docs/sdd/HANDOFF.md) | Estado, evidências e como retomar |
| [docs/sdd/README.md](docs/sdd/README.md) | Organização da documentação SDD (SPEC, DESIGN, DECISIONS, TASKS) |
| [AGENTS.md](AGENTS.md) | Contexto para sessões de agentes |
