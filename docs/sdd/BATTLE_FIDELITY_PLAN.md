# Fidelidade da batalha — revisão e plano de execução

## Estado de execução0.20 —24/10/2026

Tarefas 1–7 implementadas no workspace; tarefa 8 concluída como pesquisa e
planos, sem porte automático das famílias. Revisões de especificação e
qualidade aprovadas após correções. [Registro e limites](BATTLE_FIDELITY_0_20.md).

| Tarefa | Resultado atual |
|---|---|
| 1–2 | Autoria/Gold/minas no laço comum; fábrica/filhos/Lightning completos |
| 3 | Limites de mira únicos, extremos da CPU e HUD |
| 4 | Matriz 48, WaterEffect, som original, EPA/glow e contato pré-calculado |
| 5 | Física 20 Hz/24.8, mínimo nativo, carga 3 s e vento |
| 6 | Boomer curva/S2 temporizado/SS por estado |
| 7 | Pose/emissão/som por grupo, Dual, pausa/mudo; Armor/Turtle SS corrigido |
| 8 | Matriz 48 tiros/44 classes e planos futuros; nenhuma mecânica desconhecida inventada |

- [x] Implementação e revisões focais; probe independente48 voos sem divergência.
- [x] Rodada completa final: 7287 checks Godot, 16 testes Python e 29 partidas; parse
      aprovado, sem ERROR; `final-full-check-3.log`.
- [x] Composição/timeline nativas geradas e composição inspecionada,
      com limite explícito de framebuffer 3004×1805.
- [x] App/ZIP 0.20.0 e assinatura; PCK isolado160 checks/0 falhas, com
      ressalva explícita de CA no log (build também registra editor_settings).
- [ ] Recaptura Full HD, escuta e mouse manual/aceite do usuário.

## Plano original e critérios preservados

> As caixas detalhadas abaixo preservam o planejamento anterior à implementação;
> o quadro acima e o registro0.20 representam a execução atual. Leituras antigas
> de dados foram corrigidas pelas matrizes de fontes: Dragon corpo invisível,
> filhoSS bullet14c; GrubS2 quatro componentes; DragonS2 ticks1/6/11/16.
> Para próximos portes, usar os planos por família e a especificação vigente.

**Data:** 24/10/2026. **Base revisada:** `c796154`, sobre o roster `6038d0a`.
**Objetivo:** corrigir perda de regras no caminho real dos tiros e preparar o
porte comprovado de vento, Boomer e sincronização de arte/áudio.
**Arquitetura:** `Match` continua decidindo combate; catálogo → `ShellState` →
laço compartilhado por voo e previsão → eventos de apresentação. Minas precisam
participar dessa simulação sem trocar a identidade do disparo em andamento.
**Tecnologia:** Godot 4.7.2, GDScript, ferramentas Python de importação e análise
estática do PE x86. Nenhum executável do cliente original deve ser executado.
**Especificação:** [SPEC.md](SPEC.md), REQ-03/04/05/06/07/08/09/19/23/28/44/45;
[BATTLE_FIDELITY_HANDOFF.md](BATTLE_FIDELITY_HANDOFF.md), ADR-076/077/081/083/084.

## Limites e decisões aprovadas

- Treino desktop offline 1×1; IDs 1 Mage, 2 Bigfoot e 3 Nak preservados; ID 0 fora.
- Original comprovado prevalece; usar C# onde a regra original ainda não foi comprovada.
- Usuário aprovou física original, carga de 3 s e força mínima original em
  24/10/2026 (ADR-084). A substituição parcial do ADR-076 está especificada;
  o código ainda executa a física anterior até a tarefa 5 ser implementada.
- A tarefa 6 usa a física original escolhida. Não converter silenciosamente
  a lógica por tick do Boomer para constantes ajustadas à física C#.
- Preservar HD aprovado, fontes de arte, `.gd.uid`, `.png.import`, perfil real e fonte C#.
- Toda alteração de combate exige modelos e partidas completas; input/cena exige cenas.
- Build só após implementação e validação; reexportar e verificar assinatura
  se houver entrega de app. Sem commit, push, publicação ou novo build nesta sessão.

## Revisão dos commits e do handoff

`6038d0a` incorporou o roster de 16 mobiles, arte e especiais. `c796154` veio
depois e deriva a luz do Great Devil da silhueta HD. Este último não modifica
`match.gd`, `combat.gd`, `classic_*`, vento, CPU ou fábrica de projéteis.
A leitura das mudanças de renderer e os testes dirigidos não revelaram um
novo problema de batalha atribuível a ele; isso não equivale a revisão visual
integral nem a validação completa de todos os arquivos do commit.

Achados prioritários no roster, ainda presentes no HEAD:

| Prioridade | Evidência no código | Impacto observado | Tarefa |
|---|---|---|---|
| P1 | `classic_flight.gd:142`, `match.gd:375`, `predict_shot` | Detonação de mina muda `shot_actor` de 0 para 1 durante tiro de 0; snapshot mantém 0 e a mina. Pode atribuir dano, arma e agenda ao ator errado | 1 |
| P1 | `classic_flight.gd:105`, `shell_state.gd` | Minas S2/SS do Raon nascem com raio 0 e sua detonação causa 0. O impacto inicial do projétil ainda passa por `explode` e pode causar dano: não afirmar que o tiro inteiro é incapaz de ferir | 2 |
| P1 | `shell_state.gd:24`, `classic_flight.gd:237` | Somem `bolt_extra`, `bolt_extra_radius`, `bolt_angles`, `bolt_reach`; Lightning S2 percorre o ângulo padrão único, embora conserve `bolt_count = 4` | 2 |
| P1 | `classic_mobiles.gd:33`, emissão padrão | Boomer S2 lança só uma bala. Tiros têm mesma velocidade e voo genérico; SS só muda visual por idade, sem a mecânica original de curva/transformação | 6 |
| P2 | `combat.gd:38`, `cpu_planner.gd:35` | Mira 86–90° do Boomer é cortada em 85°; grade inicial da CPU é limitada a 15–80°. O refino pode sair dessa grade, mas não garante procurar toda a faixa | 3 |
| P2 | `import_classic_mobiles.py:30`, `classic_mobiles.gd:106`, `classic_sprite.gd:74` | Raon sem áudio pelo prefixo; clássicos lançam e soam em t=0; poses usam 19 fps e recuo global, sem os tempos reais por arma | 4 e 7 |
| P2 | `sheet_names`, `table_name`, `classic_sprite.draw_projectile` | Dragon S1 sem folha; folhas só de luz podem ter `.epa` incorreto e ser desenhadas duas vezes | 4 |
| P2 | `assets/openbound/{turtle,armor}/Bullet1.png`, `classic_sprite.draw_projectile` | Usuário relata Turtle T1 com animação do Armor T1. Os PNGs e as entradas originais são idênticos; falta investigar a composição própria do Turtle, não apenas trocar o nome da folha | 4 |

Os testes existentes de mina/raio e Lightning usam dicionários manuais. A
paridade entre previsão e voo pode passar quando **ambos** perdem a mesma
regra; são necessários testes contra resultados esperados independentes.

Correções de interpretação do handoff:

1. O roster já está commitado. O handoff de investigação era o único arquivo
   não rastreado no início desta revisão; ele deve ser preservado.
2. `tank14/15/16` são **Dragon/Knight/Aduka**, como o commit já corrigiu.
   O enum do servidor é de outra composição de cliente. Não adicionar
   Kalsiddon/J.Frog nem aplicar seus nomes às tabelas recuperadas.
3. A tabela balística recuperada também tem esses cabeçalhos antigos. Seus
   valores [40] finais 90/98/94 correspondem a Dragon/Knight/Aduka; portanto
   as conversões propostas são 360/392/376 px/s², respectivamente.
4. “JD inerte” e “Aduka com poder 0” não autorizam inventar dano: JD S2 já
   causa o impacto primário; cristal e SS precisam de análise do caminho
   completo. Aduka S2/SS podem delegar efeitos a outros objetos. Retirar ambos
   do pacote de correções mecânicas imediatas até comprovar a regra.
5. Boomer S1/S2 podem compartilhar classe, som e partes da trajetória; isso
   não é, por si, erro. O original tem S2 com quatro lançamentos e voo próprio.
6. O arquivo `re-tiros.md` existia no temporário e foi recuperado. Detalha
   Boomer; os outros mobiles continuam sem investigação concluída.
7. O relatório de arte/áudio tem dados úteis, mas foi interrompido e distingue
   achados comprovados, prováveis e hipóteses. Não tratar tudo como aceite.

## Evidências e validação desta revisão

Recuperados **511 arquivos / 74.743.996 bytes** em
`.tools/battle-re/recovered-2026-10-24/`, incluindo relatórios, disassembly,
folha de contato, WAV, tabelas e scripts. `recovery-manifest.json` registra
SHA-256 por arquivo. Clones, caches e cópias de executáveis foram excluídos;
o cliente continua somente leitura em `~/Workspaces/GunboundClassic/`.
Scripts recuperados ainda têm caminhos temporários absolutos: portar esses
caminhos e documentar entradas antes de chamá-los reproduzíveis.

**Achado adicional do usuário — Turtle T1 (24/10/2026):** os PNGs
`turtle/Bullet1.png` e `armor/Bullet1.png` têm o mesmo SHA-256
`ad0ad6dd65bb12c2fdb1fdbad2cb3bc86ba284bf3b02c3ad5f0e87f12f82b359`.
As entradas `bullet12n.img` e `bullet1n.img` foram relidas diretamente de
`graphics.xfs`: ambas têm 3472 bytes e SHA-256
`ce81891c8095354ea052b898358d901073d918db615783c7fe669cc36420f530`.
Isso confirma a aparência compartilhada da bala base e não demonstra erro
de cópia do importador. No C#, `TurtleProjectile1` acrescenta `HelicoidalTrace`
em Update/Draw e chama `TurtleProjectile1Explosion` no impacto; o renderer
clássico Godot atual só desenha a folha da bala e eventual luz. A ausência
da composição específica é uma causa candidata; conferir o renderer original
do Bullet12 antes de definir o porte. A explosão `Flame1` do Turtle tem
hash diferente da do Armor, portanto o achado não prova troca do impacto.

Probes reexecutados no HEAD, logs em `.tools/battle-re/review-2026-10-24/`:

- `parity.out`: campos Lightning perdidos, minas Raon raio 0/dano 0; 18
  combinações com impacto mais próximo igual entre previsão e avanço direto.
  Esse probe chama `advance_projectiles`, não cobre a mina que só avança em `tick`.
- `mine-owner.out`: fixture controlada de mina com um passo restante:
  `before=0 live_after=1 prediction_after=0 live_mines=0 prediction_mines=1`.
  Confirma corrupção de identidade e caminhos distintos; não mede toda a
  propagação até a agenda/recompensa, que será teste da tarefa 1.
- `wind.out`: Boomer S1, força 60, mira 45°, seed 7, terreno procedural:
  x do impacto sem vento 1239,134; com vento horizontal contrário 34,
  x=1033,152. O desvio de aproximadamente −206 px confirma efeito do vento
  atual, sem provar a curva clássica. Com vento a favor o tiro sai do mapa.
- Leitura estática direta de `GunBound.gme`, em `0x4513b0…0x451680`, confirma
  estado de curva e aceleração especial antes da integração do Boomer.
  O relatório recuperado registra MainAction `0x4542a0`, spawn `0x42bbb0`,
  tick S1/S2 `0x4513b0`, tick SS `0x452cc0` e explosão SS `0x48de60`.

Comando dirigido executado:

```sh
./scripts/check.sh test_classic_mobiles test_roster test_battle_rules test_xfs_hd_migration
python3 -m unittest discover -s tests -p 'test_avatar_effect_source.py' -v
```

As quatro suítes registram **136 + 63 + 60 + 2009 = 2268 checks, zero falhas
de assertiva**, mas o harness retorna **4**: todos os processos Godot emitem
`ERROR get_system_ca_certificates (os_macos.mm:1035)` neste ambiente. Não
enfraquecer o harness nem chamar esse resultado de verde. Há também avisos
de `Image.load` nos sprites clássicos, que pedem smoke do PCK (tarefa 4).
Os **2 testes Python passaram**. Não rodados: suíte completa, partidas,
captura GPU nova, exportação e validação manual. Evidências anteriores do
HANDOFF principal continuam históricas, não reexecuções desta revisão.

## Foco da revisão de implementação

- Mina do adversário detona durante uma salva: autoria, custo, Gold e item
  do tiro em andamento permanecem do seu atirador; tarefa 1.
- Mina mata durante mira/resolução: concluir resultado uma vez, sem XP
  duplicado e sem snapshot tocar atores vivos; tarefa 1.
- Dual/Dual+/Teleport e filhos de explosão: preservar arma, raio, emissão e
  regras de colisão de cada componente; tarefas 2, 6 e 7.
- Direção esquerda, terreno inclinado, vento vertical/zero e limites 10/90°:
  mesma geometria no HUD, CPU e lançamento; tarefas 3, 5 e 6.
- PCK sem PNG fonte, pausa, FPS variável e recuo longo: mesmos sprites,
  duração e número de sons/lançamentos; tarefas 4 e 7.

## Ordem de execução

1 → 2 → 3 formam o primeiro pacote de correções, mantendo ADR-076.
4 prepara a matriz de fontes; 5 tem decisão de física aprovada (ADR-084); 6 depende
de 4/5; 7 usa o contrato de emissão validado em 6. A tarefa 8 é pesquisa
separada para reduzir as incógnitas dos demais tiros.

### Tarefa 1 — autoria e simulação das minas

**Arquivos:** `scripts/classic_flight.gd`, `scripts/match.gd`,
`scripts/flight_snapshot.gd`, `tests/test_classic_mobiles.gd`;
criar `tests/test_classic_flight_parity.gd` e registrar no `scripts/check.sh`.
**Consome:** `_detonate_mine(model, index)`, `tick(delta)`,
`advance_projectiles(delta)`, `FlightSnapshot.capture/arm`.
**Produz:** mina não altera `shot_actor`/`shot_weapon`; voo e previsão
avançam minas no mesmo passo. Snapshots continuam cópias isoladas.

- [ ] Criar regressão baseada em `mine_owner_probe.gd`: mina do ator 1
  detona durante tiro do ator 0; assertar `shot_actor == 0`, arma e atraso
  de 0 intactos, evento de mina atribuído a 1 e estado vivo isolado da previsão.
- [ ] Acrescentar resultado por mina letal em mira/resolução, sem resultado
  duplicado; fixture de perfil sempre isolada.
- [ ] Rodar as regressões antes da correção e observar a falha de autoria/paridade.
- [ ] Remover a atribuição global em `_detonate_mine`; passar `mine.owner`
  explicitamente a dano/eventos. Centralizar o avanço de minas durante voo
  no passo comum; `tick` não pode avançá-las duas vezes. Fora de voo, manter
  um avanço determinístico e verificar fim de partida após dano letal.
- [ ] Comparar eventos completos, HP/escudo, minas, terreno e autoria em
  `tick` real versus snapshot, com deltas 1/30, 1/60 e 1/120.
- [ ] Rodar `./scripts/check.sh test_classic_mobiles test_classic_flight_parity test_items test_gold_rewards test_scene test_matches`;
  conferir falhas funcionais e erros de engine separadamente. Preparar diff
  isolado para revisão; só versionar mediante solicitação.

### Tarefa 2 — preservar parâmetros de projéteis e filhos

**Arquivos:** `scripts/shell_state.gd`, `scripts/classic_flight.gd`,
`tests/test_classic_mobiles.gd`, `tests/test_classic_flight_parity.gd`.
**Consome:** `ShellState.create(position, velocity, spawn_at, rules, weapon, component)`.
**Produz:** mesma assinatura; `blast_radius` inicial vem de `rules.radius`,
e `bolt_extra`, `bolt_extra_radius`, `bolt_angles`, `bolt_reach` sobrevivem.
Arrays de regras não compartilham estado mutável entre projéteis.

- [ ] Testar `fire` + voo de Raon S2/SS até plantar mina: raio **21**,
  detonação em alvo dentro da caixa reduz HP/escudo, fora do raio não fere.
  Não injetar manualmente o raio da mina.
- [ ] Testar Lightning por `fire` + impacto em geometria que diferencie as
  quatro diagonais de um raio vertical; comprovar choque extra **35** no S2
  e alcance **100** do SS, com atributos zerados na fixture.
- [ ] Observar RED; transportar os campos pela fábrica e fazer cristal/
  fragmentos usarem `ShellState.create`, declarando overrides de dano/raio.
  Preservar cristal com 0/0 até a tarefa 8; não atribuir dano inventado.
- [ ] Testar Turtle SS e Dragon SS até os filhos terminarem, Dual+ com armas
  distintas e Teleport sem colisão com mobiles; remover campos mortos apenas
  se nenhuma regra os consome. Não misturar nova mecânica de tiro nesta etapa.
- [ ] Rodar modelos, itens e paridade; fechar o pacote de combate com
  `./scripts/check.sh` completo, incluindo partidas. Revisar toda atualização
  de referência: nunca aceitar novos resultados só por serem os atuais.

### Tarefa 3 — uma faixa de mira para modelo, CPU e HUD

**Arquivos:** `scripts/combat.gd`, `scripts/cpu_planner.gd`,
`tests/test_classic_mobiles.gd`, `tests/test_hud.gd`, `tests/test_aiming.gd`.
**Consome:** `Match.aim_limits/shot_velocity/muzzle`, `CpuPlanner.search(plan)`.
**Produz:** o catálogo limita a mira local; a conversão geométrica não impõe
um segundo teto de 85°. CPU inclui extremos legais na busca.

- [ ] Testar Boomer 85/88/90°: vetores diferentes, 90° vertical em apoio
  plano; refletir pela esquerda e inclinar apoio sem duplicar geometria.
  Testar também a borda de 10° e limites mais estreitos de Mage/Bigfoot.
- [ ] Observar RED e remover o limite conflitante de `launch_velocity`,
  preservando a assinatura atual. Adaptar grade da CPU a `plan.limits`,
  incluindo os dois extremos mesmo se o intervalo não for múltiplo de 5.
- [ ] Testar HUD e plano da CPU no mesmo limite; rodar
  `./scripts/check.sh test_classic_mobiles test_hud test_aiming test_performance test_matches`.

### Tarefa 4 — matriz original de identidade, arte e áudio

**Arquivos:** criar `docs/sdd/BATTLE_ASSET_MATRIX.md` e
`tests/test_classic_asset_manifest.py`; modificar importador,
`assets/openbound/<kind>/frames.json` e testes clássicos conforme a matriz.
**Consome:** `graphics.xfs`, `sound.xfs`, tabelas PE e relatórios recuperados.
**Produz:** uma linha por ID/arma com tipo do cliente, tank/bullet/flame,
`.epa`, som, hash, ausência intencional ou pendência e endereço de evidência.

- [ ] Conferir as 48 combinações. Reindexar os dados 13/14/15 do cliente
  como Dragon/Knight/Aduka; não usar nomes do enum do servidor como identidade.
- [ ] Escrever testes de importação antes da correção: Raon usa prefixo de
  áudio `RaonLauncher` (crosshair continua `Raon`); Dragon S1 procura a folha
  comprovada para essa classe; folha de brilho lê o `.epa` da bala base e
  não vira corpo e luz duplicados. Confirmar o mapeamento Dragon no binário
  antes de fixar `bullet14c` como contrato.
- [ ] Registrar todas as durações `.epa` e `spawn_ticks` por arma em metadados;
  gerar folha de contato e timeline de disparo usando fontes preservadas.
- [ ] Priorizar Turtle T1: comparar composição completa (bala, cabeça/rastro
  e impacto) com Armor T1 e com o Bullet12 original. Consultar
  `UnitProjectiles/TurtleProjectile.cs`, `MobileAction/HelicoidalTrace.cs`
  e `SpecialEffectBuilder.TurtleProjectile1Explosion` no C#. Capturar ambos
  no mesmo cenário e validar a aparência própria do Turtle. O teste deve
  verificar a composição/renderização, sem exigir PNGs base diferentes:
  as entradas originais são comprovadamente iguais.
- [ ] Conferir sons errados de Nak SS, Armor SS, Grub SS, ASate e Aduka com
  as tabelas e seus chamadores; presença de nome repetido não implica erro.
- [ ] Manter ausências reais explícitas. ASate/satélite, Knight sem blast,
  Aduka SS sem arquivo e composição `flame`/`ssflame` exigem fechar o caminho
  de fallback do cliente antes de sugerir uma escolha visual ao usuário.
- [ ] Capturar fonte e PCK com o mesmo estado e comparar encaixe dos 13
  clássicos. Investigar `Image.load` em `_opaque_feet`; preferir contato
  pré-calculado no importador se o PCK não fornecer o PNG cru.
- [ ] Rodar testes de manifesto, assets e cena. Matriz incompleta permanece
  marcada como incompleta; não anunciar paridade audiovisual integral.

### Tarefa 5 — física e vento originais (implementados na 0.20; critérios históricos abaixo)

**Arquivos previstos:** `scripts/combat.gd`, `scripts/mobiles.gd`,
`scripts/classic_mobiles.gd`, `scripts/shell_state.gd`, `scripts/match.gd`,
`scripts/weather.gd`, `scripts/aim_control.gd`, `scripts/cpu_planner.gd`,
`tests/test_battle_rules.gd`, `tests/test_weather.gd`,
criar `tests/test_classic_ballistics.gd`; SPEC/DESIGN/DECISIONS antes do código.
**Decisão:** usuário escolheu física original, carga de 3 s e força mínima
original; ADR-084 substitui parcialmente ADR-076. Falta executar o porte.

Recomendação técnica: portar o passo original, com ponto fixo de 8 bits a
20 Hz, mantendo apresentação suave separada. Uma parábola equivalente em
float pode coincidir em amostras sem reproduzir truncamentos, colisões e
transições; não chamá-la de reprodução exata. A colisão refinada do cliente
ainda não foi completamente analisada; registrar essa fronteira.

- [x] Apresentar escolha e impacto em mira, alcance, carga, CPU, seeds e
  golden master; usuário escolheu a original nas três questões.
- [x] Registrar ADR-084 substituindo a parte balística pertinente do 076
  e a carga de 2 s; CPU com cobrança fixa de 2 s, agenda e perfil preservados.
- [ ] Extrair fixtures independentes do cliente: força `[25]`, gravidade
  `[40]`, seno, truncamento e sequência por tick. Usar identidades corrigidas:
  Boomer 700/392, Bigfoot 840/392, Mage 900/360, Dragon 1000/360,
  Knight 960/392 e Aduka 960/376 (velocidade máxima / gravidade em pixels/s).
- [ ] Definir APIs e testes de ponto fixo no plano específico de física
  antes de implementá-las. Guardar posição/velocidade/aceleração inteiras
  no projétil e convertê-las para desenho, sem usar interpolação na colisão.
- [ ] Fixar aceleração no lançamento; testar vento zero/cardinal/diagonal,
  componentes truncados, ambas direções, mesma força e troca de vento após
  lançamento. Regra comum não recebe um multiplicador arbitrário por mobile.
- [ ] Adotar vento inicial 0–25, eventos 0–26, convenção de tela coerente,
  oscilação por turno e Change Wind +180 conforme evidência. Conferir o
  calendário contra `weather.gd`, sem mudar silenciosamente outras colunas.
- [ ] Implementar carga de 3 s e limite mínimo nativo, conforme decisão do
  usuário; validar truncamento da força por mobile e substituir o piso 15.
  Alinhar barra, Drag/Slice, CPU e disparo real, preservando disparo único
  e cancelamento pela pausa. Não substituir por outro piso arbitrário.
- [ ] Executar suites completas, CPU/performance e novas partidas dos 16
  mobiles; salvar baseline anterior e justificar cada nova referência.
  Golden master local anterior fica preservado, não sobrescrito.

### Tarefa 6 — Boomer S1/S2/SS comprovados

**Arquivos:** `scripts/classic_mobiles.gd`, `scripts/classic_flight.gd`,
`scripts/shell_state.gd`, `scripts/match.gd`, `scripts/classic_sprite.gd`;
criar `tests/test_boomer.gd`, incluir paridade e captura dirigida.
**Consome:** física decidida na tarefa 5, matriz da tarefa 4 e os métodos de
emissão existentes (`Mobiles.emission`, `ClassicFlight.prepare`).
**Produz:** estado de curva/transformação por projétil; CPU usa o mesmo passo.

- [ ] Revalidar relatório recuperado contra os trechos PE de spawn/tick/SS;
  fechar ponto de início e fim da animação `change`, fator e arredondamento
  do raio. SS não deve transformar só porque a idade do desenho atingiu um valor.
- [ ] Criar testes de referência: vento contrário habilita curva; vento
  nulo/a favor tem sustentação; sinal de vx refletido produz caso simétrico.
  Confirmar incremento angular **1°/tick** e parâmetro especial **50**.
- [ ] Testar S2 com quatro lançamentos em ticks **8/10/12/14**
  (0,4/0,5/0,6/0,7 s), S1/SS no tick 8; mesma mira e força, sem quatro
  projéteis sobrepostos em t=0. Um som por chamada de disparo original.
- [ ] Testar SS iniciando `change` em **36 ticks de voo**; conferir o fim
  da transformação e multiplicadores nos dados [81]/[82] antes de fixar
  as assertivas de dano/raio finais. Não confundir diâmetro da tabela com raio Godot.
- [ ] Observar RED; adicionar estado pela fábrica e preparar/avançar no
  laço comum. Comparar retorno, impacto, dano, crateras e eventos, incluindo
  Dual/Dual+, espelho/tornado e limite de idade/saída do mundo.
- [ ] Rodar `test_boomer`, paridade e `./scripts/check.sh` completo; gerar
  captura com vento 0/a favor/contra para avaliação funcional do usuário.

### Tarefa 7 — animação, lançamento e som no mesmo relógio

**Arquivos:** `scripts/import_classic_mobiles.py`, `scripts/classic_sprite.gd`,
`scripts/classic_mobiles.gd`, `scripts/mobile_looks.gd`, `scripts/battle_art.gd`,
`scripts/game.gd`; criar `tests/test_classic_shot_timing.gd` e captura audiovisual.
**Consome:** durações e `spawn_ticks` conferidos na tarefa 4, emissão da tarefa 6.
**Produz:** lançamento e som seguem a mesma chamada de emissão; recuo por
mobile/arma dura a sequência original, sem depender de FPS da apresentação.

- [ ] Testar Armor S2/SS tick 14, Ice S1 tick 13, Raon tick 11 e Boomer S2
  ticks 8/10/12/14, com pausa antes/do/depois do lançamento. Conferir
  metadados com o MainAction, em vez de substituir por SpawnTime C# divergente.
- [ ] Implementar relógio da pose com durações `.epa` e eventos de lançamento.
  Vários projéteis do mesmo spawn podem ter **um** som (Mage/Trico/Raon);
  vários spawns sequenciais exigem sons separados. Não tocar um som por
  componente automaticamente, nem tocar em `fire` e novamente em lançamento.
- [ ] Reexaminar Dual: `second_volley` hoje usa o primeiro spawn como início
  da pose. Com atraso de emissão, início de pose e lançamento precisam de
  tempos distintos; testar reinício de animação sem atraso duplo ou corte.
- [ ] Validar 30/60/120 FPS, pausa cancelando carga, áudio mudo, Teleport,
  recoil longo e rápido retorno do turno; preservar animação HD aprovada.
- [ ] Rodar cenas/input/modelos/partidas e captura GPU com áudio. Exportar
  somente na entrega executável, verificar assinatura e fazer smoke no PCK
  isolado, com a mesma timeline. Registrar limites de teste manual.

### Tarefa 8 — pesquisa dos demais tiros e novos planos por mobile

**Arquivos:** criar `docs/sdd/BATTLE_SHOT_MATRIX.md`; evidências brutas em
`.tools/battle-re/`; consultar `skills/gunbound-mobile-port/SKILL.md`.
**Produz:** 48 linhas rastreáveis ou pendências explícitas, seguidas de planos
de implementação por família. Não implementar algoritmo ainda desconhecido.

- [ ] Priorizar ASate/satélite, JD/cristal e Aduka/efeito secundário (poder 0
  não prova ausência de dano); depois Grub, Dragon e Knight.
- [ ] Conferir especiais C# contra cliente: Armor S2 (relatório aponta 2
  projéteis), Raon S1 (3 no cliente versus 4 atuais), Trico, Lightning,
  Ice e Turtle. Quantidades, trajetória e tempos só viram contrato após
  conferir os chamadores; parâmetros `count` não bastam para contar emissões.
- [ ] Para cada arma registrar Spawn/Simulate/tick/Detonate, filhos,
  dano/raio, tempo, vento, arte e sons com endereços e confiança.
- [ ] Abrir planos pequenos com testes de referência e de paridade; pedir
  decisão do usuário somente quando a evidência continuar ambígua ou quando
  for necessário escolher um substituto para recurso ausente.

## Fechamento de cada pacote

- [ ] Atualizar SPEC e plano antes de mudar comportamento, ADR quando houver
  decisão relevante; após validar, atualizar TASKS e HANDOFF com fatos observados.
- [ ] Corrigir a causa do erro de certificados no ambiente de execução ou
  revalidar em ambiente adequado. O aceite técnico exige harness sem erros,
  não só contagem de assertivas, além das partidas completas exigidas.
- [ ] Revisar diff e mudanças de referência; registrar o que ainda não foi
  comparado ao original. O aceite visual/sonoro final continua com o usuário.
