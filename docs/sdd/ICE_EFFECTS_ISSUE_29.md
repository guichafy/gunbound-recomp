# Ice T2/SS — issue #29 / ADR-162

O T2 soma 5 ao terceiro campo de vulnerabilidade do alvo, até 50, mesmo
quando o escudo absorve todo o dano. O SS usa sua própria área e altera
os quatro campos, com teto 20. Por exemplo, `[0,0,50,0]` vira `[5,5,20,5]`
com o SS. O fim da animação de gelo não desfaz esses valores.

Base: origin/main a525728fa1bd4ed1a13c80f173ff3508effdf479 (11/11/2026).
REQ-04/05/07/08/09/19/20/38/44/45. Escopo offline1×1, perfil/arte/IDs preservados.

## Evidência e contrato

PE SHA2564af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde;
DAT b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf;
XFS a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08.
Ghidra12.2/JDK26, banco próprio /private/tmp/gunbound-ice-29-ghidra;
consultas01/02/04/05 com run/manifest.ok/source_unchanged=true. Consulta03
parcial:541023 não é função reconhecida; não usada como prova de sucesso.

| Regra | VA/unidade/ordem | Estado |
|---|---|---|
| Quatro campos | ator+b728/b94c/bb70/bd94, inteiros protegidos, inicialmente0 (458b80) | comprovado |
| Consumo |45db20: quatro IDIV sucessivos por100; fatores100+campo, selecionados por bits8/4/2/1 do ataque | comprovado |
| T2 |474650/474ef5: vetor[0,0,5,0] →450eb0→45db20; somente dano calculado>0, ANTES do escudo/HP; min(campo+vetor,50), sem piso | comprovado |
| T2 alvos |45db20: alive908, !bff7, tipo!=14; aplica inclusive escudo absorvendo tudo; não depende de eventoHP | comprovado |
| SS |4759b0:48de60 blast primeiro;425ac0 área estrita em hotspot−(0,10), raio130 DAT; mesmos filtros; todos min(campo+5,20) | comprovado |
| SS teto |40d8e0 inicializa e55ab8=20. SS pode REDUZIR campo>20; não aplicar max(old,new) | comprovado |
| Duração |nenhum decremento/expiração de campo; resets no construtor. Scan de offsets explícitos fecha consumidores/init/destrutor; loop indireto de45db20 também conferido | comprovado/escopo estático |
| Pose |string ice em555cc8; EPA ice, um frame com duração própria (Mage/Lightning/ASate/Grub1tick, demais20); T2 pula pose para tipos5/6/8/10, SS não | comprovado |
| HP terminal |cliente conserva alive até atualização do ator, mesmo HP<=0; treino já tem ponte HP0 e flush por tick | ponte declarada |
| Balística/contato |preservar caminho atual Ice e AdukaWeather.active; máscara global não ativa contato nativo | adaptação preservada |
| Dano/cratera T2/SS |parâmetros DAT e consumidores comuns comprovados necessários à elegibilidade; geometria hotspot/itens do treino mantida | nativo com pontes |
| Outros tiros |aplicar os quatro fatores ao dano existente conforme máscara nativa DAT; não portar toda a base de dano de outras famílias | ponte explícita |

`native_resistance` é vulnerabilidade por classe, não atributoDEFENSE.
Os catálogos anteriores de algumas famílias chamam o campoDATpercent de flags;
a máscara para estes quatro fatores será extraída separadamente do campo
seguinte comprovado em41da80. A regra base dessas famílias fica preservada;
isso é limite explícito, não alegação de revisão integral de dano.
OráculoUnicorn2.1.4 executa45db20 inteiro, incluindo escudo/HP; SS4759b0
executa estado e425ac0 reais com lookup de slot controlado, omitindo blast/UI.
Fixtures sem importação de Godot em tests/fixtures/ice_native.json.

## Plano de implementação

**Goal:** substituir chill pelo contrato separadoT2/SS sem tocar no perfil.
**Architecture:** módulo ice_effects.gd guarda operações puras, parâmetros e
catálogo pré-aquecido; Match decide impacto; atores/snapshots guardam quatro
inteiros; apresentação usa evento ice_effect e quadroEPA já existente no atlas.
**Tech Stack:** Godot4.7.2/GDScript, Python3.12, Ghidra12.2/Unicorn2.1.4.
**Spec:** SPEC.md/ADR-162 e matriz acima. Execução inline autorizada, sem pausa
para aprovação genérica. Revisão independente ao fim, antes do merge.

### 1 — Regressão e dados independentes
- [x] Gerar fixtures e catálogo reproduzível PE/DAT/XFS, sem alterar atlas.
- [x] Criar test_ice_effects via Match.explode; comprovar RED no código antigo.
- [x] Cobrir repetição, limites, escudo, zeroHP, tipo14/imune/morto e áreaN−1/N/N+1.

### 2 — Modelo comum e apresentação
- [x] Criar ice_effects.gd: warmup(), active(shell), prepare(shell,actor),
  parameters(shell,actor), eligible(actor), t2(actor,amount), ss(actor,origin,impact),
  modify_damage(actor,amount,flags), attack_mask(vehicle,weapon), pose(vehicle).
- [x] ActorState cria native_resistance independente; Match T2/SS usa parâmetros
  nativos, T2 aplica antes de Damage.deal_damage, SS depois do blast com alive
  estampado antes dele. Eventos não geram novo dano/Gold/itens/resultado.
- [x] Remover ClassicFlight.chill e entrada de catálogo; fatores tipados nos
  caminhos comuns e máscaras separadas para consumidores já portados.
- [x] BattleArt/ClassicSprite/Nak usam quadro ice e relógioEPA, sem congelar input
  nem expirar os quatro campos. Pausa congela apresentação existente.
- [x] Confirmar GREEN/fixturePE, snapshot profundo/CPU sem mutação do perfil/mundo.

### 3 — Validação e entrega
- [x] Suites dirigidas e harness integral, mantendo29partidas por processo.
- [x] GPU ID11, impactos repetidos, ambos sentidos e pausa; smoke embarcado.
- [x] Revisão independente dos cinco focos; corrigir achados com regressão.
- [ ] Atualizar TASKS/HANDOFF/MOBILES; diff/lint; commit/push/PR; quatrochecks,
  rebase merge; confirmar issue, SHA/mainCI e release automática.

## Resultados e limites

Baseline dirigido:6suítes/1079checks aprovados (baseline-retry.log).
RED inicial12checks/10falhas → GREEN ampliado300/0;8dirigidas1617/0.
Oráculo final:34danos+16corpoBigfoot+24SS+48máscaras+6inicializaçõesIce.
Revisão independente aprovou runtime/ABI/focos; P2 de proveniência corrigido,
com rejeição de PE divergente e regeneração idêntica confirmadas pelo revisor.
Leitura original do retorno boolEAX no oráculo de máscaras foi corrigida paraAL;
comparações de arraysJSON foram normalizadas para inteiros. Nenhum esperado
Godot foi usado como fixture doPE. Sonda de corpo separou bottom13c0 e flags9ce4.
Pose20ticks e inclusão dos metadados nos dois exports tiveram regressãoRED
antes das correções.
GPU final451quadros1920×1080/60Hz manual,30pausasRGBA idênticas por verificador
Python separado. Antes/depois dos impactos repetidos, dois sentidos e50→20;
PNG/MP4/manifest em docs/ice-native. Captura padrãoID11:11stills em docs/mobile-shots.
Primeira captura teve ParseError pelo nomePanel; renomeada. A primeira composição
foi substituída porNode2D filho escalado e viewports isolados; somente final éQA.
Pacote localmacOS universal assinado/ZIP extraído fora do projeto:48tiros+UI
e estadosIce aprovados; sem publicação manual. A versão local é0.20.5 docheckout.
Rodada integral01 exit1: Python semcoverage no ambiente emprestado e descriçãoIce
sem tradução; venv própria com requirements-ci pinado e tradução corrigidas.
Logs vermelhos preservados em .tools/ice-29/full-01-logs. Repetição final exit0/377,427s:360parses,114suítesGodot/54.937checks,
160Python sem skips/falhas e29partidas. CoberturaPython62%; Ruff/diff aprovados.
Performance24/0: frames máximos0,976/1,133ms nos dois casos de cena do host,
sem extrapolar benchmark para outras máquinas. Report completo .tools/check-logs/report.json.
Pacote final após tradução:ZIP SHA256
17b3d852633df1db589768be7b9d3fd0f645f09824722cf21303e869268634f6;
manifest ainda identifica a baseHEADa525728f, porque export precede commit.
Build/release remotos validarão o SHA exato integrado.
Primeiro import sandbox terminou com erro ambiental ret!=noErr; repetição fora
do sandbox aprovada. Cliente Windows inteiro/aceite humano ainda não executados.
