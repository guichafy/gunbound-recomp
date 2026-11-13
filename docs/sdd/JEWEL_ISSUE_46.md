# JEWEL — investigação e plano de porte (issue #46)

12/11/2026, America/Sao_Paulo. [Issue](https://github.com/guichafy/gunbound-recomp/issues/46).
REQ-02/04..09/19/20/23..25/32/35..37/44/45/48/50/52;
REQ-JEWEL-46 e ADR-JEWEL-46 são identificadores documentais próprios desta
pesquisa, para evitar disputar a numeração das entregas simultâneas #43–45.

## Entrega e fronteira

Pesquisa estática do cliente Thor's Hammer e planejamento de uma futura
opção JEWEL offline 1×1. Nenhum comportamento, asset ativo, perfil, versão ou
aplicativo foi alterado. SOLO continua sendo o único modo jogável. JEWEL não
significa quantidade de jogadores: configuração de modo e capacidade são
campos distintos. A expressão “Duel Mode” do pedido permanece terminologia
a esclarecer; as fontes examinadas não estabelecem esse nome como sinônimo
de JEWEL. Não renomear o botão nem inventar outro modo a partir dela.

O plano está pronto para orientar a próxima pesquisa/implementação, mas a
paridade integral das regras não está demonstrada. Dano, reposição, morte de
pilotos e interações especiais têm gates explícitos abaixo.

## Fontes e reprodução

- PE local: `.tools/mobile-animation-port/GunBound.gme` no checkout principal
  `/Users/guichafy/Workspaces/DemoGame`; SHA-256
  `4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
  Image base `0x00400000`, x86 LE32/windows. Todos os endereços abaixo são VA.
- TestClient de [jglim/gunbound-launcher](https://github.com/jglim/gunbound-launcher),
  arquivos locais em `.tools/gunbound-client/` do checkout principal.
  `graphics.xfs`: `a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`;
  `sound.xfs`: `081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023`.
  Demais DAT e PE efetivo estão pinados em [sources.json](../jewel-native/sources.json).
- [jglim/gunbound-server](https://github.com/jglim/gunbound-server), cópia
  local `reference-jglim-server`, commit
  `46af0e758643563666723efecd7a32a3debb939a`. Trechos com linhas originais em
  [server-excerpts.txt](../jewel-native/server-excerpts.txt). É emulador,
  com suposições declaradas e variantes de protocolo; não é servidor original.
- Ghidra 12.2 direto, JDK 26.0.1, banco exclusivo
  `/tmp/gb-jewel-46-ghidra`, sem GUI ou execução do jogo. Runner/exportador
  versionados na skill `gunbound-client-port`. Manifests, comandos exatos,
  logs, C, ASM e refs selecionados em [ghidra](../jewel-native/ghidra/).
  C decompilado serve de navegação; as constantes abaixo foram conferidas
  nas instruções e, para pontos/limite, diretamente nos bytes do PE.

Reexecutar o comando de `ghidra/q14/run.json` com `--output` novo e um
`--work-dir` próprio. Em banco novo, importar e indicar somente entradas
confirmadas: `438410`, `477bb0`, `478a80`, `478cb0`, `479ba0`, `47a960`,
`450e10`, `450eb0`, `4bb730`, `4cf310`, `4d54e0`, `4d6810`.
As três últimas entradas ausentes na autoanálise têm prólogos/consumidores
preservados nos extratos. Não indicar VAs internas como novas funções.

Houve 14 consultas: 11 com `run.ok` e `manifest.ok=true`; q02 falhou por
troca JDK 26→25 com cache compilado para26; q03/q09 preservam resultados
parciais por funções ausentes. q01 usou caminho Java informado inexistente,
mas o launcher escolheu JDK 26; a versão real consta no log. q03 não é uma
consulta integral aprovada. q05 semeou equivocadamente o ponto de chamada
`4bc02d` como entrada; q10 decompilou setup parcial. Isso foi corrigido só
no banco privado por [RepairJewelEntry.java](../jewel-native/RepairJewelEntry.java)
([log](../jewel-native/repair.log)). q12/q14 confirmam que `4bc02d` pertence
à entrada `4bb730`, corpo completo até `4bccfe`; esses extratos finais
substituem o pseudocódigo exploratório do setup. O PE não foi modificado.
Avisos CA do host/Java e reflexão são ambientais e estão nos logs; nenhum
timeout de análise foi reportado nos manifestos finais.

## Seleção, configuração e consumidores

| Evidência | Contrato e localização | Classificação / limite |
|---|---|---|
| J01 | Servidor `gameserver.py:1112..1122`: WORD de configuração `[2:4]` classifica `0=SOLO`, `0x44=SCORE`, `8=TAG`, `12=JEWEL`; capacidade em outro byte `[8]` | Comprovado no emulador; os valores não são enum inteiro de combate |
| J02 | Cliente `4d6810`, `4d69dc..4d69eb`: carrega `b_ready_jewel.img` com recurso1013; `4d54e0` case12 faz `config & 0xff0fffff | 0x000c0000` e envia DWORD por `0x3101` | Comprovado por ASM; preserva outros campos; criação usa `b_gamecreate_jewel.img` em `428d00`, mas callback completo de Create permanece pendente |
| J03 | `4c3020`, em `4c5e20..4c5e54`, lê inteiro protegido `context+0x45354` e testa3 antes de desenhar JewelTexture. `4bb730`, `4cf310` e helpers repetem modo3 | Comprovado: modo interno JEWEL=3. Correspondência `12 >> 2 = 3` é derivada e coerente; a rotina inteira que desempacota config ainda precisa de fixture |
| J04 | Servidor guarda/retransmite config em `0x3101`; start Serv2 escolhe mapa, posições e ordem e ecoa payload do host | Comprovado no emulador; não comprova a origem/RNG de todo o estado JEWEL nem um servidor autoritativo de física |

Os nomes SOLO/SCORE/TAG/JEWEL do protocolo não devem substituir IDs de mobile
nem quantidade de atores. `0x44` inclui bits além do seletor de modo; não
comparar a configuração inteira com12 quando lado/opções estiverem ativos.

## Objetos, criação e relógios

`438410` procura primeiro slot livre0..7 na categoria `0x186a6`, retorna se
todos estão ocupados, aloca `0x2298` bytes via construtor `477bb0` e associa
`jewel{tipo+1}`. A vtable em `555fdc` tem entradas `4780c0`, `461c60`,
`479ba0` e `47a960`: destruição, seletor EPA compartilhado, atualização e
publicação visual. JEWEL é entidade própria, não mobile jogável ou avatar.

Campos por offset, sem copiar a estrutura protegida como Dictionary:

| Offset no objeto | Uso confirmado / grau |
|---|---|
| `+04/+08` | categoria `0x186a6` / slot0..7; comprovado |
| `+14` | flag de remoção; contato ignora1; comprovado |
| `+38` | tipo0..3; comprovado |
| `+25c/+480` | coordenadas X/Y protegidas; consumidores de contato/render; comprovado |
| `+6a4/+8c8` | limite e acumulador comparados na remoção; valores iniciais300/200/limite global/limite global; papel de resistência derivado, aritmética final de dano pendente |
| `+d14` | último autor, usado para time/recompensa; transferência efetiva depende da cadeia de dano |
| `+1c18` | flag de queda/entrada usada por criação/tick; sem presumir que representa invulnerabilidade completa |

No caminho inicial (`4bb730`, q14), modo3 tenta criar **seis** objetos,
percorrendo estado RNG pré-preparado em strides `0x224` de0 a`0xcd8`.
Não há garantia de seis efetivamente inseridos: `438410` pode abortar por
falta de slot ou terreno inválido. Tipo deriva da comparação do roll com
um parâmetro global, depois40 e80. X vem de outro valor módulo largura;
modo inicial varre a primeira célula sólida naquela coluna, coloca Y+1 e
pose `normal`, rejeitando terreno não encontrado (sentinela10000/limite9000).
Não substituir isso por spawns de jogador do servidor.

`4cf310` case1 tem outro caminho modo3: exige flag lida em `4065a0`, cria
um objeto com argumento final1 e retorna. `438410` nesse caminho inicia
Y=0/pose `drop`. O relógio e o lugar exato dessa chamada na troca de turno
estão localizados, mas **não** comprovam “um novo jewel por turno” em todas
as situações: pendem a semântica da flag, agendamento e tentativas após limite.
Slots comportam8; não são oito jogadores nem oito jewels garantidos.

`479ba0`/`4785f0` consultam superfície `4e4340`, estabilizam Y/apoio e pose,
e processam remoção quando sai abaixo do mundo ou acumulador alcança limite.
Queda além do mapa também passa pela lógica de pontos fora do ramo `drop`.
Fixtures de aterrissagem, queda sem autor e dano durante `drop` são necessárias
antes de transformar isso em regra do porte. Campos protegidos usam ABI própria:
`40a2e0` recebe endereço em EAX, `40a380` usa EDI; casts de critical section
no C não são argumentos ou fórmulas válidos.

## Pontos, acertos e vitória

| Tipo / sprite | Limite inicial (`438410`) | Valor separado de recompensa | Delta do time (`479ba0`) |
|---|---:|---:|---:|
| 0 / jewel1 | 300 | 100 | +25 |
| 1 / jewel2 | 200 | 10 | +10 |
| 2 / jewel3 | parâmetro global (default100) | 5 | +5 |
| 3 / jewel4 | parâmetro global (default100) | 0 | −5 |

J05: `47a317..47a394` contém inteiros ofuscados; `40a440` faz
XOR `0xeeaeaec0`. As duas sequências são **distintas**: não usar100 como
pontos do jewel1 nem confundir pontos com Gold. Os quatro deltas do time
e default100 foram extraídos diretamente do PE por
[verify.py](../jewel-native/verify.py); resultado em
[numeric-fixtures.json](../jewel-native/numeric-fixtures.json).
A fórmula exata de Gold/recompensa depende de denominadores e atributos;
não foi fechada e não autoriza alterar saldos/XP.

J06: tick `479ba0` credita em `context+0x67e3d0` ou `+0x67e5f4`
conforme time do último autor (`context+0x50126+autor`). Soma delta e,
se negativo, grava0. Testa placar **>=** parâmetro global em `796aa0`;
startup `40daa2..40daa9` inicializa esse parâmetro com100. Isso comprova
o default, não invariância contra qualquer configuração/evento futuro.
Com gate de identidade (`3b6c4 == 3b49c`) e latch `battle +0x2382` desligado,
monta `0x4200`, escreve vencedor1 se timeB>timeA, senão0, envia e liga latch.
Empate numérico nesse comparador favorece0, mas a prioridade global entre
duas remoções no mesmo tick ainda depende da ordem da lista: não anunciar
regra geral de empate sem oráculo. `0x4200` não é chamada local de resultado.

J07: `450e10` primeiro testa mobiles categoria`0x186a1` por `45d640`,
depois jewels`0x186a6` por `478a80`, retornando no primeiro contato.
Hitbox nativo usa X±largura e Y−altura..Y, com comparações inclusivas;
largura/altura vêm dos globais protegidos `e9ba40/e55ab8`, ainda sem contrato
numérico inicial fechado. Máscara de terreno é testada antes dessa consulta
no scanner comum `455cc0`; por isso ordem de contato importa.

J08: dispatcher de blast `450eb0` chama dano de mobile `45db20` e,
separadamente, dano JEWEL `478cb0`; este último não é a mesma fórmula de HP
do piloto. `478cb0` inclui dimensões/denominadores do shell, tipo de tiro,
coeficiente da linha do stage, distância estrita, divisor por componente,
incremento do acumulador, pose `damage` e escrita de autoria. O consumidor
e ASM estão preservados, mas registrador EDI e intermediários protegidos
ainda exigem reconstrução/oráculo. Não copiar a expressão decompilada.
`43af40/43b7a0` também percorrem jewels e escrevem `shock`; interações de
área persistente precisam entrar no inventário de atacantes.

Morte/queda/respawn de **pilotos**, bônus/penalidade por acertar adversário,
timeout/passe/SS e prioridade de vitória ainda não estão fechados para JEWEL.
O `TurnTable.check_end` atual termina por HP; ativá-lo sem política própria
encerraria partidas JEWEL pelo critério SOLO indevidamente. Não presumir
que o modo elimina dano em pilotos ou que todo piloto revive.

## HUD, assets e áudio

Inventário direto/checksummado de XFS em [assets.json](../jewel-native/assets.json):
`b_gamecreate_jewel.img`5 frames, `b_gamelist_jewel.img`4 e EPA5 estados,
`b_ready_jewel.img`4; jewel1/2/3 têm100 frames, jewel4 tem80; cada luz tem50.
Os quatro EPAs têm `normal/drop/shock/damage/say`, cada sequência somando20 ticks.
Isso não significa20 ticks de vida nem reproduz automaticamente o blend.
`JewelTexture.xtf` existe; `47a960` publica slot/posição/ângulo no buffer
`context+0x23278/0x23280`, e `4c3020` faz passes corpo alfa/luz aditiva,
8 slots e UVs por slot. Extratos do renderer são recortes ASM indicados,
não cópias integrais da função.

O porte já tem `NativeJewelPanel` de `play_back179`, distinto de Gold178
e Life172, inativo no `HudArt`. Fechar fontes/pivôs/dígitos/time/limite antes
de ativá-lo. `jflame%d` e efeito3200+tipo estão no tick; a importação futura
deve incluir esse grupo e EPA/registro/luzes, sem substituir aparência.

A busca por nome JEWEL no TOC de `sound.xfs` não encontrou entradas; isso
**não** prova ausência de áudio. Efeitos/poses podem referenciar nomes/IDs
genéricos. Resolver chamadas de som dos EPAs/efeitos, PCM e escuta, inclusive
queda/acerto/remoção/placar/vitória. REQ-53 continua vigente: música de mapa
e resultado, salvo consumidor nativo contrário confirmado. Nenhuma trilha
especial foi inventada nesta pesquisa.

## Servidor, clima, itens e CPU

O emulador trata `0x4200` como `SVC_PLAY_END_JEWEL`, descriptografa e
retransmite por`0x4410`, sem recalcular placar, dano ou condição de vitória.
`0x4412` solicita resultado e`0x4413` é devolvido a todos. A própria anotação
do código sobre autoridade é especulativa. O gate do cliente é compatível
com um participante responsável pelo envio, mas não prova todas as regras
de host/migração/validação do servidor original. Offline, substituir essa
fronteira por um evento local idempotente deve ser adaptação explícita.

O scanner comum já consulta Force/eletricidade/tornado; isso não comprova
que os jewels sofrem todos esses efeitos diretamente. Os consumidores de
área `43af40/43b7a0`, terreno e dano JEWEL precisam de matriz por família.
Não remover clima/itens do JEWEL por suposição, nem generalizar que todos
os48tiros possam acertar: RaonT2/SS, NakSS/enterrado, Thor/Ion, lasers,
minas, ricochetes e efeitos persistentes têm caminhos próprios. Incluir
Dual/Dual+/Thunder/Teleport e morte do autor nas fixtures de autoria.

Nenhum AI nativo para treino contra CPU foi identificado nesta cadeia;
ausência nesta pesquisa não prova inexistência em toda a build. A CPU atual
é adaptação offline e minimiza distância do adversário, logo não satisfaz
objetivo JEWEL. Política de pontuação/prevenção de −5 e sobrevivência precisa
ser declarada adaptação e só operar sobre snapshot privado.

## Arquitetura proposta, ainda não implementada

`Match` continua dono de regras/eventos; `Game` só apresenta. Proposta:

| Arquivo | Delta futuro delimitado |
|---|---|
| `scripts/match.gd` | seletor de modo separado de roster; estado `jewels`, `team_scores`, `mode_rng`, latch; criação/tick/blast no passo comum |
| `scripts/match_mode.gd` (novo) | constantes SOLO/JEWEL, estado inicial e `check_end(model)` por modo; delegar SOLO ao contrato atual |
| `scripts/jewel_rules.gd` (novo) | fábrica/snapshot/tick/contato/dano/pontos sem recursos gráficos; sem rede |
| `scripts/flight_snapshot.gd` | copiar modo, jewels, placares, autoria, RNG e latch profundamente; não disparar recompensa persistente em simulação |
| `scripts/cpu_planner.gd`, `Match.predict_shot` | retornar também deltas de placar e alvoJEWEL; avaliar resultado completo da rajada, sem parar na primeira explosão |
| `scripts/turn_table.gd` | manter iniciativa; separar término por HP da política de modo; hooks de turno com ordem comprovada |
| `scripts/menu_screen.gd`, loading | opção explícitaSOLO/JEWEL conservando dois atores; draft/cancelamento e transmissão do modo atéMatch.start |
| `scripts/jewel_art.gd` (novo), `game.gd`, `hud_art.gd` | EPA/arte/luz/placar recebidos do modelo; interpolação só visual, sem afetar hitbox |
| importador novo e `client_audio.gd` | manifesto pinado do grupo JEWEL; streams só após consumidor confirmado |
| `classic_result.gd`, recompensa | aproveitar janela atual; evento final uma vez, preservar perfil real em todos os testes |

Assinaturas propostas: `JewelRules.create(state: Dictionary, x: int, kind: int,
dropping: bool) -> bool`, `step(model) -> void`, `hit_test(jewel: Dictionary,
pixel: Vector2i) -> bool`, `apply_blast(model, shell: Dictionary,
impact: Vector2i) -> void`; `MatchMode.check_end(model) -> bool`.
`Match.start` deve receber configuração opcional final com default SOLO,
preservando chamadas atuais. Parâmetros numéricos ainda pendentes só entram
após etapa 1; esta interface é proposta de decomposição, não novo contrato nativo.

## Plano por gates

> Execução futura: usar `superpowers:executing-plans` ou, se autorizado,
> `superpowers:subagent-driven-development`; não iniciar implementação por
> conta da existência deste plano. Ler SPEC/DESIGN e este contrato juntos.

Objetivo: JEWEL opcional offline 1×1 com regras nativas delimitadas e CPU
adaptada. Stack: Godot4.7.2/GDScript, Python para import/oráculos e Ghidra.
Preservar16 mobiles, perfil, arte/HD, máscara de terreno, SOLO e portabilidade.
Não adicionar rede, capacidade maior, outro mapa ou persistência de modo sem pedido.

1. **Fechar contrato antes do runtime.**
   - [ ] Reproduzir q14 em banco limpo; confirmar unpack de config, Create,
     fonte dos parâmetros protegidos, dano`478cb0` e ordem dos consumidores.
   - [ ] Reconstruir ABI/ASM e gerar oráculo PE independente para hitbox,
     dano/autor, limite de resistência, respawn/queda de piloto, spawn/drop,
     turnos/passagem, reposição e simultaneidade. Fixar PE/DAT e recusar outro SHA.
   - [ ] Identificar chamadores de áreas/clima/itens e som; documentar cada
     lacuna como bloqueio ou adaptação proposta. Esclarecer “Duel” sem mudar
     o nomeJEWEL comprovado. Gate: tabelas completas e esperados independentes,
     sem ABI incerta usada como fórmula. Revisar SPEC/ADR antes do código.

2. **Entidades e colisão, dependente de1.**
   - [ ] Criar `tests/test_jewel_rules.gd` e fixturesPE; executar RED por
     ausência do módulo; implementar fábrica/slots/apoio/dano no módulo e
     snapshot; executar GREEN. Cobrir6 tentativas,8 slots e9ª recusada; X fora,
     sem chão, limite do mapa, impactos nos quatro limites e±1 pixel.
   - [ ] Verificar execução=previsão em todos os campos/RNG/terreno e que
     busca não altera estado vivo. Gate: suíte dirigida sem falhas e oracle
     regenerado idêntico. Nenhum seletor de UI ativo ainda.

3. **Objetivo, agenda e encerramento, dependente de2.**
   - [ ] `test_jewel_mode.gd` RED para política JEWEL; integrar hooks no
     passo comum sem duplicar impactos. Vetores mínimos: placar0/4/5/6−5,
     99/100/101, os quatro tipos, autoria transferida/desconhecida/morta,
     morte dupla e dois jewels no mesmo tick na ordem original.
   - [ ] Verificar transiçãoN−1/N/N+1, passe, expiração, SS, Dual e efeitos
     retardados; latch impede resultado/XP repetido. Gate: política definida
     para todas as mortes de piloto e comparação SOLO sem mudança.

4. **CPU e famílias especiais, dependente de3.**
   - [ ] RED em `test_jewel_cpu.gd`: alvo lucrativo contra alvo−5, empate,
     alvo ausente, tiro indireto, múltiplas explosões, busca cancelada.
   - [ ] Implementar avaliação adaptada de deltas reais previstos; testar
     snapshot/worker e execuções determinísticas sem consumir RNG vivo.
   - [ ] Matriz48 armas×contato/área com cenários escolhidos por consumidor,
     minas/Thor/Ion e itens/climas; não exigir a mesma resposta de todas as
     famílias. Gate: partidas automáticas JEWEL terminam sem loop ou atalho para morte SOLO.

5. **Sala, loading, arte/HUD/áudio, dependente de3 e4 para exposição.**
   - [ ] Importar grupo JEWEL com hashes/registro/alpha/EPA/luz e fixtures
     independentes; testes Python de extração e `test_jewel_art.gd`.
   - [ ] RED de cena para modo default SOLO, cliqueJEWEL/cancelar/voltar,
     loading preserva modo, placar por time e resultado/OK. Implementar
     renderer/passagem de estado; sem salvar no perfil por conveniência.
   - [ ] GPU1920×1080/60 Hz: queda, apoio/rampa, dano/remoção, quatro tipos,
     fundos claros/escuros, ambos os lados, bordas e pausa30 quadros idênticos
     seguida de retomada. Escuta/input e aceite visual humanos separados.

6. **Regressão e entrega futura, dependente de1–5.**
   - [ ] Preparar `.tools`/import, executar `./scripts/check.sh` integral
     (modelos/cenas e29 partidas atuais), mais partidas JEWEL em seeds fixas
     e16 mobiles; manter guard/pool/assertivas existentes. Não substituir
     as29 partidas por casos JEWEL nem usar `--quick` como conclusão de combate.
   - [ ] Revisão de snapshot/autoria/simultaneidade/resultado, logs sem
     erros/leaks, atualizar SDD e declarar cada adaptação ainda vigente.
   - [ ] Somente se for pedida entrega de app: exportar, assinatura e smoke
     de PCK isolado/recursos/versão; nenhum resultado desta pesquisa valida
     app exportado. Publicação segue autorização específica.

Revisão focal: multiacerto no mesmo tick; crédito a autor removido; score−5
sob zero; CPU prevendo após desaparecimento do alvo; menu/loading trocando
modo enquanto a busca está pendente. Cada condição pertence respectivamente
às etapas3,3,3,4 e5; os testes correspondentes são gates, não notas opcionais.

## Verificação desta entrega e continuidade

14 consultas Ghidra e extração/checksum dos assets realizados; não executar
harness de combate para anunciar paridade de uma mudança somente documental.
`verify.py` extrai pontos/limite/opcode diretamente do PE e rejeitaSHA
divergente; comparação regenerada idêntica. O relatório de validação fica
em [validation.txt](../jewel-native/validation.txt).
Não houve execução do cliente Windows, emulação do dano completo, GPU,
escuta, input ou aceite visual novo. Aprovação de pesquisa não aprova um
modo implementado. Fontes de versões posteriores e OpenBound não foram usadas.

Worktree desta entrega: `/Users/guichafy/.codex/worktrees/f19e/DemoGame`;
branch `codex/jewel-46-research-plan`. Orientação posterior autoriza preparar
commit/PR do plano; merge ocupa posição 4, após #43, #44 e #45 e exige
liberação explícita nesta tarefa. Antes de merge: atualizar/rebase na main
resultante, conciliar registros SDD preservando entregas anteriores e repetir
verificações. Não fazer merge automático nem release manual nesta pesquisa.
