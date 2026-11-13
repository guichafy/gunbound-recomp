# Mapas clássicos — implementação autorizada13/11/2026

REQ-MAPS-45 / ADR-MAPS-45. Continuação executável de CLASSIC_MAPS_PLAN.md;
substitui somente a restrição de pesquisa/planejamento anterior. DefaultMiramoA,
16mobiles,perfil/equipamentos,treino1×1 e ausência de rede preservados.

## Contrato pré-código e gate1

PE4af6283d…fcde, XFSa52f9f46…0f08, DAT103c2b48…cfca, banco próprio
/tmp/gunbound-maps-implementation-bb36. Consultasg02/g03 ok=true.
4d4004..4038 normaliza o byte recebido %11 para jogo+475c4. 43f0e0,
cases0xc/0xe (ASM43f108..43f23b), usa apenas esse índice no prefixo de
stage.dat para IMG/LND/partícula.41f200 usa família+11×lado para clima;
4d4728..4748 monta load_stage com lado separado. Conclusão: os22lados
compartilham11mundos nativos. Os oito prefixosB sem arquivo não exigem
arquivos inventados; hokb/brickb/fackyb existentes não são usados nesse
carregador do mundo. Não portar sua geometria como regra ativa sem consumidor.
Esse resultado substitui a hipótese B1/B2 do plano, não é alias inferido por nome.

REQ-MAPS-45.1: catálogo22lados, mundo/família/índice do preset separados,
MiramoA padrão; seleção em memória e contexto resolvido uma vez.
REQ-MAPS-45.2: IMG/LND comprovados pixel a pixel, escala1:1, máscaras privadas,
crateras nas duas resoluções; offsets/pivôs preservados e partículas sem corte.
REQ-MAPS-45.3: setas da sala/lado/prévia/loading/batalha coerentes. Falha de
recurso bloqueia Start. Random offline uniforme só entre escolhas válidas.
REQ-MAPS-45.4: clima/pesos/ranges por lado do DAT, música pela família,
spawns novos por faixas de jglim como adaptação1×1; MiramoA não muda oRNG.
REQ-MAPS-45.5: CPU/previsão compartilham máscaras/cópias e estado com execução;
sem IO de recurso no worker. Câmera/parallax atuais preservados como adaptação.
REQ-MAPS-45.6: testes por lado,mapas1600/1800/2000,capturasGPU/pausa,partidas,
PCK/CI e limites observados registrados; sem alegação de cliente inteiro executado.

Loading: arquivos load_stageB ausentes exigem fallback explícito documentado
para prévia/máscaraA da mesma família, como apresentação adaptada do porte;
o contexto continua nomeando o ladoB real e não muda o terreno selecionado.
Cave diretamente selecionável é extensão offline; Random tem probabilidade
uniforme declarada, sem importar a chance do emulador como regra do cliente.

## Gates de render e adaptações declaradas

G02/G03/G05/G06/G07/G08 têm `ok=true`; artefatos em
[docs/classic-maps](../classic-maps/README.md). O caller43f122 fornece o prefixo
opcional551cb1 vazio;4e3f75 usa esse argumento para `%s%d.img`. Logo os54IMG/EPA
numerados são catalogados, mas `scenery_enabled=false` no carregamento normal.
Não ativar decoração por coincidência de nome. EPA/pivôs ficam preservados.

Fundo e préviaRGB565 retangulares são opacos, inclusive pixels pretos
(4eb8e0→4ebaf0, blit integral). O importador corrige alpha apenas nesses
consumidores; a máscara de scan da prévia continua distinta. Miramo mantém
seus trêsPNG e catálogo originais byte a byte; a nova préviaRGBA coincide com
a prévia aprovada do loading. PNGs novos têm110hashes verificados em teste.
Todos os11foregrounds foram comparados pixel a pixel ao LND. Partículas usam
células dimensionadas pelo alpha útil; MetaMine38/41 não são recortados.

Spawns1×1 por metade, câmera/parallax existentes, acesso direto aCave e Random
uniforme são escolhas offline declaradas. Os oito load_stageB ausentes usam
imagem/máscaraA da família, sem mudar identidade/clima do ladoB. Sem execução
do clienteWindows inteiro, escuta humana ou aceite visual humano nesta rodada.

## Validação observada

Testes de terreno113, spawn112, arte112 e cena306; matriz de combate1056casos
em8472assertivas, incluindo máscaras/HP/posições privadas e igualdade com
execução.44partidas naturais novas, além das29legadas. Rodada completa verde
antes do último ajuste de apresentação; rodada final, revisão, GPU e pacote
serão registrados após verificação. Não usar capturas antigas como prova final.

GPU final:22lados ×4PNG em1920×1080,30hashes de pausa idênticos por lado,
retomada altera imagem e relógio, exit0; evidência gpu-proof.json, sem erros/leaks.

Revisão independente encontrou e corrigiu Y de sete slots dentro do terreno:
a busca sobe apenas pela massa sólida contígua da coluna, preservando a
plataforma. Teste13083/0 verifica todos os candidatos expostos e os casos
AdiumB856/954 e DummyB619/1124 (antes13081/7). CaveA/B agora substituem o
rótuloRANDOM pelo rasterCAVE nativo da prévia; Random conserva o original.
Cena329/0 após RED329/23. Duas observações menores adiadas: seta anterior
emRandom entra emStardustB; passos históricos2/3 do guia ainda citamMiramo.

RecapturaGPU pós-revisão exit0:22lados/88PNG,660quadros de pausa idênticos
por lado e22retomadas distintas, em1920×1080. Substitui a captura anterior.

Harness final:381scripts compilados,125suítes Godot,83.688checks,
171testesPython/0skips,29partidas legadas+44novas=73,544,924s, FAILED[].
Os testes alterados e as partidas dosB afetados executaram após as correções;
MiramoA e os outros mapas conservaram o comportamento já validado. Lint de
correção doCI e50testes de automação passaram; coberturaPythonCI62%.
Logs fonte sem SCRIPT ERROR/ERROR/leaks. Perfis isolados, sem tocar o perfil
real. OverrideCA ignorado usado nos testes fonte foi removido doROOT antes
da exportação, sem alteração de checks/timeouts. Pacote/CI remotos pendentes.

Pacote macOS local exportado de86b2a196, versãofonte0.20.5, Godot4.7.2.
ZIP284.175.773bytes, SHA256
`3a0e74d68ae9c23fbdf465ecfcaacbb1f28b2f749c74ad19aee8b7aaa0a00abe`.
Universalarm64/x86_64, codesign ad-hoc deep/strict aprovado (sem notarização).
Executável extraído doZIP em diretório temporário sem projeto/cache/perfil
real:48tiros legados+66casos dos mapas, PACKAGED COMBAT/MAPS/SMOKE PASS,
exit0, semERROR/SCRIPT ERROR/leaks; guard180s mantido. `override.cfg` ausente
doROOT/PCK; testes/docs/referênciasprivadas excluídos. Manifesto em
[qa-summary.json](../classic-maps/qa-summary.json). Alterações posteriores
restritas a este registro/SDD; release oficial será calculada e publicada peloCI.

## Seguimento de navegação e guia (13/11/2026)

REQ-MAPS-45.3: Random é uma escolha fora da lista de mapas fixos. A seta
anterior entra no último lado disponível; a próxima entra no primeiro.
O ciclo dos mapas fixos inclui todos os lados, com volta entre as pontas.
A transição anterior pulava Meta Mine B porque find(Random) devolve−1 e
somar−1 produzia−2. Corrigir apenas a entrada no ciclo; sem regra nativa
nova alegada. Os passos2/3 do guia devem nomear o mapa/lado selecionado,
com Random resolvido uma vez no START. Validação e integração a registrar.

Validação local proporcional: cena333/0 após RED333/1 e sala172/0,
505checks sem erros de script/leaks. Regressão cobre as duas entradas de
Random e ciclos completos nos dois sentidos, incluindo todos os22lados e
volta às pontas. Sem reexecução local de GPU/partidas completas porque não
houve mudança de render/física. Resolve os dois menores adiados do PR52.
