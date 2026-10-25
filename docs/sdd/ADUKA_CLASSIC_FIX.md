# Aduka — guias e Thor do cliente clássico

REQ-04/05/07/08/19/44/45. Escopo desta correção: os guias S2/SS devem
acionar Thor mesmo sem o clima Thor. S2 conserva duas emissões, SS três
(cronologia em `classic_shot_timing.gd`). O poder zero do guia não é o poder
do efeito. T1, elenco, equipamentos, avatares HD e perfil são preservados.

## Especificação e plano (antes do código)

1. Fixar o PE e seguir chamadas, ABI, células protegidas e inicializadores.
2. Isolar `aduka_effect.gd`: preparo do guia, impacto com autoria, tabelas de
   Thor e estado visual por efeito; mesma API na execução e previsão.
3. Interceptar o guia antes da explosão comum; suprimir o segundo Thor
   climático. Snapshot copia o Thor e a lista de efeitos profundamente.
4. Verificar tabela/limiares, ausência de clima, autoria, obstáculos, repetição,
   cópia e término visual. A integração roda também as regressões completas.

## Fonte e evidências estáticas

PE `.tools/mobile-animation-port/GunBound.gme`, SHA-256
`4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde`,
image base0x400000, x86 LE32 Windows. Ghidra12.2 headless direto/JDK26,
runner da skill `gunbound-client-port`, projeto exclusivo
`builds/ghidra-aduka-fix`. Extratos locais novos em `.tools/aduka-fix/`.
JDK25 foi solicitado, mas somente JDK26 está instalado; execução direta
confirmada, sem mudar a instalação nem configurações globais.

| Contrato | Prova | Classificação e decisão |
|---|---|---|
| Thor fora do clima | `0x439916..939` compara clima4 e aceita argumento final não zero; callers S2 `0x4ab284..292` e SS `0x468601..611` empilham1 | Comprovado: efeito Aduka não consulta clima |
| Guia sem poder próprio | characterdata/type15; callers distintos de S1 | Comprovado: preparo zera dano/raio e não substitui por T1 |
| Estado inicial | construtor `0x4abb70`, células+0x4c=1, +0x270=0, +0x494=0 | Comprovado: nível1, XP0; posição é entrada de `0x439d90` |
| Nível | `0x4ac180`, EAX=self; compara XP+0x270 com tabela e `SETG`, atualiza+0x4c | Comprovado: comparação estrita, teto6 |
| Tabelas | inicializador real `0x541f10`; `PUSH imediato`, EDI=célula e `CALL 0x40a380`; getters ECX=self, subtração nível−1 e stride0x224 | Comprovado: ver tabela abaixo; não copiar pseudocódigo com argumento ausente |
| Blast do Thor | `0x432320`, ECX=y, nove DWORDs na pilha, `RET0x24`; getters `0x4ac260/330` escrevem três células cada | Comprovado: poder e dimensão vêm do Thor, não do guia |
| Origem do raio | `0x4399e5..a56`, ângulo delta e LUT `0x54c240`; floats +50/−50 em `0x5580b0/b4` | Comprovado: canhão deslocado50px com truncamento de cada produto; helper direto `target_angle`, sem quantização de voo |
| Obstáculos | ramo `0x439a68..aaf`: flag do contexto → `0x4e4fe0`, passo2, terreno1, atores1; ramo alternativo usa alvo direto | Comprovado quanto aos ramos; seleção do contexto de rede não é reproduzida no treino; trace comum explicitamente adaptado |
| Vida visual | `0x4aacb0`: contador inicial−1, incrementa, remove quando>19 | Comprovado: vinte ticks visíveis antes da remoção no21º avanço |
| Duas camadas do feixe | `0x4aacd0`: largura exterior16+tick²×100/período, alpha max(255−16tick,1); interior max(16/max(tick,1),1), alpha255 até9, depois max(455−20tick,1) | Comprovado para multiplicador visual1; quads inteiros via LUT e triângulos explícitos |
| Textura/UV/mistura | consumidor `0x4c45e4..46f3`, string `0x556794=LaserEffect`, float `0x558060=1/16`; helper `0x4ed5a0`; estados19=5/20=2 | Comprovado: `LaserEffect.xtf`, primeiras8 de16 colunas, altura completa, origemv1→destinov0, SRCALPHA/ONE |
| XP recebido e dano final | resolução de blast atual `Damage/Combat` | Adaptado: dano efetivo do porte alimenta XP; não se anuncia paridade integral do dano nativo |
| Inicialização espacial ausente | `0x439d90` recebe coordenadas, não cria posição aleatória | Adaptação explícita: sem posição ativa anterior, centro superior do mapa; não consumir RNG da partida |

| nível | poder | dimensão nativa | período visual | RGB | limiar XP |
|---|---|---|---|---|---|
| 1 | 100 | 44 | 1000 | 00ff00 | 0 |
| 2 | 140 | 46 | 800 | 00c040 | 200 |
| 3 | 180 | 48 | 700 | 008080 | 600 |
| 4 | 220 | 50 | 600 | 0040c0 | 1600 |
| 5 | 260 | 52 | 500 | 0000ff | 3600 |
| 6 | 300 | 54 | 400 | ffffff | 6600 |

O índice dos getters é nível−1. O laço de nível percorre todos os seis
limiares e grava índice+1 quando XP é estritamente maior: XP200 ainda é
nível1; XP201 é nível2; XP6600 ainda é nível5; XP6601 é nível6. Não é a
tabela C# `[800,1400,2000,2400,3000]`.

`01-gate`, `03-init`, `06-final`, `07-spawn` possuem manifestos completos
`ok=true`. `02-tables` é parcial (Animate ainda ausente), `04-thor` e
`05-state` registram seletores interiores ainda não reconhecidos; as
rotinas relevantes foram recuperadas pelas entradas demonstradas em
`06-final`. Esses resultados parciais não são tratados como sucesso.
`08-render`, `09-angle`, `10-texture` e `11-quad` também terminaram com
`ok=true`. `0x4f1f10` recebe EAX=dx/ECX=dy; divide ambos por2 rumo a zero
até caber em−127..128, depois lê WORD assinado, sem arredondar a múltiplos
de3. Amostras diretas da LUT: esquerda179°, cima89°, canhão49px nesses
extremos; esse detalhe não pode ser substituído por atan2 ideal.

`scripts/import_aduka_thor.py` extrai somente
`assets/openbound/aduka/ThorEffect.png` e `thor_effect.json`. O recurso é a
LaserEffect compartilhada, não as texturas chamadas ThorTexture1/2. Nenhum
PNG anterior é sobrescrito. ArquivoXFS SHA
`a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08`;
PNG256×256 SHA
`71ebc386de15aea7f34b6707083837c4cf4d181abd1d2c6543390561dfd204cd`.

## Integração e limites

`AdukaEffect.active`, `prepare`, `impact` e `tick` são contratos puros do
modelo, sem leitura do renderer/câmera. `impact` usa `weather.thor` e
`battle_effects` do modelo que o chamar. Cada efeito retém dono, arma,
veículo, origem e destino; a previsão trabalha sobre cópias. A conversão da
dimensão para raio do sistema de crateras atual permanece adaptação do
porte, assim como a varredura `Combat.trace_segment` e os modificadores.
O final1 em ambos os callers não comprova, sozinho, que SS atravesse
obstáculos; não inventar essa distinção por conhecimento informal do jogo.

`aduka_beam_art.gd` tem `draw(view,effects,offset)`, `clear()` e
`triangle_data(effects,offset)`. Cada view recebe um CanvasItemRID filho com
material ADD privado; o material do pai nunca é alterado. Limpa a camada a
cada desenho, inclusive lista vazia, e libera RIDs no PREDELETE. Os efeitos
de apresentação aceitam `age` congelada pela pausa; os quads usam só cópias.

## Validação dirigida observada

25/10/2026, Godot4.7.2 fonte (sem exportar):

- `test_aduka_effect.gd`: **93 checks/0 falhas**. Tabelas completas,
  igualdade/anterior/posterior nos limiares, extremos de nível, oito deltas
  assimétricos do canhão, ausência/presença anterior de Thor, obstáculo,
  autoria, guia zero/Thor separado, idempotência, três guiasSS, cópia do
  estado e vida visual.
- `test_aduka_beam_art.gd`: **16 checks/0 falhas**. Geometria/UV inteira,
  camadas/cores/alpha em0/10/19/20, múltiplos feixes, relógio congelado,
  material ADD privado, reuso/limpeza de RID e encerramento sem leaks.
- `python3 -m unittest discover -s tests -p test_aduka_thor_assets.py -v`:
  **2 testes aprovados**. Todos65536pixels são comparados independentemente
  com os WORDs ARGB4444 da fonte e o manifesto confere recurso/UV/hash.
- Parse isolado do efeito e renderer aprovado. Import do recurso concluiu;
  registrou somente o erro ambiental conhecido de CA do macOS, sem
  SCRIPT ERROR. Logs em `.tools/aduka-fix/*-engine.log` e `import-art.log`.

Integração em Match/FlightSnapshot/WeatherArt, regressões completas e QA GPU
são responsabilidade da tarefa principal; estes números dirigidos não
substituem esses gates nem constituem aceite visual.

Cliente original não executado; captura GPU temporal, escuta, mouse e aceite
visual pertencem à validação integrada, separados desta evidência estática.
Sem exportação, commit ou push nesta etapa.
