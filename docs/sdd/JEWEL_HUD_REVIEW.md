# JEWEL — correção do placar e revisão local (14/11/2026)

## Pedido, base e reprodução

REQ-JEWEL-46/JI-1..7, REQ-27/28/30/48/50. Correções locais autorizadas;
sem push/PR/merge/publicação nem atualização de aplicativo exportado.
Base integrada `49fdeaa9`, árvore idêntica ao antigo head `ed01d267`.
Checkout principal em `/Users/guichafy/Workspaces/DemoGame` estava em43ba5162,
com AGENTS.local.md não rastreado; não é a versão mais recente. Foi apenas lido.
Worktree f19e isolada em `codex/jewel-hud-review` sobre origin/main.

Imagem fornecida tem dois clientes originais, não comparação cliente/porte.
Reprodução GPU do porte antes da mudança em `.tools/jewel-hud-review/baseline`:
painel135×49 colocado no header800×40 e reduzindo glifos por8/9; invade o
mundo, remove contador superior e deixa o espaço de placar inferior vazio.
Causa: adaptação explícita antiga de draw_mode_panel, agora substituída.

## Contrato de apresentação / decisão ADR-JEWEL-HUD-REVIEW

PE SHA4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde;
graphics.xfs SHAa52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08.
Fontes existentes Ghidra C+ASM em docs/jewel-implementation/presentation:
406990 ASM406b20..43: play_back179 se time local0,180 caso contrário,
em665,551,135×49; header modo3 usa178 em321,0 (407b29..94).
408180 ASM4085de/4088c2: dígitos numfont189..198 com passo20, dois campos
em692/712 e749/769,y569. `%3d` emPE551ecc omite centena no laço iniciado
em1; glyph199 (7×25) em684/742 (offset−8/−7 dos primeiros dígitos) representa a centena quando score>=alvo100.
Logo0..99 usam dígitos nativos e100..124 usam marcador1+dois dígitos,
sem escala interna. Limite superior conservador do limiar100 mais bônus25:124; na grade de
pontos em múltiplos de5, o terminal natural máximo é120.99/124 são fixtures
de fronteira da apresentação, não partidas naturais nem regra nova.

Aplicar somente a conversão vertical já aprovada do footer: y nativo−100,
escala global1,6. Painel lógico1064,721.6 até1280,800; glifos y750.4.
Time local à esquerda (AB ou BA); modelo offline mantém A=jogador/B=CPU.
Header continua com contadorGold existente, separado do objetivoJEWEL.
Bloquear input na área inteira do painel, inclusive8px acima do footer.
Pequeno recuo vertical dos extras mouse/toque JEWEL evita contato com painel;
SOLO e sua região de input conservam o contrato anterior. Nenhum ativo novo
é gerado por IA; importar somente frame180, preservando originais/imports.

## Plano de execução (writing-plans, execução local direta)

- [x] Regressão RED: amostra geométrica usada pelo desenho real, âncora/escala/order,
  scores0/5/10/75/99/100/124, header independente; Python compara frame180 aoXFS.
- [x] Importar variante180 e corrigir Layout/HudArt; regressões GREEN.
- [x] Cena real: modos, carga/Drag/pan/retorno bloqueados no placar,
  armas/itens/Options/resultado preservados; SOLO sem painel extra.
- [x] Revisar MatchMode/JewelRules/JewelCombat/Aux, snapshots/CPU e cenas
  contra contratos existentes; corrigir apenas defeitos reproduzidos.
- [x] GPU com pontuações/contextos, dois tamanhos1280×800/1920×1080,
  comparação de pixels, pausa/retomada, sobreposição/corte e resultado.
- [x] Harness completo, logs sem erros; atualizar TASKS/HANDOFF com resultados
  e limites. Não alegar input físico/escuta/clienteWindows integral.

## Revisão e resultados

Concluída localmente. Adaptações preexistentes (CPU offline, CRT privado, produtores/
itens não nativos e retorno via resolvedor de apoio) continuam delimitadas
em JEWEL_IMPLEMENTATION.md; esta correção não anuncia paridade integral.

RED: cena/HUD9checks/4falhas (geometria ausente,2cliques atravessando,retorno indevido); Python13testes/1falha por PNG180 ausente. GREEN HUD304/0; importador13testes/0. Contagens esperadas aumentam61→62 atlas pela única nova variante180; não houve exclusão de recursos ou checks.


### Revisão dos caminhos do modo

| Caminho | Código/evidência e validação | Resultado desta revisão |
|---|---|---|
| Pontos/vitória | JewelRules.remove, MatchMode.check_end; oráculosPE e rules/match | +25/+10/+5/−5,piso0,alvo100 e latch preservados |
| Geração/queda/autoria | JewelRules initial/next_turn/step; contrato lifecycle e355ticksPE | 8slots/6tentativas/reposição e crédito mantidos |
| Piloto/retorno | MatchMode fall/choose_respawn/begin_turn, Match.can_use_item/fire/move | espera bloqueia ações; retorno+2transições e imunidade preservados |
| Itens/clima/auxiliares | passo comum Match/JewelCombat/JewelAux; integration263/aux24 | 48tiros, itens e auxiliares reais=previstos; sem mudança mecânica |
| CPU/snapshot | CpuPlanner e FlightSnapshot, matriz4504 | rajada completa/cópias privadas de2máscaras, clima, RNG e objetivos |
| Navegação/resultado | jewel_scene21/maps_scene1395, HUD/cena304 | loading congela modo/mapa; pausa/resultado/XP idempotentes |

Nenhum defeito adicional comprovado nesses caminhos; não equivale a auditoria
exaustiva dos48produtores nativos. Pontes/adaptações anteriores continuam
explícitas. Revisão independente do delta semP1/P2; somente leitura de código,
ASM e imagens, sem outra execução física do cliente.

GPU792checks/0 em24cenários, dois tamanhos1280×800/1920×1080 (pilarboxing
FullHD do canvas8:5),720bufferspausa idênticos e24retomadas. Pontos0/5/10/
75/99/100/124, AB/BA, turnoCPU, carga/MOVE expandido, espera e resultado.
Galeria em docs/jewel-hud-review/score-gallery.png e capturas representativas
em gpu/. ComparaçãoPillow do header em24imagens confirmou invariância por
pontuação/time dentro de cada resolução; hashes em header-verification.json.
Áudio mudo, eventos sintéticos nos testes; sem input físico/escuta ou cliente
Windows inteiro. Agregado final aprovado, detalhado abaixo.

Checagem Ruff ampliada fora dos gates: EXE001/I001 no importador e RUF059 no teste já existem emHEAD (confirmados por git show|ruff). Não foram alterados nem ocultados. O lint de correção da CI (`--select E9,F63,F7,F82 scripts tests`) passou.

Na captura de resultado, a janela/OK se sobrepõe intencionalmente ao HUD de fundo, conforme o fluxo existente; não foi alterada a janela nem o seu z-order.

### Extensão do pedido: projeto salvo local

Pedido de seguimento autoriza integrar localmente o delta em /Users/guichafy/Workspaces/DemoGame após as verificações. Nova inspeção: main43ba5162 é ancestral de origin/main49fdeaa9, sem mudanças rastreadas; apenas AGENTS.local.md não rastreado. Plano: fast-forward local até a base já publicada, git apply --check do patch validado, aplicar somente os arquivos desta correção, conferir hashes e suíte HUD/cena isolada no destino. Preservar o arquivo local e não executar push/PR/merge remoto/release/export. Se o checkout mudar durante a espera, reavaliar antes de aplicar.


### Resultado final observado

Agregado do código final1076,715s:402parses,139suítesGodot,92.293checks,
177Python semskips,103partidas, coberturaPython62% da automação, exit0/FAILED[].
Todos os logs de resultados inspecionados: nenhum ERROR/SCRIPT ERROR/leak.
Depois do início do agregado, apenas a preparação explícita do diretório do
perfil isolado do novo teste foi acrescentada e repetida304/0; o destino
das capturas passou para .tools. Nenhum código de jogo mudou nessa faixa.
`test_jewel_package` é teste do helper de smoke em fonte; não comprova um
novo pacote exportado. Não houve exportação/app atualizado.

Projeto salvo /Users/guichafy/Workspaces/DemoGame avançado com ff-only de
43ba5162 para49fdeaa9, depois git apply --check e aplicação do delta local.
14arquivos de runtime/testes/recursos idênticos porSHA256 à worktree validada;
AGENTS.local.md alheio preservado. Importação no destino exit0 sem erros;
sete suítes981/0 (HUD304,cena21,layout65,assets466,resultado37,loading33,música55).
A documentação e as capturas desta revisão também acompanham o projeto salvo.
Alterações ficam locais/não commitadas; nenhum push/PR/merge remoto/release.

Metadados reproduzíveis em docs/jewel-hud-review/validation.json. Logs completos
locais em .tools/jewel-hud-review; galeria/capturas inspecionadas já citadas.
Revisão independente semP1/P2. Aceite humano, escuta/input físicos e execução
inteira do cliente original continuam limites, não foram simulados como aprovação.


## Seguimento autorizado — envio e integração remota (14/11/2026)

Pedido posterior do usuário autoriza enviar a branch, abrir o PR e fazer o
merge após os quatro checks obrigatórios, sem bypass; acompanhar mainCI e a
publicação automática existente. Isso substitui somente o limite local da
entrega acima. Validação local permanece a registrada, sem mudanças novas
no runtime e sem exportação manual. Resultado remoto será registrado à parte.
