# Armor T2: segundo impacto — issue #27

Base origin/main bb5486d5b38b7ff08f4b3229e861bda7786e03d5, fetch em
11/11/2026. Worktree nativa8bf2; execução inline e commit/push/PR/rebase merge
autorizados. REQ-04/05/07/08/19/44/45. Não revisar Armor T1/SS.

## Evidência e contrato

Ghidra12.2/JDK26.0.1 executado nesta sessão em banco próprio
/private/tmp/gunbound-issue27-ghidra. PE x86 LE32/base0x400000,
SHA256 4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde.
Entradas do bootstrap pinadas em .github/ci-tools.json; manifests locais em
.tools/armor-t2/evidence-{initial,consumers,fields,effects}.

| Comportamento | Fonte / unidade / ordem | Classificação e decisão |
|---|---|---|
| objeto e fases | vtable555dac+18→4688b0; byte+3f9c zero→um; segundo contato marca+14 para remoção | comprovado em ASM, estado armor_phase por shell; sem segundo objeto |
| movimento | 4688ef..468945 soma velocidade24.8; chama455cc0(8); sem contato segue ao fim | comprovado; mesmo passo20Hz, sem reiniciar age/flight_ticks |
| contato e retorno | 455cc0 recupera endpoint anterior e varre rumo ao novo; 458920/458a00 refinam; 4566bc..456724 escrevem pixel<<8 em+40/+264 e inteiros+f54/+1178 | comprovado; contato específico T2 usa máscara1px e writeback, velocidade preservada |
| primeiro impacto | 4694ba..469d5e: cratera→dano→efeitos, seis reduções, fase1, limpa flag contato; cai no trecho final | comprovado; primeira cratera participa do próximo tick |
| fim do tick | 469dc9 publica inteiros; 46a196 soma+af4/+d18 à velocidade; segundo contato salta46a47c sem aceleração | comprovado; acelerar também após primeiro contato, nunca esperar animação |
| seis valores | +1e54/+2078/+229c potências; +24c0/+26e4/+2908 dimensões por material; 41da80 lê DAT[57..62] no ramoT2; 45db20/4e4970 selecionam material | comprovado; manter seis inteiros no shell; material0 do treino usa primeira potência/dimensão |
| redução | 469801..469cbf chama40a7d0×7, 40a8c0 CDQ/IDIV; 40d9ba inicializa e9ba40=10 | comprovado; truncar para zero, após resolver primeiro impacto, uma única vez |
| dano/cratera | ponte Damage.blast/círculo2px existente e atributos/itens | adaptação preservada; dimensão nativa reduzida chega ao raio da ponte, não alegar porte integral45db20 |
| clima/anexos | interações existentes por shell | adaptação preservada; não ampliar AdukaWeather.active nem ativar física de outros tiros; anexos por contato, Gold somente sobre eventos novos |
| encerramento | limites físicos e MAX_FLIGHT_AGE existentes | guard do treino preservado; sem segundo contato termina em miss |

Unicorn2.1.4 executa4688b0 real, com contato controlado e efeitos registrados,
para gerar tests/fixtures/armor_t2_native.json. Esperados não vêm do GDScript.
Os offsets da aceleração foram conferidos em46a1a9/46a1df. Fixture abrange
sinais/truncamentos, contato1/4 e ausência de segundo contato. Stubs não
comprovam dano, terreno ou cliente inteiro; integração Godot cobre essas pontes.

## Plano executável

1. [x] Ler issue/instruções, preparar entradas verificadas e executar Ghidra.
2. [x] Criar test_armor_t2; confirmar falha do código antigo: mesmo Dictionary
   após cratera, fase e seis campos, writeback/velocidade, remoção no segundo.
3. [x] Criar scripts/armor_flight.gd: active(shell), prepare(shell),
   after_impact(shell)->bool (true só na primeira fase); guardar armor_fields
   e armor_phase em ShellState. prepare no caminho comum de emissão.
4. [x] Match: contato exclusivo do T2, snap físico no contato; explodir antes
   da redução; continuar tick na primeira fase e remover na segunda. Preservar
   assinaturas públicas, itens/owner/volley e demais tiros.
5. [x] Testar sinais, sentidos, terreno/mobile, bordas/miss, Dual/Dual+,
   itens/anexos/Gold, deltas fracionados/pausa e snapshots independentes.
6. [x] Captura ID4: cenário que mantém câmera nos dois impactos e mostra
   primeira cratera; sequência/pausa. Rodar suites dirigidas e harness integral.
7. [ ] Revisão independente dos cinco focos; atualizar TASKS/HANDOFF/MOBILES,
   commit/push/PR, quatro gates, rebase merge; acompanhar main/release.

## Ledger

- Bootstrap: Python3.12 Homebrew não tinha Pillow; usado ambiente compatível
  .tools/ci-speed-py313 do checkout principal (Python3.12.14), somente leitura.
- Baseline dirigido:8suítes/2146checks/0falhas. Import inicial sandbox marcou
  erro ambiental CA; repetição fora do sandbox passou sem override de projeto.
- Ghidra: quatro consultas com run.ok/manifest.ok=true; avisos CA/reflexão e
  DLLsWindows ausentes identificados, sem lacuna dos extratos solicitados.

- Oráculo455cc0 real fechou o sentido:40aca0 subtrai velocidade para recuperar
  a origem. Contato do segmento(200,145)→(200,155) é(200,150), não endpoint155;
  a primeira leitura provisória foi corrigida antes do aceite do contrato.

## Resultados observados — revisão local final

- RED comportamental:16checks/4falhas (remoção no primeiro contato e snapshot
  entre fases indisponível). Erros anteriores do próprio fixture (assinatura
  start/finish) corrigidos antes de aceitar essa reprodução.
- GREEN final: test_armor_t2 179/0; inclui oráculo do PE, duas crateras,
  material/sinais, contatos/saídas nos dois sentidos, N−1/N/N+1, Dual/Dual+,
  Thunder/PowerUp/Bunge/Teleport e Gold idempotente. Real/previsão e mutação
  profunda independentes. Contato por mobile e terreno exercitados.
- Harness integral: exit0/320,647s,112suítesGodot/51714checks,
  156Python/zero skips/falhas,29partidas completas; coberturaPython62%.
  352scripts compilados sem erros. Logs em.tools/check-logs;
  rodada dirigida posterior sobrescreve report.json/import e os dois logs
  de test_armor_t2/test_ci_combat, mas preserva os outros logs da integral.
- Confirmação posterior: test_armor_t2 179/0 + test_ci_combat 225/0, exit0.
  Smoke embarcado agora exige máscara pronta e comprova mesma referência
  T2 fase1, dois contatos e encerramento no Miramo real. Pacotes finais
  serão validados pelos gates macOS/Windows existentes do PR/main.
- QA GPU OpenGL/MetalAppleM4Pro:241quadros1920×1080, passos manuais1/60s.
  T1/SS um impacto; T2 primeiro no tick9 (204,150), segundo no13 (206,178),
  raio28→19,5. Pausa30–59 com shellfase1 ativo, estado idêntico e30RGBA
  idênticos; retoma e remove após segundo contato. Não é benchmarkFPS real.
  Manifest/hash em docs/armor-t2/capture.json; MP4 e11stills preservados.
- Revisão independente sem achados mecânicos; dois P2 de QA (pausa tardia
  e acumulador de interpolação) corrigidos e recapturados, aprovados na
  segunda revisão; incremento do smoke também revisado sem achados.
- Ruff de correçãoPython e diff--check aprovados. Fixtures antigas intactas.

Limites: crateras/dano/atributos/itens e ações elétricas/Thor ainda são pontes
existentes do treino, não porte integral dos consumidores45db20/4e4970.
Materiais1/2 não têm seleção ativa no treino; seis células preservadas e
reduzidas, material0 alimenta a ponte. Sem execução do clienteWindows inteiro,
aceite visual/escuta/input humanos ou exportação/publicação manual adicional.
A integração/release automática é acompanhada no PR e no retorno da sessão.
