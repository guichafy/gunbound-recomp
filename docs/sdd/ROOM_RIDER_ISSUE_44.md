# Piloto B na sala — issue #44

## Contrato e plano (12/11/2026)

REQ-19/20/39/45/47: sala e loading apresentam B com o mesmo conjunto
padrão masculino da CPU em batalha, pelo compositor nativo AvatarArt.
A conserva o equipamento do perfil. Não alterar pivôs, orientação, EPA,
recursos, perfil nem regras; elenco de 16 mobiles e Random preservados.

1. Reproduzir a diferença de contexto e raster antes da correção.
2. Fixar PE e conferir consumidores/camadas em Ghidra próprio, XFS/IMG/EPA.
3. Regressão cobrindo os dois lados, gêneros/conjuntos, roster e loading.
4. Corrigir o contexto do B na origem; comparar GPU em coordenadas idênticas
   com composição explícita do conjunto padrão de batalha.
5. Verificar cenas/avatares e registrar resultados e limites.

## Diagnóstico inicial

`draw_room_figures` entrega `{}` para B. `draw_figure` omite avatar_context
quando não há equipamento. MobileSprite usa então chassis→corpo→cabeça do
fallback legado. Com contexto completo, AvatarArt desenha as peças antes do
chassis. Na batalha `actor_avatars[1] = catalog.defaults(0)`. A diferença está
na chamada da sala/loading, não em uma inversão exclusiva do lado direito.

PE Thor pinado: SHA256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`.
Ghidra 12.2/JDK 26, banco exclusivo `/tmp/gunbound-issue44-ghidra`.
Extratos e logs em `.tools/room-rider`. Endereço 0x42986a está no meio de
instruções de outra rotina; a consulta inicial sem função não comprova
composição. Não foi usado como entrada artificial.

## Evidência nativa e contrato da correção

| Comportamento | Fonte/consumidor Thor | Classificação e uso |
|---|---|---|
| Avatar atrás do chassis | vtable `0x556a30 → 0x4d90c0`; chamadas `0x4d91c9/0x4d92de` antes de `0x4d93f9/0x4d950e`; cada grupo envia seu buffer de triângulos antes do próximo | Comprovado estaticamente para os dois grupos de quatro slots; AvatarTexture precede CharacterTexture |
| Orientação comum | `0x4d91b6/0x4d93e6` leem o mesmo byte +0x4590c; `0x4d92cb/0x4d94fb` leem +0x45910; mesmo helper `0x4eca50` | Comprovado no ASM; não há ordem alternativa para o lado B |
| Registro das peças | `0x4dc820` prepara buffers separados e chama `0x45b730`; `0x45b7d6..0x45b7f0` soma IMG peça +0x28/+0x2c, frame mobile +0x48/+0x4c e hotspot mobile +0x28/+0x2c, mais origem do buffer (64,112) | Comprovado no ASM; não usar nomes/ABI incompletos do C como contrato de parâmetros |
| Geometria Godot | `MobileSprite.draw` preserva `rider_offset`, `origin`, `amount`, `Transform2D`, espelho e frame; contextos completos já passam pelo mesmo cálculo em A e batalha | Derivado: fornecer defaults a B elimina o caminho divergente sem deslocar os pontos |
| Padrão da CPU | `Game.start_match`, `actor_avatars[1] = catalog.defaults(0)` | Escolha existente do treino offline, não alegação de política nativa da CPU |
| Ajustes herdados de registro | Nak `RIDER_ADJUST`, Aduka `rider_adjust`, AvatarArt (-5,-5), escala/âncoras da sala | Preservados; não reavaliados como paridade pixel a pixel do cliente inteiro |

A função `0x4d7db0`, ligada à vtable da sala, prepara Avata/CharacterTexture
antes de `0x4dc820`. `0x4d6810` usa `ready_back.img` e os botões ready,
confirmando a tela. As saídas selecionadas `05/07/08` têm `run.ok`,
`manifest.ok` e `source_unchanged` verdadeiros. Resumos, ASM e C essenciais
estão versionados em `docs/room-rider-native`. Arquivo `03/0x43f4c1` foi
semeado incorretamente no operando de uma referência: **descartado**; não
sustenta conclusão alguma. A consulta `02` foi parcial por função ausente.
A análise não executou o cliente Windows.

## Delta

Somente `draw_room_figures` passa `profile.catalog.defaults(0)` a B.
Não alterar o fallback de MobileSprite: outros consumidores legados seguem
seu contrato. A sala e o loading compartilham a chamada corrigida. O estado
de batalha, perfil, regras, música, equipamentos e originais não mudam.

## Fila de integração autorizada

| Posição | Issue | Escopo | Gate de integração |
|---|---|---|---|
| 1 | #43 | Emblema | Integração própria; estado não presumido nesta tarefa |
| 2 | #45 | Inventário e plano de mapas | Pesquisa/plano; sem runtime |
| 3 | #46 | Pesquisa e plano JEWEL | Pesquisa/plano; sem runtime; confirmar integração antes de liberar #44 |
| 4 | #44 | Piloto B na sala | Esta worktree; aguardar liberação após JEWEL, atualizar/rebase sobre main e repetir verificações afetadas |

Desenvolvimento paralelo em quatro worktrees; merges sequenciais por PR,
checks/proteções sem bypass. Commit/push/PR destas quatro entregas autorizados pela
orientação posterior; o usuário reforçou versionar e enviar ao remoto
autonomamente, sem reconfirmação de rotina. Não iniciar merge/auto-merge antes da liberação.
Publicação manual extra e reexportação não fazem parte desta entrega.

## Validação em andamento

- Regressão RED: 410 checks, 136 falhas de contexto/relógio de B; nenhum erro de script.
- Após a correção: 410 checks, zero falhas de assertiva. A rodada dirigida inicial
  ainda falhou no gate por CA do sandbox e diretórios/recursos de fixture ausentes;
  não é aprovação do harness.
- GPU OpenGL/Metal, Godot 4.7.2, 1920×1080: 24 pares em coordenadas idênticas
  (Mage/Bigfoot/Nak/Armor/Grub/Aduka, masculino padrão/feminino equipado,
  caminho de sala/loading) passaram de 0/24 a 24/24 iguais.
- Comparação independente Pillow anterior/posterior: A e toda a metade esquerda
  idênticos nos 24 casos; diferenças somente na região do piloto B.
- Capturas adicionais exercitam a transição real de Start/loading/batalha.
  Ainda não constituem paridade dinâmica com o cliente original.


## Resultados observados (12/11/2026)

- Harness completo `python scripts/ci/check.py`, Python 3.12 local com Pillow/
  coverage, Godot 4.7.2, pool4/guard900s preservados: 369 parses, 119 suítes
  Godot, 61.500 checks e 29 partidas passaram em 429,293 s. A execução
  agregada saiu 1 **somente pela faixa Python**, iniciada antes de preparar
  `assets/xfs/reference/avatar.xfs`/oito DATs ignorados em checkout novo.
- A preparação oficial `bootstrap.prepare_avatar_references` validou o SHA
  e extraiu os oito DATs. Repetição Python: 160 testes/zero skips/erros,
  70,815 s. A repetição da faixa oficial com cobertura fica registrada abaixo.
- GPU final `--always-on-top --disable-vsync`, 1920×1080, `final-both`:
  24/24 comparações RGBA idênticas ao compositor explícito, mais 12 loading
  reais e 12 batalhas com os dois atores em spawns legais próximos
  (colunas Miramo743/1041), sexos/conjuntos e seis mobiles representativos.
  Stills relevantes e relatório estão em `docs/room-rider-native`.
- Revisão independente sem achados no delta; revisor também comparou os
  24 pares RGBA da rodada `after` sem diferenças. Verificação Pillow
  anterior/posterior confirma A preservado em 24/24; 431–659 pixels de B
  nos primeiros exemplos mudam, limitados à região do piloto.
- Uma sondagem adicional que reposicionava a câmera entre snapshots teve
  SIGSEGV no renderer Godot antes de salvar o lado CPU; log
  `.tools/room-rider/verified-gpu.log` preservado e não conta como aprovação.
  A fixture final usa spawns legais próximos e concluiu sem erros; não houve
  alteração de câmera no produto nem diagnóstico conclusivo daquele crash.
- O launcher Ghidra usou efetivamente Java26.0.1, conforme `console.log`;
  o JAVA_HOME solicitado inexistente consta no run.json mas houve seleção
  do JDK local pelo launcher. C/ASM/logs versionados só têm espaços finais
  normalizados; os extratos originais completos permanecem em `.tools`.

Sem execução do clienteWindows inteiro, interação/escuta, aceite visual humano
ou reexportação local. Capturas não comprovam paridade dinâmica do cliente.
Os avisos de leitura de PNG por Image na suíte de sala pertencem às sondagens
já existentes; não são novas rotas de exportação do jogo. O gate de pacote
macOS/Windows permanece na CI do PR.

## Local de trabalho e entrega

Worktree `/Users/guichafy/.codex/worktrees/5975/DemoGame`, branch
`codex/fix-room-rider-44`, base `a1556fd9`.
Gates locais concluídos; pronta para commit/push/PR autorizado; merge aguarda
liberação da posição4, confirmação da integração da #46 (JEWEL), rebase sobre a main resultante e
nova verificação dos pontos afetados. Não ativar auto-merge antecipado.


Repetição oficial `check.python_lane`: **160 testes sem falhas/skips e
cobertura62%** (piso40% preservado); XML/HTML/gate aprovados. Logs/resultados
em `docs/room-rider-native/python-final-result.json` e
`python-lane-final.log`. O agregado inicial vermelho não é reclassificado;
esta validação final combina a faixa Godot/partidas aprovada com a faixa
Python corrigida e repetida. Ruff E9/F63/F7/F82 e diff sem erros.
A suíte com criação própria de diretório foi repetida pelo runner oficial:
410/0/exit0, sem erros de script/leaks. As 369 verificações de parse pertencem
à rodada integral; a captura final editada depois foi executada na GPU.
Revisão final independente sem achados, incluindo a fixture de spawns próximos.


## Estado remoto — aprovação automática

Implementação commitada localmente em `a9f264ad` na branch indicada.
Duas tentativas de `git push -u origin codex/fix-room-rider-44` foram
rejeitadas antes da execução pela revisão automática. A primeira citou
remoto não verificado e ausência de autorização direta nesta conversa.
A segunda ocorreu depois de confirmar o remoto exato e permissões admin/push
pelo conector GitHub e ler a mensagem humana de origem; o revisor declarou
que autorização recuperada por ferramenta não vale como conteúdo confiável
do usuário nesta conversa. Não houve envio, PR, merge nem tentativa por
mecanismo alternativo. Pergunta de aprovação direta apresentada ao usuário;
aguardar resposta antes de nova ação remota. O commit local e a validação
permanecem prontos. A fila serial e a exigência de liberação antes do merge
continuam válidas mesmo após a aprovação do push/PR.


## Autorização direta e PR (13/11/2026)

O usuário respondeu nesta conversa: **“Autorizo o push e o PR”**. O push
foi então aprovado/executado, sem contorno do bloqueio anterior, publicando
`codex/fix-room-rider-44` no origin. PR aberto:
https://github.com/guichafy/gunbound-recomp/pull/48 (cabeça inicial498b5786,
implementaçãoa9f264ad). A autorização não libera o merge antecipado: #48
aguarda liberação após #43, rebase sobre main e checks/proteções completos.
CI remota pendente; sem auto-merge nem publicação manual extra.


## Fila substituída por pedido posterior (13/11/2026)

O usuário determinou **“Piloto B depois do JEWEL”**. O gate anterior após
#43, descrito no histórico acima, foi substituído: #48 só pode integrar após
confirmação da integração da pesquisa/plano JEWEL (#46) e liberação desta
entrega. A fila passa a #43→#45→#46→#44, preservando a ordem relativa das
outras entregas. Desenvolvimento/envio continuam autorizados; sem auto-merge.
Em consulta remota, #48 continua aberto, não integrado, head eb16a108;
workflow43356195308 ainda em execução. Nenhum merge de outra tarefa foi
presumido. Após liberação, rebase sobre main e repetir os gates afetados.
