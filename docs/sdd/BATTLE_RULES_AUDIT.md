# Auditoria das regras de batalha — Godot × OpenBound C# × cliente original

Pedido de 20/10/2026: investigar e comparar a implementação da batalha com o
OpenBound (`~/Workspaces/Gunbound`) e com o GunboundClassic
(`~/Workspaces/GunboundClassic` + cliente Thor's Hammer em
`.tools/gunbound-client/`), usando engenharia reversa quando preciso.
A meta é fechar o entendimento das regras ligadas ao `AGENTS.md`.

**Resultado:** a auditoria terminou com as decisões do usuário aplicadas no
ADR-076 (seção "Decisões do usuário"). A matriz abaixo registra o estado
**anterior** às mudanças. Requisitos
afetados: REQ-04, REQ-05, REQ-06, REQ-07, REQ-35, REQ-42 e REQ-43.

## Fontes e o que cada uma prova

| Fonte | Conteúdo útil para batalha | Limite |
|---|---|---|
| Godot (`scripts/match.gd`, `turn_table.gd`, `mobiles.gd`, `combat.gd`, `damage.gd`, `weather.gd`, `items.gd`) | Implementação vigente | — |
| OpenBound C# — servidor (`Openbound Network Object Library/Entity/MatchManager.cs`, `MatchMetadata.cs`, `MobileMetadata.cs`, `Common/NetworkObjectParameters.cs`; `OpenBound Game Server/Service/GameClientProvider.cs`) | Ordem de turno, delay, passe, trava do SS, vento/clima, vitória | Reescrita de fã; não é o jogo original |
| OpenBound C# — cliente (`OpenBound/GameComponents/...`, `Common/Parameter.cs`) | Balística, massa, vento por projétil, HUD, relógio | Idem |
| `GunboundClassic/gunbound-server` (jglim) | Só protocolo: mapa aleatório, spawns de `map_data.json`, ordem inicial aleatória (`random.shuffle`), modos | **Não tem física, dano nem delay**: o pacote de batalha `0x4200` é só repassado |
| Cliente Thor's Hammer `.tools/gunbound-client/*.dat` | `characterdata.dat` (16 × 332 bytes), `itemdata.dat` (100 × 308 bytes) decodificados com `scripts/gunbound_xfs.py` | Tabelas, não regras |
| [colemancda/GunBound-Decomp](https://github.com/colemancda/GunBound-Decomp) (decompilação Ghidra do mesmo `GunBound.gme`) | Funções `ComputeTurnDelay`, `CommitTurnDelay`, `SortTurnOrderByDelay`, `AdvanceTurnQueue`, `BeginNewTurn`, `FUN_0041c360`, `DrawWindGauge`, `ApplyBlastDamage`, `SimulateProjectileFrame` | Corpos "raw Ghidra port", não verificados à mão; campos sem nome |

Engenharia reversa feita aqui: leitura do texto decompilado (via API do GitHub,
nada clonado nem executado) e decodificação LZHUF própria dos `.dat`. Os
arquivos ficaram só no scratchpad da sessão.

### Como os campos do `characterdata.dat` foram ligados ao delay

`FUN_0041c360` (chamada por `CreateMobile`) copia a tabela por tipo de mobile
(`ctx + 0xf0384 + tipo × 0xb1ac`, passo `0x224` por campo) para o objeto do
mobile. O índice do campo nessa tabela coincide com o índice `int32` do
registro do `characterdata.dat`:

| Campo do registro | Célula no mobile | Uso em `ComputeTurnDelay` |
|---|---|---|
| `[28]` delay base (500–550) | `+0x8de8` (+ atributo de avatar × 25 / 10) | parcela fixa de todo disparo |
| `[29]` 10 (Turtle 12) | `+0x900c` | multiplica o tempo gasto |
| `[30]`/`[31]`/`[32]` 250 / 300–440 / 800–840 | `+0x9230`/`+0x9454`/`+0x9678` | custo de S1/S2/SS |
| `[33]`, `[34]` | `+0x989c`, `+0x9ac0` | termo de item (não rastreado por inteiro) |

`ComputeTurnDelay` (`0x45d150`):
`(base + ((400 − relógio) / 20) × [29] + custo_do_tiro + termo_de_item) × 10`.
O relógio é a célula `+0x8bc4`, que `DrawWindGauge` exibe como `valor / 20`
(ticks de 50 ms) e que o `OnTick` compara com `0x8c` (7 s) para o aviso de tempo.

**Validação cruzada:** `base + custo` reproduz exatamente o `DelayPresets` do C#
em 12 dos 16 mobiles (Armor 770/960/1320, Mage 750/900/1300, Bigfoot
770/920/1320, Lightning 750/800/1300, JD 740/830/1290…). As quatro exceções são
Nak (tipo 2), Aduka, Kalsiddon e JFrog. O valor do C# para o Nak (760/910/1310)
é igual ao do registro 15 do original, o que sugere uma troca de linhas no
fork. Com isso, o `characterdata.dat` é a fonte dessas tabelas no original.
Isso corrige a dúvida do GunBound-Decomp, que achava que o arquivo só era
validado e descartado.

## Matriz de regras

Os status abaixo descrevem o estado **antes** do ADR-076. O que foi aplicado
está em "Decisões do usuário".

Status: **igual**; **adaptação** (decisão registrada); **baseline** (regra
inventada em 0.1 e nunca revista contra o C#); **divergente** (diferente e sem
decisão); **desconhecido** (a fonte não permite concluir).

| # | Regra | Godot | C# OpenBound | Original TH | Status |
|---|---|---|---|---|---|
| 1 | Quem abre a partida | Sempre o jogador (`match.gd:95`) | Time sorteado, alternando A/B (`MatchManager` ctor) | Servidor sorteia `turn_order` (jglim `start_game_serv2`) | **baseline** (SPEC "Jogador começa") |
| 2 | Escolha do próximo | Menor `ready`; `ready += delay` (`turn_table.gd:11`) | Menor `Delay` acumulado (`OrderBy`) | Menor delay (`SortTurnOrderByDelay`) | igual |
| 3 | Desempate | Favorece o **outro** (`turn_table.gd:16`) | `OrderBy` estável: quem acabou de agir continua primeiro e **joga de novo** | Ordem vinda do servidor (`0x3020`/`0xc300`); não determinável pelo cliente | **divergente** |
| 4 | Delay do tiro Mage/Bigfoot | C# ÷ 7,5 | 750/900/1300 e 770/920/1320 | idem (base + custo) | igual (escala ADR-024) |
| 5 | Delay do tiro Nak | 760/910/1310 ÷ 7,5 (`mobiles.gd:27`) | 760/910/1310 | **770/920/1320** | **divergente** |
| 6 | Tempo gasto no turno entra no delay | Não | Não | **Sim**: +10 por segundo inteiro gasto (unidades C#) | **divergente** (C# e Godot omitem) |
| 7 | Duração do turno | 30 s (`match.gd:119`) | 30 s (`TimePerPlayerTurn`) | 20 s (400 ticks de 50 ms), inferido | adaptação herdada do C#; original provável 20 s |
| 8 | Custo de passar / tempo esgotado | 80 (≈ 600 unidades C#) (`turn_table.gd:24`) | 200 (`TurnSkipDelayCost`) | Não isolado; pelo item 6, passar no fim do tempo custa base + 20 s × 10 | **baseline**, diverge do C# |
| 9 | Trava do SS ao usar | +4, desce 1 por turno próprio, abre no 1º turno | idem (`SSCooldownTimer + 1`) | não rastreado | igual (ADR-066) |
| 10 | Trava do SS ao **passar** com SS selecionado | Não trava | **Trava** (`ComputePlayerTurnSkip`, com o `== 0` comentado) | não rastreado | **divergente** (provável bug do C#) |
| 11 | Delay de item | custo C# × (1 − ItemDelay/100) ÷ 7,5, cobrado no uso | idem | `itemdata.dat`: Dual 600, Teleport **100**, Dual+ **250**, Energy Up 1 100, Energy Up 2 **300**, Team Teleport 50, Change Wind **150**, Power Up 150, Thunder 200, Bunge **50**, Blood 0 | igual ao C#; **5 itens divergem do original** |
| 12 | Slots por item | 1/2 | 1/2 | flag `2 Slots` do `itemdata.dat` | igual nos três |
| 13 | Atributo de delay do avatar | C# `× (1 − AttackDelay/100)` | idem | soma `atributo × 2,5` ao delay base | igual ao C#; modelo original diferente |
| 14 | Vento | Força 0–34, ângulo 0–359; perturbação força −2..+1 e ângulo −3..+2 com 50% (`MatchMetadata.cs:153–154`); troca no clima Wind | idem (`MatchMetadata`) | não rastreado | igual + adaptação (vento sorteado no início, `weather.gd`) |
| 15 | Clima por rodada | Fila de 4, avança a cada 2 turnos | idem (`PassTurn(RoomSize)`) | `SpawnWeatherHazards` em `BeginNewTurn` | igual (0.9) |
| 16 | Morte súbita | Ausente | Só UI/música (`MatchSuddenDeathType`), sem regra | Há limite de turnos com aviso a 10 do fim e bônus a cada N turnos (`BeginNewTurn`) | **desconhecido** no original; ausente nos dois |
| 17 | Empate (os dois morrem) | Empate (`winner = -1`, `turn_table.gd:44`) | **Não há empate**: vence o time de quem enviou o pedido (`CheckWinConditions`) | não rastreado | **divergente**; empate dá XP próprio (SPEC) |
| 18 | Balística | Gravidade 260, velocidade 180–660 px/s, vento × 1,3, 120 Hz (`combat.gd`) | Gravidade 196, velocidade = força × 100 / massa 14, vento × 1,2, passo 0,015 por quadro de 60 Hz | Ponto fixo; gravidade por mobile no `[40]` (Mage 90, Bigfoot/Nak 98, Aduka 90, JFrog 94) | adaptação (ADR-024/026); **valores do C# e do original não aplicados** |
| 19 | Dano | Fórmula inversa do C# com caixa (ADR-066) | `CalculateDamage` | `ApplyBlastDamage` não calcula o valor no cliente; o registro tem blocos `內/中/外` por arma | igual ao C#; original **desconhecido** |
| 20 | Vida/escudo do Mage | 760 / 220 / regen 20 | 760 / 220 / 20 | **730** / 220 / regen **30** | igual ao C#; diverge do original |
| 21 | Ângulos de mira | Mage 15–50; Bigfoot 18–40 (SS 23–35); Nak 10–50 | idem | Mage 15–50; Bigfoot 18–40 / 23–35; Nak 130–170 pela cauda | igual |
| 22 | Movimento por turno | 90 unidades a 60/s | `MaximumStepsPerTurn` 90 | `[25..27]` não mapeados | igual ao C# |
| 23 | Queda e saída do mapa | ADR-066 (queda curta não fere; vazio mata) | idem | não rastreado | igual |
| 24 | Aleatoriedade do servidor | `rng` por partida (seed nos testes) | `Random(10)` fixo por processo | — | artefato do C#; não replicar |

## Leitura dos achados

1. **Delay original = base + custo do tiro + tempo gasto.** O C# guarda só
   `base + custo` em tabela e descarta o tempo gasto. Atirar rápido não dá
   vantagem no C# nem no Godot; no original dá.
2. **Nak**: o delay que o Godot herdou do C# diverge do cliente original, de
   onde vieram a arte e o dano do Nak (ADR-074). Pela regra da 0.15 ("dados
   do cliente original"), o esperado seria 770/920/1320.
3. **Regras de turno do baseline** (jogador começa, empate de iniciativa para
   o outro, passar = 80) são de 0.1. Nunca foram revistas contra o C#.
4. **C# com comportamento suspeito**: no empate de delay, quem acabou de agir
   joga de novo. Passar com SS selecionado trava o SS. Morte dupla dá vitória a
   quem pediu a verificação. Replicar isso seria fidelidade a bugs do fork.
5. **Itens**: cinco custos do C# não batem com o `itemdata.dat`
   (Teleport, Dual+, Energy Up 2, Change Wind, Bunge).
6. **Balística e dano originais**: o integrador é em ponto fixo e o dano é
   resolvido fora de `ApplyBlastDamage`. Portar isso pede uma etapa própria de
   engenharia reversa. Os números do C# (196, massa 14, vento 1,2) estão
   disponíveis, mas trocar a física muda toda a mira e as seeds 81–93.

## Termo fixo `[34]` = 200

O `[34]` vale 200 nos 16 registros. O `Base` do `DelayPresets` do C#, que o
fork nunca usa, é exatamente `[28] + [34]` em todas as linhas que batem
(Mage 700 = 500 + 200, Bigfoot 720 = 520 + 200…). Até o `Base` 710 do Nak no
C# é `[28]` do registro 15 + 200, o que reforça a troca de linhas.

`CommitTurnDelay(flag, mobile)` soma `[34] − 3 × atributo` quando `flag` está
ligado. O custo do tiro só entra quando o bool `+0x8bae` está desligado
(provável "passou o turno"). Não foi possível provar quais chamadas ligam o
`flag`, então o +200 fica como hipótese. Não foi aplicado ao tiro nem ao
passe; ver decisão abaixo.

## Decisões do usuário (20/10/2026) — ADR-076

| Tema | Decisão |
|---|---|
| Política | Original quando comprovado; senão, C# |
| Tempo gasto | Soma `[29]` (10) por segundo inteiro até o disparo; turno continua com 30 s |
| Abertura | Sorteada pelo `rng` da partida |
| Passe | 200 (C#), sem termo de tempo; `[34]` não aplicado |
| Nak | 770/920/1320 |
| Mage | 730 de vida, 30 de regeneração de escudo |
| Itens | Delays do `itemdata.dat` |
| Balística | Números do C#: gravidade 196, força × 100 / massa 14, vento × 1,2 |
| Mantidos no Godot | Empate de iniciativa a favor do outro, empate por morte dupla, passe sem travar o SS |

Escolhas de implementação declaradas:
- o piso de força 15 continua;
- o relógio de voo segue em tempo real (o C# avança 0,015 s de física por
  quadro de 60 Hz, ou seja, 0,9×; a geometria da trajetória não muda);
- o passo da busca da CPU foi refinado para compensar o alcance mais sensível
  à força;
- o atributo de delay do avatar continua no modelo C# (só sobre o custo do
  tiro); o tempo gasto e o passe não recebem desconto.

## Limites desta investigação

- Corpos do decompilador não foram verificados à mão; os nomes de célula vêm
  do próprio GunBound-Decomp. O relógio de 20 s e o termo de tempo gasto têm
  confiança média-alta: a fórmula é explícita, e a identidade do relógio vem da
  exibição em `DrawWindGauge`.
- O termo de item de `ComputeTurnDelay` (`[33]`, quantidade − 3 × atributo)
  não foi entendido por inteiro. O uso do `f24` do `itemdata.dat` como delay
  se apoia em 6 de 11 valores iguais ao C#.
- Não foram rastreados no original: desempate, custo de passar, trava do SS,
  queda, vento, dano e morte súbita.
- Gold/XP ficaram fora deste corte (ver `GOLD`/perfil nos documentos da loja).
