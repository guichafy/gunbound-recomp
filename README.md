# Gunbound Recomp

Projeto de reescrita com foco em fidelidade, em **Godot 4.7.2 + GDScript**, dos projetos
[jglim/gunbound-launcher](https://github.com/jglim/gunbound-launcher) (launcher e TestClient
do cliente **GunBound Thor's Hammer**) e [jglim/gunbound-server](https://github.com/jglim/gunbound-server)
(emulador do servidor). A meta é manter o jogo original e, sobre essa base, levá-lo a várias
plataformas e estendê-lo com funcionalidades novas.

Hoje o projeto cobre o cliente: um treino offline **1×1 contra a máquina no macOS**, no mapa
Miramo Town A, com os 16 mobiles, itens, clima, lobby, sala e Avatar Shop clássicos.

> **GunBound** é marca de terceiros. Este é um protótipo de estudo com código publicado no GitHub.
> Não há releases de aplicativos publicadas neste repositório; os builds macOS são locais e não notarizados.
> O porte ainda contém adaptações documentadas e não alega paridade integral com o cliente original.

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
| Validação | Resultados, datas e limites por mudança em [HANDOFF](docs/sdd/HANDOFF.md). O harness completo inclui suítes Godot, testes Python e 29 partidas; `--quick` omite as partidas longas. Resultados anteriores não comprovam mudanças posteriores |
| Aplicativo exportado | Build local em `builds/Gunbound Recomp.app`, fora do Git. A versão 0.20.5 exportada não inclui todas as mudanças posteriores da `main`; reexporte e confira a assinatura conforme [DESENVOLVIMENTO](docs/DESENVOLVIMENTO.md) |

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
- **Grub** (ADR-150): T2 com quatro corpos, ricochetes e dano repetido do SS revisados pelo cliente. Tornado, atributos do dono e contato do T1 permanecem adaptações; aguarda aceite. [Registro](docs/sdd/GRUB_CLIENT_FIX.md).
- **Boomer** (ADR-142 a 149): tiros, dano/cratera, boca, poses e vento na queda revisados; apoio em rampa com aceite visual delimitado. Pose do chassis apoiado dependente do vento ainda não comprovada. [Evidências e limites](docs/sdd/BOOMER_ISSUE_9.md).

### Pendente

- Armor S2 com dois impactos, Trico S2 e Dragon S2/SS (família de rajadas).
- Satélites do Knight e campo do Ice.
- Revisão completa de Bigfoot e Nak. Bigfoot usa ataques herdados; Nak tem porte parcial.
  Boomer e Grub têm revisões recentes, com limites e adaptações nos registros acima.
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

Requisitos: Git, Godot **4.7.2** e Python 3 para os scripts de ferramentas e validação.
O fluxo abaixo usa a instalação macOS em `/Applications/Godot.app`; ajuste o executável
se o Godot estiver em outro local. Windows, Linux, Android e iOS ainda não têm builds validados.

```bash
git clone https://github.com/guichafy/gunbound-recomp.git
cd gunbound-recomp
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
```

```bash
./scripts/check.sh --quick
```

Após clonar, o comando do Godot importa o projeto, o que um checkout novo exige.
`./scripts/check.sh --quick` roda as suítes sem as partidas longas. Para jogar, rode `scenes/main.tscn` no editor ou abra o app
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

## Contribuir e relatar problemas

Abra uma [issue](https://github.com/guichafy/gunbound-recomp/issues) com a versão ou commit,
sistema operacional, passos para reproduzir, resultado esperado e observado. Para diferenças
visuais, inclua uma captura e indique se a referência é o cliente Thor's Hammer ou uma
adaptação documentada. Remova dados pessoais e caminhos privados dos anexos.

Antes de propor uma mudança, consulte [PORTE](docs/PORTE.md) e os requisitos em
[SPEC](docs/sdd/SPEC.md). Pull requests devem explicar o problema, a mudança e as verificações
executadas, incluindo limites de validação. Mudanças de combate exigem o harness completo;
navegação e input exigem os testes de cena. Use perfis isolados nos testes.

## Referências e atribuições

As referências principais são [jglim/gunbound-launcher](https://github.com/jglim/gunbound-launcher)
e [jglim/gunbound-server](https://github.com/jglim/gunbound-server). A origem e as atribuições
dos assets estão nos respectivos catálogos e registros de importação. Código, marcas e assets
de terceiros não devem ser tratados como se compartilhassem uma licença única.
