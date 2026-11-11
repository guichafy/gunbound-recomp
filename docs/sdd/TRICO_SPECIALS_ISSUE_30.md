# Trico T2/SS — issue #30 / ADR-163

Base: origin/main a9a89fd92476fe5122bd049025be2a34923134a2.
Escopo autorizado: trajetória/contato dos três componentes T2 e máquina SS;
Godot 4.7.2, GDScript, treino offline 1×1. Sem nova arte ou multiplayer.
REQ-04/05/07/08/19/44/45. Assinaturas públicas preservadas.

## Identidade e evidência

Ghidra12.2/JDK26.0.1 executado nesta sessão em banco exclusivo
/private/tmp/trico-issue30-ghidra. PE SHA256
4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde,
x86 LE32/base400000. DAT b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf;
graphics.xfs a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08.
Somente Thor's Hammer. VAs são endereços virtuais, não offsets de arquivo.
Oráculo reproduzível: tests/tools/trico_oracle/generate.py (Unicorn2.1.4),
fixture tests/fixtures/trico_native.json; executa instruções reais do PE.

| Contrato | Fonte e ordem/unidade | Classificação |
|---|---|---|
| Emissão T2 | MainAction4b31f0, evento6/quadro6: idx0/1/2 (Dual8/9/10), mesmo theta/P, divisor3 | comprovada |
| Construção | 42bbb0: idx2/10 comum; especiais phase=theta+180*(idx%8), step=-8 se theta<91, senão+8; 4a2a70 radius2 | comprovada |
| Passo T2 | Animate4a4610 chama tick4a2ce0 ANTES de radius+2/teto30 e phase=(phase+step)%360 (resto assinado) | comprovada |
| Centro/publicação | células3fa8/41cc guardam centro24.8; centro+=v; X+=trunc((sin(p)+sin(p+90))*radius*256), Y+=trunc((sin(p+90)-sin(p))*radius*256); LUT float32 VA54c240 | comprovada |
| Contato T2 | temporariamente v=publicado-anterior publicado; heading=(p+90)%360; 455cc0(stride8); restaura v balística; aceleração depois do contato livre | comprovada |
| Limites T2 | 4a42fd..4a4387 testa f54/1178 publicados, não o centro privado; remove sem blast | comprovada |
| SS contato | 4accf0/5565f8: count=-1 em voo; tick4ad3b0 chama contato455cc0 e Explode4ad230; count=0, seed=uint32(x+y); ssflame4, sem blast inicial | comprovada |
| SS ação | Animate4ae0f0→4acd10: incrementa count; 2/4/6/8/10/12/14/16 emitem431d90; count21 remove sem blast | comprovada |
| SS posição | RNG próprio uint32: q=(seed*214013+92312341)&0xffffffff; seed+=(((q+1)*97)&0xffffffff)%1000001, duas vezes por ação; offsets=q%width-trunc(width/2), primeiraX/segundaY | comprovada |
| SS largura | 41da80 carrega3198 da linha3/[79]=50 (T2[66]=100); fixture executa inicializador com DAT direto | comprovada |
| CPU | mesmo passo de Match e Dictionary privados, snapshot profundo | porte |
| Dano/cratera/itens/clima particular | fórmulas de blast/Dig e geometria/hotspot existentes do treino; anexos consumidos uma vez no contato SS, filhos sem replicar anexos | adaptação declarada |

Não anunciar porte integral do Trico: bônus por componente, dano/cratera,
clima específico e muzzle não são fechados por esta entrega. O calendário
climático global permanece ativo. Não ampliar AdukaWeather.active para obter
contato; invocar o produtor de contato independentemente dessa máscara.

## Plano de implementação

Execução inline já autorizada, usando writing-plans/executing-plans/TDD;
revisão independente final. Localização SDD segue as instruções do projeto.

### 1. T2 (vermelho/verde próprio)

- [x] tests/test_trico_t2.gd: comparar cada tick da fixture (centro, publicado,
  velocidade, fase, radius), idx2 comum, lados/vento, 90/91 e ciclos completos.
- [x] Observar falha no código antigo e registrar log.
- [x] Criar scripts/trico_flight.gd: active(shell), prepare(shell,entry,theta),
  hit_point(shell,carrier), finish_tick(shell). Campos trico_component,
  trico_phase, trico_step, trico_radius, trico_heading privados por shell.
- [x] classic_mobiles.gd usa flight=trico_t2 e componentes0/1/2;
  match.gd prepara theta nativo quantizado e seleciona contato independente.
- [x] Confirmar fixture verde; Raon/Turtle intactos.

### 2. SS (vermelho/verde próprio)

- [x] tests/test_trico_ss.gd: impacto sem blast, todas as ações/seed até21,
  offsets negativos e limites, snapshots, pausa/deltas, Dual/Dual+, Gold/anexos.
- [x] Observar falha da cadeia antiga.
- [x] TricoFlight.begin_ss(shell,point), tick_ss(shell)->Dictionary com
  posição opcional/finished; SS estacionário e invisível após contato,
  efeito ssflame4 separado; oito blast com autoria preservada, anexos uma vez.
- [x] Remover só catálogo Trico de orbit/chain; preservar consumidores legados.

### 3. Verificação e integração

- [x] Dirigidas da issue; harness integral com29partidas e Python, Ruff/diff.
- [x] Captura GPU temporal ID5, vento/inclinação/lados/transições/pausa.
- [x] Revisão independente nos cinco focos obrigatórios; corrigir e repetir.
- [x] TASKS/HANDOFF/MOBILES: resultados efetivos/limites.
- [ ] Commit/push/PR, quatro gates, Rebase and merge sem bypass; CI main/release.

Focos: contato não ativa física climática; oito ações não duplicam anexos;
snapshot não altera mundo vivo; N−1/N/N+1 e fracionamento/pausa; expectativas
antigas só mudam com prova. Baseline dirigida 1453checks/9suítes/0falhas.
Tentativa sandbox inicial abortou por API macOS de certificados no import;
repetição fora do sandbox aprovada. Nenhuma regra foi alterada até esse ponto.

## Resultados observados — 11/11/2026

Ghidra12consultas em banco exclusivo: run/manifest.ok e source_unchanged=true;
sem timeout. ASM essencial e identidade em docs/trico-native/contract.asm e
ghidra.json. Oráculo:14históriasT2 (inclui idx2 e bordas),12contatos (seis
negativos),3históriasSS,2inicializações DAT. Regeneração idêntica SHA256
f6f8551a15872c49c7ff4990eaecb0d54dff82b8c52300521cb42100eec779c7;
PE divergente rejeitado antes do emulador. Não inclui o binário no Git.

TDD: T2 antigo2642checks/1757falhas→2642/0; SS antigo validado146/78→148/0.
Ampliação e revisão:AL/EAX do produtor455cc0 corrigido com seis casos sem
contato (RED3376/6). Limites publicadosT2 geraram RED4043/3→GREEN4043/0.
SS final394/0 cobre RNG/ações, snapshot, fracionamento/pausa, Dual/Dual+,
Teleport, Thunder único e Gold igual ao dano efetivo. Native terrain não
ativa AdukaWeather.active; inventário climático permaneceu intacto.

Harness integral final .tools/trico-full-exact.log, exit0/387,267s:
364parses,116suítesGodot/59.385checks,160Python (sem falhas/skips),29partidas.
CoberturaPython62%; Ruff e git diff --check aprovados. O runner de29casos
com orçamento900s por processo foi preservado. Confirmações anteriores
limpas385,567s/58.701checks e386,272s/59.385 não substituem a rodada final.
Logs detalhados e report.json em .tools/check-logs; cópia preservada em
.tools/trico-full-exact-report.json.

GPU final .tools/trico-gpu3.log:421quadros1920×1080/60Hz manual (sem promessa
de desempenho real), T2 normal/vento+rampa/SS em ambos os sentidos.
3/3/8impactos por lado, seis salvos terminados. Pausa100..129 durante SS
ativo e T2 ainda presente:30PNGs integralmente idênticos em RGBA, conferidos
por Pillow e revisor; retomada concluída. Manifest/stills/MP4 em
docs/trico-native. Primeira montagemGPU tinha transform interno de sprite
fora da escala do painel e foi substituída pela captura3 com Node2D próprio.

Revisão independente sem achados pendentes após corrigir ABI do oráculo;
revisor reexecutou históriasPE,36sondas de contato fracionário, raster em
0/±90/135graus e bordas. Conferiu snapshots/anexos/Gold/relógios e smoke.
O raster confirma rotação−radians(heading), sem interpolação na colisão.

PacoteQA local via scripts/ci/package.py→build_macos.py, universal,
assinatura deep/strict válida, smoke no ZIP extraído48tiros+UI+Ice+Trico.
Smoke fonte249/0; pacote confere SS2..16/terminal21 no Miramo real.
Versão0.20.5 do checkout, manifest aponta basea9a89fd9 pois o export precedeu
o commit; fontes efetivas desta entrega, sem override TLS nem perfil real.
ZIP SHA256 e334f97d8717b96c886df77ef9ff71e576ece04aeba10726adf4dd9042b15b61.
Nenhum artefato publicado manualmente; versão/release remotas pelo workflow.
Preparação inicial sem template macOS falhou; foi copiado só .tools/macos.zip
existente (SHA25688df5e2e6fee99088699be66e6d42e4da4fb0c5619d054297d755a49558a4792),
sem modificar instalação global. Manifesto do executável confirma4.7.2.

Limites: clienteWindows completo, escuta/input e aceite visual humano não
executados. O porte fecha trajetória/contatoT2 e máquinaSS desta issue;
dano/cratera/itens/clima particular e geometria muzzle/hotspot continuam
pontes declaradas. Não há alegação de Trico integralmente nativo.
Operação remota autorizada: PR/quatro gates/rebase merge e acompanhamento
CI/main/release; SHA/PR/issue/resultados remotos no retorno à orquestração.

## Emenda de QA do PR37 — REQ-52 (11/11/2026)

Cabeça29e18b44: macOS aprovou todas as assertivas (mapa48/0, timing49/0,
Trico4043+394/0 e smoke249/0), mas o processo reportou1/3recursos em uso no
encerramento de mapa/timing. Logs em .tools/pr37-macos/check-logs e run
43017556712/job130512726833. Doze repetições locais verbosas não reproduziram
o vazamento; não confundir isso com prova de correção do host remoto.

Somente fixtures foram ajustadas: tests/support/suite.gd capturaWeakRefs de
playbacks antes de mute/stop/free e aguarda sua liberação observada, com o
mesmo limite5s de test_client_audio. Cada cena ganhou uma assertiva de
liberação; nenhuma assertiva anterior, regra de áudio/jogo, timeout900s do
runner ou inventário de29partidas foi relaxado. A causa assíncrona é
consistente com o precedente, mas a CI anterior não identificou os tipos
dos recursos vazados; confirmação cabe à nova execução hospedada.

Revisão independente sem achados. Dirigidas finais de seis suítes:
4815checks/0 (mapa49, timing50, áudio224, música55, Trico4043/394).
O harness59385 acima é anterior a essa emenda somente de testes; os dois
checks adicionais e os resultados remotos serão registrados no PR/retorno.
