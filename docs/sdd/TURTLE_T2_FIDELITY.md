# Turtle T2 — fidelidade do movimento 0.20.2

24/10/2026 (America/Sao_Paulo). REQ-04/08/19/44/45, ADR-087. O usuário apontou que o T2 ainda
não reproduzia o original. O movimento e o rastro foram corrigidos; revisão
independente e harness final aprovados. Baseline 0.20.1 preservado em
`.tools/turtle-t2/before/`. Avatares, T1, SS, HUD e carga mantêm seus contratos.

## Causa e contrato implementado

A 0.20.1 corrigiu a faixa e o SS, mas manteve a órbita constante
`Vector2(0,20).rotated(age*1.5+phase)`. Ela não reproduzia a agenda de fase e
amplitude do cliente, nem a largura e orientação próprias do T2. A aproximação
C# também é distinta; o porte segue as instruções e LUTs comprovadas do PE.

`TurtleFlight` mantém quatro inteiros por projétil: fases iniciais 0/180°,
amplitude 1000, avanço 5 e contador 0. A amplitude é dividida por 100 para
obter pixels. Nos dez primeiros ticks ela cresce 200 e o avanço cresce 4;
depois diminuem 20 e 1, respectivamente, com piso zero. A fase usa o avanço
atual antes de atualizar esse envelope. Após 55 ticks, as fases param em
185/5°; a amplitude chega a zero após 160 ticks.

A ordem no passo comum de 20 Hz é: mover a trajetória central, calcular a
onda/colisão, aplicar aceleração, guardar a seção do rastro, avançar fase e
atualizar amplitude/avanço. O ponto da onda usa o heading quantizado **antes**
da aceleração; a seção usa o heading **depois**, com meia largura de 10 px.
Os produtos das LUTs são truncados antes de shift8/divisão inteira por 100.
O offset não se acumula na trajetória central. Colisão real e previsão usam
o mesmo ponto, enquanto a apresentação interpola cópias das posições/seções.
Dual/Dual+ têm relógios independentes; Teleport continua sem onda.

Provas: Detonate `0x4af9ca..4afbdf`, Animate `0x4b1073..4b1763` e helper de
heading `0x4585e0`. Pesquisa, extratos ASM e manifestos em
`.tools/turtle-t2/research.md`; oráculo com **32 estados e 98 amostras de
geometria em sete direções/casos**, derivado das instruções e LUTs sem chamar
o produto. O cliente original não foi executado.

## Raster e revisão

A revisão reproduziu um P2 em tiros legais de força mínima: a mudança de
orientação perto do ápice pode cruzar os vértices do quadrilátero. A
triangulação automática de `draw_polygon` rejeitava esse formato. Também
ocorria no caminho adaptado de Tornado, sem interpolação.

O T2 agora envia dois triângulos explícitos por seção ao RenderingServer,
com índices 0/1/2 e 0/2/3, preservando diagonal, UV e alpha. T1 mantém seu
`draw_polygon` anterior. O reparo não muda a onda nem o ponto de colisão.

Regressões: **RED 426 checks/327 falhas → GREEN inicial 520/0**. Raster:
RED 584/1, seguido do fix e revalidação. **Suíte T2 final: 588 checks/0 falhas**,
incluindo paridade real/previsão, 30/60/120 FPS, pausa e itens.

Gates independentes de especificação e qualidade aprovados após o P2:
24 cenários/28667 verificações de integração, 46 de isolamento CPU/T1 e
32 de raster, todos sem falhas. Os dois quadriláteros cruzados preservam
triângulos, posições, UVs e alpha; um callback `_draw` os submeteu sem erro
no teste headless. Relatório em `.tools/turtle-t2/review.md`.

## Validação final e captura temporal

**Harness completo: 8020 checks Godot + 16 testes Python + 29 partidas
(13 seeds e 16 mobiles), zero falhas; parse de todos os scripts aprovado.**
Log `.tools/turtle-t2/full-check.log`. Depois dessa rodada, somente o script
de captura recebeu seis SubViewports de 960×320 para recortar os painéis;
seu parse isolado passou com log limpo.

Captura pelo editor nativo, Cmd+R, usando `tests/capture_turtle_t2.gd` e
adaptador Node local: **1920×1080, 60 FPS, 270 quadros/4,5 s**, incluindo
30 quadros de pausa. Mostra T2 normal, força mínima P1 e Tornado adaptado do
C#, nos dois sentidos. Quadros 030/090/149/230 foram inspecionados: duas
faixas oscilam e se aproximam da trajetória central; contador 61/avanço 0 no
fim da sequência. Quadros 150 e 179 da pausa têm hash de bytes idêntico.

[Vídeo Full HD](../turtle-t2/turtle-t2.mp4) ·
[Início](../turtle-t2/time-030.png) ·
[Oscilação](../turtle-t2/time-090.png) ·
[Antes da pausa](../turtle-t2/time-149.png) ·
[Pausa](../turtle-t2/time-179.png) ·
[Retomada](../turtle-t2/time-209.png) ·
[Aproximação](../turtle-t2/time-230.png).

Vídeo final de 706847 bytes (aproximadamente 690 KiB), com os seis painéis
recortados. Quadros completos em `.tools/turtle-t2/gpu-frames/`. A evidência usa Match e
renderer reais; não é captura dinâmica do cliente original. O usuário confirmou
o aceite visual do T2: “Agora funcionou”. Escuta e mouse manual continuam
sem validação registrada; esse aceite não amplia a paridade mecânica declarada.

## Limites e pacote

Esta versão fecha a onda e a seção do T2 no voo ordinário. Tornado, colisão
varrida, dano/cratera e física numérica dos filhos SS permanecem adaptações;
não é emulação integral do combate. C# e imagens originais preservados.

**App/ZIP 0.20.2 reexportados**, exit0; assinatura ad-hoc verificada com
`codesign --verify --deep --strict`. ZIP de 210317612 bytes (aproximadamente
201 MiB), CRC e ambas as versões 0.20.2 do Info.plist interno conferidos.
Probe de recursos na fonte: **163 checks/0 falhas**, log limpo.

Smoke do PCK isolado em `/tmp`: **179 checks/0 falhas/exit0**, modo packed,
`res=` vazio, `override.cfg=false` e TLS override vazio. O único ERROR do
smoke é o conhecido `get_system_ca_certificates` no startup do macOS; build
também registra editor_settings fora da sandbox. Não declarar esses logs
limpos. Override ausente do ROOT e do pacote.

Hashes de runtime, testes e QA permaneceram iguais após as verificações;
a última revisão da captura foi compilada separadamente antes do export.
Logs locais: `.tools/turtle-t2/build-macos.log`, `pck.log` e
`pck-source.log`; hashes em `.tools/turtle-t2/release-artifacts.json`.
PNGs preexistentes não foram alterados; `git diff --check` passou. Pacote
0.20.1 preservado como histórico. Sem commit, push ou publicação.
