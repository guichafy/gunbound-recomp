# Aduka — auditoria da família (ADR-124)

Estado histórico. ADR-125/`ADUKA_COMBAT_REA.md` substitui os adapters de dano,
contato e tornado aqui declarados; T2passa a3porpedido ealpha para visibilidade.

27/10/2026, REQ-02/04/05/07/08/09/19/20/44/45. Pedido: revisar mobile,
T1/T2/SS e assets por engenharia reversa, com atenção ao T2. Preservar
orientação ADR-122 e centralização ADR-123, aceitas pelo usuário.

## Fonte e matriz de evidência

PE `.tools/mobile-animation-port/GunBound.gme`, SHA256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`,
image base0x400000, x86 LE32. graphics.xfs SHA256
`a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`.
Ghidra12.2/JDK26 direto, runner da skill, banco
`builds/ghidra-aduka-fix`, extratos novos em `.tools/aduka-audit/`.

| Contrato | Fonte/consumidor | Estado/decisão |
|---|---|---|
| T1: tick1; T2: dois nos2/6; SS: três nos2/6/10 | MainAction0x466fd0, ASM + tank16.epa | Comprovado; cronologia existente preservada/revalidada |
| T2/SS: guia sem blast próprio; impacto solicita Thor uma vez | tick4aafd0; SS467a70→4685b0;4398e0 | Comprovado; preservar passo real/previsão/autoria |
| Thor fora do clima/tabelas1–6 | 4398e0,541f10, getters4ac260/330/400/4d0 | Comprovado na ADR-094; revalidar integração |
| Balas: corpo alpha, brilho SRCALPHA/ONE; T2 só bullet16sl | Spawn42bbb0, vtables5565ac/555d74/555e88; Render4c3020, passada4c4f78 | Comprovado; renderer específico, sem duplicar alpha do glow |
| T2/SS: espelho vertical à esquerda | slot3 488880, condição90<ângulo<270 | Comprovado; corrigir só Aduka; sem rastro (ADR-120) |
| Thor: normal/active/fire, EPA20Hz, escala nativa, corpo+thorl | Spawn439d90, vtable5565cc, render4abf60→4c4aca..4c4d1c | Comprovado; substituir .6/15Hz do C# quando há Aduka |
| Rotação Thor | 4398e0 grava heading+44;4c4bc6→4ecc70 | Comprovado:−heading, sem PI extra |
| Oscilação/estado Thor |4abda0/4abf60: fase22,−1×5/0×6/+1×5/0×6, sem bob emfire | Comprovado; relógio/copias no modelo |
| Origem50px e feixe | ADR-094,4398e0/4aacd0/4ecc70 | Comprovado nos contratos delimitados; preservar LUT/truncamentos |
| Som T2/SS |4398e0→432320 empilha owner/1/1; tabelaMageT2=22blast; guiaSS23blast ausente | Comprovado: efeitoThor usa22blast em ambos; guiaSS não inventa outro som |
| Posição inicial Thor | spawn4bc117 recebe coordenadas externas | Adaptação determinística do treino, sem RNG extra; preparar antes do impacto |
| Dano final/colisão/muzzle/calendário comuns | Damage/Combat/Match/Weather atuais | Adaptadores do porte; regredir e declarar limites, sem paridade integral |

01-dispatch/03-draw-thor/06-scene-render completos. 02-spawn-flight parcial
por488880 ausente, recuperada via vtable em03. 04-thor-runtime/05-thor-render
parciais nos seletores ausentes;4abf60 recuperada por vtable em05. Seu trecho
a partir de4ac050 já está separado no banco antigo: conferir ASM dos dois
trechos. Não tratar pseudocódigo/custom ABI como fonte C original.

## Plano de implementação e validação

- [x] Fixar regressões de camadas, sentido Thor, presença/relógio/pausa e som;
  esperados de ASM/EPA/XFS antes das correções.
- [x] Auditar pixels/hotspots/EPA Aduka e extrair corpo/luz Thor com catálogo
  próprio, preservando os arquivos anteriores.
- [x] `aduka_sprite.gd`: camadas/heading/espelho corretos, sem rastro.
- [x] Helper de camada aditiva: limpeza por view/frame e liberação de RIDs.
  Revisão independente: também limpar na troca da UI; HUD deve ficar acima
  dos CanvasItems filhos. GPU reproduziu ambos os defeitos antes da correção.
- [x] Estado Thor nativo no retrato copiado; preparar para Aduka, controlar
  normal/active/fire no passo20Hz compartilhado por execução/previsão.
- [x] Renderer Thor original (sem escala/PI extra, bob discreto) e som nativo.
- [x] Exercitar Dual/Dual+/Thunder/Teleport, clima, dois sentidos, cópias e
  múltiplos guias sem duplicação; harness completo e29partidas.
- [x] Auditoria Python PE/assets, GPU temporal FullHD/pausa e logs; registrar
  aceite/limites. Captura Godot não é execução do cliente Windows original.

Sem arte gerada, rede, perfil real, nova versão, exportação ou publicação.

## Implementação e resultados observados

`MobileLooks` ativa `AdukaSprite` (subclasse de ClassicSprite, montagem
aprovada intacta). T1 usa corpo alpha + brilho aditivo; T2 usa só sua folha
de brilho, uma vez; SS usa corpo + brilho, com UV vertical Facing à esquerda
em T2/SS. Nenhum rastro foi adicionado. As fontes de tiros/casco/impacto
existentes já eram as originais e não precisaram ser substituídas.

`import_aduka_native.py` extrai ThorBody/ThorLight e EPA em catálogo próprio,
com hotspots nativos. `AdukaEffect` prepara Thor antes do primeiro impacto
quando há Aduka no elenco, mantendo a posição determinística do treino.
Normal/active/fire, ease inteiro e relógios vivem em `weather.thor` e são
copiados profundamente pelo snapshot. Thor aponta pelo ângulo nativo, sem
PI extra, e usa escala1 e EPA20Hz. O feixe conserva tabelas/LUT/UV da ADR-094.
O efeito de Thor em T2 e SS usa22blast PCM; o guia SS não inventa23blast.
Também o Thor climático de uma partida com Aduka passa pelo mesmo estado,
nível e tabela, evitando que um T1 devolva o progresso à tabela C#.

Revisão independente encontrou dois P2 de composição, ambos reproduzidos e
corrigidos: HUD agora em Node2D z1, mundo/efeitos emz0 e controles emz2;
`replace_root` limpa feixe e glows ao ir para sala/lobby/loja. GPU antes deu
`hud_above_beam=false/no_glow_residue=false`; depois ambos true. Revisão
final aprovada, sem P1/P2 restante. Não houve nova revisão do dano global.

Validação desta entrega (Godot4.7.2):

- Regressão inicial:17checks/8falhas reproduziram os caminhos ausentes;
  suíte final `test_aduka_native`:39/0 (inclui EPA/Facing/som/30×60Hz).
- `test_aduka_assets.py`:5/5; pixels de **495quadros** comparados comXFS
  (323casco +60balas/impacto +112Thor/luz), pivôs/EPA/ASM e PCM22blast.
  sound.xfs SHA256
  `081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023`.
- Harness completo: **13241checks Godot,42testes Python,29partidas**, sem
  falhas, parse aprovado/exit0 (`.tools/aduka-audit/full-harness.log`).
- Após corrigir os P2 visuais:8suítes1004/0; `check.sh --quick` final
  **13253checks,42Python,80suítes,parse aprovado,exit0**. Os12checks novos
  conferem também igualdade e isolamento de todo Thor real/previsão.
  Partidas não repetidas após o ajuste exclusivamente de HUD/limpeza.
- GPU M4Pro/gl_compatibility:300quadros1920×1080, relógio60Hz, seis contatos
  T1/T2/SS×dois sentidos, pausa30idêntica e retomada; T2 acionou2Thor, SS3,
  T1 teve um impacto próprio, em ambos sentidos. Captura/escrita levou14,27s;
  isso não é medição de performance de jogo a60FPS. Vídeo recompõe o relógio.
- Sala real e Miramo/HUD: T2 sem alterar muzzle/velocidade da fixture; primeiro
  Thor no quadro74. HUD sobre feixe e limpeza na saída comprovados por pixels.
  Galeria, vídeo, JSON e extratos essenciais em `docs/aduka-audit`.
- Logs GPU limpos; import só registrou as ressalvas ambientais conhecidas de
  CA/editor_settings do macOS. Não são erros de script ou de recursos.

## Limites e aceite

Dano final ainda usa a fórmula C# vigente de Damage/Combat (ADR-066); a caixa,
varredura DDA do terreno2px e muzzle comuns continuam adaptações. No cliente,
432320 monta o objeto de blast e suas tabelas, mas isso não comprova sozinho
a fórmula final do dano. A varredura de obstáculos de Thor conserva o ramo
adaptado declarado na ADR-094; ambos callers nativos forçam a mesma porta,
sem prova de que SS deva atravessar paredes. Não inventar essa distinção.
Tabelas, autoria, zero do guia, dano separado de Thor, crateras e execução=
previsão foram verificados; não se anuncia paridade integral de combate.

Cliente Windows original não executado. PCM conferido byte a byte e streams
encaminhados pelo runtime; escuta e mouse manual não realizados. Aceite
visual do usuário nesta revisão pendente. Sem app/PCK/ZIP novo, versão,
commit ou push. Os resultados da ADR-094/122/123 permanecem históricos.
