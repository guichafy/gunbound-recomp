# Clima global Thor’s Hammer — issue #26

Base: origin/main `43ba5162089ce235f2ae3869357ce007ca42a9f0`, conferida por fetch
em 11/11/2026. Execução inline autorizada, nesta worktree isolada; publicação
por PR/rebase e gates existentes. REQ-04/05/07/08/09/19/23/24/25/32/35/44/45.

## Matriz de evidência e contrato

Ghidra 12.2/JDK26.0.1 executado nesta sessão em banco exclusivo
`/private/tmp/gunbound-issue26-ghidra`. PE x86 LE32/base0x400000; hashes de
PE/DAT/XFS e extratos aceitos em `docs/native-weather/evidence.json`.

| Comportamento | Fonte/ordem/unidade | Classificação / porte / verificação |
|---|---|---|
| calendário sem gate de mobile | 41fd50: 7 pesos, 8 células, 31 trocas; LCG32 343fd/5809315, avanço mod1000001 | comprovado; reutilizar MageWeather, fixtures independentes existentes e regressão de roster |
| vento e coluna | 41f200/4217b0/4d0a10: período, três valores da tabela1024 por fronteira, índice&7; largura64..127; vento0..26 | comprovado; mesmo estado copiável, anterior/exato/posterior e volta dos oito slots |
| Miramo | 419d90/stage.dat: registros484, pesos@260, ranges292/356/420 | comprovado; pesos2/1/2/1/2/0/0 e oito ranges por família para todo roster |
| limpeza/fusão | 43c620 antes da fronteira em4cee69; 435800/435ad0/435da0, contato estrito largura/4, primeira fusão max×1,5 | comprovado; preservar implementação/testes existentes |
| Moon | 4cee30 chama43c6a0 em categoria5; ator vivo habilitado, HPmax×3/100 ou8/100, limiteHPmax | comprovado; nenhum requisito de Mage; regen comum antes, escudo separado |
| Eclipse | 43a670, 4b8584, 4ba690: reset global de Dual/Dual+ e bloqueio de item | comprovado; preservar estoque e ausência de trava SS adicional |
| Thor | 4bb730/4bc117/439d90 cria independente do clima; 4cee30: Y+40 até1000 na fronteira, saída preserva posição; 4ccd10→4ac180 recalcula nível | comprovado; inicialização/transição para todos, máscara1px necessária pelo consumidor thor_contact |
| física particular | AdukaWeather.active e caminhos por mobile | fora da generalização; não ampliar a lista ao preparar máscara; contatos/anexos ainda adaptados continuam declarados |
| entradas do treino | seed local, período2, categorias habilitadas; procedural sem stage usa mundo | adaptação explícita preservada; “todos” inclui somente7 categorias |
| apresentação | WeatherArt seleciona colunas nativas por is_native e Thor por thor.native | reutilizar; sequência GPU sem Mage, ambos lados, pausa e retomada |

O nome MageWeather é histórico; renomear a arquitetura não faz parte da mudança.
As categorias Fraqueza/Espelho/Aleatório não são sorteadas no caminho ativo.
A classe Weather e seus testes diretos permanecem como legado/adaptação,
sem afirmar que representam o treino atual. A mudança global não comprova
anexos elétricos/Thor ou física de cada projétil por consequência.

## Plano executável

1. [x] Ler fontes/instruções, issue, preparar entradas verificadas e executar Ghidra.
2. [x] Registrar regressão `test_native_weather_roster` (falha no gate antigo):
   pares com/sem Mage e lados invertidos, Miramo/procedural/original/todos;
   calendário/RNG/ranges/vento/colunas/Thor iguais com mesma entrada offline.
   Conferir fixtures aritméticas independentes e fronteiras de16 turnos;
   Moon3/8%, limite/morto/inativo, Eclipse/Dual, ThorY/nível/persistência.
   Snapshot: mutar cópia e simular tiro sem tocar mundo/geradores vivos.
3. [x] Match.start sempre instancia MageWeather, configura Miramo e Thor;
   MenuScreen.refresh_climate usa pesos globais também com slots Random e
   nomes Moon/Lua e Eclipse, sem condicionar ao roster;
   prepara máscara1px global para Thor sem alterar seleção de contato.
   Preservar assinaturas públicas e implementação do calendário. Atualizar
   fixtures antigas somente onde o contrato agora ativo exige; testes de
   legado injetam Weather explicitamente, identificados como legado.
4. [x] Ampliar capture_weather para transições sem Mage e lados trocados,
   pausa30 quadros, retomada, PNG/manifesto inspecionados. Validar dirigidas,
   harness integral29partidas/Python/parse, lint e diff. Registrar limites.
5. [ ] Revisão independente da branch exata; corrigir achados com regressões.
   Atualizar TASKS/HANDOFF. Commit convencional, push feature, PR; exigir
   quatro checks e rebase merge, acompanhar main/release sem artefato manual.

## Focos de revisão

Máscara não habilita contato; anexos não duplicam Gold/autoria/resultado;
calendário/Thor/RNG/terreno profundamente copiados; fronteiras N−1/N/N+1 e
pause/deltas fracionados; expectativas herdadas não enfraquecidas.

## Ledger

- Bootstrap inicial com Python3.12 sem Pillow interrompido; ambiente virtual
  próprio `.tools/issue26-venv` com dependências fixadas da CI preparado.
- Bootstrap validou todas as entradas da configuração CI; não copiou logs ou
  bancos da worktree original. `--no-legacy-sound` evita escrita em pasta irmã;
  testes usam GUNBOUND_SOUND_XFS para a cópia local verificada.

### Execução e tentativas (11/11)

- Baseline dirigido anterior à mudança: todas as10suítes verdes; logs
  `.tools/issue26-baseline.log`. Primeiro import restrito encontrou erro
  ambiental de serviços macOS; repetição fora do sandbox passou com perfis
  temporários do runner, sem override exportável.
- RED roster:560checks/320falhas (`issue26-red-detail.log`); GREEN final
 2976/0. Ajustes nas fixtures novas: nívelThor1000XP é3 pela tabela nativa
  (não2 do legado), snapshot armado limpa Gold por contrato e a comparação
  de ação já disparada precisa receber o mesmo tracker. Nenhuma regra de
  produção alterada para acomodar essas correções das expectativas.
- Sala: gate adicional em refresh_climate descoberto; RED15checks/8falhas,
  GREEN15/0. Pesos sete categorias mapeados aos oito ícones existentes,
  Moon/Lua e Eclipse identificados também em slots Random. Suítes da sala
  59+172+34checks/0 (`issue26-room-green.log`).
- test_weather_legacy preserva as68assertivas anteriores com injeção explícita
  de Weather; test_weather valida o caminho ativo. O primeiro teste de pausa
  não tinha coluna no seed escolhido; fixture passou a incluir coluna elétrica.
- Ghidra: primeira consulta integral; segunda parcial por entradas indiretas
  ausentes; bytes/prólogo/vtable confirmados, entradas semeadas no banco próprio;
  consulta final com14VAs e ambos manifestos íntegros. PE não mudou. Avisos de
  truststore/reflexão Java explícitos em docs/native-weather/README.md.
- Oráculo aritmético independente confirmou seis seeds; importer reproduziu
  stage.dat sem delta no catálogo. Ruff da CI e oráculo passaram; execução
  opcional de Ruff com todas as regras encontrou dívida histórica nos demais
  scripts (sem alterações fora do escopo); o shebang novo recebeu modo executável.
- Revisão independente de código/evidências/cinco focos e delta da sala: sem
  achados acionáveis. Inspeção das duas imagens Thor confirma satélite/feixe,
  sem confundir alvo fora do enquadramento com validação visual de dano.
- GPU:480quadros1920×1080,60pausas idênticas por comparação RGBA independente;
  complemento60quadros mostra Thor com câmera após evento GrantTurn. Modelos
  avançam1/60s manualmente; não é benchmark de60fps em tempo real. Fonte,
  manifestos, PNGs e vídeos em docs/native-weather; brutos em .tools/issue26-gpu.
- Harness preliminar completo336,401s:350parses,51531checks,29partidas,
 156Python/0falhas/cobertura62%; única suíte Godot vermelha foi a regressão
  da sala executada antes da correção. Logs preservados separadamente em
  `.tools/issue26-preliminary-checks`, não usados como aprovação integral.
- Código estabilizado; harness integral final em `.tools/issue26-full-final.log`
  e `.tools/check-logs`. Aguardar seu resultado antes de commit/push/PR.
  Main remota reconferida ainda43ba5162. Não houve implementação de outra issue,
  alteração da versão ou export/publicação manual.

### Validação final da árvore estabilizada

Harness completo:exit0/318,421s;350parses,111suítesGodot/51531checks,
29partidas,156Python/zero falhas/skips; cobertura de linhas da automação62%.
`test_weather`15/0, `test_native_weather_roster`2976/0,
`test_weather_legacy`68/0; demais suítes dirigidas e cena aprovadas.
Ruff CI/oráculo e diff sem erros. Registro durável em
`docs/native-weather/validation.json`; logs integrais locais nele indicados.
GPU540quadros no total,480transições+60focaisThor;60pausas idênticas.
Revisão independente de regras, evidência, testes, sala e recortesGPU sem
achados acionáveis. Alvo/impacto fora da câmera focal; dano validado no modelo.
ClienteWindows original, escuta/input e aceite humano não executados.
Commit/PR/merge e pacote/release serão acompanhados pelos gates hospedados;
não houve exportação manual nem alteração de versão nesta árvore.
