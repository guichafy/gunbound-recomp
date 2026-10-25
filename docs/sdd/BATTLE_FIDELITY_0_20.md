# Fidelidade da batalha 0.20.0

24/10/2026. REQ-03/04/05/06/07/08/09/10/19/23/28/34/44/45;
ADR-084/085. Código integrado ao workspace, sem commit ou push nesta entrega.
A versão continua definida somente em `project.godot`.

## O que foi implementado

As tarefas 1–7 de [BATTLE_FIDELITY_PLAN.md](BATTLE_FIDELITY_PLAN.md) estão
implementadas. A tarefa 8 entregou pesquisa de 48 tiros e planos por família;
não significa que todas as mecânicas pesquisadas já tenham sido portadas.

- Minas conservam dono, dano e crédito de Gold sem trocar autor, arma, item
  ou custo do tiro em andamento. Avanço no laço comum da previsão/voo;
  resultado letal e recompensa sem duplicação. ShellState preserva raio,
  parâmetros Lightning e estado completo dos filhos/cristais.
- Balística comum original a **20 Hz**, ponto fixo **24.8** (8 bits
  fracionários), LUTs originais, truncamentos e aceleração capturada no
  lançamento. Movimento, colisão e aceleração têm ordem explícita. CPU usa
  cópias fechadas; tabelas/catálogo são carregados antes da thread de busca.
- Mira limitada pelo catálogo, sem teto adicional de 85°; CPU considera os
  extremos legais. HUD, inclinação, direção e disparo usam a mesma conversão.
  Força física `P=1..10*f25`, convertida uma vez do percentual da barra.
  Slice chega a 100% em **3 s**, dispara uma vez e cancela na pausa; Drag
  preserva soltura, força variável e mínimo nativo. Vento inicial 0–25,
  eventos 0–26, oscilação por turno e 90° para cima na tela.
- Boomer tem curva/sustentação e S2 em ticks 8/10/12/14. SS normal até 35,
  change congelado nos ticks 36–45, sem contatos climáticos, e retomada 46:
  dano ×2 e diâmetro 46→55 antes de converter ao raio 27, 5. Cada projétil
  guarda seu relógio; o desenho não decide transformação.
- Catálogo audiovisual de **48 combinações** usa MainAction/EPA: pose,
  grupos, componentes e áudio autoritativo. Um som por chamada de emissão;
  Dual separa início da segunda pose do primeiro spawn, Dual+ mantém sua
  arma e Aduka SS não perde a emissão final no tick 10.
- Turtle S1/S2 desenha **WaterEffect** original sobre histórico físico
  (16 pontos, 15 segmentos, largura±16, fase 8 e alpha de 4 bits), sem a cabeça
  compartilhada com Armor. Dragon S1/S2 mantém corpo invisível/partículas;
  `bullet14c/cl` é só filho SS. Glow-only usa uma camada e EPA base.
  Knight151blast e Aduka23blast ausentes permanecem silêncio explícito.
- Contato opaco dos 13 clássicos é pré-calculado para funcionar no PCK sem
  PNG cru. Interpolação modifica só cópias visuais. Armor/Turtle SS publicam
  estados visuais a partir do open/hold existente; Turtle retém o último
  quadro de change quando não há cnormal na EPA. HD aprovado preservado.

## Evidências e estado da validação

Revisões independentes de minas/fábrica, física/Boomer e audiovisual aprovaram
especificação e qualidade após correções. A revisão física fechou quatro
regressões: dupla quantização, tick perdido por fracionamento, contato de
clima durante o freeze e carga máxima em 99, 999…%. A revisão audiovisual
reproduziu e fechou a regressão de Armor SS preso visualmente em normal.

| Evidência observada | Resultado |
|---|---|
| Física comum; Boomer | 1077 +88 checks, sem falhas |
| Minas/voo; Gold; roster clássico | 86 +43 +136 checks, sem falhas |
| Assets; timeline; cena de timing | 49 +158 +18 checks, sem falhas; teardown de áudio corrigido no teste e revalidado dirigido |
| Probe independente de todos os tiros | 48 voos, sem divergências de FP/projéteis/eventos/terreno/HP/escudo/posição entre real e snapshot |
| Auditoria de assets | 95 folhas/13 mobiles; 396 PNGs originais preexistentes byte-idênticos; matriz de timing48/48 |
| Harness completo final | **7287 checks Godot, 16 testes Python e 29 partidas completas**, zero falhas; parse de todos os scripts/capturas aprovado |

A rodada intermediária passou nas assertivas, mas não fechou o harness por
teardown do AudioServer; o teste foi corrigido sem alterar produção nem
relaxar filtros de ERROR. Fixtures antigas de carga/física e a API removida
`Combat.advance` foram migradas, mantendo as verificações funcionais.
A rodada final **`./scripts/check.sh` passou integralmente**, após o fix do
teardown. Log: `.tools/battle-execution/final-full-check-3.log`. São 13 seeds
existentes +16 partidas naturais, uma por mobile. A cena de timing também
passou em duas execuções dirigidas posteriores ao fix (18 checks cada),
sem ERROR; estes resultados dirigidos não são somados novamente ao total.

### Capturas e pendências da entrega

O editor nativo gerou [composition.png](../classic-shots/composition.png) e
[timeline.png](../classic-shots/timeline.png). O coordenador inspecionou a
composição: WaterEffect distinto do Armor, estados do Boomer e contatos.
O framebuffer salvo mede **3004×1805**, com o quadro 1920×1080 no canto;
**não é uma captura Full HD final**. O script agora usa SubViewport 1920×1080
e compila, mas sua reexecução nativa foi bloqueada por timeout no controle UI;
a CLI GPU aborta134. Recaptura Full HD permanece pendente, sem inventar PNG.

A recaptura1920×1080 deve registrar método, arquivos, inspeção e limites,
preservando a evidência existente.

### Aplicativo e PCK

App e ZIP **0.20.0** reexportados em `builds/` (ZIP aproximadamente201 MB),
com CRC do ZIP e Info.plist interno conferidos, além da assinatura válida por
`codesign --verify --deep --strict`. Build terminou com exit0; seu log
**não está limpo**: o ambiente macOS emite erro de certificados CA e impede
salvar `editor_settings-4.7.tres` fora da sandbox. Esses erros não foram
suprimidos. Log local: `.tools/battle-execution/build-macos.log`.

Smoke executado em `/tmp`, com `--main-pack` absoluto externo ao projeto:
**160 checks, zero falhas de assertiva, exit0**. Auditoria confirmou
`mode=packed`, `res` sem raiz do projeto, `override.cfg=false` e override TLS
vazio. Não houve SCRIPT ERROR nem leaks. O log registra **um ERROR ambiental**
de `get_system_ca_certificates` (`ret != noErr`), portanto não é apresentado
como smoke com log limpo. Evidência: `.tools/battle-execution/pck-smoke.log`.
Aprovação das assertivas de recursos/runtime é distinta dessa ressalva do
ambiente. O override de certificados não foi serializado no pacote.

Escuta/captura de áudio e teste manual com mouse **não realizados**.
O áudio foi validado por PCM, agenda e pool SFX; não pela saída do dispositivo.

Logs e relatórios locais em `.tools/battle-execution/`, incluindo
`progress.md`, `mines-review.md`, `physics-review.md`, `final-review.md` e
`audiovisual-fix-report.md`. Não são dependências runtime. `override.cfg`
resolveu certificados no ambiente de teste e foi removido do ROOT antes
do export; **não deve integrar o pacote**.
O preset inclui JSONs/LUTs e os recursos importados WAV/PNG; o smoke isolado
acima verificou o conjunto empacotado, incluindo recursos de apresentação.

## Limites e próxima etapa

A engenharia reversa foi estática: o cliente original não foi executado.
As fixtures independentes comprovam operações traduzidas, não equivalência
da partida completa. Permanecem adaptações a colisão varrida/caixas, dano e
crateras, tornado, hélices/órbitas, sinalizador e calendário de clima. Não
anunciar emulação nativa integral desses sistemas.

[BATTLE_SHOT_MATRIX.md](BATTLE_SHOT_MATRIX.md) registra48 tiros/44 classes,
fontes e confiança. [BATTLE_MOBILE_FAMILY_PLANS.md](BATTLE_MOBILE_FAMILY_PLANS.md)
separa próximos portes: Armor S2/dois impactos, geometrias especiais,
ASate/Knight/satélites, JD/atração, Aduka/Thor e Grub/ricochetes, entre outros.
Poder 0 na tabela não comprova ausência de dano: pode ser um estágio guia.
As partículas Dragon e estágios secundários SS ainda não têm paridade visual
integral. Matriz preenchida não transforma pendências em mecânicas prontas.

O contato pré-calculado do ASate passou de 0 para−3 porque usa o fundo alpha
real; isso desloca o registro visual 3 px, sem modificar colisão. É um limite
explícito para inspeção visual. O aceite funcional/visual/sonoro pelo usuário
continua pendente. Perfil real e fonte C# não foram modificados; rede,
contas, ranking e multiplayer não fazem parte desta versão.
