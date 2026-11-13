# JEWEL offline — execução do plano aprovado

Pedido de13/11/2026 autoriza implementar o plano [JEWEL_ISSUE_46.md](JEWEL_ISSUE_46.md).
Base verificada `a10ebf26d1f48685c22d7923cf4d11aa58fb3565`, worktreef19e,
branch `codex/jewel-offline-mode`, distinta da implementação de mapas em bb36.
Versão fonte única permanece a do project.godot; números de releases não
substituem essa configuração nem autorizam bump manual.

## Contrato de entrega — REQ-JEWEL-46

- JI-1: selecionar SOLO/JEWEL na sala; resolver modo antes do loading e
  conservá-lo até resultado/volta. SOLO é padrão e mantém contrato anterior.
- JI-2: jewels têm estado próprio, até oito slots, geração/apoio/queda/poses,
  resistência, autoria e remoção pelos consumidores comprovados. Não são atores.
- JI-3: colisão/dano/áreas/itens/clima correm no mesmo passo real e previsto;
  snapshots isolam entidades, placares, RNG e autoria. Não usar interpolação
  em contato. Regras ainda adaptadas do combate devem ser delimitadas.
- JI-4: pontos por time+25/+10/+5/−5, piso0, alvo100; morte/respawn/agenda e
  reposição dependem do contrato nativo fechado antes do respectivo código.
  Resultado é idempotente; teste nunca lê ou grava perfil real.
- JI-5: CPU escolhe objetivos pelo resultado completo da rajada na cópia;
  a estratégia offline é adaptação declarada, sem ler estado vivo no worker.
- JI-6: arte/EPA/luzes/impactos/HUD e sons comprovados do Thor, com
  proveniência/pivôs/alpha preservados. Nenhuma aparência nova ou trilha inventada.
- JI-7: testes independentes de modelo/cena/CPU, partidas completas SOLO e
  JEWEL, GPU temporal/pausa, regressão e revisão; interação com mapas após
  rebase na primeira entrega. Merge JEWEL aguarda liberação após mapas.

## Arquitetura escolhida

Executar os seis gates do plano. `MatchMode` separa a política de objetivo
da iniciativa existente; `JewelRules` guarda entidades e regra sem Node ou
recurso gráfico. `FlightSnapshot` fecha cópias privadas. `JewelArt` interpreta
EPA e publica camadas alfa/luz; sala e HUD consomem o modo do modelo. CPU
usa resultados previstos, não um atalho geométrico de pontuação.

Alternativas de embutir jewels em actors ou usar uma segunda simulação só
da CPU conflitam com identidade de mobile/atributos e com execução=previsão;
o plano aprovado já escolhe entidades separadas e passo comum.

## Estado de execução

1. Contratos: fechados nos recortes descritos abaixo, limites explícitos.
2. Entidades/snapshot: implementados, oráculosPE e cópia privada aprovados.
3. Objetivo/agenda/resultado: implementados, cena21/0, retorno/XP idempotentes.
4. CPU/famílias/itens/clima: integração48tiros261/0; primeira partida natural33tiros.
5. Importação/arte/sala/loading/HUD/áudio: implementados; GPU210quadros271/0.
6. QA/revisão local aprovados; PR51 em rascunho, CI remoto e rebase/matriz de mapas pendentes.

Cada lacuna resolvida deve apontar ASM/bytes/oráculo e fronteiras; qualquer
adaptação remanescente deve ser nomeada com impacto e validação. Esta página
não aprova regras novas que a pesquisa não demonstrou.

## Contratos fechados durante a execução

[Dano](../jewel-implementation/damage/CONTRACT.md) fecha ABI450eb0/478cb0,
339blastsPE+16contatos+7shocks. [Ciclo](../jewel-implementation/lifecycle/CONTRACT.md)
fecha geradores, limiar15/40/80, contador estabelecidos, retorno por clique
após2avanços, HPmax, passe e imunidade de piloto. [Auxiliares](../jewel-implementation/lifecycle/AUXILIARIES.md)
fecha JD T2/SS, Lightning SS e gatilho Raon (categoria186a6).
`damage-tick-fixtures.json` executa355ticks doPE: queda/bounce/vento/apoio/
ânguloLUT/EPA. O resultado observado doRED foi240falhas;
758checks finais da suíte correspondente passaram. Não confundir casosPE
com checksGodot nem evidência estática com execuçãoPE.

## Integração e adaptações delimitadas

- `JewelRules` mantém8slots, seis tentativas iniciais e uma reposição por
  troca (inclui passe); menor limiar15. Resistência acumulada/autor, quedas,
  vento, apoio e remoção seguem o consumidor nativo; corpo e luz usam mesmo
  frameEPA, sem módulo para inventar luz fora dos50quadros disponíveis.
- `MatchMode` preserva iniciativa SOLO, bloqueia HP/escudo por dano emJEWEL
  e impede fim por eliminação. Humano escolheX com clique/toque no mundo;
  CPU escolhe seuX anterior imediatamente (estratégia offline declarada).
  Retorno após2transições restauraHP/shield e passa pelo resolvedor de apoio
  existente: a queda visual de piloto segue a ponte offline já existente,
  sem alegação de reprodução integral do drop doPE. Ator esperando não
  atira/usa item/move nem colide; os turnos dele passam para agenda avançar.
- StreamCRT privado reproduz a fórmula e ordens inicial/reposição, sem
  reproduzir consumos globais de ofuscação/UI do cliente inteiro.
- `JewelCombat` usa triplosP/D/aspecto de shell nativo onde já portados
  (Mage/Bigfoot/Boomer/Ice/Grub/Aduka/Thor/Lightning). DAT pinado confirma
  que os3materiais são iguais em todas48linhas. As famílias restantes
  conservam shell já preparado/dano/raio e itens do treino anterior como
  pontes declaradas; defesa de mobile nunca é aplicada a jewels. Minas,
  bolts e filhos conservam payloads próprios, sem clonar dano do pai.
  NÃO se anuncia paridade integral desses48produtores com o cliente.
- JD adiciona14bruto por tickSS semDefense/Attack, autoria antes de gate
  slope80; atração/repulsão e dívida de movimento próprias. LightningSS
  seleciona jewels porPOSdireto/raio120; shock só muda pose, sem resistência
  ou autor. MinasRaon testamPOSjewel em8pxestritos, incluindo drop.
- CPU é adaptação offline: escolhe jewel positivo próximo para rumo,
  avalia rajada completa com pontos e resistência útil na cópia, evita valor
  negativo e mantém dificuldade/erros e relógio de busca anteriores.
- HUDusa NativeJewelPanel/dígitosnumfont189..198 e pontos dos dois times;
  posição no header800×500 e escala para caber são adaptações visuais do
  layout atual. O consumidorPE408180 desenha dígitos no footer800×600.
  Som de remoção `jblast.xes` já extraído; Jflame em remoção por dano (inclusive drop), salvo ramo de vitória,
  sem trilha nova. Resultado mantém BGM de batalha até OK (ADR-153).

## Validação em curso

RED modelo observado por ausência de argumento modo; GREEN14/0.
RED cena2/2→GREEN21/0; cena/sala/loading/HUD/resultado somam821/0.
Regras758/0 e arte26/0; Python pixels/EPA4/4 +DAT48×3triplos aprovado.
Primeira importação no sandbox falhou por certificados doSO: repetição
fora do sandbox com perfil de teste isolado foi aprovada. `override.cfg`
local só aponta certificados, está ignorado e proibido nos exports; não é
parte da mudança. Não usar tentativas ambientais como rodada verde.


Revisão independente encontrou doisP2: JD precisava chamar consumidores de
jewels e minas independentemente; previsão parava no fimFLIGHT antes de
pontuação tardia por void. Corrigidos e reavaliados semP1/P2 pendente;
integração261/0 inclui os reproduzidos e todos48tiros. Ao avaliar queda
posterior, a cópia usa advance_idle_tick comum por até360ticks de movimento,
sem agenda/reposição; estado vivo e turno permanecem privados.

Revisão de ASM adicional47a281→47a763: drop não pontua, mas dano suficiente
continua criandoJflame; RED759/1→GREEN759/0. Ramo de vitória47a711 salta
som/Jflame; evento de apresentação conserva esse gate. Passar contexto para
contato nativo de Armor/Trico não deve habilitar clima nesses produtores:
uma rodada integral detectou SCRIPT ERROR(influenced) no shell vazio usado
por esses scanners; sample agora exige shell real, mantendo consultaJEWEL
separada da ativação meteorológica. Rodada final ainda necessária.

GPU final210frames1920×1080,271assertivas/0: estados, tipos0..3, drop/vento,
dano/score, shocksemcrédito, alfa/luz, Jflame,30bufferspausaRGBAidênticos e
retomada no primeiro tick nativo. Primeira assertiva de retomada verificava
um frame de60Hz antes de completar20Hz; fixture corrigida para o tick real,
sem mudar runtime/limite. Capturas de sala/loading/batalha/resultado1280×800
inspecionadas; primeira fixture sem queue_redraw após editar estado foi
recapturada. Não houve aceite humano, interação física/escuta ou execução
integral do clienteWindows. Sem bump/manualrelease; presets incluem JSONsJEWEL.

Extratos C/ASM/logs versionados tiveram apenas espaços de fim de linha e
linhas vazias finais normalizados para `git diff --check`; bytes/endereços,
instruções e diagnósticos permanecem integrais. Hashes dos manifestos
identificam o PE de origem, não a apresentação textual desses extratos.


Conferência final de45db20: o gateJEWEL ocorre após escolha da pose. Um
novo evento `pilot_hit` conserva hurt/shock sem publicar HP/shield_damage,
HUD numérico ou Gold fictício. RED17/2→GREEN17/0; cena/modelo/Gold/resultado
somam410checks/0 após esse ajuste. Agregado anterior passou em616,667s:
385parses,62.930checks,165Python sem skips,37partidas; o agregado do head
com esse evento visual está em execução e terá resultado registrado à parte.

PCK final isolado passou smoke de lobby/sala/loja e48tiros; versão0.20.5,
sem override/recursos de teste. Não é atualização do aplicativo instalado.

O treino não ativa o sorteio de falas/canal de chat do cliente (ramo raro
após47a83c); pixels e EPA `say` estão preservados e são interpretáveis pelo
renderer. Essa omissão de apresentação é declarada, sem inventar textos ou
ampliar o escopo para o chat/rede do cliente. Evidência de clipping, publicação,
HUD e Jflame em [presentation/CONTRACT.md](../jewel-implementation/presentation/CONTRACT.md).


## Resultado final local — código63b4be53

`head-harness.log`:606,981s,385scripts compilados,129suítesGodot,
62.933assertivas,165testesPython sem skips,37partidas completas
(29SOLO existentes+8JEWEL cobrindo16mobiles), coberturaPython62%.
Exit0/FAILED[]; logs inspecionados, Ruff e diff sem erros. Metadados e hash
do PCK em [validation.json](../jewel-implementation/validation.json).

O [PR51 de implementação](https://github.com/guichafy/gunbound-recomp/pull/51)
foi aberto em rascunho após envio da branch. Revisão independente não tem
P1/P2 pendente. Os quatro checks remotos ainda precisam de confirmação;
merge aguarda mapas integrados, liberação da fila e rebase com a matriz
JEWEL×mapas. Worktree/branch preservados para essa continuidade. PR50 é
somente a pesquisa histórica já integrada, não esta entrega.


## Correção do checkout CI — PR51

A execução [43477147316](https://github.com/guichafy/gunbound-recomp/actions/runs/43477147316)
do head9b4d7eb6 falhou corretamente no Windows: `test_jewel_rules` encontrou
JSON vazio na primeira fixture e atingiu guard900s. O sparse checkout do job
não incluía `docs/jewel-implementation`, onde estão as três fixtures. As
37partidas e as outras suítes Windows passaram; macOS foi cancelado nessa
execução. Isso não valida o pacoteWindows nem substitui o novo gate remoto.

Incluída somente essa pasta no checkout desktop. Nova regressão inventaria
os literais `res://docs/` das suítes e exige cobertura pelos diretórios do
checkout: RED3falhas (uma por fixture) → GREEN3testes/0. Probe independente
com os padrões reais do Git incluiu3/3. Python completo166testes/0skips,
120,447s/cobertura62%; Ruff/diff aprovados. Runtime, fixtures, assertivas,
nomes dos quatro checks, pool4 e guard900s não mudaram. Nova CI pendente.

## Integração após PR52 — REQ-JEWEL-46 / JI-7 (13/11)

PR52 confirmado merged em20:34:37UTC, main e2e6da50. JEWEL rebaseado sobre
essa main; conflitos de sala/loading, catálogos/export, SDD e inventários
resolvidos preservando as duas entregas. Os quatro checks do head anterior
97b2193e passaram (incluindo macOS/Windows e pacotes), mas não validam o rebase.

Gate atual: matriz dos22lados/11mundos1600/1800/2000 em modoJEWEL e regressão
SOLO; seleção/lado/Random e contexto único congelado no loading, spawn,
clima por lado, música por família, máscara privada, CPU e previsão real.
Expandir as oito partidasJEWEL anteriores com22naturais (uma por lado),
preservar29regressões+44partidas de mapas e todos os guards/pool4. Nova
suite de modelo/cena e GPU da combinação precedem checks do head rebaseado.

A coordenação liberou a integração após mapas e depois acrescentou um
seguimento pequeno de mapas (seta anterior saindo deRandom e guia). Isso
não interrompe desenvolvimento/QA; somente o MERGE aguarda a última
liberação após esse seguimento. Não duplicar a correção de mapas aqui.

O smoke do pacote deve exercitar também o novo modo: selector/loading e
catálogos exportados, JEWEL em22lados, imunidade sem crédito fictício,
snapshot, blast nativo, placar e latch de resultado. Isso complementa, sem
substituir, os48tiros e66casos de mapas já presentes no smoke do release.


### Resultado da matriz sobre e2e6da50

Modelo4504/0 e cena1395/0; agregado local1059,496s/398parses/137suítes/
91.779checks/177Python semskips/103partidas/62%, exit0. GPU22lados FullHD,
682assertivas/0 e660bufferspausa idênticos,22retomadas;88buffers salvos
verificados independentemente emPillow. Smoke específico do pacote acrescentado
após início desse agregado passou203/0; não confundir essa faixa com o agregado.

PR53/main f1bfba90 confirmado integrado e liberação final de merge recebida.
O último rebase trará só o cicloRandom/guia e sua regressão; validar seleção
comJEWEL/SOLO e preservar o agregado já verde, sem repetir faixas não afetadas.
Checks remotos do head completo continuam obrigatórios antes do merge.
