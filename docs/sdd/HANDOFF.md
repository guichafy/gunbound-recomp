# Hand-off — Gunbound Recomp 0.20.5

## Grub: clima no S2/SS e luz do casco na sala — 28/10/2026

Relato do usuário na `main`: tiros do Grub não interagiam com eletricidade/tornado e a imagem do
Grub na sala ficava errada, piorando depois do Start. Emenda 2 da ADR-150 (REQ-51).
S2/SS chamam `AdukaWeather.sample` em cada amostra grossa da varredura (antes do terreno) e
`AdukaWeather.finish` no lugar de `v+=a` com tornado, como `0x49e650`/`0x4857f0` e `0x49fd40`/`0x486ea0`
(prova estática; o emulador não exercitou colunas). T1 segue o contato comum. A luz `tank13l` passou a
valer por view (`hull_view`): sala/loading mostram o casco aceso como na batalha e não acumulam mais a
luz no loading seguinte a uma partida. `test_grub_model` 300/0 (12 checks novos de clima falham sem a
ligação); sonda GPU local `.tools/grub-room/proof.gd` com recorte da figura idêntico entre 2 e 40 quadros,
após a partida e no segundo loading. Harness completo: parse OK, todas as suítes Godot sem falha,
`test_matches` 13/0 e `test_classic_matches` 16/0; exit 5 por 5 suítes Python de assets que exigem
`.tools/gunbound-client/sound.xfs`, ausente neste checkout (não tocadas). Sem versão, exportação ou
push; aceite visual do usuário pendente. `project.godot` reformatado pelo editor ficou fora do commit.

## Main protegida e anexos das próximas releases — 28/10/2026

Nova branch codex/main-protection-release-assets criada de origin/main
f4cdbbc3, com pull --ff-only. Configuração administrativa aplicada e relida:
main exige PR, branch atualizada, histórico linear e quatro checks de
lint/versão/testes-build-smoke macOS/Windows da app GitHub Actions15368;
administradores sujeitos às regras, sem force push/exclusão. Somente Rebase and
merge permitido; zero aprovações externas no repositório individual.
Política versionada em .github/main-protection.json e merge-settings.json;
editar os JSONs não altera configurações remotas automaticamente.

Usuário aprovou dois ZIPs + SHA256SUMS nas próximas releases. Todos os seis
arquivos internos continuam validados; manifestos e hashes individuais ficam
nos artifacts desktop (14dias). Consolidado temporário UTF-8/LF, falha de upload
mantém draft e retry não altera inputs nem migra releases publicadas.0.21.0
preservada com seis anexos; os dois Source code são automáticos do GitHub.
Prévia do PR agora valida os commits reais preservados pelo rebase, além do
título, para antecipar erros convencionais antes do merge.

Testes de publicação/versão reproduziram o comportamento antigo antes da
correção. 39 testes da automação, Ruff e actionlint aprovados. Suíte Python
completa: 144 testes em 60,929 s, zero falhas/skips; revisão independente sem
achados novos. Log .tools/main-protection-python.log. CI da nova revisão deve
ser conferida no PR; não reutilizar o resultado da release anterior como prova
desta mudança. Sem alteração no jogo, assets, perfil ou versão de desenvolvimento.

## Primeira release automática publicada — 28/10/2026

Pipeline main40752719203 no SHA f4cdbbc39453bddfb3eb121ff5102b14e816542b:
lint, versão, macOS, Windows e publicação aprovados. Em cada runner nativo:
100suítes Godot/45.935checks,29partidas,139testes Python sem falhas/skips;
cobertura da automação Python51%. Ambos ZIPs extraídos passaram smoke
lobby/sala/loja. Release pública v0.21.0, tag no SHA testado, seis arquivos
anexados; manifestos, tamanhos e SHA256 do servidor conferidos.
macOS universal com assinatura ad-hoc, sem notarização; Windows x86_64 unsigned.
Execução: https://github.com/guichafy/gunbound-recomp/actions/runs/40752719203
Release: https://github.com/guichafy/gunbound-recomp/releases/tag/v0.21.0
Esses resultados são da primeira release, não da revisão posterior dos anexos.

## Validação hospedada do PR11 — JSON canônico no Windows (28/10/2026)

Execução Actions40738742117, revisão daec5b63: macOS aprovou testes, cobertura,
exportação universal, smoke do ZIP e upload. Windows aprovou as100suítes Godot,
45.935checks e29partidas, mas dois dos139testes Python falharam: catálogos
regenerados pelos importadores ASate/áudio tinham CRLF em vez do LF versionado.
A gravação dos JSONs e sidecars de áudio agora usa bytes UTF-8/LF; WAV/MP3,
regras e assets versionados preservados. Os testes de reprodução simulam a
conversão de newline Windows em qualquer SO; ambos falharam antes e passaram
com a correção. Workflow antecipa esses dois checks e mostra log Python em
caso de falha. O resultado da nova revisão deve ser conferido nos checks do PR;
não confundir o sucesso macOS da revisão anterior com validação da nova.

## CI/CD desktop implementado — REQ-52 / ADR-151 (28/10/2026)

O pedido posterior corrige a entrega documental e autoriza implementar a pipeline
no PR11. Workflow em PR/main: lint, versão convencional, bootstrap Godot4.7.2 e
TestClient por hash, matriz nativa macOS/Windows, harness completo/29partidas,
cobertura Python (piso40% na automação), exports e smoke de ZIP extraído fora
projeto. Release somente main, após ambos pacotes; tag-reserva durável, draft,
checksums/manifestos, retomada de upload e validação do SHA. Título de PR é
revalidado inclusive ao editar; main exige commits convencionais novos.

Revisão independente: corrigidos lookup de drafts, validação de tag divergente,
reservas de versão e título do PR. Script de smoke opt-in injeta perfil isolado
antes de criar o perfil normal; o template release não aceita --script do editor.
macOS universal validado com ZIP real, lobby/sala/loja e codesign estrito; versão
local0.20.5, sem release publicada nesta sessão. Windows está configurado para
execução no runner hospedado, ainda sem prova nativa local. Cobertura de linhas
GDScript, notarização/Authenticode e QA humano continuam limites explícitos.
Plano, comandos e política em CI_CD_PLAN.md/CI_CD_DESIGN.md.

Validação local final: `GODOT=… python scripts/ci/check.py`, exit0, parse
aprovado, 99suítes Godot/45.926checks/zero falhas, 13+16partidas e139testes
Python/zero skips. Smoke isolado adicional:9checks/0. Cobertura da automação
Python52% (piso40%), XML/HTML gerados. Ruff e actionlint passaram; a única
exceção documentada é o schema antigo de concurrency.queue do actionlint.
Log `.tools/full-ci-check.log`; relatório `.tools/check-logs/report.json`.
ZIP macOS real passou; Windows ainda precisa do runner hospedado no PR.

## English repository presentation — 2026-10-28

At the user’s request, the public GitHub description and the entire root README
were translated into English, including headings, tables and image alt text.
Existing links, technical scope and validation limits were preserved. Linked
Portuguese documents are identified as such. The rendered preview and saved
README were checked in the browser; no harness run, behavior change or export.

## Apresentação do repositório GitHub — 28/10/2026

Revisão solicitada pelo usuário e realizada pela interface do GitHub: descrição
e dez tópicos salvos; README corrigido para distinguir código público de builds
locais, atualizar Grub/Boomer e vincular validações por mudança. Acrescentados
requisitos, clone, orientações de issues/PRs e referências/atribuições.
Validação: prévia renderizada e conteúdo salvo conferidos no navegador.
Sem alteração de comportamento, execução do harness, versão ou exportação.
Servidor, multiplayer e demais plataformas continuam no roadmap.


## Boomer — consumidores intermediários e inteiros protegidos

REA/Ghidra mostraram que 0x40a380 renova a chave com 16 `_rand` quando
a chave antiga é não nula. Uma leitura íntegra por 0x40a2e0 também chama
o setter e pode consumir esses 16 valores; soma/subtração protegida pode
consumir 32 no mesmo recorte. Contar apenas os pares booleanos subestima
o consumo entre clima e animação. Callbacks de UI e eventos da cena antes
dos mobiles continuam com destinos dependentes do estado. Quatro auxiliares
foram delimitados sem calls a RNG; o relatório conserva indireções como
desconhecidas. Evidências, grafo de 2207 funções e probes em
`BOOMER_ISSUE_9.md`. Nenhuma pose de chassis sob vento foi comprovada.

## Boomer — recepção de clima e ordem do RNG

No caminho do laço principal, 0x413130 drena mensagens por 0x4129c0
antes de executar passos de 50 ms da cena. A vtable 0x5566d8 encaminha
o pacote pelo slot +8 a 0x4b5460 e o passo +0x24 a 0x4bd8b0. Se a
cena ativa e o pacote 0xc300 forem esses, seu tratamento ocorre na mesma
thread antes dos passos: dois sorteios no setter inicial, mais dois no
ramo opcional do parser de clima. O passo da cena tem outros dois antes
de iterar objetos; demais consumidores impedem contagem global exata.
Não foi demonstrada pose apoiada dependente de vento. Evidências e limites
em `BOOMER_ISSUE_9.md`; somente documentação alterada nesta investigação.

## Boomer — ordem da fila de clima no quadro

Em 0x4bd8b0, a iteração virtual dos objetos ocorre antes da chamada
condicionada a 0x4ce610, que processa o Change Wind da fila quando o
contador chega a zero. No caminho observado estaticamente, ambos ocorrem
na mesma thread; o passo já realizado não é reexecutado por esse caso.
Recepção externa e ordem global do RNG entre quadros continuam abertas.
O código não prova pose de chassis apoiado dependente do vento. Probe
estático dos bytes passou; detalhes e limites em `BOOMER_ISSUE_9.md`.

## Boomer — correção do ramo `emotion1` e produtor da flag

O `case 0` de 0x45ed80 é o tipo do mobile, não o estado EPA. Boomer é
tipo 5 e não percorre o sorteio `emotion1`/flag do caso 0; a afirmação
anterior estava incorreta. 0x439e40 grava +0x8ba8 como verdadeiro no ator
selecionado sob condições, usando dois sorteios, e limpa o anterior.
O passo do piloto precede o chassis; no laço 0x4bd8b0 a atualização de
objetos antecede uma transição condicionada na mesma thread. A ordem
entre eventos de vento e quadros completos ainda não está demonstrada.
Detalhes e limites em `BOOMER_ISSUE_9.md`; nenhum código do jogo mudou.

## Boomer — flag e RNG no caminho de clima

REA rastreou 0x4d0a10 → 0x41ebf0 → `_rand`: a rotina que recebe dados
incluindo o vento consome dois sorteios apenas num ramo condicionado pelo
modo e pelos dados. A fila 0x4ce610 também tem um ramo condicionado com
dois sorteios, separado do caso Change Wind; as flags escritas nesses ramos
não são a +0x8ba8 que controla `emotion1`. O RNG é por thread: a sequência
e uma influência sobre o sorteio da pose continuam sem prova em execução.
O apoio aprovado e o código do jogo não foram alterados. Evidências, limites
e tentativa de emulação em `BOOMER_ISSUE_9.md`.

## Boomer — rastreamento de indireções do repouso

REA e Ghidra fecharam a chamada virtual do objeto interno de piloto:
o construtor 0x458b80 chama 0x44fb40 em +0x38, que instala a vtable
0x555b38; sua entrada +8 é 0x44fcb0. Esse passo avança o EPA e escolhe
`normal`/`look` por sorteio e flag, não por leitura direta do vento.
Ao terminar `normal`, o caso do tipo nativo 0 em 0x45ed80 pode escolher
`emotion1` por sorteio e flag +0x8ba8; esse caso não é do Boomer tipo 5.
`tank6.epa` contém 30 quadros para essa sequência, mas seu uso não foi provado.
Isso é evidência de variação visual sem leitura direta de vento, não prova
que o vento jamais a influencie indiretamente. A chamada ao cliente Windows
não foi executada. Vtables, hashes, evidência REA e limites documentados em
`BOOMER_ISSUE_9.md`; código e apoio aprovado não foram alterados nesta etapa.
O armazenamento de booleanos 0x4064a0 também consome duas chamadas a
`_rand`; a flag +0x8ba8 pode ser zerada ou copiada por caminhos identificados.
Essa concorrência de consumo é uma hipótese de influência indireta, ainda
sem prova para mudança de vento. Probe de vtables/PE/XFS passou novamente e
`./scripts/check.sh test_boomer` passou 928/0 nesta investigação.

## Issue #8 — Grub pelo cliente, 28/10/2026

REQ-51/ADR-150. Ghidra 12.2 + execução das rotinas do PE num emulador x86 (Unicorn, `tests/tools/grub_oracle`).
S1/SS θ+2; S2 emite 4 corpos; S2 e SS ricocheteiam (`grub_flight.gd`/`grub_surface.gd`, módulo constante
1800/1600, detonam em 44/40 ou ao tocar com o contador no limite); SS atravessa mobiles e fere a cada quadro;
dano e cratera da linha type 12 (`grub_combat.gd`). Rastro S2/SS e espelho SS. O par biônico 10/70 saiu só do Grub (a
linha type 12 não o tem); tornado, atributos do dono e contato do T1 permanecem adaptações. Matriz, hashes, comandos e perguntas em
`GRUB_CLIENT_FIX.md`. Resultados observados na seção de validação ao final dele. Sem versão nova,
exportação, commit ou push; cliente Windows e escuta não exercitados.

## Boomer — sequência de vida baixa, ADR-149

`wnormal`/`wmove` no caminho 0x461ca0 dependem de vida atual < máximo/3
inteiro, não do vento. `Mobiles.low_health` aplica esse limite ao Boomer;
outros mobiles mantêm a regra existente. `test_boomer` 928/0. GPU 640
quadros: 332/333 de 1000 HP, vento 0/26, dois sentidos, pausa30/retomada;
`docs/boomer-weak-pose-20261028`. O efeito do vento sobre o chassis apoiado
segue sem consumidor comprovado, apesar da varredura adicional no PE.
Detalhes, hashes, REA, Ghidra e limites em `BOOMER_ISSUE_9.md`.
Harness completo: 29.244 checks Godot, 92 testes Python e 29 partidas,
sem falhas/exit0. Log `.tools/boomer-issue9/harness-wind-weak-adr149.log`,
SHA-256 `fd53eb788920a5ad5da811441453b2041ebd452ea3a23213b98ab7ab106af598`.

## Boomer — apoio em rampa, ADR-148

`Match.body_rotation` usa o alinhamento de três amostras e LUT nativos para
o Boomer; máscara de 2 px, hotspot e ponte de posição seguem adaptações.
Amostras GPU em `docs/boomer-support-20261028`: quatro combinações de rampa
e sentido, repouso/recuo e pausa30; vento apoiado 10 casos com Change Wind.
O usuário avaliou a montagem em repouso: “O apoio nas rampas parece correto”.
Esse aceite visual não comprova a equivalência integral do apoio nativo.
Recuo com roda elevada foi observado no quadro 108 do atlas nativo. Pose do
corpo sob vento ainda não comprovada e não inventada; comparar os limites em
`BOOMER_ISSUE_9.md`. Não há execução do cliente Windows.
Harness completo: 29.229 checks Godot, 92 testes Python e 29 partidas,
sem falhas/exit0; `.tools/boomer-issue9/harness-support-adr148.log`, SHA-256
`4ab92b1f3a12d6adefc121508c0599a11e629689ff0b3cf111256b2965790498`.

## Boomer — investigação anterior ao ADR-148, 28/10/2026 (histórico)

REA confirma três amostras nativas de terreno para Boomer (centro e ±14 px;
DAT 28×24), tratamento de borda e LUT de ângulo. O porte usa ±18 px,
`atan2`, clamp e grade de 2 px; a origem, o apoio e a pose ao vento ainda
precisam ser fechados. Snapshot e identificadores em `BOOMER_ISSUE_9.md`.
O usuário observou que o Boomer parece flutuar na captura de rampa. Uma
captura do mixer Godot de T2 e impacto foi ouvida e avaliada como correta
para esse cenário; não é comparação com cliente Windows. Repetição reproduzível
em `tests/capture_boomer_audio.gd` e `docs/boomer-audio/boomer-t2-mixer.wav`.
Não houve alteração de regra nem correção visual nesta investigação.

## Issue #9 Boomer — boca, poses e PCM, ADR-147 (parcial)

A boca usa o ponto fixo do chassis do cliente (DAT 75°/38, LUT e espelho),
independente da mira; suporte/inclinação no modelo offline e a conversão ao
hotspot continuam adaptações. HUD, sinalizador e previsão compartilham as
funções existentes. `tank6.epa` controla os tempos das poses de dano, item
e morte, sem a tinta/rolagem/fade genéricos. Os WAVs ativos de disparo e
impacto foram reimportados em PCM sem perda; seus dados importados coincidem
com `sound.xfs` do TestClient, cujo hash foi reconfirmado nesta etapa.

Harness completo: 113 suítes, 29.215 checks Godot, 92 testes Python e 29
partidas, sem falhas/exit0. `test_boomer` 899/0 e
`test_classic_shot_timing_scene` 49/0. Log
`.tools/boomer-issue9/harness-adr147.log`, SHA256
`f299d75c1151bb2f6609407058af44bc9a433023632bf7b07b0ffe6ed0ee8a79`.
Reexecução antes do commit: mesmo resultado, exit0; log
`.tools/boomer-issue9/harness-push.log`, SHA256
`bc37912d923e314ccb2ef28f6908ebf0521a0306c9312a662f92bdbcf7e53915`.
Capturas GPU 1920×1080: boca plana 540 passos/6 casos, boca inclinada 360/4,
poses nativas 720/8 e vento apoiado com Change Wind 1000/10; pausa30 e
retomada em todos. As fixtures tardias tiveram parse dirigido e execução
GPU; detalhes, repetição de fixtures e limites em `BOOMER_ISSUE_9.md`.

0x450730 avança o EPA sem leitura direta do vento; 0x45cb50 o aplica à
posição em queda. As chamadas indiretas não excluem outra influência sobre
a pose apoiada. O áudio `docs/boomer-audio/boomer-t2-audicao.wav` é uma
mistura de referência dos PCM nativos, não gravação do aplicativo; escuta
humana, aceite visual e cliente Windows seguem não exercitados. O usuário
solicitou o encerramento da issue e o envio à main; essa decisão não elimina
os limites registrados. Não houve nova exportação de app/ZIP.

## Issue #9 Boomer — vento na queda, ADR-146 (parcial)

Animate 0x461ca0 chama 0x45cb50, que em queda acumula o vento horizontal
quantizado e desloca o chassis com quociente/resto assinados; o Boomer usa
esse passo no laço comum real/previsão. Os outros mobiles preservam ADR-077.
Queda instantânea, interpolação, paredes e condições nativas de estado
continuam adaptações. Não foi demonstrada pose dependente do vento apoiado.
Change Wind e Moon/Eclipse foram exercitados especificamente no Boomer;
Moon/Eclipse foram forçados nas fixtures, não sorteados em Miramo.

Harness completo: 29.146 checks Godot, 92 testes Python, 13 partidas gerais
e 16 clássicas, sem falhas/exit 0; log `.tools/boomer-issue9/harness-adr146.log`,
SHA256 `2d66da3b9934e5e32614aa2f3fb2b11831ee84242c72dbe8328cd603afac4d1e`.
O teste Boomer atualizado passou 861/0. A nova captura foi criada após o
parse global e passou em parse dirigido. GPU 1920×1080: 1120 passos, 14
casos, dois sentidos, pausa30 e retomada. Uma primeira captura com terreno
visual incorreto foi descartada; a final tem máscara e desenho alinhados.

REA/Ghidra e classificação dos sete climas em `BOOMER_ISSUE_9.md`. A boca
nativa usa pares DAT 75/38 e inclinação do apoio; falta reconciliar o ponto
de referência do ator e o movimento do apoio antes de alterar a geometria.
Cliente Windows, escuta/mouse e aceite visual não foram exercitados. A cópia
local de sound.xfs não foi reencontrada; mantém-se a verificação histórica.
Issue #9 não concluída; sem reexportação de app/ZIP, commit ou push.

## Issue #9 Boomer — continuação ADR-145 (parcial)

Harness completo: 29.102 checks Godot, 92 testes Python, 13 partidas gerais e
16 clássicas, exit 0. Log `.tools/boomer-issue9/harness-adr145.log`, SHA256
`f744fb5131398d5d5ecd266275d1a2209a8a810953bdb17c56b1672f3c7bdb97`.
Após o harness, houve apenas limpeza dos PNGs da captura e parse dirigido.

Explosões do Boomer acionam minas na elipse comprovada, com borda estrita e
autoria; o SS transformado compõe flame63/ssflame6 e gira as duas camadas.
O dano/cratera das minas, RNG visual e ramo nativo de 5 graus permanecem
adaptações. Suites dirigidas: Boomer 817, minas 33, Gold 43 e itens de cena 49,
sem falhas. GPU 1920×1080: 360 passos, quatro cenários normal/transformado e
dois sentidos, pausa de 30 quadros idênticos. Registros e limites em
`BOOMER_ISSUE_9.md`; evidência REA em `builds/boomer-issue9-rea-impact.json`.
A emissão usa LUT e campos 36/37 do characterdata (75/38 para T1 do Boomer);
composição e conversão ainda não foram fechadas, então a boca segue adaptação.
Consumidor do vento no chassis, critérios restantes,
escuta e aceite visual continuam pendentes: issue não concluída. A captura não
executa o cliente Windows; app/ZIP não reexportados.

## Issue #9 Boomer — histórico ADR-142/143/144

Dano/cratera e atributos (ADR-142); varredura 455cc0, Force/tornado e
orientação dos tiros (ADR-143); eletricidade/Thor anexos (ADR-144). Harness
`./scripts/check.sh`: 29.069 checks Godot, 13 partidas gerais e 16 clássicas,
zero falhas/exit0, parse aprovado; `.tools/boomer-issue9/harness-adr144.log`,
SHA256 `711f1b12b445c90d362d4cb60cbedf11be4e922ad0a0d9a41ba7b75843810a58`.
Depois do harness, quatro checks de Thunder, Teleport e vento foram adicionados
sem alterar produção; rodada dirigida `test_boomer` 788/0, `test_items` 49/0,
`test_mage_weather_effects` 57/0. A captura climática criada após o parse do
harness foi compilada e executada separadamente.

GPU: seis capturas de tiros, 240 passos/1280×800, SS35/36/45/46; mais dez
T1 com vento zero/quadrantes, 180 passos, ambos sentidos. Todas com pausa30
idêntica e retomada. Seis cenas climáticas controladas, 540 quadros/1920×1080,
1/4/1 efeitos elétricos e Thor por arma/sentido, pausa30 e retomada. Amostras
em `docs/boomer-issue9` e `docs/boomer-weather`. Captura anterior descartada:
máscara de terreno e indicador de vento estavam inconsistentes; final corrigida.
REA/Ghidra e matriz em `BOOMER_ISSUE_9.md`. Vento no chassis, colisão com
minas e efeitos/impactos ainda precisam de auditoria; não anunciar paridade
integral. Sem cliente Windows, escuta/mouse ou aceite visual; app/ZIP não
reexportados. Issue #9 ainda aberta e não concluída.

## Relevo dos poços da sala — ADR-141, 27/10/2026

Pedido posterior restaura os seis poços rebaixados visíveis no `room_back`;
as seis faixas A/B vazias continuam ocultas e sem controles. Substitui a
cobertura da ADR-140. REA/Hopper confirmou carregamento `ready_back.img`,
e quadro 0 do XFS é pixel idêntico ao PNG nativo; detalhes e evidências em
`ROOM_REFERENCE_LAYOUT.md` e `.tools/room-depth`. Seis suítes dirigidas:
685 checks/0; captura GPU 1920×1080, nativo/HD com geometria igual. Cliente
Windows, mouse físico e aceite visual não exercitados. Sem novo app/ZIP,
versão, commit ou push; harness completo não repetido para esta apresentação.

## Issue #10 — sala 1×1, 27/10/2026

REQ-02/ADR-140: somente TeamA0 e TeamB0 aparecem no 1×1. Os seis poços
desenhados pelo próprio `room_back` são cobertos pelo azul do painel; faixas
e coberturas seguem capacidade por time, sem novo modo. Coberturas ignoram
mouse. `test_room_reference` 232/0, incluindo cliques nos poços, Random e
capacidade maior; GPU 1920×1080 em `.tools/issue-10`, nativo e HD com
geometria/hitboxes iguais. Sem mouse físico ou aceite visual humano. Não
alterados versão, app/ZIP ou assets. Registro `ROOM_REFERENCE_LAYOUT.md`.
Harness completo `./scripts/check.sh`: 28.373 checks Godot, 29 partidas e
suítes Python, zero falhas, parse aprovado e exit 0.

## Versionamento da pré-partida e posição dos nomes — 27/10/2026

Pedido atual autoriza o commit local das correções anteriores e esclarece:
somente reposicionar os nomes na prévia inferior, sem adicionar mobiles.
Ghidra12.2 confirmou 0x4430c0 (linha+18) e o consumidor 0x442280 (mapa em y18,
nome em y+5). O porte já soma STAGE_ORIGIN; retirar a margem repetida18 e o
ajuste extra20, conservando somente +5. Nomes sobem33px nativos e mantêm x,
fonte/cor/indicador existentes. Imagem/máscara atual do painel preservadas;
`loadstage.img` do PE tem228px e não substitui o painel209px já aprovado.
ASM, pseudocódigo e manifestos em `docs/match-loading/native-surface`.

Validação final: **10 suítes / 1.401 checks Godot / zero falhas/exit0**,
incluindo os11spawns (test_match_loading33/0) e menu clássico146/0. Log
`.tools/match-loading/names-final-tests.log`. GPU1920×1080:18casos,
72comparações idênticas e295passos temporais; nenhuma figura desaparece,
mapa/título estáveis e entrada na batalha após5s. PNGs/relatório atualizados;
log`.tools/match-loading/names-final-gpu.log` semERROR/SCRIPT ERROR.

Cinco arquivos centrais do menu clássico idênticos ao HEAD anterior; física,
perfil real e assets originais preservados. Sem harness completo novo/29
partidas (apresentação), cliente Windows ou escuta; captura muda. Tentativa
intermediária teve erro de inferência e foi descartada; o ramo experimental
de marcadores nativos saiu após o esclarecimento do usuário. Somente as
rodadas finais acima validam este snapshot. Capturas não comprovam60FPS.
Fonte0.20.5, aplicativo/ZIP não reexportados; aceite visual pendente. Sem push.


## Correção da pré-partida após validação — REQ-49 / ADR-138

Pedido de 27/10/2026: painel central mostrava o mobile do piloto e os pilotos
sumiam ao Start. `present_loading` passava um retrato para a prévia, criava
um título de mobile e exibia os nomes nos slots; `draw_room_figures` desviava
para um desenho só de casco. Removidos esses caminhos: `room_maps[1]` mantém
a imagem e o título MIRAMO TOWN do cliente (`ready_selectmap.img`), sem label
sobreposto. Sala/loading compartilham mobile+piloto/equipamento/animação e
os cabeçalhos dos slots ficam livres de nomes de mobiles. Random, mínimo
5 s e spawns mantidos. Arte/layout/menu clássico ADR-137 preservados.

Regressão reproduzida antes do ajuste: três falhas headless e quatro recortes
GPU diferentes. O teste antigo que exigia o comportamento errado foi corrigido.
Validação dirigida: `./scripts/check.sh test_match_loading test_room_ui
 test_room_reference test_room_polish test_room_settings test_scene
 test_battle_options test_aiming test_hud test_result_screen`: **10 suítes,
1.390 checks Godot, zero falhas/exit0**. Parse dos quatro scripts alterados
aprovado. Log local `.tools/match-loading/correction-tests.log`.

GPU real 1920×1080: **18 casos e 72 comparações RGBA idênticas** (16 mobiles,
Random e fallback nativo da prévia). Sequência de **295 passos de 1/60 s**:
zero desaparecimentos, mapa constante, 135 poses distintas; loading presente
até 4,916 s e batalha após 5 s. PNGs inspecionados, relatório de hashes em
`docs/match-loading/room-loading-proof.json`; log GPU sem ERROR/SCRIPT ERROR.
A cadência simulada não comprova performance de 60 FPS.

Contrato e comandos em `LOADING_SCREEN.md`. Sem harness completo/29 partidas
novo (mudança de apresentação); sem cliente Windows ou escuta, captura muda.
Aceite visual pendente. Versão 0.20.5/app/ZIP mantidos. Sem commit/push;
seis untracked preexistentes de resultado/imports preservados.

## Encerramento da partida — ADR-139 / REQ-50

Pedido de 27/10/2026 (imagem de referência WIN/LOSE): o fim do treino abre a
janela de resultado do cliente no lugar do cartão com REVANCHE. Ghidra 12.2
(JDK 26, `builds/ghidra-result`) no PE `4af6283d…`: `result_back.img` é o
recurso 9001; `FUN_004c8890` desenha os painéis A (24,48) e B (403,48), WIN
para o time vencedor, e as linhas de y151 com passo 66; `FUN_004d0260` fixa
barra, rank1, guild/apelido em `font.fnt`, P `%3d` e G `%5d` em numfont; o OK
`b_result_confirm` (671,441) nasce na mensagem 0x4413. Contrato completo em
`RESULT_SCREEN_NATIVE.md`; extratos em `.tools/result-port/ev2..ev4`.

Código: `classic_result.gd` (layout puro + nó ×1,6), `match_overlay.show_result`
sem escurecer e com bloqueador transparente, catálogo `assets/xfs/result`
(58 quadros) de `scripts/import_xfs_result.py`, incluído no filtro de export.
Adaptações: OK volta à sala (despachante de 0x3f8 não localizado); OK sobre
o footer no canvas de 500; P = XP do porte, CPU "CPU"/Chick com 0P; empate
desenha LOSE nos dois; guild, marcador de evento e log no chat inativos;
aviso discreto só se o perfil não gravar.

Validação: `test_result_screen` 37/0 (oráculo dos offsets do ASM, cena, ESC,
XP único, ajuda, clique no OK) e `test_import_xfs_result` 4/0 (decoder
independente `gunbound_xfs.py`). Captura GPU 1280×800 em `docs/result-screen`
(vitória, derrota, empate, OK hover/push; log sem ERROR). Sobreposição com a
imagem do usuário recortada para 800×600 alinha painéis, barras, texto, P, G
e OK sem desvio (`.tools/result-port/blend.png`, fora do Git).
Harness completo `./scripts/check.sh`: **113 suítes, 28.338 checks Godot, 92
testes Python e 29 partidas, zero falhas/exit0**, parse aprovado. Log
`.tools/result-port/full-harness.log`, SHA-256 `4a526cfd…bde2`.

Aceite visual: o usuário aprovou a janela nas capturas (27/10/2026).
Pendentes: cliente Windows não executado, áudio mudo nas capturas e destino
nativo do OK. Versão 0.20.5, app/ZIP não reexportados, sem push.

## Integração do PR #5 — 27/10/2026

A pedido do usuário, a branch `cursor/match-loading-screen-ba1a` (PR #5,
tela de loading do Start) entrou na `main` local por merge (`650b871`), após
versionar o delta pendente da ADR-137 (`8095e3e`). Conflitos nos documentos
SDD, README e `check.sh` resolvidos mantendo os dois lados. O PR usava
REQ-48/ADR-133, já ocupados: renumerado para REQ-49/ADR-138. O
`assets/classic/loading/catalog.json` do PR faltava no filtro de exportação
e foi incluído. Suítes dirigidas após o merge: 8 suítes, 1.213 checks, 0
falhas; o harness completo acima já cobre o merge. O PR no GitHub continua
aberto; nada foi enviado ao remoto.

## Versionamento local do menu clássico — 27/10/2026

O usuário autorizou o commit local das alterações da ADR-137, incluindo
menu, assets/fallback, curva de áudio, testes, evidências e capturas.
Hashes do snapshot validado reconferidos antes do registro. Mantida a versão
0.20.5, sem reexportar aplicativo ou enviar ao remoto. Os registros abaixo
descrevem a validação anterior a esse commit.

## Menu clássico único durante a batalha — ADR-137

Pedido de27/10/2026: portar com REA e manter somente o menu do cliente.
Substituídos painel recomposto323×328 e pausa própria por play_option276×408
em8,45 nativos, ×1,6, com labels/RLE/pivôs intactos e OK/QUIT/X originais.
ESC/Options/P mostram o mesmo menu; show_pause é apenas alias. OK grava,
X/ESC restauram snapshot e volumes; QUIT volta à sala sem premiar abandono.
Pausa e disponibilidade de saída são adaptações explícitas do treino offline.
Sniper/MIDI/3d ainda não portados ficam desabilitados; sem regra nova de combate.

REA6.7.0/Hopper no PE4af6283d…/graphics.xfs a52f9f46…: loader, renderer,
input, dispatch e dois setters de áudio;13registros portáveis emdocs/battle-options.
Níveis nativos de scroll/áudio, limites estritos e estados dos botões portados.
Curva SetVolume100*(valor−100)centésimosdB convertida para amplitude Godot,
sem piso nos valores antigos1..19; OFF corta efeitos ativos. Master−19dB,
backend/agendamento de faixas e resposta da câmera seguem adaptações declaradas.

Cinco atlas novos,61HUD/15entradas, fallback nativo integral independente
validado por hash. OráculoRLE bruto compara pixels de ativos/fallbacks;
13Python aprovados. Revisão corrigiu scroll legado29/55/79 e piso/Stop de
áudio;146checks do novo menu e925checks dirigidos/0, revisão final semP1/P2.
GPU360quadros1920×1080,3×30quadrosRGBA idênticos na pausa e retomada,
24PNGs, viewport header/níveis/OK/X/QUIT e ESC/P; fallback pixelidêntico.
README4PNGs e86quadrosT1/GIF/MP4 regenerados emFullHD. Capturas finais
semERROR/SCRIPT ERROR/leaks. Perfil real preservado, áudio mudo.

Harness completo final `./scripts/check.sh`: **110 suítes,28.279 checks Godot,88 testes Python e29 partidas, zero falhas/exit0**. Parse aprovado; fontes inalteradas durante a rodada final. Log `.tools/battle-menu/full-harness-final.log`, SHA256 `088fff0db999b93aa0dce5da7b924eb44a0d99f6fb42bc14b9d9352cf9bdc5f2`.

Sem cliente Windows executado, escuta/input humanos ou aceite visual;
importeditor só reporta CA/editor_settings ambientais conhecidos, exit0.
Versão0.20.5/app/ZIP anteriores mantidos, sem exportação, commit ou push.
Contrato emBATTLE_OPTIONS_NATIVE.md; manifesto docs/battle-options/verified-source.json.


## Versionamento local autorizado — 27/10/2026

O usuário solicitou versionar o delta acumulado das ADR-133 a ADR-136:
assets do cliente, faixas do HUD, cronômetro/vento, MOVE e fundo opaco,
com testes, documentação e capturas. O pedido autoriza o commit local.
A versão do aplicativo permanece 0.20.5; não inclui exportação ou push.
Os resultados abaixo e os hashes do manifesto final foram reconferidos
antes do registro em Git.

## Fundo do footer — ADR-136

O usuário apontou background ausente após a correção MOVE. O importador HUD
transformava preto RGB565 em transparência. REA/Hopper confirmou o desenho
retangular de play_back, spans e flush da camada3 com REP MOVSD/MOVSB sem
chave de cor. Restaura-se alpha255 somente em tipo0 de play_back.img; decoder
global e demais recursos mantidos. Layout/movimento/regra/clock/vento intactos.
Os pixels opacos do painel prevalecem também sob os controles e overlays.

Oráculo novo falhou antes da correção e reconstrói RGBA das palavras brutas;
11 testes Python aprovados. Sete suítes dirigidas:1.195 checks Godot +11 Python,
exit0. Revisão independente sem P1/P2. Harness completo final:109 suítes,28.157 checks Godot,86 testes Python e29
partidas, zero falhas/exit0; parse aprovado. Manifesto `docs/footer-background/verified-source.json`.
GPU480 quadros1920×1080, Slice/Drag/esquerda/direita,4×30 quadros idênticos na
pausa/retomada;35 PNGs. Probe800×44 sobre magenta/verde igual às35.200 palavras
RGB565, zero transparentes e1.449 pixels pretos restaurados. README4telas e86
quadros T1/GIF/MP4 regenerados. Contrato em `FOOTER_BACKGROUND_NATIVE.md`.

As validações e capturas ADR-134/135 abaixo são históricas quanto ao fundo.
Não alegar execução do cliente Windows ou paridade integral do jogo. Áudio
mudo, aceite visual desta correção pendente; Godot import tem apenas erro
ambiental ao salvar editor_settings fora do sandbox. App/ZIP não atualizados;
versão0.20.5, sem commit/push. Delta Git preexistente preservado.

## MOVE no footer durante a movimentação — ADR-135

A posição anterior acima do footer foi substituída após a validação do usuário.
Ghidra confirmou o consumidor 407860..40796f: moldura play_back[5/6] em
(169,574), pivôs (0,+10)/(0,0), fill8 em (244,583), 400×12 com clip inclusivo.
No canvas curto subtraem-se 100 px do y. MOVE agora sobrepõe a parte inferior
da carga no footer; abertura compacta, expansão no próximo update e ocultação
ao soltar. Apenas apresentação; regras, cronômetro e vento preservados.

56 atlas/12 entradas XFS; quadro6 novo sem redimensionamento. Falha de quadro6
usa o compacto5 com pivô10. Revisão independente aprovada, sem P1/P2.
`check.sh --quick`: 107 suítes/28.157 checks Godot/85 testes Python, exit0.
Mais duas suítes em chamada separada: 13 seeds +16 mobiles =29 partidas, exit0.
**Cobertura combinada: 109 suítes, 28.157 checks Godot, 85 testes Python e
29 partidas, zero falhas.** Código de produção estável entre as chamadas.

GPU: 240 quadros 1920×1080, dois sentidos, 2×30 quadros RGBA idênticos na pausa,
retomada comprovada no recorte MOVE, soltura e dois fallbacks idênticos ao
compacto. 22 PNGs em `docs/move-bar`; contrato em `MOVE_BAR_NATIVE.md`,
manifesto em `docs/move-bar/verified-source.json`.

Sequências anteriores move-*.png da ADR-134 são históricas e foram rejeitadas;
a validação abaixo pertence ao snapshot anterior. A frequência da UI continua
adaptada ao porte. Cliente Windows não executado/áudio mudo; aceite visual desta
correção pendente. README T1 não movimenta o ator e mantém a captura anterior.
Versão 0.20.5/app/ZIP mantidos; sem commit/push.

## HUD em duas faixas, cronômetro e vento — ADR-134

Validação do usuário pediu corrigir assets e disposição: header com Options/clima/
Gold/itens/Skip; footer com S1/S2/SS/ângulo/Slice/Drag/carga/MOVE. Pedido adicional
incluiu cronômetro e vento. Correção pronta no fonte;55 atlas/12 entradas XFS,
fontes/pivôs/PNG nativos, sem GPT ou fit individual nos componentes novos.
ConsumidoresASM/contrato/limites em `HUD_CLIENT_LAYOUT.md`. Escopo Solo;
variantes Life/Jewel identificadas, inativas e sem placares inventados.

Layout compartilhado em battle_hud_layout.gd: header 64 px/footer 70,4 px,
mundo1280×665,6 desde y64. Câmera/draw/input acompanham o recorte; modelo,
terreno, colisão, vento físico e 30 s de ação não mudaram. Clock original mostra
segundos+décimos; vento usa o próprio ponteiro do anel laranja moon.xtf,
texto WIND/força em numfont imóvel e orientação coerente com vetor físico.
Fallback integral por grupo de clock/vento, por textura nos demais.

**109 suítes, 28.131 checks Godot, 85 testes Python e 29 partidas, zero falhas**; parse aprovado/exit0.
Log `.tools/hud-layout/full-harness-final.log`; manifesto/hash em
`docs/battle-hud-layout/verified-source.json`. Rodada intermediária exit2 porque
a lista do runner foi alterada enquanto executava; `sh -n` aprovado e a rodada
final completa repetida após estabilização. Não contar essa rodada como verde.

GPU final 960 quadros1920×1080/8 casos,8×30 quadros RGBA idênticos na pausa,
retomada confirmada. Centroide dos pixels do ponteiro prova quatro cardinais
(produto escalar>0,9999). README com 4 PNGs + 86 quadros de T1 real/GIF/MP4 regenerados.
Revisão independente: fallback de clima, altura do lock e 1 px do vento
corrigidos; teste red/green. Cliques reais pelo viewport em S1/S2/SS, Options,
itens, Skip e selector; Drag/pan bloqueados em ambas as faixas.

Aceite humano desta correção, escuta e execução do cliente Windows pendentes.
Canvas do porte mantém miolo mais curto que 800×600. Captura/clock 60 Hz não
comprovam performance 60 FPS. Editor import só teve editor_settings ambiental;
logsGPU finais sem ERROR/SCRIPT ERROR/leaks. Versão permanece 0.20.5; app/ZIP
anteriores não atualizados. Sem commit/push; delta Git preexistente preservado.

## Assets de batalha do cliente — REQ-48 / ADR-133

Retomada de27/10/2026 concluída sobre os arquivos já modificados pelo trabalho
anterior. Inventário e resultados em `CLIENT_ASSETS_PORT.md`, com relatórios
por grupo de HUD, clima, itens e áudio. Miramo usa mos.img/pmos.img, alpha
comprovado contra mos.lnd (3.240.000pixels) e fallback anterior idêntico.
HUD:27atlas de recortes nativos nas caixas atuais; clima/Thor:8folhas originais
com EPA/pivôs e fallback nativo; itens:ícones/beacon/19chamas/banner nativos;
áudio:96entradas exatas, stage1..6 e turn2local/turnadversário ativos.

Composição/layout do HUD e climas fora do modo Mage continuam adaptados.
Lacunas ficam declaradas, sem GPT ativo nesses grupos: componentes do HUD,
Weakness/Mirror/Random, aura UsingItem, fundo/abas do popup antigo e sons sem
recurso/evento comprovado. O stage.dat nativo e outros imports já comprovados
podem conservar caminhos históricos em assets/openbound. Originais e HD
anteriores preservados, elenco/equipamentos/perfil e regras sem mudança.

`./scripts/check.sh` final: **107 suítes, 27.945 checks Godot, 82 testes Python e 29 partidas, zero falhas**, parse aprovado,
exit0. Log `.tools/client-assets-full-harness.log`; hashes, fontes e resultados
em `docs/client-assets/verified-source.json`. Primeira rodada completa teve
apenas test_room_ui exigindo caminhoHD antigo; expectativa atualizada para
xfs/items, dirigida172/0 e harness completo repetido. Log inicial preservado.
Revisão independente achouP2 nos dígitos0..7 da fila; mapeamento corrigido,
oráculo de pixels e capturas finais refeitos. SS usa5faces nativas.

GPU M4Pro:720quadros1920×1080, sete casos, sete pausas de30quadrosRGBA
idênticos e retomada confirmada; galeria/MP4/GIF em `docs/client-assets` e
quatro casos/dois sentidos em `docs/client-weather-assets`. Eventos Thor e
chamas controlados são fixtures de apresentação; teleporte também disparado
por Game. Relógio60Hz não comprova performance60FPS. Logs finais sem erro de
script/recurso/leaks. GPU restrita abortou134; execuções finais fora do sandbox
exit0. Import teve apenas CA/editor_settings ambientais conhecidos.

README regenerado por `tests/capture_readme.gd`:4PNGs e86quadros de T1real,
MP4/GIF recompostos. Corrigido stretch antigo que capturava1728×1080 e gerava
MP41920×1200; cada snap agora exige1920×1080, conferido também por PIL/ffprobe.

Limites:visor de ângulo branco tem contraste reduzido no painel claro; escuta,
input/aceite humanos e execução do clienteWindows não realizados. Sem nova
versão/export/app/PCK/ZIP, commit ou push; aplicativo exportado anterior não
foi atualizado. Fonte permanece0.20.5. Perfil real não usado nas capturas/testes.

## Tela de loading ao Start da sala — ADR-138 / REQ-49

Integrado à `main` local em 27/10/2026 (PR #5, branch `cursor/match-loading-screen-ba1a`).
O PR numerava esta entrega como REQ-48/ADR-133, já usados pelos assets de
batalha; foi renumerada para REQ-49/ADR-138 sem mudar o conteúdo.

Pedido de 27/10/2026: ao Start da sala, mostrar a transição do cliente (a
imagem de referência é a loading com o mapa embaixo e os nomes nos spawns).
No 1×1 local a tela fica no mínimo 5 segundos. Random já aparece resolvido.
Não há rede nesta etapa.

Fonte: `GunBound.gme` SHA-256 `4af6283d…`, `graphics.xfs` SHA-256 `a52f9f46…`.
O painel é `load_back.img` (quadro 0, 800×244; quadro 1, barra 156×14).
O mapa é `load_stage01.img` quadro 0, identificado pelo rótulo MIRAMO TOWN
no bitmap. O quadro 1 é a máscara. Em 0x004430c0 a coluna é
`spawn_x * 748 / largura` e a linha é o primeiro pixel não zero mais 18;
sem máscara, y = 122. A largura do Miramo neste porte é 1800. A conta
`map_id * 11 + lado` não seleciona esse arquivo: o índice 11 repete o Cave.

`begin_loading` sorteia o mobile e um ponto por lado, desenha a tela e só
então chama `start_match` com esses valores. `start_match()` direto não
espera (a revanche saiu com a ADR-139). A escolha Random da sala permanece pendente para a
próxima visita.

Validação: `test_match_loading` 21 checks, 0 falhas. `test_room_settings`,
`test_room_reference` e `test_scene` conferem o Start e o caminho imediato.
Captura GPU 1280×800 em `docs/match-loading/loading-random.png` (Knight/Knight,
seed 7). Sem cliente Windows, sem escuta e sem aceite visual. Sem mudança de
versão, app ou PCK. Partidas completas não foram reexecutadas: o caminho
padrão de `Match.start` não muda quando não há override de spawn.

## Objetivo jglim, OpenBound fora do escopo e capturas do README — ADR-132

Pedido de27/10/2026: o projeto reescreve jglim/gunbound-launcher e
jglim/gunbound-server com fidelidade, multiplataforma e extensões; OpenBound
(Season 2) sai das instruções. Feito: skill gunbound-mobile-port apagada; pasta
`~/Workspaces/Gunbound` desanexada (Claude settings, `.devin`, hook); agente,
skills, AGENTS, README, PORTE/MOBILES/DESENVOLVIMENTO/HISTORICO, VALIDACAO,
APRENDIZADO, topo de SPEC/DESIGN e sdd/README limpos. Registros antigos intactos
como histórico. Código e `assets/openbound/` inalterados.

Capturas: `tests/capture_readme.gd` (GPU 1920×1080, exit0, log sem ERROR) gerou
lobby/sala/loja, um T1 real do Bigfoot (86 quadros) e `docs/readme/shot.gif/mp4`.
Miramo e HUD ainda usam derivados HD/herdados: trocar pelo cliente é tarefa à
parte. Pendente fora do repositório: `~/.codex/config.toml` ainda confia e dá
escrita a `~/Workspaces/Gunbound` (configuração global do usuário, não alterada).

## README e documentação de entrada — 27/10/2026

Pedido do usuário: README simples sobre a reescrita e seus TODOs, com o
detalhe em documentos menores. README refeito (visão do porte fiel, estado,
TODOs entregue/em progresso/pendente/roadmap); novos `docs/PORTE.md`,
`MOBILES.md`, `JOGAR.md`, `DESENVOLVIMENTO.md` e `HISTORICO.md`, derivados de
TASKS/DECISIONS/HANDOFF. Só documentação: sem mudança de código, versão,
app, commit ou push. Atualizar o README e o MOBILES junto com o TASKS nas
próximas entregas.

## Retratos da loja sem contorno pontilhado — ADR-131

Correção pedida pelo usuário sobre a ADR-130: `decode_gunbound_img.py` só usa
preto como chave em frames RGB565 cheios; RLE mantém o preto opaco (captura
original confirma). 496 retratos `_rle`, 98 frames da loja e 4× regenerados;
retrato em card+(52,62)+pivô (`portrait_pivot`). Peças vestidas inalteradas.
`test_shop_original` 77/0, `test_xfs_import` 14/0, 14 suítes da loja/avatares
sem falhas; harness `--quick` 97 suítes, 27092 checks, 0 falhas (partidas omitidas: sem mudança de regra). Sem commit novo.

## Avatar Shop e avatares originais — ADR-130 / REQ-47

Pedido27/10/2026: corrigir assets/imagens do Avatar Shop com os originais do
jogo, REA quando preciso. Ler `AVATAR_SHOP_ORIGINAL.md`. Decisões do usuário:
avatares **tudo original** (loja, sala, batalha), botões originais em inglês,
loja igual ao cliente (sem busca/contador/"Nível"/rótulos PT/prévia de mobile).

`import_xfs_shop.py` extrai 171 frames (116 anteriores idênticos) incluindo
`numfont` e o atlas ASCII do `font.fnt`; `build_shop_smooth_hd.py` gera o
BICUBIC4× aprovado em `assets/hd/classic/shop_smooth_4x` (fallback por hash).
`classic_shop_art.gd` desenha frames com pivô nativo, texto 8×12/avanço6 e
números pelas regras do cliente. `avatar_shop.gd` reescrito; `AvatarArt`
nativo por padrão (`new(true)` só para auditorias HD). GPT de loja/avatares
preservado em disco, fora do uso ativo. Gênero/atributos na faixa lateral.

Evidência: REA/Hopper (strings, xrefs, `%8d`/`%02d`) e Ghidra12.2 headless
(`builds/ghidra-shop-ev1/ev2`: 0x44a000, 0x44c460, 0x4ed9f0) no PE `4af6283d…`;
posições restantes por casamento de template em `gb-avatar.png`. Testes:
`test_shop_original` 70 checks com oráculos independentes; 20 suítes
dirigidas 6663 checks/0. GPU 1920×1080 + 120 quadros60Hz e comparação lado a
lado em `docs/avatar-shop-original`. Harness completo `./scripts/check.sh`: **99 suítes, 27085 checks, 29 partidas, 0 falhas**
(log `.tools/shop-original-harness.log`); depois disso o check 1280×800 levou
`test_shop_original` a 73/0 e shop_wide/audit/classic repetidas sem falhas.
Smoke de pacote novo: `tests/capture_shop_original_pck.gd` (não executado: sem export).

Pendências: aceite visual/mouse do usuário; popup de compra sem captura
original (adaptado); itens "Standard" listados no inventário para permitir
voltar ao padrão; app não reexportado; nenhum commit/push.

## Mage: partículas decorativas em voo — ADR-129

Pedido seguinte implementado no fonte. Ler `MAGE_FLIGHT_SPARKS.md`.
Force/Electric agora usamCrashTexture.xtf original, quadfloat32/UV/ADD,
posições fixas e relógio20Hz. Nasceclock1/alfa239, gira1°/6°, termina no16.
Scanner455cc0 publica os pontoscoarse8 apósclima/antescontato, semFX extra
no refino. Sorteios só no apresentador, separados do combate/CPU. Force0
consome também a tentativa436bd0, cuja densidadeMage1e50 é0 e não geraFX.

65.536pixels conferidos; testes focais63+206Godot/2Python e revisãofocal
semP1/P2 após corrigir a tentativa comum. FPS10/30/40/60 com estados iguais;
probe independente com partículas vivas e pósresultado sem mexer atores.
GPU360quadrosFullHD,12casos/dois sentidos, pausa30 idêntica; arena realT2
Force/Electric também com pausa/retomada/menuclear. Evidência em
`docs/mage-sparks`, extratos locais `.tools/mage-sparks` e anterior`moon16..20`.
Harness final98suítes/parse/exit0: **27046Godot+60Python+29partidas/0**;
fontes/assets/fixtures iguais por hash. Seed4242/qualidade3 são inputs locais, sem
replay do RNG globalWindows. Sem clienteWindows/escuta/aceitehumano,
versão/exportação/app/ZIP. Pedido posterior autorizou commit e push na
`main` do conjunto integrado com suas dependências nativas pendentes;
o envio inclui o commit localAduka já ancestral da branch. Demais bridges
daADR-128 preservados. Hashes e limites em `docs/mage-sparks/verified-source.json`.

## Mage: climas secundários — ADR-128

Pedido de27/10/2026 implementado e validado no fonte. Ler
`MAGE_SECONDARY_WEATHER.md`. Partidas contendoMage usam calendário nativo7
categorias/8slots, vento e rangesX do `stage.dat`; Miramo ganhaThor2 e cura0.
Moon só cura ator do turno3%/8% maxHP; Eclipse bloqueia itens/limpaDual global.
Colunas mesclam pelo primeiro encontro e a transição43c620 limpa outros tipos
a cada turno, antes de novos spawns. Elétrico→Thor→Mage/EMP; elétrico tem
blast115/dim27 base e choque40/30 por componente, semForce herdada. Thor usa
posiçãoLCG/Y500, avanço40 até1000, poder÷1/2/1 e período×divisor; nível só
recalcula no turno seguinte. Outras duplas preservamWeather anterior.

`MageWeather.copy()` duplica estado e usa o mesmo passo real/previsão. Três
XTFs originais extraídas, quads64Y/UV/blend/20Hz nativos. GPU540quadros em
1920×1080/60Hz, seis casos com contatos controlados, pausa30 idêntica.
Vídeo/PNG/JSON em `docs/mage-weather`. REA estático, sem cliente Windows;
seeds/período e bridges de itens/regen comum/partículas em voo declarados.
Sem nova exportação, alteração de versão, commit ou envio ao remoto.

Harness final95suítes/parse/exit0: **26775Godot+58Python+29partidas/0**.
AjusteUI posterior limpa item enfileirado emEclipse sem consumi-lo;
regressão49/0, dois checks novos: consolidação26777Godot. Revisão focal
semP1/P2. Fontes/recursos conferidos por hash, prova de pausaRGBA
independente e limites em `docs/mage-weather/verified-source.json`.
TTL sem decremento no ciclo2D auditado (Animate+8/Draw+c/deleção+14),
sem generalização a outros fluxos indiretos/3D.

## Lightning: revisão de assets, combate e Tempo — ADR-127

Pedido27/10/2026, skillgunbound-client-port, mesmoPE/XFS/DAT e
Ghidra12.2/JDK26 direto. Matriz/plano/limites em`LIGHTNING_CLIENT_REVIEW.md`;
11consultas e35extratos em`docs/lightning-review/native-proof.json`.

`LightningCombat` porta T1stride3/T2stride8 com refino1/sóterreno, vertical
na primeira superfície e duas diagonais do topo. SS seleciona inimigo em
raio estrito120 pelo hotspotY−10 e cria strikeT1, sem blast primário do guia.
Dano/Defense/tipos/escudo/cratera usam núcleo comum; flags extraídos do campo
correto separado do raio. Choque76/76/46, mecânicos+8%/raio+20%; cadeia20
com raio original e filtros próprios. Elegibilidade anterior ao blast letal
permite devolver choque antes do resultado. CPU/snapshots compartilham tudo.

Force+3/+8/+8 por tick,20..100, separado do poder. Tornado mantém24.8,
reflete duas vezes/libera na3ªsaída e retoma vento no próximo tick, semimpulso
C#. Outros climas/itens/regen/apoio/origem/scheduler mantêm bridges declarados.
Não anunciar combate integral nativo nem migrar demais ataques por efeito
colateral; fontes/HD/avatares/perfil e revisãoMage simultânea preservados.

445quadrosmobile+79tiros/impactos, pivôs/EPA/PCM conferidos contraoriginais.
Lightning.xtf original novo para raios aditivos, quads inteiros/UV1/4,
alpha255−24×tick/10ticks. SSpl emADD e headingquantizado, semrastro.
EPA14dead oculta AvataTexture/AvataEffect; chassis continua, semusar11campos
inutilizáveis comoRiderPivot. Poses vivas preservam montagem aprovada.

Validação final`./scripts/check.sh`: **25416checksGodot+55Python+29partidas/0**,
90suítes, parse aprovado, exit0. Log`.tools/lightning-review/final-harness.log`,
SHA/contagens em`docs/lightning-review/verified-source.json`. Revisão
independente semP1/P2; `git diff --check` limpo. Suspeita de imunidadeKnight
foi descartada:campo+24 é estadoEPA, não IDmobile. Não foi alterado.

GPU realM4Pro:300quadrosT1/T2/SS+300vento/tornado,1920×1080/relógio60Hz,
pausa30..59 durante o raio idêntica e retomada. Poses150quadros/padrão+GreatDevilHD,
dois sentidos, pausa30idêntica; morte igual por pixels com/sem equipamento.
Miramo realT2:primeirofeixequadro74, pausa/retomada, HUD acima e efeitoslimpos
ao voltar. Uma primeiraQA detectou dados retidos após saída; corrigido e
recapturado comarray/RIDs limpos. Vídeos/PNG/JSON em`docs/lightning-review`.
Tempos15,46s/19,86s de captura/escrita não comprovam performance60FPS.

GPU restrita abortou134 antes do quadro; execução fora do sandbox concluiu.
Importeditor registrou CA/editor_settings ambientais conhecidos; harness/GPU
finais semSCRIPT ERROR/ERROR. SemclienteWindows/escuta/input humano nem aceite
visual. Perfil isolado, som silenciado. Sem versão/app/export/PCK/ZIP/commit/push.

## Mage: revisão de assets, força, combate e Tempo — ADR-126

REA Ghidra12.2/JDK26 no mesmoPE/XFS. `MageCombat` porta dados200/186/380,
dimensões66/54/60, aspectos143/134/130 e atributos divididos1/2/1 antes da
soma. Núcleo45db20/455cc0 compartilhado comAduka: dano linear/passes inteiros,
AABB, stride8/refino1, scanlines e máscara1px copiada paraCPU. T2 usa onda
na colisão. EMP drena escudo antes do blast, raio estrito150/hotspotY−10.

Tornado conserva24.8, duas inversões/saída3, vento/gravidade retomam no tick
seguinte. Revisão independente corrigiu umP2: bordaT2 usa ponto da hélice,
sem trocar pelo carrier. Force por tick separado. Revisão final semP1/P2.
489quadros/pivôs/EPA, LaserEffect ePCM21fire/22blast conferidos; fontes e
avatares/HD preservados, sem nova imagem ou compensação do piloto.

Validação consolidada: **20598checksGodot+48Python+29partidas,87suítes
aprovadas**, parse limpo. Harness estável emcópia Mage separada do trabalho
Lightning simultâneo. UmPNG de referência de botões faltou nessa cópia:
comando completo terminouexit1; pasta reanexada e suíte inteira repetida
596/0/exit0. Consolidação exige todas as87suítes e preserva ambos os logs,
sem anunciar exit0 para a rodada parcial. JSON emdocs/mage-review/verification.json.
Nova suíteMage4054/0 (567fixtures de distância, limites deEMP/tornado,
real×CPU até dano/cratera, itens e quatro ventos/dois sentidos).
Workspace integrado também passou6839checks dirigidos/0 duranteLightning.

GPU M4Pro:480quadros1920×1080, relógio60Hz, T1/T2/SS/dois sentidos com e
semvento/tornado/Force; impactos1/2/1 emcada cenário, pausas30idênticas,
retomada inspecionada. Captura/escrita49,588s, semalegar performance60FPS.
Sala eMiramo/HUD/três tiros reais também capturados, pausa30por arma.
Vídeo8s, imagens, manifestos e18extratos emdocs/mage-review; contrato/matriz
emMAGE_CLIENT_REVIEW.md. GPU final semerro de script/recursos.

Fraqueza/Mirror/Random/Protection, calendário/clima/choques, ativação de
itens, muzzle/origem/apoio e limite12s continuam bridges declaradas.
ClienteWindows, escuta/mouse humanos e aceite visual não realizados.
Semversão nova/export/app/PCK/ZIP, commit oupush; perfil real preservado.
A revisãoLightning simultânea não foi alterada nem validada integralmente
aqui. HistóricoMage/arte adaptada anterior não prova esta entrega.

## Versionamento local do trabalho Aduka

Pedido posterior do usuário: registrar as alterações do Aduka no Git local.
Verificação antes do commit:3856checks/0 em seis suítes dirigidas
(combate, clima, apresentação, Thor, integração e cronologia), exit0;
hashes da implementação coincidem com a validação completa daADR-125.
Código, assets, fixtures, documentos e capturas fazem parte do registro.
Trabalho simultâneo do Mage permanece separado. Versão do aplicativo0.20.5
preservada; sem nova exportação nem envio ao remoto.

## Aduka: dano/colisão/clima e T2 com3 bichos — ADR-125

Validação final: **16544checksGodot +44testesPython +29partidas/0**,
84suítes, parse aprovado e exit0 em `./scripts/check.sh`.
Log final `.tools/aduka-combat/verified-harness.log`; revisão semP1/P2,
GPU sem erros de script. Os números das seções anteriores são históricos.

Pedido posterior substitui adaptações de dano/contato daADR-124 e exige3T2
visíveis, vento atual e tornado sem força desproporcional. REA estático
Ghidra12.2/JDK26 no mesmo PE/XFS;17extratos essenciais em
`docs/aduka-combat/native-proof.json`, matriz/plano/limites em
`ADUKA_COMBAT_REA.md`. `AdukaCombat` porta queda linear, aspecto, passes
inteiros, Defense/tipos, escudo e XP; AABB sem rotação, offsets assimétricos,
stride8/refino1, Thor2px e cratera de scanlines. Máscara1px original clonada
na previsão; apoio/grade comum e demais ataques preservados.

`AdukaWeather` conserva a velocidade24.8 dentro do tornado, faz duas
inversões e libera na terceira saída; vento/gravidade da semente voltam no
tick seguinte. Sem relançamento vetorial C#. Force acumula uma vez/tick em
20..100, aplicado separadamente; Thor não herda atributos do guia. T2tem3
emissões2/6/10 por pedido explícito (PE tem2); folha original`bullet16sl`
em alpha como corpo fallback para não sumir sobre neve. PNG/pivôs intactos.

Revisão independente do código/ASM corrigiu doisP2 de LUTnegativa/Ysuprimido
e efeitoBunge; revisão posterior sem P1/P2. Novas suítes: combate661checks,
clima2629checks (616fixtures de dano +2000ticks independentes de tornado,
quatro ventos/dois sentidos real×CPU). Assets/PE auditados por Python.

GPU M4Pro real: Miramo/T2com3spriteslegíveis, Thorquadro77, HUD protegido e
semglow ao sair. GaleriaT1/T2/SS300quadros1920×1080, T1umimpacto/T2trêsThor/
SStrêsThor por sentido; vento/tornado outros300quadros/dois sentidos.
Ambas pausas30idênticas e retomada. Captura/escrita15,46s/19,66s, relógio60Hz;
não é prova de performance60FPS. Clipes e JSON em `docs/aduka-combat`.
Captura familiar inicialmente ociosa noquadro17; repetida integralmente com
force_draw, sem reutilizar a tentativa parcial.

Sem executar o cliente Windows/escuta humana; aceite visual do usuário
pendente. Muzzle/origem convertida/apoio, calendário e climas adicionais,
ativação nativa de itens ainda são bridges offline declarados. Import só
teve os erros ambientais CA/editor_settings conhecidos; nenhum perfil real
alterado. Sem versão/exportação/app/PCK/ZIP, commit ou push.

As seções ADR-124 anteriores descrevem o estado antes deste porte.

## Revisão Aduka T1/T2/SS e assets — ADR-124

Pedido de revisão geral por REA após centralização (posição/orientação atuais
preservadas). Ghidra12.2/JDK26 no mesmo PE/XFS, matriz e limites em
`ADUKA_AUDIT.md`; extratos `.tools/aduka-audit/01..07`, essenciais em
`docs/aduka-audit/source-proof.json`. T1tick1, T2ticks2/6 e SSticks2/6/10
reconfirmados. `AdukaSprite` mantém montagem/atlas e corrige corpo alpha,
glow aditivo e Facing vertical T2/SS. Sem rastro, conforme ADR-120.

ThorBody/ThorLight/EPA originais em catálogo `aduka/thor_native.json`;
renderer em escala nativa20Hz/ângulo sem PI extra/bob discreto. Estado
normal/active/fire, ease e clocks em `weather.thor`, tick comum e cópia
profunda para CPU. Thor preparado antes do impacto quando há Aduka, com
posição inicial determinística adaptada; rota climática usa mesmo Thor.
T2/SS produzem2/3feixes sem blast próprio do guia; efeito usa22blast PCM
pela chamada432320(owner,1,1), sem som extra inventado do guiaSS23ausente.

Revisão independente tratou dois P2: feixe sobre HUD e glows residuais ao
trocar tela. Reprodução GPU antesfalse/false, depoistrue/true; HUD emz1,
mundo/RIDs emz0, controles emz2; `replace_root` limpa todos os passes.
Revisão final aprovada, sem P1/P2 restante.

Validação: **harness completo13241checksGodot+42Python+29partidas/0**, parse
aprovado/exit0. Após os ajustes só de HUD/limpeza:8suítes1004/0 e
**quick final13253checksGodot+42Python,80suítes/0**, com12novos checks de
Thor real/previsão/isolamento. Partidas completas anteriores usam o mesmo
modelo final. Auditoria de495quadros, pivôs/EPA/ASM e PCM; originais intactos.
GPU real M4Pro:300quadros1920×1080/relógio60Hz, pausa30idêntica e retomada,
T1/T2/SS nos dois sentidos. Captura/escrita levou14,27s (não é prova de
performance60FPS). Sala e Miramo/T2 reais com HUD; primeiro raio noquadro74.
Imagens/vídeo/JSON em `docs/aduka-audit`; logs `.tools/aduka-audit`.

Dano final C#, caixa/muzzle comuns, DDA2px e ramo de obstáculos de Thor
seguem adaptações declaradas; sem alegar paridade integral. Cliente Windows
original não executado; escuta/mouse/aceite visual pendentes. Import teve
somente CA/editor_settings ambientais conhecidos; GPU sem erros de script.
Sem nova versão, exportação/app/PCK/ZIP, commit ou push.

## Piloto mais centralizado no Aduka — ADR-123

Usuário aprovou a orientação da ADR-122 e pediu aproximar o piloto do centro.
`MobileLooks` declara `rider_adjust=(8,0)` só no Aduka; `ClassicSprite` soma
a constante ao RiderPivot no consumidor. Idle(-8,-23)→(0,-23), conservando
deslocamentos relativos das poses e todos os Y. Sala/arena/loja e piloto
padrão/equipado compartilham esse encaixe; orientação aprovada, casco,
metadados/fontes e combate preservados. Adaptação visual solicitada, não
alegação de paridade nativa. Evidência de origem/plano em `ADUKA_CENTER.md`.

Verificação atual: **1018 checks/0, 11suítes, exit0** (classic_mobiles,
original_mobiles, avatar_mount/art/hd/continuity, room_ui, room_reference,
roster, scene, shop_wide). GPU real M4 Pro fora do sandbox, 1920×1080,
relógio60Hz/150quadros, seis poses/dois sentidos/padrão/HD, pausa30 idêntica e
retomada. Sala real A/B antes/depois, piloto padrão/Great Devil. Imagens e
amostras temporais inspecionadas, JSON em `docs/aduka-center`; sequência/log
local em `.tools/aduka-center`. Sem erro de script; partidas não repetidas
(só encaixe visual). Sem nova versão, exportação/app/PCK, commit ou push.
Aceite visual da centralização pendente; orientação anterior aprovada.

## Orientação do conjunto Aduka na sala — ADR-122

Usuário rejeitou a ADR-121 e enviou imagem do lado A: personagem olhando à
direita, traseira/mira do Aduka à esquerda. O deslocamento X foi removido;
RiderPivot original restaurado integralmente. `MobileLooks` declara
`room_facing=-1` só no Aduka, consumido por `Game.draw_figure`, para converter
a orientação visual da sala no sentido de tiro esperado por `ClassicSprite`.
Casco/piloto giram juntos; B espelha A. Arena mantém `rear` e tiro pelas costas.

Verificação desta correção: **982 checks/0, dez suítes, exit0** (`check.sh` com
classic_mobiles, original_mobiles, avatar_mount/art/hd/continuity, room_ui,
room_reference, roster e scene). `git diff --check` limpo. GPU real M4 Pro,
1920×1080: sala A/B com Aduka, piloto padrão e Great Devil; galeria de seis
poses, dois sentidos de tiro, padrão/HD, relógio60Hz/150quadros, pausa30
idêntica e retomada. Capturas atuais e referência do usuário em
`docs/aduka-orientation`, script `tests/capture_aduka_mount.gd`, log
`.tools/aduka-rider/orientation-gpu.log`. Imagens da sala/galeria inspecionadas;
não é execução do cliente original. Combate não alterado, partidas não
repetidas; sem nova exportação/app, versão, commit ou push. Aceite visual
da nova composição pendente. A seção ADR-121 abaixo é histórico rejeitado.

## Piloto à direita no Aduka — ADR-121

**Histórico rejeitado; substituído pela ADR-122.**

Usuário esclareceu que deseja mover o piloto para o lado direito do mobile,
sem virar o personagem. `ClassicSprite.rider_offset` inverte somente X no
Aduka: idle(-8,-23)→(8,-23) no casco, com espelho automático no sentido
oposto. Piloto padrão/equipado compartilham o encaixe; altura/EPA, direção das
peças, metadados/PNG originais, outros mobiles e combate preservados.

`./scripts/check.sh test_classic_mobiles test_original_mobiles test_avatar_mount
test_avatar_art test_avatar_hd test_avatar_continuity test_room_ui test_scene`:
**694 checks/0, oito suítes, exit0**. GPU real no M4 Pro fora do sandbox:
`tests/capture_aduka_mount.gd`, 1920×1080, relógio60Hz, 150quadros, seis poses
(hurt com inclinação15°), dois sentidos, padrão/HD, pausa30 idêntica e retomada.
Antes/depois e amostra posterior em `docs/aduka-mount`; logs em
`.tools/aduka-rider`. A primeira execução GPU no sandbox saiu134; repetição
fora dele concluída. Imagens inspecionadas; sem alegação de execução do cliente
original ou aceite do usuário. Partidas não repetidas (só encaixe visual).
Sem app novo, versão, commit ou push; aceite visual pendente.

## Rastro só no T1 do Raon — ADR-120

O usuário não quer rastro fora do T1 do Raon. `ClassicSprite.has_trail` liga
as sete cópias e o esvaziamento após o impacto só para `raon`/T1; T2/SS do Raon,
os outros mobiles, o espelho Facing e o Nak voltaram ao desenho aprovado.
`test_raon_trail` 93/0, `check.sh --quick` 13202 checks/0 (sem captura GPU nova:
só a seleção do desenho mudou). A seção ADR-119 abaixo é histórica.
Sem app, versão 0.20.5, sem commit.

## Rastro em todas as balas comuns — ADR-119 (histórico, substituída)

Pedido “Adicione rastro”. Censo do slot3 no PE: quase todas as classes usam
`0x458690` (rastro); Trico SS `0x4ae1a0` (rastro); Nak SS, Grub SS e Aduka
T2/SS `0x488880` (rastro + espelho vertical indo para a esquerda); Mage T1/T2,
Turtle T1/T2, Dragon T1/T2, satélites/íons têm desenho próprio sem histórico.
`ClassicSprite` decide por `trail_style(kind, weapon)` e desenha brilho+corpo
nas sete cópias; a cena esvazia a cauda de qualquer bala com rastro
(`leaves_trail`). Nak recebe só as cópias, mantendo a orientação aprovada.
`test_raon_trail` 95/0, Python 13/13, `check.sh --quick` 13204 checks/0
(partidas não repetidas: só desenho). GPU: amostra Armor/JD/Grub/Aduka/Nak/Mage
em `.tools/raon-shots/gallery`; galeria completa ficou lenta com o jogo aberto.
Sem app, versão 0.20.5, sem commit.

## Rastro das balas Raon — ADR-118

Vídeo do usuário (YouTube `fd9VsdZQbsI`, 1:15–1:20) mostrou o T1 com cauda
densa de cópias. No cliente, toda bala comum publica posição/ângulo por quadro
(`0x458690`), o render desenha os níveis 7..0 com alfa 255−32k e o histórico
desloca a cada quadro, no máximo um por tick de 20 Hz. `ClassicSprite`
desenha agora as sete cópias anteriores (histórico `trail` por tick, quadro
atual da bala) só para o Raon e, depois do impacto, a cena esvazia a cauda
nível a nível (`lingering`), como no vídeo em 1:17,7. Sem espelho vertical:
o nativo grava 0 no flag, então robôs indo para a esquerda giram 180° como no
original. `test_raon_trail` 45/0, Python 12/12, `check.sh --quick` 13154
checks/0 (partidas não repetidas: modelo/colisão inalterados). GPU T1 nos dois
sentidos e T2/SS com pausa idêntica (`docs/raon-shots/t1-trail-godot.png`,
`trail-left.png`). Ângulo por nível usa o deslocamento do tick (nativo:
campo de 3°). Mesmo rastro existe para as balas comuns dos outros mobiles,
mas não foi ativado.
Sem app, versão 0.20.5, sem commit.

## Minas Raon no terreno — ADR-117

Relato após a ADR-116: robôs do T2 virados, mina deve estourar ao encostar e
falhas de estouro ligadas ao terreno. AnimateMine/AnimateSuperMine (`0x498b60`/
`0x4921e0`) mostram: mina no pixel do chão, sonda y−15, encaixe 15 px, queda
+1 px/tick com quique a v≥5, remoção fora do mundo sem explosão e gatilho por
distância < 8 px até os pés de qualquer mobile vivo (dono incluído; S2[66]/
SS[79]=8). Supermina também explode junto de outra mina; explosão em y−10.
O Godot usava caixa a partir de `pos+(0,5)` (o Raon com apoio 20 ficava 1 px
fora), não fazia a mina cair e espelhava ao contrário. Desenho agora gira em
torno do chão pela inclinação nativa (`0x4986a0`, LUT `0x598e7e`) e recorta a
célula 32×32 (`0x497980`). Balas T2/SS continuam atravessando mobiles: nem a
simulação nem a detonação testam mobiles; o “encostar” vem do gatilho da mina.

Código: `raon_effect.gd` (`slope_angle`, `settle`, `touching`, `draw_transform`,
`blast_point`), `classic_flight.gd` (remoção/centro), `classic_sprite.gd`
(desenho). `test_raon_mines` RED→33/0, `test_raon_effect` 168/0 (testes
antigos migrados para a âncora no chão), Python 11/11, e aceitação real em
`test_raon_shots` 102/0: bala T2/SS atravessa o mobile, planta sob os pés,
detona no tick seguinte, causa dano e o turno SS sai do voo. `./scripts/check.sh`:
**13102 checks Godot, 80 suítes, 29 partidas, exit0** (`.tools/raon-shots/
final-harness-117.log`). GPU real `tests/capture_raon_mines.gd` em relevo:
330 quadros/60Hz, pausa30 idêntica, retomada, detonação supermina×mina e
mobile×mina na cratera; evidência `docs/raon-shots/mines-terrain.png`. A janela
oculta do macOS deixa a captura lenta; usar `--disable-vsync --always-on-top`.
T1 sem divergência estática: tira em `docs/raon-shots/t1-strip.png`, aguardando
referência do usuário; tira do T2 nos dois sentidos em
`docs/raon-shots/t2-flight-directions.png` (giro das balas em voo sem prova
nativa, renderer comum inalterado). Sem app reexportado, versão0.20.5, sem commit.

## Tiros Raon T1/T2/SS — ADR-116

Pedido: corrigir os tiros do Raon. Ghidra direto sobre o mesmo PE
(`.tools/raon-shots/q1..q9`) mostrou quatro divergências da 0.20.5: T1 com
fases dos componentes 1/2 invertidas (nativo idx2→0, idx3→180); T2 com leque
de ±3° em vez de força nativa P+15/P−15 no mesmo ângulo (constante 15 em
0x794bf0, WinMain); SS sem o P+15; balas de mina colidindo com mobiles,
embora `SimulateShot_Bullet7n_9s_7p_9p` não chame `HitTestMobilesAndJewels`.
Também a supermina passou a usar `vx>0` estrito para a direção.

Código: `raon_effect.gd`, `combat.gd`/`match.gd` (`native_power` da emissão,
somado após quantizar, sem clamp, compartilhado por execução/previsão/CPU/itens)
e catálogo Raon com `skip_actors`. Teste novo `test_raon_shots` (RED 39 → 95/0),
`test_raon_effect` 168/0 (expectativa de fase corrigida), integração 263/0,
prova Python do PE 9/9.

`./scripts/check.sh`: **13062 checks Godot, 33 testes Python, 29 partidas**,
zero falhas, parse aprovado, exit0 (`.tools/raon-shots/final-harness.log`).
Ajuste posterior em `create_mine` (`fp_ready`) revalidado nas suítes Raon
(95/0, 168/0, 263/0, Python 9/9) e no parse; harness inteiro não repetido.
As partidas com Raon mudam de trajetória de propósito; continuaram aprovadas.
GPU real `tests/capture_raon_shots.gd` (gl_compatibility, M4 Pro, fora do sandbox): 3 tiros × 2 sentidos,
300 quadros/60Hz, pausa de 30 quadros idêntica e retomada nos seis;
comparativo em `docs/raon-shots/before-after.png`. É captura do Godot, não
execução do cliente original. Pendentes: ponto exato do plantio, contato/encosta
e dano das minas, rotação do sprite pelo heading, escuta/mouse, aceite visual.
Sem app reexportado, versão inalterada (0.20.5), sem commit.

## Bigfoot com acabamento4× — ADR-115

Pedido: aplicar ao Bigfoot a suavização BICUBIC4× aprovada nos botões/lobby.
Nove folhas de `bigfoot/original` (corpo, tiros, luzes, Flame1–3) em
`assets/hd/classic/mobiles_smooth_4x/bigfoot`, por quadro, alpha nearest.
`MobileLooks` liga só no Bigfoot (`smooth`); `ClassicSprite` valida catálogo
(`mobile_smooth_art.gd`) e multiplica apenas recortes de origem. Destino, pivô,
contato, avatar, regras e demais mobiles nativos; folha inválida volta ao nativo.

`test_bigfoot_smooth` 70/0; regressões dirigidas 1196/0 + 1772/0; 21 Python.
GPU1920×1080/60Hz: galeria 210 quadros com pausa idêntica e sala/arena reais
em escala de uso (nativo×4×, movimento). PCK isolado 30/0/exit0. Atlas4×
custa 172 MB descomprimido. Commit local 5f86a74 mesclado na `main` local
(sem push); sem app novo ou versão. Aceite visual pendente.
Merge com a sala (ADR-104…114): ADR renumerada para 115 e `density` do
Random herdada de MobileSprite. Harness `--quick` após o merge: parse limpo,
76 suítes, 12974 checks Godot/0 + Python. Sete falhas iniciais eram do
worktree novo (pastas `.tools/missing-*` criadas por engano e referências XFS
locais ausentes); corrigido o ambiente, todas passaram. Partidas completas
não repetidas: regras de combate não mudaram.
Registro/limites: `BIGFOOT_SMOOTH_4X.md`; evidência em `docs/bigfoot-smooth-4x`.

## Aceite e commit local dos ajustes da sala — 25/10/2026

Usuário aprovou o resultado final ("Agora ficou bom") e autorizou o commit
de todos os ajustes pendentes da sala: ADR-107 a114, incluindo cards/Ready,
dificuldade da CPU, clima, START/SETTINGS, modal/fonte, alpha e alinhamento.
Código, fontes/derivados preservados, testes e evidências reunidos na main.

Verificação repetida para o versionamento:1350checksGodot/0 em8suítes,
21testesPython/0 da skillHD,24hashes dos catálogos novos conferidos e
git diff --check limpo. Aceite visual final confirmado; a versão aprovada
é `room_settings_word_baseline`. Sem push, nova versão ou nova exportação
de app/ZIP/PCK; os resultados de pacotes anteriores são históricos.

## Alinhamento visual dos T de SETTINGS — ADR-114

Usuário apontou TT acima deSE/INGS. Compensação óptica de+1pixel nativo
somente nos dois T, nos quatro estados, em `room_settings_word_baseline`
78×22. Usa a linha superior visível, incluindo suavização, em vez de alinhar
apenas a caixa de pixels fortes. Fonte/1436facesRGBA, espaços, acabamento,
transparência, demais letras e START aprovados preservados.

988checksGodot/0; dois novos checks reproduziram o erro anterior. GPUFullHD
e revisão aprovadas: START inteiro idêntico, bordas transparentes, estados,
fallback e clique/modal. Ver `SETTINGS_BASELINE.md` e `docs/settings-baseline`.
Sem nova exportação/PCK/app, versão, commit/push. Aceite visual separado.

## Acabamento único da palavra SETTINGS — ADR-113

Usuário aprovou alpha daADR-112 mas rejeitou os recortes. Agora
word_polished78×22/quatro estados mantém1436facesRGBA nativas exatas, com
espaço2px e um contorno azul único2px/alpha suave0,15px. RGBBICUBIC4×;
fallbackRGB nativo/alpha de áreaBOX semringing. Todas4bordas transparentes.
Casca eSTART aprovados intactos; topo absoluto das faces continua18.

986checksGodot/0 em4suítes. GPUFullHD confirmaSTART inteiro idêntico àADR112,
cenário nos cantos,4estados/fallback da palavra e clique/modal preservados.
Revisão final aprovada;PCK96/0/exit0, semoverride, ressalvas ambientais
CA/editor_settings registradas.
VerSETTINGS_WORD_FINISH.md e docs/settings-word-finish. Semapp/ZIP,versão,
commit/push; aceite visual do usuário separado.

## Alpha real e composição de SETTINGS — ADR-112

Casca107×45 `room_footer_shell_clear` nas texturas reais deSTART/SETTINGS:
cantos externos transparentes, sem cenário gravado no sprite. FonteSTART
aprovada preservada em camada separada. SETTINGS83×20 `word_isolated`, Tdo
START,IsemfragmentoX, espaçamento3px e topo18 comum; componente8conexa remove
fragmentos do A vizinho nosTs.1436pixels de faceRGBA exatos às fontes.

1344checksGodot/0 em8suítes. GPUFullHD: cenário nos cantos, letteringSTART
idêntico, quatro estados/fallback da palavra e cliqueSETTINGS preservados.
Revisão final aprovada;PCK96/0/exit0,semoverride, ressalvas ambientaisCA/
editor_settings registradas. Fontes/derivados anteriores mantidos. VerROOM_BUTTON_ALPHA.md e
docs/room-button-alpha. Semapp/ZIP,versão,commit/push; aceite visual separado.

## SETTINGS retorna aos pixels completos da fonte — ADR-111

Usuário rejeitou a reconstrução daADR-110 porque alterou a fonte. Registro
ativo room_settings_word agora aponta aWordComplete74×20/quatro estados,
copiandoRGBA completo dos glifos/contornos nativos. Limpar fundo/vizinhos e
ajustar junções; não recriar preenchimento ou traço. Versões rejeitadas
preservadas. START aprovado, modal e fonteASCII permanecem iguais.

969checksGodot/0;629núcleos e3156contornos exclusivosRGBA idênticos às fontes.
GPUFullHD:START aprovado idêntico,4estados/fallback eSETTINGS abre modal.
Revisão aprovada após corrigir margem do push;4364pixels de stencil dentro
dos limites. PCK79/0/exit0,semoverride,comressalvas ambientais registradas.
Contrato/evidência:SETTINGS_ORIGINAL_LETTERS.md e docs/settings-lettering-original.
Semapp/ZIP,versão,commit/push; aceite visual do usuário separado.

## Acabamento de SETTINGS; START aprovado preservado — ADR-110

Usuário aprovouSTART e rejeitou emendas deSETTINGS daADR-109. SETTINGS agora
usa palavraRGBA única81×17, recuperada dos glifos nativos, com altura/espaço/
contorno comuns e acabamento4×; não usaSystemFont. Quatro estados e fallback,
sem retângulos opacos dos recortes. Originais,modal efonteASCII preservados.

965checksGodot/0, revisão aprovada com reproduçãoRGBA dos dois atlas; GPU
FullHD dos4estados/fallback/clique real. START aprovadoRGBA idêntico na mesma
cena congelada. VerSETTINGS_LETTERING_FIX.md e docs/settings-lettering-fix.
Sem novoapp/ZIP,versão,commit/push; aceite visual permanece separado.

## SETTINGS, modal clássico e fonte preservada — ADR-109

START semseta eCHANGE substituído porSETTINGS semsetacircular. Bordas azuis
recortadas doSTARTGAME; START conserva palavra raster eSETTINGS usa letras
dos sprites originais, conforme correção do usuário que rejeitouSystemFont.
Modal azul560×470 com moldura nativa, rádios eOK/Cancel;95glifosASCII8×12 do
font.fnt original, fallbackexistente para caracteres fora desse repertório.
Layout é adaptação solicitada, sem novos modos/regras/perfil.

1317checksGodot/0 em8suítes (modal25/0),21Python/0. GPUFullHD comprova fonte
visível/corouro, botões/modal eidle;9quadrosRGBA/95glifos/9120bits conferidos.
Revisão aprovada após correção deESC com foco noLineEdit; cancelar/aceitar e
Start testados com cliques reais. VerROOM_SETTINGS_CLASSIC.md e captura atual
docs/room-settings-classic; versões intermediárias de fonte foram descartadas.
PCK isolado70/0/exit0,semoverride,comressalvasCA/editor_settings ambientais;
semapp/ZIP,versão,commit/push. Aceite visual,
mouse físico eescuta separados das verificações automatizadas.

## Ajustes finais da sala — ADR-108

Dificuldade agora aparece comoCPU · Normal/Leve/Precisa no card da máquina,
atualizada só aoAceitar. Oito pesos brancos têm base laranja restaurada por
amostra da textura ativa, sem poços escuros; fontePNG original intacta.
START usaSTARTGAME azul nativo107×45/quatro estados em660,552, no padrão
EXIT/CHANGE. CatálogoChrome43registros; START verde e42anteriores preservados.

1286checks Godot/0 em7suítes,752/0 na repetição final,21Python/0. GPUFullHD
confirma8baseslaranja,Normal/Precisa,estadosSTART eidle preservado. Revisão
independente aprovada.4quadros/alpha conferidos;222PNGs prévios intactos.
PCK isolado55/0/exit0,semoverride;CA/editor_settings ambientais registrados.
Contrato/resultados:ROOM_FINAL_POLISH.md e docs/room-final-polish. Sem novoapp,
ZIP,versão,commit/push; app exportado anterior não atualizado.

## Cards da sala, Ready e configuração do mapa — ADR-107

Pedido posterior corrige apoio144 daADR-106: composição em105/563,155,
encaixada na faixa nativa. Nomes dos mobiles ocultos nos dois cards, incluindo
Random; apelido/CPU,avatar/idle preservados. Ready/chave e cinco placas
SOLO/1:1/A SIDE/NODEATH/BASIC usam arteXFS,4×conservador/fallback. Placas
refletem somente regras existentes; nenhum modo novo. Chave não cobre nome.

7PNGs/25janelas,64checks independentes deRGBA/alpha/hash;456assets prévios
intactos. Regresso1093Godot/0 em10suítes,21Python/0. GPU1920×1080,17escolhas
nos dois lados,Nak equipado,24quadros20Hz/20variações,âncorasfixas/heldtime
idêntico. Revisão aprovada apósP2: Ready usaIGNORE e preserva clique no card,
com cliques reais de viewport e probe negativoPASS reproduzindo2falhas.
PCK40/0/exit0,semoverride; ressalvas ambientaisCA/editor_settings registradas.
VerROOM_CARD_FIDELITY.md e docs/room-card-fidelity. Sem novoapp/ZIP,versão,
commit/push; app anterior não atualizado. Aceite visual/mouse físico/escuta
separados das verificações automatizadas.

## Versionamento e push solicitados — 25/10/2026

Usuário autorizou versionar todas as correções pendentes da sala e enviar ao
origin. Preparação na main, incluindo ADR-105/106, assets nativos/4×, Random
com avatar, idle ativo, catálogo/slots e evidências/testes. Verificação repetida:
1027checks Godot/0 em10suítes deUI/avatar/animação,21testes Python da skill,
100hashes do manifest conferidos e git diff --check limpo. Fetch confirmou
origin/main como ancestral, com3commits locais anteriores ainda não enviados;
o envio solicitado inclui esses ancestrais. Sem novoapp/ZIP ou versão.

## Sala corrigida, Random com piloto e idle ativo — ADR-106

Catálogo agora usa tiles nativos uniformes64×43 com símbolos1/2slots; barra
usa35/71×31, seis posições. Setas encaixadas. Mobile tem âncora fixa no chão144,
faixaA/B atrás e nome à frente; idle/avatares recebem elapsed, sem seno adicional.
Random usa corpo original OpenBound12quadros, avatar equipado e4×/fallback;
UI−2 e sorteio14/15 noStart intactos. Nome/mapa duplicados removidos, só setas
laterais nativas; inativas enquanto MiramoTownA for o único mapa implementado.

23PNGs/56janelas,132checks de arte +Randomfonte/alpha/hash conferidos;
359arquivos anteriores e11PNGs da etapa anterior intactos. Regressão1720/0,
rodada finalUI/animação1027/0,21Python. GPU24quadros com animação/âncoras fixas,
avatarRandom altera só piloto/semRNG. PCK109/0/exit0 semoverride/TLSlocal,
CA/editor_settings ambientais registrados. VerROOM_POLISH.md e docs/room-polish.
Sem novoapp/versão/commit/publicação; aceite visual/mouse/escuta separados.


## Sala conforme foto — ADR-105

Pedido substitui grade8×2/abas daADR104:14mobiles comuns+Random em5×3.
Knight/Dragon não têm botões diretos;Random−2 é apenas escolhaUI e sorteia
14/15 aoStart, com RNGprivado e flags independentes piloto/CPU. Mantém seleção
na sala/loja. Catálogo único11itens com roda/setas,6slots preservados.
Oito lugares têm faixasA/B nativas,nomes na base e mobiles acima delas.

11PNGs/15janelas4× novas emroom_reference_4x,alpha nearest; source eHD anteriores
intactos. Setaspressed17px versusnormal16 são PNGs separados, sem padding.
1669checks Godot/0,21Python; revisão455+7+81semfalhas. GPU1920×1080 ePCK53/0/exit0,
semoverride/TLSlocal. Fonte/hash/limites:ROOM_REFERENCE_LAYOUT.md;
capturas emdocs/room-reference. Sem novoapp/versão/push/commit solicitado.
Perfil/batalha/recompensas preservados. Aceite visual,escuta/mouse físico
permanecem separados das verificações automatizadas.


## Sala clássica e acabamento4× — ADR-104

Trabalho anterior já versionado emd8b50c7. Sala usa mapa/retratos nativos,
fundo e11folhas de itens em BICUBIC4× (14PNGs/84células,alpha nearest).
Ghidra confirma janelas332,51/378,390. CabeçalhoGM, pesos de clima, avisos e
contenção dos textos implementados. Dragon/Knight ficam textuais, pois a
fonte éRandom. Grade8×2,16mobiles,estados/hitboxes e6slots preservados.
ItemArt de batalha e perfil/combate/versão intactos. Fallback nativo validado.

1256checks Godot/0,21Python, revisão final172/0 e auditoria95/0. GPU real
1920×1080 normal/stress, mesma geometria; galeria16retratos. PCK183/0/exit0,
semoverride/TLSlocal. Fonte/PNG/catálogos incluídos, commitlocal autorizado.
Limites ambientais e escopo adaptado em ROOM_UI_FIDELITY.md; capturas/hashes
emdocs/room-ui. Sem push/appnovo; app previamente exportado continua anterior.
Aceite visual/escuta/mouse físico permanecem separados.


## Lobby com acabamento4× completo — ADR-103

Correção chat/GM versionada em5732568. Fundo, molduras chat/canal,
preenchimento e50insígnias agora usam BICUBIC4× conservador/alpha nearest.
SeisPNGs em assets/hd/classic/lobby_smooth_4x; fontes/botões prévios intactos.
Tamanho visual/posições/áreas de clique nativos; fallback validado.
Sala permaneceRGBAidêntica. Sem alteração de perfil/combate/versão.

1045checks Godot/0 e21testes Python, revisão independente776/0,54células
conferidas. GPU1920×1080 padrão/stress, PCK223/0/exit0 semoverride/TLSlocal.
CA/editor_settings ambientais detalhados em LOBBY_ART_HD.md. Commit local
autorizado, sem push/app novo. Aceite visual do usuário e mouse físico/escuta
permanecem separados. Capturas/hashes: docs/lobby-art-hd.


## Lobby corrigido e patente GM — ADR-102

Rank deixou de ser level(): perfil novo e legado sem patente recebem GM20,
Administrador do Sistema. Campo rank version4 persiste separado do XP/level;
saldos, avatares e atributos preservados. REA/Hopper confirmou o WORD+4 do
cliente e atlas rank1/rank2, GMquadro24; GM27OpenBound não é a convençãoThor.
GP continua sendo XP local; nenhuma ladder ou tabela competitiva foi criada.

Cartão tem campos separados/contidos, insígnias originais no cartão/canal;
chat recebe Enter, texto literal,64mensagens e roda do mouse. Entrada usa
estilo transparente dentro da faixa. Filtros usam posições nativas; tag de
versão cabe na lateral. Catálogo/extrator de patentes separados, sem substituir
botõesHD/fundos aprovados. Registro/evidência: `LOBBY_UI_RANK.md`.

Validação **1086checks Godot/0**,96/0 repetidos pelo revisor,50quadrosXFS
conferidos. GPU real1920×1080, padrãoGM e stress em `docs/lobby-rank`.
PCK isolado109/0/exit0 com CAambiental e semoverride/TLSlocal. Import/export
registram CA/editor_settings ambientais. Sem execução do cliente original,
sem perfil real nos testes, sem versão/app/publicação. Commit local solicitado em25/10/2026; nova
verificação dirigida735checks/0 antes do versionamento. Aceite visual
manual e eventual aplicativo atualizado ainda separados.

## Versionamento local — 25/10/2026

Por solicitação do usuário, alterações pendentes da sessão anterior reunidas
para commit local: restauração/suavização dos botões, integração, evidências,
testes e skills, incluindo a cópia Codex de `gunbound-client-port` (9 arquivos
idênticos à skill já versionada). Verificação repetida nesta sessão:
`test_classic_buttons_hd test_scene test_items_scene test_roster test_shop_wide`
com **778 checks/0 falhas**, **21 testes Python** da skill HD aprovados e
`git diff --check` sem problemas. Sem push, mudança de versão ou nova exportação;
os limites de inspeção visual/manual e do aplicativo abaixo permanecem.

## Suavização aprovada aplicada — ADR-101

O usuário aprovou o EXIT bicúbico e autorizou aplicação ao lote e adoção na
skill. `ClassicChrome` agora usa `assets/hd/classic/buttons_smooth_4x`:
42atlas/197estados, BICUBIC por quadro e alpha nativo preservado. EXIT
idêntico à prévia aprovada;180arquivos de fontes/exatos anteriores intactos.
Geometria, estados, cliques e fallback permanecem. As cores são interpoladas.

Validação atual: **778checks Godot +21testes Python**, sem falhas. GPU real
1920×1080: layout/hitboxes iguais, mudançasRGBA restritas aos botões. PCK
isolado92/0/exit0 confirma atlas, JSONs, hash do EXIT e ausência de override/TLS
local. Revisão independente aprovada; CA/editor_settings ambientais no registro.

Skill instalada sincronizada:14arquivos idênticos, estrutura/links e21testes
aprovados. Modo exato permanece disponível; verificador não sobrescreve
imagens/relatórios. Registro: `CLASSIC_BUTTONS_SMOOTHING.md`; capturas em
`docs/classic-buttons-smoothing`. Sem app novo/versão/publicação; aplicativo
previamente exportado não foi atualizado. Inspeção visual integral pelo
usuário e escuta/mouse manual permanecem separados das verificações automáticas.

## EXIT — prévia de suavização conservadora

Pedido atual: avaliar melhoria de nitidez antes de um lote. Duas restaurações
IA do estado normal alteraram detalhes/margens e foram rejeitadas para
produção. O usuário aceitou testar suavização algorítmica conservadora.

`docs/exit-restoration-preview/exit-4x-bicubic.png`:1712×180, quatro estados
processados separadamente com BICUBIC, alinhamento/alpha preservados e sem
margens novas. As cores são interpoladas; não é repetição exata de pixels.
Dimensões/grade/alpha aprovados, comparação antes/depois e quatro estados
conferidos. Fonte e atlas ativo intactos. Registro em
`CLASSIC_HD_RESTORATION_SKILL.md` e `docs/exit-restoration-preview/reference.json`.
Aceite visual, eventual integração e lote aguardam decisão do usuário.

## Botões4× integrados no lobby/sala — ADR-100

`ClassicChrome` usa os atlas4× validados, mantendo geometria/estados no
manifest nativo. Apenas recortes de textura mudam de densidade; mínimos,
posições, filtro, stretch e hitboxes ficam iguais. Fallback nativo para HD
ausente/inválido. Os dois JSONs foram incluídos no preset de exportação.

Suítes dirigidas: **735checks/0falhas**, incluindo nova544/0, cliques reais
da viewport e fallback. GPU final1920×1080: lobby/sala RGBA idênticos ao usar
texturas nativas ou4× na mesma cena congelada. PCK isolado91/0/exit0 confirma
42atlas e os dois JSONs, sem override/TLS local. Revisão independente aprovada.
PNG/JSON em `docs/classic-buttons-integration`; registro e limites em
`CLASSIC_BUTTONS_HD_INTEGRATION.md`.

GPU restrita abortou em registro gráfico/fontes; captura fora do sandbox
funcionou. CA/editor_settings ambientais explícitos no registro.95arquivos
de origem e42PNGsHD intactos por hash. Sem nova versão/app; app já exportado
não foi atualizado. Aceite visual/escuta/mouse manual pendentes.

## Todos os botões clássicos4× — derivados exatos

Pedido seguinte aplicado aos41atlas restantes de `assets/classic`. Conjunto
em `assets/hd/classic/buttons_4x`:42PNGs incluindo o CREATE já conferido,
197estados, catálogo com dimensões/ordem/regiões/hashes e registro original.
Checker exato aprovado em42/42; comparação independente de8087792pixels RGBA
sem divergências ou novas cores/margens.95arquivos de origem intactos por
hash antes/depois. Inspeção de amostras START/canal1/Friends/Dragon.

ZIP42PNGs+catálogo em `docs/classic-hd-restoration/classic-buttons-4x.zip`,
CRC e hashes conferidos. Relatórios em `reports/buttons-4x` nessa pasta.
Registro: `CLASSIC_HD_RESTORATION_SKILL.md`. Derivados ainda não conectados
ao runtime; nenhum build, versão ou código alterado nesta etapa.

## CREATE4× — ampliação exata na skill HD

Pedido posterior e escolha explícita do usuário por repetição de pixels.
Saída `docs/classic-hd-restoration/output/create-4x.png`:1712×180RGBA opaco,
quatro estados de428×180, sem margens novas. Checker exato e enumeração
independente conferem308160pixels, zero divergências e mesmas648cores.
PNG inspecionado. É ampliação pixelada4×, sem alegar novos detalhes por IA.

Skill ganhou helper de repetição e `--exact-pixels` no checker;15testes
aprovados no repositório e na instalação sincronizada;11arquivos idênticos,
estrutura/links válidos e revisão independente aprovada. A nova tentativa
IA2164×726 também foi rejeitada e preservada.
Registro: `CLASSIC_HD_RESTORATION_SKILL.md`. Fonte, runtime e build preservados.
Aceite visual do usuário e eventual integração permanecem separados.

## Skill gunbound-classic-hd — restauração fiel (ADR-099)

Pedido atual atualiza a skill, sem trocar arte ativa. Prompt completo do usuário,
fonte visual única, preservação de geometria/paleta/alpha/quadros e alvo4×
substituem o padrão de acabamento2.5D. Rig/efeitos aprovados continuam acessíveis
no seu escopo. Registro: `CLASSIC_HD_RESTORATION_SKILL.md`.

Três gerações reais com `assets/classic` foram rejeitadas: lobby1448×1086
(alvo3200×2400, alpha/aparência alterados), CREATE2170×725 (alvo1712×180)
e Mage2048×768 (alvo1260×188); atlas ganharam padding/aspecto errado.
Brutos, prompts e JSONs/hash em `docs/classic-hd-restoration`. Nenhum foi aplicado.
Checker read-only:9testes aprovados; estrutura válida e cinco cenários de
comportamento revisados independentemente. Sem validação Godot/GPU nova nem build.
Cópia instalada sincronizada com backup;9testes também aprovados na instalação,
estrutura/links válidos e arquivos idênticos. Aceite de arte futura continua pendente.

## Sala — ícone do Dragon

`b_ready_mobile14` do cliente é o Aduka, o mobile que vem depois do Grub.
A grade entregava esse botão ao Dragon (ID 14). O Dragon passa a usar o
quadro 0 do atlas `tank14` (`b_ready_mobile_dragon`); o Aduka (ID 16) fica
com o botão original 14. Sem mudança de ID, de combate ou de versão.

## Sala — Knight, Aduka e item de 2 slots

O ícone de Knight e de Aduka colava o quadro 0 do atlas por cima do botão
inteiro de `b_ready_mobile01`, que já traz o Armor. O recorte do spritesheet
é um só mobile; o lugar A/B também desenha um atlas e um avatar, o mesmo
caminho dos outros clássicos, sem empilhar casco, arma e piloto. O fundo do
botão agora perde o Armor antes da colagem. Item de 2 slots é um retângulo
só (os dois lugares e o vão); item de 1 slot continua em um. Clique na peça
remove o item inteiro. Catálogo, gravação e o limite de 6 slots permanecem.
CPU sem itens. Sem rede, sem commit, sem reexportar e sem mudar a versão.

Suítes: `scripts/check.sh test_items_scene test_scene test_roster`.
Resultado: **154 checks, 0 falhas** (itens 47, cena 27, roster 80).
Aceite visual da sala ainda depende do olhar do usuário. O cliente original
não foi executado. Sem captura nova.

## Sala — grade, lugares e avatar — ADR-096

A grade 8×2 é a única escolha de mobile. Cada ícone cabe na própria célula
do poço (36×28, passo 41×40); o PNG de 63×47 não invade o vizinho. O clique
aplica no piloto. O lugar B só muda o modo (“Escolhendo: máquina”) e o
próximo clique da mesma grade vale para a CPU. O modal de mobile saiu; o
popup de CHANGE permanece.

Os lugares A e B desenham o mobile num nó acima do fundo e atrás dos nomes.
O piloto usa o avatar equipado do perfil, no mesmo encaixe da arena. A CPU
fica com o piloto padrão, sem as peças do perfil. O casco na sala é 52 px
nativos para o cell mais largo caber nos 124 px do lugar. Sem rede, sem
commit, sem reexportar e sem mudar a versão.

Suítes: `scripts/check.sh test_scene test_roster test_bigfoot test_classic_mobiles test_items_scene`.
Resultado: **324 checks, 0 falhas** (cena 27, roster 80, Bigfoot 28, clássicos 142, itens 47).

Pendente: aceite visual do usuário (pés na base, cabeça abaixo do nome, sentido). Sem captura nova. O cliente original não foi executado.

## Lobby clássico e sala — ADR-096

A entrada passou a ser o lobby (`gamelist_back`). Create abre a sala 1×1
(`ready_back`), que conserva mobile, CPU, itens, apelido, dificuldade, clima
e Iniciar. Buddy não entra. Ranking e Join ficam desabilitados. Sem rede.
Rank/GP do cartão são nível e XP locais. O mapa segue Miramo Town A. Jewel,
Death e Big Bomb não viram regra. A loja volta à tela que a abriu. O app não
foi reexportado e a versão do `project.godot` não mudou.

Extração: `python3 scripts/import_classic_lobby.py` (SHA do XFS conferido).
Suítes: `scripts/check.sh test_scene test_items_scene test_roster test_bigfoot test_classic_mobiles test_shop_wide`.

Resultado: **336 checks, 0 falhas** (cena 27, itens 46, roster 63, Bigfoot 28,
clássicos 136, loja larga 36). O ESC da loja aberta na entrada volta ao lobby;
`test_shop_wide` foi ajustado para essa volta, sem afrouxar o resto.

Pendente: aceite visual do lobby e da sala, escuta, e o cliente original não
foi executado. Sem captura nova. A grade de mobiles cabe no painel medido, então
os ícones de 63×47 aparecem reduzidos. Importação Godot dos PNG concluiu;
gravar `editor_settings` falhou por permissão ambiental, como nas entregas anteriores.

## Itens da sala no painel direito

Os seis lugares pintados em `ready_back` mostram o ícone do item. O nome
deixou de ser um rótulo no poço abaixo desses retângulos, onde vazava para
fora. A escolha fica nesse painel, grava em `options.items` ao mudar e não
abre o modal Select Item. Sem rede, sem regra nova de combate e sem app novo.

Suítes: `scripts/check.sh test_items_scene test_scene` — **74 checks, 0 falhas**
(itens 47, cena 27). Sem captura da sala nesta correção; o cliente original
não foi executado e não houve validação de escuta nem de mouse.

## Correções ASate/JD/Aduka/Raon — ADR-094

Ler SPECIAL_MOBILES_CLASSIC_FIX.md e os quatro registros CLASSIC_FIX.
Módulos próprios integrados ao passo real/previsão: Ion com1/3/6 filhos;
JD T2 atrai, SS repele e causa dano por tick; Aduka T2/SS chamam Thor fora
do clima Thor; Raon T1 três componentes e minas com autoria/clocks próprios.
Minas SS concluem antes da troca de turno; fase `mines` resolve S2 antes
do input. CPU reconhece plantio/Thor. Thunder preservado uma vez no guia.
Cristal JD novo substitui o anterior do mesmo dono. Render EPA/arte original,
laser Thor aditivo e PCM Ion T1/T2; SS Ion sem stream porque fonte ausente.

Verificação final: **11493 checks Godot +29 testes Python +29 partidas**,
zero falhas; parse aprovado. Integração nova263/0, revisão independente
tratada. App/ZIP0.20.5 reexportados e assinados, versão/CRC conferidos;
probe PCK isolado68/0/exit0, com ressalva ambiental de CA. Export/import
registram CA/editor_settings sem permissão; sem SCRIPT ERROR/leaks no PCK.
Após o último ajuste simultâneo da sala, seis suites dirigidas184/0 e nova
exportação/PCK confirmam a composição final, sem runtime mais novo que o pacote.
QA GPU não executou: SIGABRT/FontRegistry antes do primeiro quadro;
LaunchServices também falhou. Script temporal pronto e parse aprovado,
sem captura nem aceite visual/escuta novos. Detalhes/hashes/logs no registro.
Dano/colisão comum, apoio/parede e partes de minas S2 continuam adaptações
declaradas. Perfil, avatares/HD e mudanças locais da sala preservados.
Commit local autorizado pelo usuário em25/10/2026, sem envio ao remoto.

## Sala inicial 1×1 — ADR-092

A entrada deixou de ser o cartão “Preparar treino”. `menu_screen.gd` monta a
sala: lugar do piloto, lugar da máquina, Miramo Town A no centro, retrato e
Iniciar. Configurações da partida guarda apelido, dificuldade e clima até
Aceitar; Cancelar restaura. Mobile aplica no clique. O botão CPU escolhe o
mobile da máquina (ADR-093); sem escolha, vale `Mobiles.opponent`. Piloto e
máquina aparecem no casco nativo de 60 px (ADR-095), num palco da altura do sprite. Itens segue
o PopupSelectItem. Opções do cliente não entraram nesse menu. Sem regra nova
de combate, sem troca de mapa e sem build.

Validação: `test_scene` (cancelar/aceitar/mobile/CPU) e `test_items_scene`
(apelido e contagem de itens). Captura visual da sala ainda não registrada.
Aceite do usuário pendente.

## Ghidra adotado na skill — ADR-091

gunbound-client-port agora prefere Ghidra headless direto, com
`scripts/run_ghidra.py`, `scripts/ExportClientEvidence.java` e
`references/ghidra.md` na própria skill. Não depende dos scripts temporários
da avaliação anterior. Importação nova, seeding explícito de entradas
comprovadas, referências/vtable/dados e reabertura testados;22extratos
idênticos. Função ausente retorna falha apesar do exit0 do launcher.

Ponte estática→Godot: float8/LUTs extraídos e8checks independentes de
ângulo/seção passaram; suites dirigidas1368/0. Runner5testes Python
aprovados, incluindo descendente resistente ao TERM após timeout; validator,
links/UI/alias aprovados. Testes independentes antes/depois da skill;
detalhes, hashes, limites e evidência em GHIDRA_SKILL_VALIDATION.md.
Não executamos o cliente original/GUI nem QA visual novo. Esta tarefa não
conclui a implementação0.20.4 preexistente. Sem mudança de runtime/build.
Versionamento local autorizado posteriormente pelo usuário, após pull/merge
da main. Revisão final: cinco testes Python do runner aprovados; alterações
da skill e registros preparados para commit local, sem push. Override de
certificados permanece local e excluído do versionamento.

## Avaliação de ferramenta — Ghidra 12.2

Pedido atual: avaliar Ghidra após problemas no Hopper. Resultado em
[GHIDRA_EVALUATION.md](GHIDRA_EVALUATION.md): headless direto funciona no Mac
arm64/Java25, autoanálise26s/2408funções. Quatro de oito rotinas Mage exigiram
indicar entradas conhecidas em vtables; depois8/8 decompiladas e reabertura
readOnly com24extratos idênticos. Cache redirecionado e projeto fora de
`.tools` (Ghidra rejeita componente de projeto iniciado por ponto).
REA6.7.0 atual sem GHIDRA_INSTALL_DIR e sua política aceita12.1.x, rejeita12.2;
usar CLI direta neste ambiente. GUI/cliente original não executados; sem
benchmark novo do Hopper. Nenhuma regra/asset/build alterado nesta avaliação;
trabalho parcial0.20.4 preexistente não foi validado por ela.

## Estado atual — restauração Bigfoot/Mage 0.20.3

Pedido atual substitui parcialmente a preservação HD da ADR-088. Ler
ORIGINAL_MAGE_BIGFOOT.md e ADR-089. Atlas tank2/tank5, EPA, RiderPivot,
tiros/luzes/impactos extraídos em subpastas original/, sem sobrescrever os
arquivos anteriores. Catálogo ativo usa ClassicSprite/ClassicMageSprite,
escala nativa, miras e auras originais. Imagens/descritores HD anteriores
conservados como histórico; avatares/equipamentos, regras, IDs e perfil
mantidos. Mage T1/T2 conservam composição OpenBound adaptada; SS nativo usa
ssflame2. Bigfoot T2 usa seu flame52 em vez do Armor do fork.

Validação atual: **8059 checks Godot + 17 testes Python + 29 partidas**,
zero falhas e parse aprovado. Oráculo de pixels/hotspots/RiderPivot/EPA do
XFS; regressão ativa 39/0. Galeria GPU real 1920×1080/210 quadros/60 Hz:
poses, sentidos, inclinações, tiros/impactos; pausa de 30 quadros idênticos.
São fixtures de apresentação, não execução do cliente ou tiros reais.
PNG/MP4/hashes em docs/original-mobiles/. Captura específica menu/loja/arena
preparada e parse aprovado; execução posterior bloqueada por timeout UI.
Suites de cena/modelos cobrem esses fluxos.

App/ZIP **0.20.3** exportados, assinatura profunda/estrita, versão e CRC
conferidos. PCK isolado 44/0/exit0: 16 sprites/JSON/recursos carregam, sem
override/TLS local nem SCRIPT ERROR/leaks. Ressalvas ambientais de CA no
smoke e CA/editor_settings no export detalhadas no registro. Override de CA
usado apenas no harness e removido antes do build. Aceite visual do usuário,
mouse manual e escuta pendentes. Nenhum commit/push.

As seções abaixo são históricas; resultados anteriores não validam 0.20.3.

## Catálogo clássico — REQ-46, ADR-089

Pedido: manter todos os avatares originais do Gunbound clássico e refazer o
catálogo com equivalência ao launcher e ao servidor jglim. Ler
`AVATAR_CLASSIC_CATALOG.md`. A versão do aplicativo continua a da `main`
(0.20.2); este índice não reexporta o app.

Na `main`, REQ-45 e ADR-082 já nomeiam o roster dos 16 mobiles e o brilho do
chifre. O catálogo de avatares fica em REQ-46 e ADR-089 para não reutilizar
esses números.

- `avatar.xfs` local é o TestClient do launcher (22968 bytes, mesmo SHA-256).
  562 registros, 479 compráveis. Nenhum foi removido. `ff.dat` continua vazio;
  `ff00001.img` e `sff00001.img` ficam fora da loja. Love Cupid (id 143) não
  existe nesta versão e o decodificador não o inventa.
- `assets/xfs/avatars/classic.json` é o índice: DAT, slot do servidor, preços,
  oito status na ordem do AvatarInfoProcessor e texto CP949. A arte e a chave
  `xfs:gênero:categoria:id` permanecem. Categoria da loja não muda, então
  equipamento salvo continua na mesma peça.
- WORD: id nos 15 bits baixos, bit 15 masculino. DWORD: slot no terceiro byte
  (corpo, cabeça, olho, bandeira). Equipado: quatro WORDs nessa ordem. O
  conjunto `amigos` (`448043802480A480`) resolve Rocker Suit, Rocker Hair,
  Dizzy Glasses e Bazooka. Padrão masculino `0080008000800000`; feminino oito
  zeros. Bandeira vazia é WORD 0 nos dois gêneros.
- 28 descrições saem de CP1252 para CP949. A reticência volta a ser `…` e o
  UserID do concurso volta a `까꿍사냥꾼`. Preços e bônus intactos.
- Validação na branch, antes do merge: `test_xfs_import.py` 12 testes;
  `test_xfs_catalog.gd` 3816 checks, zero falhas; regressão de catálogo,
  perfil, equipamento, saldo, atributos, migração HD, arte e loja XFS, 2178
  checks, zero falhas. Sem partida completa: dano, atraso e o snapshot de
  bônus não mudaram de fórmula.
